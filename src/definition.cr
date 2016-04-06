require "yaml"

module POSIX
  class Definition
    YAML.mapping({
      includes:  { type: Array(String) },
      requires:  { type: Array(String), nilable: true },
      constants: { type: Array(String), nilable: true },
      enums:     { type: Array(String), nilable: true },
      types:     { type: Array(String), nilable: true },
      unions:    { type: Array(String), nilable: true },
      structs:   { type: Array(String), nilable: true },
      functions: { type: Array(String), nilable: true },
      variables: { type: Array(String), nilable: true },
      maps:      { type: Hash(String, String), nilable: true },
      libraries: { type: Hash(String, Array(String)), nilable: true },
    })

    def self.load(name : String, abi : String)
      definition = from_yaml(File.read(path(name)))
      definition.name = name
      definition.abi = abi
      definition
    end

    def self.path(name)
      File.join(__DIR__, "include/#{name}.yml")
    end

    property! name, abi

    {% for kind in %w(includes requires constants enums types unions structs functions variables) %}
      def {{kind.id}}
        if list = @{{kind.id}}
          list.each { |item| yield(item as String) }
        end
      end
    {% end %}

    {% for kind in %w(maps aliases) %}
      def {{kind.id}}
        if list = @{{kind.id}}
          list.each { |name, value| yield(name as String, value as String) }
        end
      end
    {% end %}

    def libraries
      if libs = @libraries
        if list = libs[@abi]?
          list as Array
        end
      end
    end
  end
end
