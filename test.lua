-- Load our native module
local mp = require("./msgpack")
local io = require("io")
local string = require("string")
local table = require("table")
local math = require("math")

math.randomseed(1)

function display(m,x)
  local _t = type(x)
  io.stdout:write(string.format("\n%s: %s ",m,_t))
  if _t == "table" then print(x) end
end

function printf(p,...)
  io.stdout:write(string.format(p,...)); io.stdout:flush()
end

function simpledump(s)
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

function streamtest(unp,t,dolog)
  local s = mp.pack(t)
  if dolog and #s < 1000 then simpledump(s) end
  local startat = 1
  while true do
    local unit = 1+math.floor( math.random(0, #s/10 ) )
    local subs = string.sub( s, startat, startat+unit-1 )
    if subs and #subs > 0 then
      unp:feed( subs )
      startat = startat + unit
    else
      break
    end
  end
  local out = unp:pull()
  if t ~= nil and t ~= false then 
    assert(out, "no result")
  end
  local res = deepcompare(out,t)
  assert(res,"table differ")
  out = unp:pull()
  assert(not out,"have to be nil")
end


local msgpack_cases = {
   false,true,nil,0,0,0,0,0,0,0,0,0,-1,-1,-1,-1,-1,127,127,255,65535,
   4294967295,-32,-32,-128,-32768,-2147483648, 0.0,-0.0,1.0,-1.0,  
   "a","a","a","","","",
   {0},{0},{0},{},{},{},{},{},{},{a=97},{a=97},{a=97},{{}},{{"a"}},
}




-- quick test   
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

-- streaming API test 
unp = mp.createUnpacker(1024*1024)

-- stream raw test
streamtest(unp,{ hoge = { 5,6 }, fug="11" },true)
streamtest(unp,"a")
streamtest(unp,"aaaaaaaaaaaaaaaaa")



--streaming: basic test
print("stream basic test")
t = { aho=7, hoge = { 5,6,"7", {8,9,10} }, fuga="11" }
sss = mp.pack(t)
assert(unp)
unp:feed( string.char( 0x83, 0xa3, 0x61, 0x68 ) )
unp:feed( string.char( 0x6f, 0x7, 0xa4, 0x66 ) )
unp:feed( string.char( 0x75, 0x67, 0x61, 0xa2 ) )
unp:feed( string.char( 0x31, 0x31, 0xa4, 0x68 ) )
unp:feed( string.char( 0x6f, 0x67, 0x65, 0x94 ) )
unp:feed( string.char( 0x5, 0x6, 0xa1, 0x37 ) )
unp:feed( string.char( 0x93, 0x8, 0x9, 0xa ) )
out = unp:pull() 
assert( out )
assert( deepcompare(t,out) )
assert( not unp:pull() )



   
--streaming: empty table
print("stream empty containers" )
streamtest(unp,{})
streamtest(unp,"")


-- streaming: types
print("stream types test")
t = {}
for i=1,70000 do table.insert( t, "a" ) end -- raw32
streamtest( unp, { table.concat( t ) } )

t = {}
for i=1,100 do table.insert( t, "a" ) end -- raw16
streamtest( unp, { table.concat( t ) } )

t = {}
for i=1,70000 do t[ "key" .. i ] = i end -- map32
streamtest( unp, t )

t = {}
for i=1,100 do t[ "key" .. i ] = i end -- map16
streamtest( unp, t ) 

t = {}
for i=1,70000 do table.insert(t,1) end -- ary32
streamtest( unp, t ) 

t = {}
for i=1,100 do table.insert(t,i) end -- ary16
streamtest( unp, t ) 

streamtest( unp, {0.001}) -- double
streamtest( unp, {-10000000000000000}) -- i64
streamtest( unp, {-1000000000000000}) -- i64
streamtest( unp, {-100000000000000}) -- i64
streamtest( unp, {-10000000000000}) -- i64
streamtest( unp, {-1000000000000}) -- i64
streamtest( unp, {-100000000000}) -- i64
streamtest( unp, {-10000000000}) -- i64
streamtest( unp, {-1000000000}) -- i32
streamtest( unp, {-100000000}) -- i32
streamtest( unp, {-10000000}) -- i32
streamtest( unp, {-1000000}) -- i32
streamtest( unp, {-100000}) -- i32
streamtest( unp, {-10000}) -- i16
streamtest( unp, {-1000}) -- i16
streamtest( unp, {-100}) -- i8
streamtest( unp, {-10}) -- neg fixnum
streamtest( unp, {-1}) -- neg fixnum
streamtest( unp, { 1000000000000000000 }) -- u64
streamtest( unp, { 100000000000000000 }) -- u64
streamtest( unp, { 10000000000000000 }) -- u64
streamtest( unp, { 1000000000000000 }) -- u64
streamtest( unp, { 100000000000000 }) -- u64
streamtest( unp, { 10000000000000 }) -- u64
streamtest( unp, { 1000000000000 }) -- u64
streamtest( unp, { 100000000000 }) -- u64
streamtest( unp, { 10000000000 }) -- u64
streamtest( unp, { 1000000000 }) -- u32
streamtest( unp, { 100000000 }) -- u32
streamtest( unp, { 10000000 }) -- u32
streamtest( unp, { 1000000 }) -- u32
streamtest( unp, { 100000 }) -- u32
streamtest( unp, { 10000 }) -- u16
streamtest( unp, { 1000 }) -- u16
streamtest( unp, { 1,10,100 }) -- u8


-- streaming: multiple tables
print("stream multiple tables")
t1 = {10,20,30}
s1 = mp.pack(t1)
t2 = {"aaa","bbb","ccc"}
s2 = mp.pack(t2)
t3 = {a=1,b=2,c=3}
s3 = mp.pack(t3)
sss = s1 .. s2 .. s3
assert( #sss == (#s1 + #s2 + #s3 ) )
unp:feed(s1)
unp:feed(s2)
out1 = unp:pull()
assert(out1)
assert( deepcompare(t1,out1))
out2 = unp:pull()
assert(out2)
assert( deepcompare(t2,out2))
out3 = unp:pull()
assert( not out3 )
unp:feed(s3)
out3 = unp:pull()
assert( deepcompare(t3,out3))
out4 = unp:pull()
assert( not out4 )




-- stream: gc test
print("stream gc test")
t = { aho=7, hoge = { 5,6,"7", {8,9,10} }, fuga="11" }
s = mp.pack(t)
for i=1,100000 do
  local u = mp.createUnpacker(1024)
  u:feed( string.sub(s,1,11))
  u:feed( string.sub(s,12,#s))
  local out = u:pull()
  assert(out)
  out = u:pull()
  assert(not out)
end

-- stream: find corrupt data
print("stream corrupt input")
s = string.char( 0x91, 0xc1 ) -- c1: reserved code
local uc = mp.createUnpacker(1024)
local res = uc:feed(s)
assert( res == -1 )

-- stream: too deep
print("stream too deep")
t={}
for i=1,2000 do
  table.insert(t, 0x91 )
end
s = string.char( unpack(t) )
uc = mp.createUnpacker(1024*1024)
res = uc:feed(s)
assert(res==-1)



-- normal test  
print("simple table")

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
simpledump(sss)



local data = {
   nil,
   true,
   false,
   1,
   -1,
   -2,
   -5,
   -31,
   -32,   
   -128, -- 10
   -32768, 
   
   -2147483648,
   -2147483648*100,   
   127,
   255, --15
   65535,
   4294967295,
   4294967295*100,   
   42,
   -42, -- 20
   0.79, 
   "Hello world!",
   {}, 
   {1,2,3},
   {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18}, -- 25
   {a=1,b=2},
   {a=1,b=2,c=3,d=4,e=5,f=6,g=7,h=8,i=9,j=10,k=11,l=12,m=13,n=14,o=15,p=16,q=17,r=18},
   {true,false,42,-42,0.79,"Hello","World!"}, -- 28
   {{"multi","level",{"lists","used",45,{{"trees"}}},"work",{}},"too"},
   {foo="bar",spam="eggs"},
   {nested={maps={"work","too"}}},
   {"we","can",{"mix","integer"},{keys="and"},{2,{maps="as well"}}},
   msgpack_cases,

}

local offset,res

-- Custom tests
print("Custom tests")
for i=1,#data do -- 0 tests nil!
   printf("%d ", i )
   offset,res = mp.unpack(mp.pack(data[i]))
   assert(offset,"decoding failed")
   if not deepcompare(res,data[i]) then
      display("expected",data[i])
      display("found",res)
      assert(false,string.format("wrong value in case %d",i))
    end
end
print(" OK")
-- on streaming
for i=1,#data do
  printf("%d ",i)
  streamtest(unp, data[i])
end





-- Corrupt data test
print("corrupt data test")
local s = mp.pack(data)
local corrupt_tail = string.sub( s, 1, 10 )
offset,res = mp.unpack(s) 
assert(offset)
offset,res = mp.unpack(corrupt_tail) 
assert(not offset)

-- error bits test
local res,msg = pcall( function() mp.pack( { a=function() end } ) end )
assert( not res )
assert( msg == "invalid type: function" )

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
      printf("%d ", i)
      if i==#msgpack_cases then break end
      local rlen,res = mp.unpack(string.sub(bindata,offset+1))
      assert(rlen)

      if not deepcompare(res,msgpack_cases[i]) then
        display("expected",msgpack_cases[i])
        display("found",res)
        assert(false,string.format("wrong value %d",i))
      end
      -- stream too.
      streamtest(unp,msgpack_cases[i])
       
      offset = offset + rlen
   end
   print("")
end
print("OK")


-- Raw tests

print("Raw tests ")

function rand_raw(len)
  local t = {}
  for i=1,len do t[i] = string.char(math.random(0,255)) end
  return table.concat(t)
end

function raw_test(raw,overhead)
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
print("OK")

for n=65535-5,65535 do
   printf(".")   
   raw_test(rand_raw(n),3)
end
print("OK")

-- raw32
printf("test raw32:")
for n=65536,65536+5 do
   printf(".")      
   raw_test(rand_raw(n),5)
end
print("OK")



-- Integer tests

printf("Integer tests ")

function nb_test(n,sz)
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
for n=65532,65540 do
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
for n=65532,65540 do
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
print("\nOK")



-- below: too slow and >4G mem.. cannot in i386 build
--for n=4294967295-100,4294967295 do
--  raw_test(rand_raw(n),5)
--end
--print(" OK")



print("test finished")
