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

#ifndef MSGPACK_LUA_PACKER_HPP_
#define MSGPACK_LUA_PACKER_HPP_

#include <lua.hpp>
#include <msgpack.hpp>

namespace msgpack {
namespace lua {

class PackerImpl;

/**
 * Metatable for this class:
 * callback = nil or function (serialized string)
 */
class Packer {
private:
  Packer(const Packer&);
  Packer& operator =(const Packer&);

public:
  static const char* const MetatableName;
  static void registerUserdata(lua_State* L);
  static int create(lua_State* L);

private:
  static int finalizer(lua_State* L);

public:
  Packer(PackerImpl* buf);
  ~Packer();

  /**
   * @brief Pack arbitrary data.
   *
   * This function has a variable number of arguments. The type of each
   * argument is automatically detected and packed in an appropriate way.
   * This function also correctly packs tables or arrays which recursively
   * have tables or arrays.
   */
  int pack(lua_State* L);

  /**
   * @brief Pack tables.
   *
   * This function packs tables. If arguments are actually arrays (having only
   * integral keys), this function packs them as tables.
   *
   * If arguments recursively have an array, it will be packed as an array,
   * not as a table.
   */
  int packTable(lua_State* L);

  /**
   * @brief Pack arrays.
   *
   * This function packs arrays. If arguments have keys other than integers,
   * this function ignores those keys and only packs integral keys and their
   * values.
   *
   * In addition, if arguments recursively have an table, it will be packed
   * as an table, not as an array.
   */
  int packArray(lua_State* L);

  PackerImpl* packer() { return packer_; }
  const PackerImpl* packer() const { return packer_; }

private:
  PackerImpl* packer_;
};

} // namespace lua
} // namespace msgpack

#endif
