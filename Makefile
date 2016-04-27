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

.PHONY: clean test

all: bin/main
	$(MAIN) --arch=$(ARCH) --sys=$(SYS) --abi=$(ABI)

crystal: bin/main
	$(MAIN) --arch=$(ARCH) --sys=$(SYS) --abi=$(ABI) --source=$(PWD)/include/crystal

clean:
	rm -f bin/main

bin/main: src/*.cr
	@mkdir -p bin
	$(CRYSTAL_BIN) build -o bin/main src/main.cr

gnu32: bin/main
	C_INCLUDE_PATH=/usr/include:/usr/lib/llvm-3.6/lib/clang/3.6.2/include \
		$(MAIN) --arch=$(ARCH) --sys=$(SYS) --abi=$(ABI) $(SOURCES)

test:
	for target in targets/*; do\
	  echo $$target;\
	  for file in `find $$target -iname "*.cr"`; do\
		$(TEST) $$file;\
	  done;\
	done
