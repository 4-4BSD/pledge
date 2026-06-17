# Makefile for pledge
#
# Prerequisites:
#   ../mruby    # mruby checkout (sibling directory)
#
# Quick start:
#   make        # build toolchain and standalone binary
#   make test   # run tests
#   make clean  # clean build artifacts
#   make install  # install binary and man page to $(PREFIX)

MRUBY_DIR    ?= ../mruby
BUILD_CONFIG  = build.rb
BUILD_NAME    = pledge
BUILD_DIR     = $(MRUBY_DIR)/build/$(BUILD_NAME)
BUILD        ?= test

RUBY_GEM_FILES != find mrblib -type f 2>/dev/null | sort
SPEC_FILES     != find spec -type f -name '*_spec.rb' 2>/dev/null | sort

PREFIX      ?= /usr/local
MANPREFIX   ?= $(PREFIX)/man

ENTRYPOINT      = src/main.rb
STANDALONE_BIN  = bin/pledge
STANDALONE_IREP = tmp/pledge_main.c
MAIN_OBJ        = tmp/main.o
IREP_OBJ        = tmp/pledge_main.o

TOOLCHAIN_BIN   = bin/mruby bin/mrbc bin/mruby-config
TOOLCHAIN_STAMP = tmp/toolchain.$(BUILD).stamp

.if ${BUILD} == "production"
MRBC_FLAGS = --remove-lv
POST_BUILD = strip $(STANDALONE_BIN)
.else
MRBC_FLAGS =
POST_BUILD = true
.endif

.PHONY: all build toolchain standalone test clean distclean install

all: standalone

build: toolchain

toolchain: $(TOOLCHAIN_STAMP)

standalone: $(STANDALONE_BIN)

test: toolchain
.for spec in $(SPEC_FILES)
	bin/mruby $(spec)
.endfor

$(TOOLCHAIN_STAMP): $(BUILD_CONFIG) $(RUBY_GEM_FILES)
	mkdir -p tmp bin
	ruby -C $(MRUBY_DIR) minirake clean 2>/dev/null || true
	BUILD=$(BUILD) ruby -C $(MRUBY_DIR) minirake MRUBY_CONFIG=$$(pwd)/$(BUILD_CONFIG)
	cp -r $(BUILD_DIR)/bin/* bin/
	touch $(TOOLCHAIN_STAMP)

$(STANDALONE_IREP): $(ENTRYPOINT) $(TOOLCHAIN_STAMP)
	mkdir -p tmp
	bin/mrbc $(MRBC_FLAGS) -B pledge_main -o $(STANDALONE_IREP) $(ENTRYPOINT)

$(MAIN_OBJ): main.c $(TOOLCHAIN_STAMP)
	mkdir -p tmp
	$$(bin/mruby-config --cc) \
		$$(bin/mruby-config --cflags) \
		-I $(BUILD_DIR)/include \
		-c main.c \
		-o $(MAIN_OBJ)

$(IREP_OBJ): $(STANDALONE_IREP) $(TOOLCHAIN_STAMP)
	mkdir -p tmp
	$$(bin/mruby-config --cc) \
		$$(bin/mruby-config --cflags) \
		-I $(BUILD_DIR)/include \
		-c $(STANDALONE_IREP) \
		-o $(IREP_OBJ)

$(STANDALONE_BIN): $(MAIN_OBJ) $(IREP_OBJ) $(TOOLCHAIN_STAMP)
	mkdir -p bin
	$$(bin/mruby-config --ld) -o $(STANDALONE_BIN) \
		$(MAIN_OBJ) \
		$(IREP_OBJ) \
		$$(bin/mruby-config --ldflags-before-libs) \
		$(BUILD_DIR)/lib/libmruby.a \
		$$(bin/mruby-config --ldflags) \
		$$(bin/mruby-config --libs | sed 's/-lmruby//g')
	$(POST_BUILD)
	chmod 755 $(STANDALONE_BIN)

clean:
	rm -f $(TOOLCHAIN_BIN)
	rm -f tmp/toolchain.*.stamp
	rm -f $(STANDALONE_BIN) $(STANDALONE_IREP) $(MAIN_OBJ) $(IREP_OBJ)

distclean: clean
	rm -f $$(pwd)/*.lock
	rm -rf $(BUILD_DIR)
	rm -rf $(MRUBY_DIR)/build/repos/$(BUILD_NAME)

install: $(STANDALONE_BIN)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(STANDALONE_BIN) $(DESTDIR)$(PREFIX)/bin/pledge
.if exists(man/man1/pledge.1)
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	install -m 644 man/man1/pledge.1 $(DESTDIR)$(MANPREFIX)/man1/pledge.1
.endif
