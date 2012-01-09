lua-msgpack-native
====
<a href="http://travis-ci.org/kengonakajima/lua-msgpack-native"><img src="https://secure.travis-ci.org/kengonakajima/lua-msgpack-native.png"></a>

Faster implementation of [MessagePack](http://msgpack.org/) for Lua.
It's about 5 or 10 times faster than a [Lua binding of libmsgpack mplua](https://github.com/nobu-k/mplua),
and 20 or 50 times faster than luvit's embedded JSON parse/stringify.

It's even faster on smaller/simpler objects like data packets of multiplayer networked games.


Performance is improved by skipping (1) making msgpack_object tree
inside libmsgpack, and (2) traversing the tree when constructing Lua table.

lua-msgpack-native just directly reads input string and construct Lua table,
so never make object tree other than Lua tree. 2 or 3 times less buffer copy
and memory allocation.

Compatibility
====
tested on luvit on OSX Lion and Linux(Ubuntu 11.04, travis-ci node.js worker)
current luvit depends on LuaJIT2.

Usage
====
In your app:

    local mp = require( "msgpack" )
    local tbl = { a=123, b="any", c={"ta","bl","e",1,2,3} }
    local packed = mp.pack(tbl)
    local unpacked_table = mp.unpack(packed)

    

Benchmark
====

command line:

    luvit bench.lua

output:

    mp:   empty      0.69   sec   4347826.0869565   times/sec   6.5072463768116   times faster
    mp:   iary1      0.87   sec   3448275.862069    times/sec   5.9310344827586   times faster
    mp:   iary10     0.31   sec   967741.93548387   times/sec   2.9677419354839   times faster
    mp:   iary100    0.21   sec   142857.14285714   times/sec   1.9047619047619   times faster
    mp:   iary1000   2.43   sec   12345.679012346   times/sec   1.3662551440329   times faster
    mp:   iary10000  2.31   sec   1298.7012987013   times/sec   1.4718614718615   times faster
    mp:   str1       0.47   sec   6382978.7234042   times/sec   10.489361702128   times faster
    mp:   str10      0.48   sec   6250000           times/sec   10.354166666667   times faster
    mp:   str100     0.76   sec   3947368.4210526   times/sec   6.9868421052632   times faster
    mp:   str500     1.36   sec   2205882.3529412   times/sec   4.3970588235294   times faster
    mp:   str1000    2.22   sec   1351351.3513514   times/sec   3.0855855855856   times faster
    mp:   str10000   1.76   sec   170454.54545455   times/sec   1.4545454545455   times faster

To compare with luvit's JSON (based on libyajl), command line:

    luvit jsonbench.lua

output:

    json:	empty	0.304742	sec	98443.929619153	times/sec
    json:	iary1	0.402968	sec	74447.59881678	times/sec
    json:	iary10	0.060066	sec	49945.060433523	times/sec
    json:	iary100	0.031954	sec	9388.4959629468	times/sec
    json:	iary1000	0.302775	sec	990.83477830072	times/sec
    json:	iary10000	0.331131	sec	90.598584850105	times/sec
    json:	str1	0.244788	sec	122555.02720722	times/sec
    json:	str10	0.316844	sec	94683.81916653	times/sec
    json:	str100	0.420545	sec	71336.00447039	times/sec
    json:	str500	0.629439	sec	47661.489040241	times/sec
    json:	str1000	0.630663	sec	47568.986923286	times/sec
    json:	str10000	0.368189	sec	8147.9892120623	times/sec

lua-msgpack-native is 20x ~ 50x faster than luvit's JSON.


    
Related works
====
In many cases ,Lua runtime doesn't allow adding native modules.
In these cases you can use [pure lua implementation of MessagePack](https://github.com/kengonakajima/lua-msgpack)

This module mainly targets on [luvit](https://github.com/luvit/luvit).
To maximize performance, you'd use LuaJIT2 or luvit or something.

This repository has orig_msgpack directory, 
that contains original msgpack C++ library source code and mplua stub C code.
Every line of these code is from those projects.

 
