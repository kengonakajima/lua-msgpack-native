local mp = require "./msgpack"
local mpo = require "./orig_mplua/msgpackorig"

local os = require "os"
local table = require "table"

local nLoop = 3000

function makeiary(n)
   local out={}
   for i=1,n do table.insert(out,i) end
   return out
end
function makestr(n)
   local out=""
   for i=1,n-1 do out = out .. "a" end
   out = out .. "b"
   return out
end

local datasets = {
   { "empty", nLoop*1000, {} },
   { "iary1", nLoop*1000, {1} },
   { "iary10", nLoop*100, {1,2,3,4,5,6,7,8,9,10} },
   { "iary100", nLoop*10, makeiary(100) },
   { "iary1000", nLoop*10, makeiary(1000) },
   { "iary10000", nLoop, makeiary(10000) },
   { "str1", nLoop*1000, "a" },
   { "str10", nLoop*1000,  makestr(10)  },
   { "str100", nLoop*1000, makestr(100)  },
   { "str500", nLoop*1000, makestr(500)  },   
   { "str1000", nLoop*1000, makestr(1000)  },
   { "str10000", nLoop*100, makestr(10000)  },
}

for i,v in ipairs(datasets) do
   st = os.clock()
   local nLoop = v[2]
   local offset,res
   for j=1, nLoop do
      offset,res = mp.unpack( mp.pack(v[3] ) )
   end
   assert(offset)      
   local et = os.clock()
   local mptime = et - st
   st = os.clock()
   for j=1, nLoop do
      offset,res = mpo.unpack( mpo.pack( v[3] ) )
   end
   assert(offset)      
   et = os.clock()
   local mpotime = et - st

   print( "mp:", v[1], mptime, "sec", nLoop/mptime, "times/sec", (mpotime/mptime), "times faster")

end
