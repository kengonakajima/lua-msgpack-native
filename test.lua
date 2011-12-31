-- Load our native module
local mp = require("./msgpack")
local io = require("io")
local string = require("string")
local table = require("table")
local math = require("math")

local pretty
local res,err = pcall( function()
                          pretty = require "pl.pretty"
                          require "pl.strict"
                       end)

local display = function(m,x)
                   local _t = type(x)
                   io.stdout:write(string.format("\n%s: %s ",m,_t))
                   if _t == "table" and pretty then pretty.dump(x) else print(x) end
                end

local printf = function(p,...)
                  io.stdout:write(string.format(p,...)); io.stdout:flush()
               end

local simpledump = function(s)
                      local out=""
                      for i=1,string.len(s) do
                         out = out .. " " .. string.format( "%x", string.byte(s,i) )
                      end
                      print(out)
                   end

-- copy(right) from penlight tablex module! for test in MOAI environment. 
function deepcompare(t1,t2,ignore_mt,eps)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' then
        if ty1 == 'number' and eps then return abs(t1-t2) < eps end
        return t1 == t2
    end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not deepcompare(v1,v2,ignore_mt,eps) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not deepcompare(v1,v2,ignore_mt,eps) then return false end
    end
    return true
end


local msgpack_cases = {
   false,true,nil,0,0,0,0,0,0,0,0,0,-1,-1,-1,-1,-1,127,127,255,65535,
   4294967295,-32,-32,-128,-32768,-2147483648, 0.0,-0.0,1.0,-1.0,  
   "a","a","a","","","",
   {0},{0},{0},{},{},{},{},{},{},{a=97},{a=97},{a=97},{{}},{{"a"}},
}


   

