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

#ifndef MSGPACK_LUA_PACKER_IMPL_HPP_
#define MSGPACK_LUA_PACKER_IMPL_HPP_

#include <lua.hpp>
#include <msgpack.hpp>

namespace msgpack {
namespace lua {

class PackerImpl {
public:
  virtual ~PackerImpl() {}

  /**
   * @brief Serializes given data
   *
   * @return The number of return values.
   */
  virtual int pack(lua_State* L, int arg_base) = 0;

  /**
   * @brief Serializes data as a table
   *
   * @return The number of return values.
   */
  virtual int packTable(lua_State* L, int arg_base) = 0;

  /**
   * @brief Serializes data as an array
   *
   * @return The number of return values.
   */
  virtual int packArray(lua_State* L, int arg_base) = 0;

  /**
   * @brief This function flushes serialized data
   * @return The number of return values.
   */
  virtual int flush(lua_State* L) = 0;
};

class DirectPackerImpl : public PackerImpl {
public:
  DirectPackerImpl() {}
  virtual ~DirectPackerImpl() {}

  /**
   * @return Always returns 1, serialized data.
   */
  virtual int pack(lua_State* L, int arg_base);

  /**
   * @return Always returns 1, serialized data.
   */
  virtual int packTable(lua_State* L, int arg_base);

  /**
   * @return Always returns 1, serialized data.
   */
  virtual int packArray(lua_State* L, int arg_base);

  /**
   * @return Always returns 0, because this function flushes serialized
   * data for each call of pack function.
   */
  virtual int flush(lua_State* L) { return 0; }
};

} // namespace lua
} // namespace msgpack

#endif
