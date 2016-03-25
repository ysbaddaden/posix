require "./transform"
require "option_parser"

module H2CR
  struct Options
    property os : String?
    property libc : String?
    property arch : String?
    property bits : Int32?
    property debug : Bool

    def initialize
      @debug = false
    end

    def path
      String.build do |str|
        str << "lib_c"
        {% for part in %w(os libc arch) %}
          if %value = {{ part.id }}
            str << File::SEPARATOR
            str << %value
          end
        {% end %}
      end
    end
  end

  def self.run
    options = Options.new

    parser = OptionParser.new
    parser.banner = "Usage: h2cr [options] files"

    parser.on("--os=N", "Specify the operating system (android, darwin, freebsd, linux, windows)") do |os|
      options.os = os
    end

    parser.on("--libc=NAME", "Specify the libc (eg: cygwin, gnu, musl)") do |libc|
      options.libc = libc
    end

    parser.on("--arch=NAME", "Specify the arch (arm, arm64, mips, mips64, x86, x86_x64)") do |arch|
      options.arch = arch
    end

    parser.on("--bits=N", "Specify the long bit size (32, 64)") do |n|
      options.bits = n.to_i
    end

    parser.on("--debug", "Print the bindings to STDOUT") do
      options.debug = true
    end

    parser.on("-h", "--help", "Show this help") do
      puts parser
      exit
    end

    names = parser.parse(ARGV)
    names = nil if names.try(&.empty?)

    names ||= Dir[File.join(__DIR__, "include", "**", "*.yml")]
      .map { |name| name.sub(File.join(__DIR__, "include", ""), "").sub(".yml", "") }
      .sort

    unless options.debug
      if options.os.nil? || options.arch.nil?
        puts "Error: missing required --os and --arch arguments"
        puts parser
        exit
      end
    end

    names.each do |name|
      path = File.join(options.path, "#{name}.cr")
      transformer = POSIX::Transformer.new(name, bits: options.bits)

      if options.debug
        puts "# #{path}"
        puts transformer.transform
      else
        parent = File.dirname(path)
        puts "#{name} => #{path}"
        Dir.mkdir_p(parent, mode = 0o755) unless Dir.exists?(parent)
        File.write(path, transformer.transform)
      end
    end
  end
end

H2CR.run
