MAIN = bin/main
CRYSTAL_BIN ?= crystal
TMP = /tmp/crystal-posix-test
TEST = rm -f $(TMP); $(CRYSTAL_BIN) build --prelude=empty -o $(TMP) src/base.cr

TARGET := $(subst -, ,$(shell \
	llvm-config-3.6 --host-target 2>/dev/null || \
	llvm-config-3.5 --host-target 2>/dev/null || \
	llvm-config35 --host-target 2>/dev/null || \
	llvm-config36 --host-target 2>/dev/null || \
	llvm-config --host-target 2>/dev/null ))
ARCH ?= $(word 1,$(TARGET))
SYS ?= $(word 3,$(TARGET))
ABI ?= $(word 4,$(TARGET))

all: bin/main
	$(MAIN) --arch=$(ARCH) --sys=$(SYS) --abi=$(ABI)

bin/main: src/*.cr
	@mkdir -p bin
	$(CRYSTAL_BIN) build --release -o bin/main src/main.cr

android: bin/main
	CPATH=include/android/arm $(MAIN) --arch=arm --sys=linux --abi=android
	CPATH=include/android/arm64 $(MAIN) --arch=arm64 --sys=linux --abi=android
	CPATH=include/android/mips $(MAIN) --arch=mips --sys=linux --abi=android
	CPATH=include/android/mips64 $(MAIN) --arch=mips64 --sys=linux --abi=android
	CPATH=include/android/x86 $(MAIN) --arch=x86 --sys=linux --abi=android
	CPATH=include/android/x86_64 $(MAIN) --arch=x86_64 --sys=linux --abi=android

freebsd: bin/main
	#CPATH=include/freebsd32 $(MAIN) --arch=x86 --sys=freebsd
	CPATH=include/freebsd64 $(MAIN) --arch=x86_64 --sys=freebsd

linux: bin/main
	CPATH=include/linux/gnu32 $(MAIN) --arch=x86 --sys=linux --abi=gnu
	CPATH=include/linux/gnu64 $(MAIN) --arch=x86_64 --sys=linux --abi=gnu
	CPATH=include/linux/musl32 $(MAIN) --arch=x86 --sys=linux --abi=musl --arch=x86
	CPATH=include/linux/musl64 $(MAIN) --arch=x86_64 --sys=linux --abi=musl

macosx: bin/main
	CPATH=include/darwin $(MAIN) --arch=x86_64 --sys=macosx --abi=darwin

windows: bin/main
	CPATH=include/cygwin $(MAIN) --arch=x86 --sys=win32 --abi=cygwin

test:
	for target in src/c/*; do\
	  echo $$target;\
	  for file in `find $$target -iname "*.cr"`; do\
		$(TEST) $$file;\
	  done;\
	done
