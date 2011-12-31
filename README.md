lua-msgpack-native
====
Faster implementation of [MessagePack](http://msgpack.org/) for Lua.
It's about 5 or 10 times faster than [mplua](https://github.com/nobu-k/mplua),
a Lua binding of MessagePack.

Performance is improved by skipping (1) making msgpack_object tree
inside libmsgpack, and (2) traversing the tree then construct Lua table.
lua-msgpack-native just directly reads input string and construct Lua table,
so never make object tree other than Lua tree.

Benchmark
====
