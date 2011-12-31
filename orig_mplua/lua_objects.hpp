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

#ifndef MSGPACK_RPC_LUA_LUA_OBJECT_HPP_
#define MSGPACK_RPC_LUA_LUA_OBJECT_HPP_

#include <lua.hpp>
#include <msgpack.hpp>

namespace msgpack {
namespace lua {

/**
 * @brief Lua Object class for serialization.
 */
class LuaObjects {
public:
  /**
   * @param arg_base This is necessary only when LuaObjects will be serialized
   */
  LuaObjects(lua_State* L, int arg_base = 0, bool pack_as_array = false);

  template<typename Packer>
  void msgpack_pack(Packer& pk) const {
    int n = lua_gettop(L);
    if (arg_base_ > n) {
      if (pack_as_array_) pk.pack_array(0);
      return;
    }

    // If pack_as_array is true, all elements in the stack
    // will be serialized into an array. Otherwise,
    // each element will be serialized independently.
    if (pack_as_array_) pk.pack_array(n - arg_base_ + 1);
    for (int i = arg_base_; i <= n; i++) {
      pack(pk, i);
    }
  }

  template<typename Packer>
  void packTable(Packer& pk) const {
    int n = lua_gettop(L);
    for (int i = arg_base_; i <= n; i++) {
      int t = lua_type(L, i);
      if (t != LUA_TTABLE) {
        luaL_error(L, "Arguments must be tables.");
        return;
      }
      packTableAsTable(pk, i);
    }
  }

  template<typename Packer>
  void packArray(Packer& pk) const {
    int n = lua_gettop(L);
    for (int i = arg_base_; i <= n; i++) {
      int t = lua_type(L, i);
      if (t != LUA_TTABLE) {
        luaL_error(L, "Arguments must be tables.");
        return;
      }
      packTableAsArray(pk, i);
    }
  }

  void msgpack_unpack(const msgpack::object& msg);

private:
  // TODO: merge these with mplua's implementation
  template<typename Packer>
  void pack(Packer& pk, int index) const {
    int t = lua_type(L, index);
    switch (t) {
    case LUA_TNUMBER: packNumber(pk, index); break;
    case LUA_TBOOLEAN: packBoolean(pk, index); break;
    case LUA_TSTRING:  packString(pk, index); break;
    case LUA_TTABLE: packTable(pk, index); break;
    case LUA_TUSERDATA:
      // TODO: support userdata serialization.
      // Calling __serialize meta-method may be good.

      // raise an error temporally
      luaL_error(L, "Packing userdata has not been supported yet. "
                 "However, it will be implemented soon.");
      return;

    case LUA_TNIL:
    case LUA_TTHREAD:
    case LUA_TLIGHTUSERDATA:
    default:
      luaL_error(L, "invalid type for pack: %s",
                 lua_typename(L, t));
      break;
    }
  }

  template<typename Packer>
  void packNumber(Packer& pk, int index) const {
    double n = lua_tonumber(L, index);
    int64_t i = static_cast<int64_t>(n);
    if (i == n) pk.pack(i);
    else pk.pack(n);
  }

  template<typename Packer>
  void packBoolean(Packer& pk, int index) const {
    int b = lua_toboolean(L, index);
    pk.pack(b != 0);
  }

  template<typename Packer>
  void packString(Packer& pk, int index) const {
    size_t len;
    const char* str = lua_tolstring(L, index, &len);
    if (str == NULL) {
      int t = lua_type(L, index);
      luaL_error(L, "lua_tolstring failed for index %d: type = %s",
                 index, lua_typename(L, t));
      return;
    }
    pk.pack_raw(len);
    pk.pack_raw_body(str, len);
  }

  template<typename Packer>
  void packTable(Packer& pk, int index) const {
    // TODO: support serialize meta-method for Lua classes.

    // check if this is an array
    // NOTE: This code strongly depends on the internal implementation
    // of Lua5.1. The table in Lua5.1 consists of two parts: the array part
    // and the hash part. The array part is placed before the hash part.
    // Therefore, it is possible to obtain the first key of the hash part
    // by using the return value of lua_objlen as the argument of lua_next.
    // If lua_next return 0, it means the table does not have the hash part,
    // that is, the table is an array.
    //
    // Due to the specification of Lua, the table with non-continous integral
    // keys is detected as a table, not an array.
    bool is_array = false;
    size_t len = lua_objlen(L, index);
    if (len > 0) {
      lua_pushnumber(L, len);
      if (lua_next(L, index) == 0) is_array = true;
      else lua_pop(L, 2);
    }

    if (is_array) packTableAsArray(pk, index);
    else packTableAsTable(pk, index);
  }

  template<typename Packer>
  void packTableAsTable(Packer& pk, int index) const {
    // calc the size of the table
    // TODO: Make this faster!!
    size_t len = 0;
    lua_pushnil(L);
    while (lua_next(L, index) != 0) {
      len++; lua_pop(L, 1);
    }
    pk.pack_map(len);

    int n = lua_gettop(L); // used as a positive index
    lua_pushnil(L);
    while (lua_next(L, index) != 0) {  
      pack(pk, n + 1); // -2:key
      pack(pk, n + 2); // -1:value
      lua_pop(L, 1); // removes value, keeps key for next iteration
    }
  }

  template<typename Packer>
  void packTableAsArray(Packer& pk, int index) const {
    int n = lua_gettop(L);
    size_t len = lua_objlen(L, index);

    pk.pack_array(len);
    for (size_t i = 1; i <= len; i++) {
      lua_rawgeti(L, index, i);
      pack(pk, n + 1);
      lua_pop(L, 1);
    }
  }

  template<typename Packer>
  void packTableAsClass(Packer& pk, int index) const {
    // TODO: implement
  }

  template<typename Packer>
  void packTableAsUserdata(Packer& pk, int index) const {
    // TODO: support userdata serialization.
    // Calling __serialize meta-method may be good.

    // raise an error temporally
    luaL_error(L, "Packing userdata has not been supported yet. "
               "However, it will be implemented soon.");
  }

private:
  void unpackArray(const msgpack::object_array& a);
  void unpackTable(const msgpack::object_map& m);

private:
  lua_State* L;
  int arg_base_;
  bool pack_as_array_;
};

} // namespace lua
} // namespace msgpack

#endif
