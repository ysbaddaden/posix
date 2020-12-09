module POSIX
  class Resolver
    private getter types
    getter unions
    getter structs

    def initialize
      @types = {} of String => String
      @unions = {} of String => CrystalLib::StructOrUnion
      @structs = {} of String => CrystalLib::StructOrUnion
    end

    # Resolves a type down to a Primitive, Union or Struct type.
    def resolve(name : String)
      if _name = types[name]?
        resolve(_name)
      else
        name
      end
    end

    def struct?(name)
      structs[name]?
    end

    def union?(name)
      unions[name]?
    end

    # Resolves a type, avoiding "private" types (ie. starting with an
    # underscore) as much as possible.
    #
    # For example we're resolving `__size_t` to `ssize_t` on the following
    # pattern:
    #
    #     typedef ssize_t long
    #     typedef __ssize_t ssize_t
    #
    # It also tres to avoid the glibc pattern:
    #
    #     typedef __ssize_t long
    #     typedef ssize_t __size_t
    #     void fn(__ssize_t* x)
    #
    # which would bind to:
    #
    #     alias X_SsizeT = Long
    #     alias SsizeT = X_SsizeT
    #     fun fn(x : X_SsizeT)
    #
    # when it should be as simple as:
    #
    #     alias SsizeT = Long
    #     fun fn(x : SsizeT)
    #
    def resolve_public(name : String)
      return name unless name.starts_with?('_')

      # looking up for: typedef ssize_t __ssize_t
      if value = types.key_for?(name)
        if value != name
          return value unless value.starts_with?('_')
        end
      end

      # looking down for: typedef __size_t ssize_t (recursively)
      if value = types[name]?
        if value != name && (val = resolve_public(value))
          return val
        end
      end

      name
    end

    def map_default(name, value)
      types[name.to_s] = value.to_s
    end

    @outer_typedef : CrystalLib::ASTNode?

    def map_recursive(node)
      if node.is_a?(CrystalLib::Typedef)
        @outer_typedef = node
      end

      if node.is_a?(CrystalLib::StructOrUnion)
        _name = node.unscoped_name
        _name = @outer_typedef.try(&.name) if _name.empty?
        if _name
          case node.kind
          when :union
            unions[_name] = node
          when :struct
            structs[_name] = node
          end
        end
      end

      value = if node.responds_to?(:type)
                map_recursive(node.type)
              elsif node.responds_to?(:node)
                map_recursive(node.node)
              end
      name = find_name(node)

      if value
        unless value.empty?
          if node.is_a?(CrystalLib::PointerType) ||
              node.is_a?(CrystalLib::IncompleteArrayType)
            value = "#{value}*"
          end

          if node.is_a?(CrystalLib::ConstantArrayType)
            value = "StaticArray(#{value}, #{node.size})"
          end

          if name
            unless name.empty?
              types[name] = value
            end
          end
        end
      end

      name
    end

    private def find_name(node)
      value = if node.responds_to?(:unscoped_name)
               node.unscoped_name
             elsif node.responds_to?(:name)
               node.name
             elsif node.responds_to?(:kind)
               node.kind.to_s
             elsif node.is_a?(CrystalLib::NodeRef) ||
                 node.is_a?(CrystalLib::PointerType) ||
                 node.is_a?(CrystalLib::IncompleteArrayType) ||
                 node.is_a?(CrystalLib::ConstantArrayType) ||
                 node.is_a?(CrystalLib::FunctionType)
               return
             else
               STDERR.puts "WARN: unsupported #{node.class.name} node:\n#{node.inspect}\n\n"
               return
             end
      case value
      when .empty?
        nil
      when "Char_S"
        "SChar"
      else
        value
      end
    end

    def map_recursive(node : CrystalLib::Function)
    end

    def map_recursive(node : CrystalLib::Define)
      #types[node.name] = node.value unless node.value.empty?
    end

    def map_recursive(node : CrystalLib::Enum)
      #node.values.each { |n| map_recursive(n) }
    end

    def map_recursive(node : CrystalLib::EnumValue)
      #map_enum_value(node)
    end

    #private def map_enum_value(node)
    #  value = case node.value
    #          when Int8 then "#{node.value}_i8"
    #          when Int16 then "#{node.value}_i16"
    #          when Int32 then "#{node.value}_i32"
    #          when Int64 then "#{node.value}_i64"
    #          when UInt8 then "#{node.value}_u8"
    #          when UInt16 then "#{node.value}_u16"
    #          when UInt32 then "#{node.value}_u32"
    #          when UInt64 then "#{node.value}_u64"
    #          when String then node.value.to_s
    #          else
    #            STDERR.puts "WARN: lost enum value type #{node.value.class.name} for #{node.value}"
    #            node.value.to_s
    #          end
    #  types[node.name] = value unless value.empty?
    #end

    def inspect(io : IO)
      types.each do |name, value|
        io << name << " = " << value << "\n"
      end
    end
  end
end
