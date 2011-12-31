lua-msgpack-native
====
Faster implementation of [MessagePack](http://msgpack.org/) for Lua.
It's about 5 or 10 times faster than a [Lua binding of libmsgpack mplua](https://github.com/nobu-k/mplua),
especially on smaller/simpler objects like data packets of multiplayer networked games.

Performance is improved by skipping (1) making msgpack_object tree
inside libmsgpack, and (2) traversing the tree when constructing Lua table.

lua-msgpack-native just directly reads input string and construct Lua table,
so never make object tree other than Lua tree. 2 or 3 times less buffer copy
and memory allocation.


Benchmark
====
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

Related works
====
In many cases ,Lua runtime doesn't allow adding native modules.
In these cases you can use [pure lua implementation of MessagePack](https://github.com/kengonakajima/lua-msgpack)
