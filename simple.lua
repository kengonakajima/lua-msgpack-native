local mp = require "./msgpack"
local mpo = require "./orig_mplua/msgpackorig"

local os = require "os"
local table = require "table"


st = os.clock()
for i=1,100000 do
   local ary = mp.largetbl(100)
end
et = os.clock()
print( "100:", (et-st), 100000/(et-st), "/sec" )

st = os.clock()
for i=1,10000 do
   local ary = mp.largetbl(1000)
end
et = os.clock()
print( "1000:", (et-st), 10000/(et-st), "/sec" )

st = os.clock()
for i=1,1000 do
   local ary = mp.largetbl(10000)
end
et = os.clock()
print( "10000:", (et-st), 1000/(et-st), "/sec" )


st = os.clock()
for i=1,10000 do
   local ary = mp.largetbl(100000)
end
et = os.clock()
print( "100000:", (et-st), 10000/(et-st), "/sec" )


--[[

Call graph:
    2664 Thread_2867852   DispatchQueue_1: com.apple.main-thread  (serial)
      2544 lua_call  (in luvit) + 76  [0x3d26c]
      + 2541 lj_BC_FUNCC  (in luvit) + 50  [0x320fa]
      + ! 648 lj_tab_new  (in msgpack.luvit) + 48,54  [0x308a50,0x308a56]
      + ! 610 lua_pushnumber  (in msgpack.luvit) + 21,41,...  [0x30e685,0x30e699,...]
      + ! 603 lua_rawseti  (in msgpack.luvit) + 86,139,...  [0x30f186,0x30f1bb,...]
      + ! 361 index2adr  (in msgpack.luvit) + 241,11,...  [0x30dd11,0x30dc2b,...]
      + ! 126 msgpack_largetbl  (in msgpack.luvit) + 101,96,...  [0x300db5,0x300db0,...]  mp.c:571
      + ! 114 msgpack_largetbl  (in msgpack.luvit) + 118,133,...  [0x300dc6,0x300dd5,...]  mp.c:572
      + ! 71 msgpack_largetbl  (in msgpack.luvit) + 156,161  [0x300dec,0x300df1]  mp.c:570
      + ! 4 lua_rawseti  (in msgpack.luvit) + 27  [0x30f14b]
      + ! : 4 index2adr  (in msgpack.luvit) + 246  [0x30dd16]
--]]
-- lj_tab_newと pushnumber, rawseti consumes near 80%, so no room for improvement.


