CFLAGS=$(shell luvit-config --cflags) -arch i386 -g -O3
LIBS=$(shell luvit-config --libs) -arch i386 ../deps/luvit/deps/luajit/src/libluajit.a 

all: msgpack.luvit msgpackorig.luvit

lua_objects.o : lua_objects.cpp
	g++ -c lua_objects.cpp $(CFLAGS)
zone.o : zone.c
	g++ -c zone.c $(CFLAGS)
unpack.o : unpack.c
	g++ -c unpack.c $(CFLAGS)

packer_impl.o : packer_impl.cpp
	g++ -c packer_impl.cpp ${CFLAGS}

unpacker.o : unpacker.cpp
	g++ -c unpacker.cpp ${CFLAGS}
packer.o : packer.cpp
	g++ -c packer.cpp ${CFLAGS}

msgpack.o : msgpack.cpp
	g++ -c msgpack.cpp ${CFLAGS}

mp.o: mp.c
	cc -c mp.c ${CFLAGS}

msgpack.luvit: mp.o msgpack.o packer.o unpacker.o packer_impl.o unpack.o zone.o lua_objects.o
	g++ -o msgpack.luvit mp.o msgpack.o packer.o unpacker.o packer_impl.o unpack.o zone.o lua_objects.o ${LIBS} 

msgpackorig.luvit: msgpack.o packer.o unpacker.o packer_impl.o unpack.o zone.o lua_objects.o
	g++ -o msgpackorig.luvit msgpack.o packer.o unpacker.o packer_impl.o unpack.o zone.o lua_objects.o ${LIBS}

clean:
	rm -f *.o msgpack.luvit msgpackorig.luvit

test: msgpack.luvit
	luvit testit.lua