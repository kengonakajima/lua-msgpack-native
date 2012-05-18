CFLAGS=$(shell luvit --cflags) -g -O3
LIBS=$(shell luvit --libs)  ../deps/luvit/deps/luajit/src/libluajit.a 

all: msgpackorig.luvit

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

msgpackorig.luvit: msgpack.o packer.o unpacker.o packer_impl.o unpack.o zone.o lua_objects.o
	g++ -o msgpackorig.luvit msgpack.o packer.o unpacker.o packer_impl.o unpack.o zone.o lua_objects.o ${LIBS}

clean:
	rm -f *.o *.luvit

