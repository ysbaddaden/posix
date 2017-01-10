require "./definition"
require "./transformer"
require "option_parser"

module H2CR
  struct Options
    property arch : String
    property sys : String
    property abi : String
    property debug : Bool
    property source : String

    def initialize(@arch = "", @sys = "", @abi = "")
      @debug = false
      @source = File.join(Dir.current, "include", "posix")
    end

    def bits=(@bits : Int32)
    end

    def bits
      @bits || arch.includes?("64") ? 64 : 32
    end

    def target
      {arch, sys, abi}.join('-')
    end
  end

  def self.run
    options = Options.new

    parser = OptionParser.new
    parser.banner = "Usage: h2cr [options] files"

    parser.on("--arch=NAME", "Specify the ARCH (arm, arm64, mips, mips64, x86, x86_x64)") do |arch|
      options.arch = arch
    end

    parser.on("--sys=NAME", "Specify the OS (linux, macosx, pc, unknown)") do |sys|
      options.sys = sys
    end

    parser.on("--abi=NAME", "Specify the ABI (eg: android, cygwin, darwin, freebsd, gnu, musl, netbsd, win32)") do |abi|
      options.abi = abi
    end

    parser.on("--bits=N", "Force the LONG bit size (32, 64)") do |n|
      options.bits = n.to_i
    end

    parser.on("--source=PATH", "Path to source definitions") do |source|
      options.source = source
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

    names ||= Dir[File.join(options.source, "**", "*.yml")]
      .map { |name| name.sub(File.join(options.source, ""), "").sub(".yml", "") }

    #unless options.debug
    #  names.each do |name|
    #    POSIX::Definition.load(name, options.source, options.abi).requires do |dep|
    #      names << dep unless names.includes?(dep)
    #    end
    #  end
    #end

    names.sort.each do |name|
      path = File.join("targets", options.target, "c", "#{name}.cr")
      definition = POSIX::Definition.load(name, options.source, options.abi)
      transformer = POSIX::Transformer.new(definition,
                                           bits: options.bits,
                                           arch: options.arch,
                                           abi: options.abi
                                          )

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
