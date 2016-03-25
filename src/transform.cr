require "yaml"
require "crystal_lib"
require "crystal_lib/clang"
require "./resolver"

STDERR.sync = true

module CrystalLib
  class StructOrUnion
    def dup(name)
      cpy = StructOrUnion.new(kind, name.to_s)
      cpy.fields = fields
      cpy
    end
  end

  class Function
    def dup(name)
      cpy = Function.new(name.to_s, return_type, variadic?)
      cpy.args = args
      cpy
    end
  end

  class Var
    def dup(name)
      Var.new(name.to_s, type)
    end
  end
end

module POSIX
  class Transformer
    getter name
    getter nodes
    getter resolver
    private getter requirements
    private getter processed

    def initialize(name, @bits = nil)
      @name = name.to_s

      @resolver = Resolver.new
      @nodes = CrystalLib::Parser.parse(header)

      maps { |name, value| resolver.map_default(name, value) }
      @nodes.each { |node| resolver.map_recursive(node) }

      @requirements = [] of String
      @processed = [] of String
    end

    def transform
      String.build do |io|
        requires do |name|
          _name = name as String
          if File.dirname(_name) == File.dirname(@name)
            io << "require \"./#{File.basename(_name)}\"\n"
          elsif File.dirname(@name) != "."
            io << "require \"../#{_name}\"\n"
          else
            io << "require \"./#{_name}\"\n"
          end
        end
        io << "\n"
        io << "lib LibC\n"

        constants { |name| transform(io, name, :constant) }
        io << "\n"

        enums { |name| transform(io, name, :enum) }
        io << "\n"

        types { |name| transform(io, name, :type) }
        io << "\n"

        unions { |name| transform(io, name, :union) }
        io << "\n"

        structs { |name| transform(io, name, :struct) }
        io << "\n"

        aliases do |name, value|
          io << "  alias #{crname(name)} = #{crname(value)}"
        end
        io << "\n"

        functions do |name|
          if name.index('\n')
            flags = name.strip.split('\n')
            name = flags.pop
          end
          if name.index(':')
            name, return_type = name.split(" : ", 2)
          end
          if node = find_node(name, :function)
            processed << name as String
            if node.is_a?(CrystalLib::Function)
              transform(io, node as CrystalLib::Function, return_type: return_type, flags: flags)
              next
            end
          end
          STDERR.puts "WARN: can't find #{name}"
        end
        io << "\n"

        variables { |name| transform(io, name, :variable) }
        io << "\n"

        until requirements.empty?
          requirements.uniq!

          name = requirements.shift
          next if processed.includes?(name)
          processed << name
          next unless name.starts_with?('_')

          if node = resolver.unions[name]?
            transform(io, node.dup(name))
          elsif node = resolver.structs[name]?
            transform(io, node, name)
          end
        end

        io << "end\n"
      end
    end

    def transform(io, name, type : Symbol)
      if node = find_node(name, type)
        if type == :struct
          while node.is_a?(CrystalLib::Define)
            node = find_node(node.value, type)
          end
          if node.is_a?(CrystalLib::StructOrUnion)
            node = node.dup(name)
          end
        end
        processed << name as String
        transform(io, node)
      else
        STDERR.puts "WARN: can't find #{name}"
      end
    end

    def find_node(name, type)
      case type
      when :function
        # prefer functions over macros
        if node = nodes.select(&.is_a?(CrystalLib::Function)).find(&.name.==(name))
          return node
        end

        # follow #defines to find function
        _name = name
        while node = find_node(_name, :any)
          break unless node.is_a?(CrystalLib::Define)
          _name = node.value
        end
        if node.is_a?(CrystalLib::Function)
          return node.dup(name)
        end
      when :union
        if node = nodes.select(&.is_a?(CrystalLib::StructOrUnion)).find(&.unscoped_name.==(name))
          return node
        end
      when :type
        # prefer typedef over #define
        if node = nodes.select(&.is_a?(CrystalLib::Typedef)).find(&.name.==(name))
          return node
        end
      when :variable
        # follow #defines to find variable
        _name = name
        while node = find_node(_name, :any)
          break unless node.is_a?(CrystalLib::Define)
          _name = node.value
        end
        if node.is_a?(CrystalLib::Var)
          return node.dup(name)
        end
      end

      nodes.find do |node|
        if node.responds_to?(:unscoped_name)
          node.unscoped_name == name
        else
          node.name == name
        end
      end
    end

    def transform(io, node : CrystalLib::Define)
      value = node.value

      if node.name == value
        # macro definition may reference an enum value
        if enum_value = find_enum_value(node.name)
          value = enum_value.value.to_s
        end
      end

      _value = crvalue(value)
      begin
        ast = Crystal::Parser.parse(_value)
        if ast.is_a?(Crystal::Call)
          unless ast.name == "new"
            STDERR.puts "WARN: can't parse #{node.name}: #{value}"
            return
          end
        end
      rescue
        STDERR.puts "WARN: can't parse #{node.name}: #{value}"
      else
        io << "  " << node.name.sub(/^[_]+/, "") << " = " << _value << "\n"
      end
    end

    def transform(io, node : CrystalLib::Enum, name = nil)
      name ||= node.name

      io << "  enum " << crname(name) << " : " << crtype(node.type) << "\n"
      node.values.each do |ev|
        io << "    " << crname(ev.name) << " = " << ev.value << "\n"
      end
      io << "  end\n"
    end

    def transform(io, node : CrystalLib::StructOrUnion, name = nil)
      if private_struct?(node)
        io << "  type " << crname(node.unscoped_name) << " = Void\n"
        return
      end

      definition = String.build do |str|
        str << "  " << node.kind << " " << crname(name || node.unscoped_name) << "\n"

        node.fields.each_with_index do |field, index|
          type = field.type

          case type = field.type
          when CrystalLib::NodeRef
            # nested structs/unions
            case nested = type.node
            when CrystalLib::StructOrUnion
              if nested.unscoped_name == ""
                type = nested.dup(node.unscoped_name + field.name)
                transform(io, type)
              end
            else
              raise "UNSUPPORTED nested: #{nested.name} (#{nested.class.name})"
            end
          end

          _name = field.name.empty? ? "__reserved_#{index}" : field.name
          _type = crtype(type)
          _type = "Void*" if _type == "Void"

          str << "    " << _name << " : " << _type << "\n"
        end

        str << "  end\n"
      end

      io << definition
    end

    def transform(io, node : CrystalLib::Typedef)
      name, type = node.name, node.type

      while type.is_a?(CrystalLib::TypedefType)
        break unless type.name.starts_with?('_')
        type = type.type
      end

      if type.is_a?(CrystalLib::NodeRef)
        type = type.node
      end

      if type.is_a?(CrystalLib::StructOrUnion)
        transform(io, type.dup(name))
      elsif type.is_a?(CrystalLib::Enum)
        transform(io, type, name)
      else
        __type = crtype(type)

        if __type == "Void*"
          io << "  type " << crname(name) << " = Void*\n"
        else
          if type.is_a?(CrystalLib::PointerType)
            node = type.type
            if node.is_a?(CrystalLib::NodeRef)
              node = node.node
            end
            transform(io, node)
          end
          io << "  alias " << crname(name) << " = " << __type << "\n"
        end
      end
    end

    def transform(io, node : CrystalLib::Function, return_type = nil, flags = nil)
      if flags
        flags.each do |flag|
          io << "  " << flag << "\n"
        end
      end
      io << "  fun " << node.name
      if node.args.any? || node.variadic?
        io << '('

        node.args.each_with_index do |arg, index|
          name = arg.name == "" ? "x#{index}" : arg.name
          name = name.sub(/^_+/, "")
          io << ", " unless index == 0
          io << name << " : " << crtype(arg.type)
        end

        io << ", ..." if node.variadic?
        io << ')'
      end
      io << " : " << (return_type || crtype(node.return_type)) << "\n"
    end

    def transform(io, node : CrystalLib::Var)
      io << "  $" << node.name << " : " << crtype(node.type) << "\n"
    end

    def transform(io, node)
      STDERR.puts "unsupported node (#{node.class.name})"
    end

    def find_enum_value(name)
      @nodes.each do |node|
        next unless node.is_a?(CrystalLib::Enum)
        node.values.each do |enum_value|
          return enum_value if enum_value.name == name
        end
      end
      nil
    end

    def crname(cname)
      case cname
      when "ssize_t"
        "SSizeT"
      when "char_s", "uchar"
        "Char"
      when "schar"
        "SChar"
      when "ushort"
        "UShort"
      when "ulong"
        "ULong"
      when /^uint(.*)/
        "UInt#{$1}".camelcase
      when .starts_with?("_")
        "X_#{cname.downcase.gsub(' ', '_').camelcase}"
      when /\s/
        cname.split(/\s+/).map { |cn| crname(cn) as String }.join
      when /^[A-Z]/
        cname
      else
        cname.downcase.camelcase
      end
    end

    def crtype(ctype)
      case ctype
      when CrystalLib::TypedefType
        name = ctype.name
        if (ref = ctype.type).is_a?(CrystalLib::NodeRef)
          # avoids private struct reference
          if (_node = ref.node).is_a?(CrystalLib::StructOrUnion)
            if _node.unscoped_name != "" && !_node.name.starts_with?('_')
              ctype = _node
              name = ctype.unscoped_name
            end
          end
        elsif (func = ctype.type).is_a?(CrystalLib::FunctionType)
          # avoids private func reference
          return crtype(func) if name.starts_with?('_')
        end

        _name = resolver.resolve_public(name)
        crtype_struct_or_union(_name) || crname(_name)
      when CrystalLib::PrimitiveType
        crname(ctype.to_s)
      when CrystalLib::UnexposedType
        "Void"
      when CrystalLib::PointerType
        "#{crtype(ctype.type)}*"
      when CrystalLib::ConstantArrayType
        "StaticArray(#{crtype(ctype.type)}, #{ctype.size})"
      when CrystalLib::IncompleteArrayType
        "#{crtype(ctype.type)}*"
      when CrystalLib::NodeRef
        crtype(ctype.node)
      when CrystalLib::Enum
        p [:type, ctype]
      when CrystalLib::StructOrUnion
        if ctype.kind == :struct && private_struct?(ctype)
          "Void"
        elsif rtype = resolver.resolve_public(ctype.unscoped_name)
          if rtype.starts_with?("_") && rtype == ctype.unscoped_name
            "Void"
          else
            crtype_struct_or_union(rtype) || crname(rtype)
          end
        else
          crtype_struct_or_union(ctype.unscoped_name) ||
            crname(ctype.unscoped_name)
        end
      when CrystalLib::FunctionType
        inputs = ctype.inputs.map { |arg| crtype(arg) as String }.join(", ")
        "#{inputs} -> #{crtype(ctype.output)}"
      else
        raise "unsupported type: #{ctype.inspect}"
      end
    end

    private def crtype_struct_or_union(name)
      if name == "__pid_t"
        p resolver.struct?(name)
      end

      if resolver.struct?(name)
        if name.starts_with?('_')
          # HACK: let's skip implementation detail
          return "Void"
        else
          requirements << name
        end
      elsif resolver.union?(name)
        requirements << name
      end
      nil
    end

    private def private_struct?(node : CrystalLib::StructOrUnion)
      #node.kind == :struct && (node.fields.empty? || node.fields.all?(&.name.starts_with?('_')))
      node.kind == :struct && node.fields.empty?
    end

    def crvalue(value)
      if value.starts_with?('(') && value.ends_with?(')')
        value = value[1 .. -2]
      end

      # resolves constant value
      value = value.gsub(/\b_[A-Z0-9_]+/) do |m|
        if (node = nodes.find(&.name.==(m))).is_a?(CrystalLib::Define)
          node.value =~ /^[+-.xo\da-f()]+[ULF]*$/ ? node.value : m
        else
          m
        end
      end

      value = value
        .gsub(/\b0(\d+)/, "0o\\1")
        .gsub(/\b([+-.xo\da-fA-F]+)F\b/, "\\1_f32")
        .gsub(/\b([+-.xo\da-f]+)LL\b/i, "\\1_i64")
        .gsub(/\b([+-.xo\da-f]+)L\b/i, "\\1_i#{bits}")
        .gsub(/\b([+-.xo\da-f]+)LL\b/i, "\\1_u64")
        .gsub(/\b([+-.xo\da-f]+)ULL\b/i, "\\1_u64")
        .gsub(/\b([+-.xo\da-f]+)UL\b/i, "\\1_u#{bits}")
        .gsub(/\b([+-.xo\da-f]+)U\b/i, "\\1_u32")

      # execute stdint macros
      [8, 16, 32, 64].each do |n|
        value = value
          .sub(/_*UINT#{n}_C\((.+)\)/, "\\1_u#{n}")
          .sub(/_*INT#{n}_C\((.+)\)/, "\\1_i#{n}")
      end

      if value =~ /^\((?:const)?(.+?)\)([-x\da-f]+)$/
        t, v = $1, $2

        if t.ends_with?("*")
          t = crname(t[0 .. -2])
          t = "Pointer(#{resolver.resolve_public(t)})"
        else
          t = crname(resolver.resolve_public(t))
        end

        value = "#{t}.new(#{v})"
      end

      value
    end

    # Extract long bit size from limits.h.
    #
    # This doesn't work on GNU libc which requires the compiler to define the
    # LONG_BIT, INT_MAX, ... constants.
    def bits
      @bits ||= begin
                  if node = resolve_constant("LONG_BIT")
                    return node.value.to_i
                  else
                    STDERR.puts "ERROR: impossible to determine LONG BIT size"
                    exit
                  end
                end
    end

    private def resolve_constant(name)
      node = nodes.find(&.name.==(name))
      while node.is_a?(CrystalLib::Define)
        return node if node.value =~ /^\d+$/
        node = nodes.find(&.name.==(node.value))
      end
    end

    def header
      String.build do |str|
        str << "#define __CYGWIN__ 1\n"
        str << "#define _GCC_LIMITS_H_ 1\n"
        #str << "#define _POSIX_C_SOURCE 200809L\n"
        #str << "#define _XOPEN_SOURCE 700\n"
        str << "#include <limits.h>\n"
        includes { |h| str << "#include <#{h}.h>\n" }
      end
    end

    {% for kind in %w(includes requires constants enums types unions structs functions variables) %}
      def {{kind.id}}
        if list = source[{{kind}}]?
          (list as Array).each { |item| yield(item as String) }
        end
      end
    {% end %}

    def maps
      if list = source["map"]?
        (list as Hash).each { |name, value| yield(name as String, value as String) }
      end
    end

    def aliases
      if list = source["aliases"]?
        (list as Hash).each { |name, value| yield(name as String, value as String) }
      end
    end

    def source
      @source ||= YAML.parse(File.read(source_path)).raw as Hash
    end

    def source_path
      File.join(__DIR__, "include/#{name}.yml")
    end
  end

  def self.transform(name)
    Transformer.new(name).transform
  end
end
