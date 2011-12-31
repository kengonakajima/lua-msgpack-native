/*
 * MessagePack for Lua
 *
 * Copyright (C) 2009 Nobuyuki Kubota 
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "unpacker.hpp"

#include <memory>
#include "lua_objects.hpp"

namespace msgpack {
namespace lua {
namespace {
template<int (Unpacker::*Memfun)(lua_State*)>
int unpackerProxy(lua_State* L) {
  Unpacker* p =
    *static_cast<Unpacker**>(luaL_checkudata(L, 1, Unpacker::MetatableName));
  return (p->*Memfun)(L);
}
} // namespace

const char* const Unpacker::MetatableName = "msgpack.Unpacker";

void Unpacker::registerUserdata(lua_State* L) {
  if (luaL_newmetatable(L, Unpacker::MetatableName) == 0) {
    lua_pop(L, 1);
    return; // already created
  }

  // metatable.__index = metatable
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");

  // set __gc
  lua_pushcfunction(L, &Unpacker::finalizer);
  lua_setfield(L, -2, "__gc");

  // set __call
  lua_pushcfunction(L, &unpackerProxy<&Unpacker::next>);
  lua_setfield(L, -2, "__call");

  // register methods
  const struct luaL_Reg Methods[] = {
    {"next", &unpackerProxy<&Unpacker::next>},
    {"feed", &unpackerProxy<&Unpacker::feed>},
    {NULL, NULL}
  };
  luaL_register(L, NULL, Methods);
  lua_pop(L, 1);
}

int Unpacker::create(lua_State* L) {
  // TODO: check the argument of constructor (feeding Lua function)

  Unpacker** p = static_cast<Unpacker**>(lua_newuserdata(L, sizeof(Unpacker*)));
  luaL_getmetatable(L, Unpacker::MetatableName);
  lua_setmetatable(L, -2);
  *p = new Unpacker();
  return 1;
}

int Unpacker::finalizer(lua_State* L) {
  Unpacker* p =
    *static_cast<Unpacker**>(luaL_checkudata(L, 1, Unpacker::MetatableName));
  delete p;
  return 0;
}

Unpacker::Unpacker() {
}

Unpacker::~Unpacker() {
}

int Unpacker::feed(lua_State* L) {
  return feed(L, 2);
}

int Unpacker::feed(lua_State* L, int arg_base) {
  // TODO: check feeding function
  
  // check arguments first to avoid copying serialized data incompletely
  int n = lua_gettop(L);
  std::vector<std::pair<const char*, size_t> > strs;
  size_t total_size = 0;
  for (int i = arg_base; i <= n; i++) {
    size_t len;
    const char* v = luaL_checklstring(L, i, &len);
    strs.push_back(std::make_pair(v, len));
    total_size += len;
  }

  // copy strings to the buffer
  unpacker_.reserve_buffer(total_size);
  for (size_t i = 0, offs = 0; i < strs.size(); i++) {
    memcpy(unpacker_.buffer() + offs, strs[i].first, strs[i].second);
    offs += strs[i].second;
  }
  unpacker_.buffer_consumed(total_size);
  return 0;
}

int Unpacker::next(lua_State* L) {
  // feed data until execute returns true
  try {
    msgpack::unpacked data;
    while (!unpacker_.next(&data)) {
      // TODO: check the argument for feeding function and call it
      // TODO: call the feeding function passed to constructor

      // FIXME: currently, this function simply returns
      return 0;
    }

    msgpack::object msg = data.get();
    LuaObjects res(L);
    res.msgpack_unpack(msg);
    return 1;

  } catch (const msgpack::unpack_error& e) {
    return luaL_error(L, "deserialization failed: %s", e.what());
  }
}

int Unpacker::each(lua_State* L) {
  // TODO: implement
  return 0;
}

} // namespace lua
} // namespace msgpack
