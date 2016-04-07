require "./definition"
require "./transformer"
require "option_parser"

module H2CR
  struct Options
    property arch : String
    property sys : String
    property abi : String
    property debug : Bool

    def initialize(@arch = "unknown", @sys = "unknown", @abi = "unknown")
      @debug = false
    end

    def bits=(@bits : Int32)
    end

    def bits
      @bits || arch.includes?("64") ? 64 : 32
    end

    def target
      @target ||= {arch, sys, abi}.join('-')
    end
  end

  def self.run
    options = Options.new

    parser = OptionParser.new
    parser.banner = "Usage: h2cr [options] files"

    parser.on("--arch=NAME", "Specify the ARCH (arm, arm64, mips, mips64, x86, x86_x64)") do |arch|
      options.arch = arch
    end

    parser.on("--sys=N", "Specify the OS (darwin, freebsd, linux, win32)") do |sys|
      options.sys = sys
    end

    parser.on("--abi=NAME", "Specify the ABI (eg: cygwin, darwin, android, gnu, musl)") do |abi|
      options.abi = abi
    end

    parser.on("--bits=N", "Force the LONG bit size (32, 64)") do |n|
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

    names.each do |name|
      POSIX::Definition.load(name, options.abi).requires do |dep|
        names << dep unless names.includes?(dep)
      end
    end

    names.sort.each do |name|
      path = File.join("targets", options.target, "c", "#{name}.cr")
      definition = POSIX::Definition.load(name, options.abi)
      transformer = POSIX::Transformer.new(definition, bits: options.bits)

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
