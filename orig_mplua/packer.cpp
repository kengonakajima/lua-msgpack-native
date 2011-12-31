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

#include "packer.hpp"

#include <cassert>
#include "packer_impl.hpp"

// TODO: check error codes of msgpack

namespace msgpack {
namespace lua {
namespace {
template<int (Packer::*Memfun)(lua_State*)>
int packerProxy(lua_State* L) {
  Packer* p =
    *static_cast<Packer**>(luaL_checkudata(L, 1, Packer::MetatableName));
  return (p->*Memfun)(L);
}
} // namespace

const char* const Packer::MetatableName = "msgpack.Packer";

void Packer::registerUserdata(lua_State* L) {
  if (luaL_newmetatable(L, Packer::MetatableName) == 0) {
    lua_pop(L, 1);
    return; // already created
  }

  // metatable.__index = metatable
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");

  // set __gc
  lua_pushcfunction(L, &Packer::finalizer);
  lua_setfield(L, -2, "__gc");

  // register methods
  const struct luaL_Reg Methods[] = {
    {"pack", &packerProxy<&Packer::pack>},
    {"packTable", &packerProxy<&Packer::packTable>},
    {"packArray", &packerProxy<&Packer::packArray>},
    {NULL, NULL}
  };
  luaL_register(L, NULL, Methods);
  lua_pop(L, 1);
}

int Packer::create(lua_State* L) {
  // TODO: check the argument of constructor
  // TODO: Create StreamPackerImpl if stack[1] == function

  Packer** p = static_cast<Packer**>(lua_newuserdata(L, sizeof(Packer*)));
  luaL_getmetatable(L, Packer::MetatableName);
  lua_setmetatable(L, -2);
  *p = new Packer(new DirectPackerImpl());
  return 1;
}

int Packer::finalizer(lua_State* L) {
  Packer* p =
    *static_cast<Packer**>(luaL_checkudata(L, 1, Packer::MetatableName));
  delete p;
  return 0;
}

Packer::Packer(PackerImpl* packer) : packer_(packer) {
  assert(packer != NULL);
}

Packer::~Packer() {
  delete packer_;
}

int Packer::pack(lua_State* L) {
  return packer_->pack(L, 2); // excluding Packer userdata
}

int Packer::packTable(lua_State* L) {
  return packer_->packTable(L, 2);
}

int Packer::packArray(lua_State* L) {
  return packer_->packArray(L, 2);
}

} // namespace lua
} // namespace msgpack
