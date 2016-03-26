lib LibC
  alias Char = UInt8
  alias UChar = Char
  alias SChar = Int8
  alias Short = Int16
  alias UShort = UInt16
  alias Int = Int32
  alias UInt = UInt32

  ifdef x86_64
    alias Long = Int64
    alias ULong = UInt64
  elsif i686
    alias Long = Int32
    alias ULong = Int32
  end

  alias LongLong = Int64
  alias ULongLong = UInt64
  alias Float = Float32
  alias Double = Float64
end

ifdef darwin
  ifdef x86_64
    require "./x86_64-macosx-darwin/**"
  else
    # TODO: darwin x86 (?)
    {% raise "only x86_64 architecture is supported for sys=macosx abi=darwin" %}
  end
elsif linux
  ifdef musl
    ifdef x86_64
      require "./x86_64-linux-musl/**"
    elsif i686
      require "./x86-linux-musl/**"
    else
      # TODO: ARM, MIPS, ...
      {% raise "only x86 and x86_64 architectures are supported for sys=linux abi=musl" %}
    end
  elsif gnu
    ifdef x86_64
      require "./x86_64-linux-gnu/**"
    elsif i686
      require "./x86-linux-gnu/**"
    else
      # TODO: ARM, MIPS, ...
      {% raise "only x86 and x86_64 architectures are supported for sys=linux abi=gnu" %}
    end
  else
    # TODO: android
    {% raise "only gnu and musl ABI are supported for sys=linux" %}
  end
else
  # TODO: cygwin, freebsd, ios
  {% raise "only darwin and linux systems are supported" %}
end
