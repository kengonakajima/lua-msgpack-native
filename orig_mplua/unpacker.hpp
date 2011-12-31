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

#ifndef MSGPACK_LUA_UNPACKER_HPP_
#define MSGPACK_LUA_UNPACKER_HPP_

#include <lua.hpp>
#include <msgpack.hpp>

namespace msgpack {
namespace lua {

/**
 * @todo implement Feeder for Unpacker to use user defined feeding function.
 */
class Feeder;

class Unpacker {
private:
  Unpacker(const Unpacker&);
  Unpacker& operator =(const Unpacker&);

public:
  static const char* const MetatableName;
  static void registerUserdata(lua_State* L);
  static int create(lua_State* L);

private:
  static int finalizer(lua_State* L);

public:
  Unpacker();
  ~Unpacker();

  /**
   * @brief feeding serialized data
   */
  int feed(lua_State* L);

  /**
   * @brief feed function with base index of the stack.
   */
  int feed(lua_State* L, int arg_base);

  /**
   * @brief Get deserialized objects if exist
   *
   * @return When there is a deserialized object, this function returns it.
   * Otherwise, returns nil.
   *
   * @note this function can be call in two ways:
   * unpacker.data() or unpacker().
   *
   * memo:
   * Currently, Unpacker only support manual feeding by calling feed function.
   * Feeding from user defined function should also be supported. 
   *
   * example code:
   * p = msgpack.Unpacker([feeder1])
   * for v in p [, feeder2] do
   *   -- v has deserialized data
   * end
   *
   * There can be three type of feeding functions:
   *
   * 1. funciton f (unpacker) unpacker.feed("data") end
   * 2. function f () return "data" end --> feed "data"
   * 3. function f (unpacker) unpacker.feed("data1"); return "data2" end
   *      --> feed "data2"
   *
   * 3 may be good. Every function returns nil when no more feed exists.
   */
  int next(lua_State* L);

  /**
   * @brief deserialize objects and pass them to the given function.
   *
   * @pre
   * Usage:
   * p = msgpack.Unpacker()
   * -- feed data
   * p:each(function (object)
   *   -- process deserialized object here
   * end)
   */
  int each(lua_State* L);

private:
  msgpack::unpacker unpacker_;
};

} // namespace lua
} // namespace msgpack

#endif