local origt = {{"multi","level",{"lists","used",45,{{"trees"}}},"work",{}},"too"}
local sss = mp.pack(origt)
local l,t = mp.unpack(sss)
assert(#t == #origt)
assert(t[1][1]=="multi")
assert(t[1][2]=="level")
assert(t[1][3][1]=="lists")
assert(t[1][3][2]=="used")
assert(t[1][3][3]==45)
assert(t[1][3][4][1][1]=="trees")
assert(t[1][4]=="work")
assert(t[1][5][1]==nil)
assert(t[2]=="too")


sss = mp.pack({1,2,3})
l,t = mp.unpack(sss)
assert(t[1]==1)
assert(t[2]==2)
assert(t[3]==3)
assert(t[4]==nil)

sss = mp.pack({a=1,b=2,c=3})
l,t = mp.unpack(sss)
assert(t.a==1)
assert(t.b==2)
assert(t.c==3)
assert(t.d==nil)



local data = {
   true,
   false,
   1,
   -1,
   -2,
   -5,
   -31,
   -32,   
   -128,
   -32768,
   
   -2147483648,
   -2147483648*100,   
   127,
   255,
   65535,
   4294967295,
   4294967295*100,   
   42,
   -42,
   --  0.79, double is not implemented!
   "Hello world!",
   {},
   {1,2,3},
   {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18},
   {a=1,b=2},
   {a=1,b=2,c=3,d=4,e=5,f=6,g=7,h=8,i=9,j=10,k=11,l=12,m=13,n=14,o=15,p=16,q=17,r=18},
   {true,false,42,-42,0.79,"Hello","World!"},
   {{"multi","level",{"lists","used",45,{{"trees"}}},"work",{}},"too"},
   {foo="bar",spam="eggs"},
   {nested={maps={"work","too"}}},
   {"we","can",{"mix","integer"},{keys="and"},{2,{maps="as well"}}},
   msgpack_cases,

}

local offset,res

-- Custom tests
printf("Custom tests ")
for i=0,#data do -- 0 tests nil!
   print("test i:",i, data[i] )
   offset,res = mp.unpack(mp.pack(data[i]))
   assert(offset,"decoding failed")
   if not deepcompare(res,data[i]) then
      display("expected",data[i])
      display("found",res)
      assert(false,string.format("wrong value %d",i))
   end
end
print(" OK")


-- Corrupt data test
print("corrupt data test")
local s = mp.pack(data)
local corrupt_tail = string.sub( s, 1, 10 )
offset,res = pcall(function() mp.unpack(s) end)
assert(offset)
offset,res = pcall(function() mp.unpack(corrupt_tail) end)
assert(not offset)

-- Empty data test
print("empty test")
local offset,res = mp.unpack(mp.pack({}))
assert(offset==1)
assert(res[1]==nil)



print("MessagePack test suite")
local files = { "./cases.mpac", "./cases_compact.mpac" }

for i,v in pairs(files) do
   print( "test on ", v )
   
   local f = io.open(v,'rb')
   assert(f)

   local bindata = f:read("*all")
   print("file len:", string.len(bindata))
   f:close()

   --
   local offset,i = 0,0
   while true do
      i = i+1
      print("case:",i)
      if i==#msgpack_cases then break end
      local rlen,res = mp.unpack(string.sub(bindata,offset+1))
      assert(rlen)

      if not deepcompare(res,msgpack_cases[i]) then
         display("expected",msgpack_cases[i])
         display("found",res)
         assert(false,string.format("wrong value %d",i))
      end
      offset = offset + rlen
   end
end
print("OK")


-- Raw tests

print("Raw tests ")

local rand_raw = function(len)
                    local t = {}
                    for i=1,len do t[i] = string.char(math.random(0,255)) end
                    return table.concat(t)
                 end

local raw_test = function(raw,overhead)
                    offset,res = mp.unpack(mp.pack(raw))
                    assert(offset,"decoding failed")
                    if not res == raw then
                       assert(false,string.format("wrong raw (len %d - %d)",#res,#raw))
                    end
                    assert(offset-#raw == overhead,string.format(
                              "wrong overhead %d for #raw %d (expected %d)",
                              offset-#raw,#raw,overhead
                        ))
                 end

printf(".")
for n=0,31 do -- fixraw
   raw_test(rand_raw(n),1)
end

-- raw16
printf("test raw16:")
for n=32,32+100 do
   raw_test(rand_raw(n),3)
end
for n=65535-5,65535 do
   printf(".")   
   raw_test(rand_raw(n),3)
end

-- raw32
printf("test raw32:")
for n=65536,65536+5 do
   printf(".")      
   raw_test(rand_raw(n),5)
end




-- Integer tests

printf("Integer tests ")

local nb_test = function(n,sz)
                   offset,res = mp.unpack(mp.pack(n))
                   assert(offset,"decoding failed")
                   if not res == n then
                      assert(false,string.format("wrong value %d, expected %d",res,n))
                   end
                   assert(offset == sz,string.format(
                             "wrong size %d for number %d (expected %d)",
                             offset,n,sz
                       ))
                end

printf(".")
for n=0,127 do -- positive fixnum
   nb_test(n,1)
end

printf(".")
for n=128,255 do -- uint8
   nb_test(n,2)
end

printf(".")
for n=256,65535 do -- uint16
   nb_test(n,3)
end

-- uint32
printf(".")
for n=65536,65536+100 do
   nb_test(n,5)
end
for n=4294967295-100,4294967295 do
   nb_test(n,5)
end

-- no 64 bit!
printf(".")  
for n=4294967296,4294967296+100 do -- uint64
  nb_test(n,9)
end

printf(".")
for n=-1,-32,-1 do -- negative fixnum
   nb_test(n,1)
end

printf(".")
for n=-33,-128,-1 do -- int8
   nb_test(n,2)
end

printf(".")
for n=-129,-32768,-1 do -- int16
   nb_test(n,3)
end

-- int32
printf(".")
for n=-32769,-32769-100,-1 do
   nb_test(n,5)
end
for n=-2147483648+100,-2147483648,-1 do
   nb_test(n,5)
end





print("OK")





printf(".")
for n=-2147483649,-2147483649-100,-1 do -- int64
  nb_test(n,9)
end
print(" OK")

printf("Floating point tests ")
printf(".")
for i=1,100 do
  local n = math.random()*200-100
  nb_test(n,9)
end
print(" OK")


print("long array test (16bit-32bit)")
for i=65530,65600 do
   if (i%10)==0 then printf(".") end
   local ary = rand_raw(i)
   local ofs,res = mp.unpack(mp.pack(ary))
   assert(ofs,"decoding failed")
   if not deepcompare(res,ary) then
      assert(false,"long ary fail. len:"..i)
   end
end
print("")

print("long map test")
for n=65530,65550 do
   printf(".")
   local t = {}
   for i=1,n do
      t[ "key" .. i ] = i
   end
   local ss = mp.pack(t)
   local ofs,res = mp.unpack(ss)
   assert(ofs,"decoding failed")
   if not deepcompare(res,t) then
      assert(false,"long map fail. len:"..n)
   end
end
print("")

print("long str test")
for n=65530,65550 do
   printf(".")
   local s = ""
   for i=1,n do
      s = s .. "a"
   end
   local ss = mp.pack(s)
   local ofs,res = mp.unpack(ss)
   if not deepcompare(res,s) then
      assert(false,"long str fail. len:"..n)
   end
end




-- below: too slow and >4G mem.. cannot in i386 build
--for n=4294967295-100,4294967295 do
--  raw_test(rand_raw(n),5)
--end
--print(" OK")


