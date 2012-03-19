
LUVIT=deps/luvit/build/luvit
LUVITCONFIG=$(LUVIT) deps/luvit/bin/luvit-config.lua



ifeq ($(shell uname -sm | sed -e s,x86_64,i386,),Darwin i386)
#osx
export CC=gcc #-arch i386
CFLAGS=$(shell $(LUVIT) --cflags) -g -O3 -I./deps/luvit/deps/luajit/src
LIBS=$(shell $(LUVIT) --libs)  ./deps/luvit/deps/luajit/src/libluajit.a
LDFLAGS=
else
# linux
CFLAGS=$(shell $(LUVIT) --cflags) -g -O3 -I./deps/luvit/deps/luajit/src
LIBS=$(shell $(LUVIT) --libs)  ./deps/luvit/deps/luajit/src/libluajit.so -lm -ldl
LDFLAGS=
endif

# workaround for luvit build script bug: bad symlink to luajit have to be a directory for gcc
LUAJITBIN=deps/luvit/include/luvit/luajit



all:  test


mp.o: mp.c
	echo $(LUVITCONFIG)
	$(CC) -c mp.c $(CFLAGS)

msgpack.luvit: mp.o
	echo $(LIBS)
	rm $(LUAJITBIN)
	$(CC) -o msgpack.luvit mp.o $(LIBS)

test: $(LUVIT) msgpack.luvit
	$(LUVIT) test.lua

$(LUVIT) :
	git submodule init
	git submodule update
	cd deps/luvit; ./configure; make


clean:
	rm -rf *.o *.luvit deps/luvit/build/*

