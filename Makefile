MAIN = bin/main
CRYSTAL = crystal
TMP = /tmp/crystal-posix-test
TEST = rm -f $(TMP); $(CRYSTAL) build --prelude=empty -o $(TMP) src/base.cr

all: android freebsd linux macosx windows format

bin/main: src/*.cr
	@mkdir -p bin
	$(CRYSTAL) build --release -o bin/main src/main.cr

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
	#CPATH=include/linux/gnu64 $(MAIN) --arch=x86_64 --sys=linux --abi=gnu
	CPATH=include/linux/musl32 $(MAIN) --arch=x86 --sys=linux --abi=musl --arch=x86
	#CPATH=include/linux/musl64 $(MAIN) --arch=x86_64 --sys=linux --abi=musl

macosx: bin/main
	CPATH=include/darwin $(MAIN) --arch=x86_64 --sys=macosx --abi=darwin

windows: bin/main
	CPATH=include/cygwin $(MAIN) --arch=x86 --sys=win32 --abi=cygwin

format:
	$(CRYSTAL) tool format src/c

test:
	for target in src/c/*; do\
	  echo $$target;\
	  for file in `find $$target -iname "*.cr"`; do\
		$(TEST) $$file;\
	  done;\
	done
