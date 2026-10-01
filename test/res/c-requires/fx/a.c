// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2023 Birch Point SWE
#include <lua.h>
#include <lauxlib.h>

int luaopen_fx_a (lua_State *L)
{
  lua_getglobal(L, "require");
  lua_pushstring(L, "fx.b");
  lua_call(L, 1, 1);
  return 1;
}
