# SOURCES = $(wildcard src/*.cr) $(wildcard src/**/*.cr)

MAIN = bin/main
CRYSTAL = crystal

all: android freebsd linux windows format

bin/main: src/*.cr
	@mkdir -p bin
	$(CRYSTAL) build --release -o bin/main src/main.cr

android: bin/main
	CPATH=include/android/arm $(MAIN) --os=android --arch=arm --bits=32
	CPATH=include/android/arm64 $(MAIN) --os=android --arch=arm64 --bits=64
	CPATH=include/android/mips $(MAIN) --os=android --arch=mips --bits=32
	CPATH=include/android/mips64 $(MAIN) --os=android --arch=mips64 --bits=64
	CPATH=include/android/x86 $(MAIN) --os=android --arch=x86 --bits=32
	CPATH=include/android/x86_64 $(MAIN) --os=android --arch=x86_64 --bits=64

freebsd: bin/main
	CPATH=include/freebsd $(MAIN) --os=freebsd --arch=x86_64 --bits=64

linux: bin/main
	CPATH=include/linux/x86/gnu $(MAIN) --os=linux --libc=gnu --arch=i686 --bits=32
	#CPATH=include/linux/x86_64/gnu $(MAIN) --os=linux --libc=gnu --arch=x86_64 --bits=64
	CPATH=include/linux/x86/musl $(MAIN) --os=linux --libc=musl --arch=i686 --bits=32
	#CPATH=include/linux/x86_64/musl $(MAIN) --os=linux --libc=musl --arch=x86_64 --bits=64

windows: bin/main
	CPATH=include/cygwin $(MAIN) --os=windows --libc=cygwin --arch=x86 --bits=32

format:
	$(CRYSTAL) tool format lib_c
