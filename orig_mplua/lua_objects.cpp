/*
 * MessagePack for Lua
 *
 * Copyright (C) 2010 Nobuyuki Kubota
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

#include "lua_objects.hpp"

namespace msgpack {
namespace lua {

LuaObjects::LuaObjects(lua_State* L, int arg_base, bool pack_as_array)
  : L(L), arg_base_(arg_base), pack_as_array_(pack_as_array) {
}

void LuaObjects::msgpack_unpack(const msgpack::object& msg) {
  namespace type = msgpack::type;
  switch (msg.type) {
  case type::NIL:
    lua_pushnil(L);
    break;

  case type::BOOLEAN:
    lua_pushboolean(L, msg.via.boolean);
    break;

    // Lua internally uses double to represent integer. In addition,
    // lua_Integer is the alias of ptrdiff_t, which can be 32 bits.
    // Therefore, pushing (u)int64_t as double is the best way.
  case type::POSITIVE_INTEGER:
    lua_pushnumber(L, msg.via.u64);
    break;

  case type::NEGATIVE_INTEGER:
    lua_pushnumber(L, msg.via.i64);
    break;

  case type::DOUBLE:
    lua_pushnumber(L, msg.via.dec);
    break;

  case type::RAW:
    lua_pushlstring(L, msg.via.raw.ptr, msg.via.raw.size);
    break;

  case type::ARRAY:
    unpackArray(msg.via.array);
    break;

  case type::MAP:
    unpackTable(msg.via.map);
    break;

  default:
    luaL_error(L, "invalid type for unpack: %d", msg.type);
    return;
  }
}

void LuaObjects::unpackArray(const object_array& a) {
  lua_newtable(L);
  for (uint32_t i = 0; i < a.size; i++) {
    msgpack_unpack(a.ptr[i]);
    lua_rawseti(L, -2, i + 1);
  }
}

void LuaObjects::unpackTable(const object_map& m) {
  lua_newtable(L);
  for (uint32_t i = 0; i < m.size; i++) {
    msgpack_unpack(m.ptr[i].key);
    msgpack_unpack(m.ptr[i].val);
    lua_rawset(L, -3);
  }
}

} // namespace lua
} // namespace msgpack
