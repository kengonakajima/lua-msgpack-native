
LUVIT=deps/luvit/build/luvit
LUVITCONFIG=$(LUVIT) deps/luvit/bin/luvit-config.lua

ifeq ($(shell uname -sm | sed -e s,x86_64,i386,),Darwin i386)
#osx
export CC=gcc -arch i386
CFLAGS=$(shell luvit-config --cflags) -g -O3 -I./deps/luvit/deps/luajit/src
LIBS=$(shell luvit-config --libs)  ./deps/luvit/deps/luajit/src/libluajit.a
LDFLAGS=
else
# linux
CFLAGS=$(shell $(LUVITCONFIG) --cflags) -g -O3 -I./deps/luvit/deps/luajit/src
LIBS=$(shell $(LUVITCONFIG) --libs)  ./deps/luvit/deps/luajit/src/libluajit.a -lm -ldl
LDFLAGS=
endif





all:  test


mp.o: mp.c
	$(CC) -c mp.c $(CFLAGS)

msgpack.luvit: mp.o
	echo $(LIBS)
	$(CC) -o msgpack.luvit mp.o $(LIBS)

test: $(LUVIT) msgpack.luvit
	$(LUVIT) test.lua

$(LUVIT) :
	git submodule init
	git submodule update
	cd deps/luvit; ./configure; make


clean:
	rm -rf *.o *.luvit deps/luvit/build/*

