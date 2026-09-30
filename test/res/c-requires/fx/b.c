#include <lua.h>
#include <lauxlib.h>

int luaopen_fx_b (lua_State *L)
{
  lua_pushstring(L, "from b");
  return 1;
}
