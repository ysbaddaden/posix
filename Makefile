MAIN = bin/main
CRYSTAL_BIN ?= crystal
TMP = /tmp/crystal-posix-test
TEST = rm -f $(TMP); $(CRYSTAL_BIN) build --prelude=empty -o $(TMP) src/base.cr

SOURCES = arpa/inet dirent dlfcn errno fcntl iconv netdb netinet/in netinet/tcp \
	pthread signal stdio stdlib string sys/mman sys/select sys/socket sys/stat \
	sys/time sys/times sys/un sys/wait termios time unistd

TARGET := $(subst -, ,$(shell \
	llvm-config-3.6 --host-target 2>/dev/null || \
	llvm-config-3.5 --host-target 2>/dev/null || \
	llvm-config35 --host-target 2>/dev/null || \
	llvm-config36 --host-target 2>/dev/null || \
	llvm-config --host-target 2>/dev/null ))
ARCH ?= $(word 1,$(TARGET))
SYS ?= $(word 3,$(TARGET))
ABI ?= $(word 4,$(TARGET))

.PHONY: clean test

all: bin/main
	$(MAIN) --arch=$(ARCH) --sys=$(SYS) --abi=$(ABI) $(SOURCES)

clean:
	rm -f bin/main

bin/main: src/*.cr
	@mkdir -p bin
	$(CRYSTAL_BIN) build -o bin/main src/main.cr

android: bin/main
	CPATH=include/android/arm $(MAIN) --arch=arm --sys=linux --abi=android
	CPATH=include/android/arm64 $(MAIN) --arch=arm64 --sys=linux --abi=android
	CPATH=include/android/mips $(MAIN) --arch=mips --sys=linux --abi=android
	CPATH=include/android/mips64 $(MAIN) --arch=mips64 --sys=linux --abi=android
	CPATH=include/android/x86 $(MAIN) --arch=i686 --sys=linux --abi=android
	CPATH=include/android/x86_64 $(MAIN) --arch=x86_64 --sys=linux --abi=android

freebsd: bin/main
	#CPATH=include/freebsd32 $(MAIN) --arch=x86 --sys=freebsd
	CPATH=include/freebsd64 $(MAIN) --arch=x86_64 --sys=portbld --abi=freebsd

linux: bin/main
	CPATH=include/linux/gnu32 $(MAIN) --arch=i686 --sys=linux --abi=gnu
	CPATH=include/linux/gnu64 $(MAIN) --arch=x86_64 --sys=linux --abi=gnu
	CPATH=include/linux/musl32 $(MAIN) --arch=i686 --sys=linux --abi=musl
	CPATH=include/linux/musl64 $(MAIN) --arch=x86_64 --sys=linux --abi=musl

gnu32: bin/main
	C_INCLUDE_PATH=/usr/include:/usr/lib/llvm-3.6/lib/clang/3.6.2/include \
		$(MAIN) --arch=$(ARCH) --sys=$(SYS) --abi=$(ABI) $(SOURCES)

macosx: bin/main
	CPATH=include/darwin $(MAIN) --arch=x86_64 --sys=macosx --abi=darwin

windows: bin/main
	CPATH=include/cygwin $(MAIN) --arch=i686 --sys=win32 --abi=cygwin

test:
	for target in targets/*; do\
	  echo $$target;\
	  for file in `find $$target -iname "*.cr"`; do\
		$(TEST) $$file;\
	  done;\
	done
