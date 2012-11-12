package = "lua-msgpack-native"
version = "scm-1"
source = {
   url = "https://github.com/kengonakajima/lua-msgpack-native.git",
   branch = "master"
}
description = {
   summary = "Faster implementation of MessagePack for Lua runtime",
   homepage = "http://github.com/kengonakajima/lua-msgpack-native",
   license = "Apache",
   maintainer = "Kengo Nakajima"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      msgpack = {
         sources = {
            "mp.c",
         }
      }
   }
}
