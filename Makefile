CFLAGS=$(shell luvit-config --cflags) -arch i386 -g -O3
LIBS=$(shell luvit-config --libs) -arch i386 ./deps/luvit/deps/luajit/src/libluajit.a 

all: msgpack.luvit


mp.o: mp.c
	cc -c mp.c ${CFLAGS}

msgpack.luvit: mp.o 
	g++ -o msgpack.luvit mp.o ${LIBS} 

clean:
	rm -f *.o *.luvit

