#include "postgres.h"
#include "fmgr.h"

PG_MODULE_MAGIC;

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <luajit.h>

PGDLLEXPORT Datum _PG_init(PG_FUNCTION_ARGS);
PGDLLEXPORT Datum _PG_fini(PG_FUNCTION_ARGS);

#define out(...) ereport(INFO, (errmsg(__VA_ARGS__)))
#define dolog(...) ereport(LOG, (errmsg(__VA_ARGS__)))
#define pg_throw(...) ereport(ERROR, (errmsg(__VA_ARGS__)))


static lua_State *L = NULL;


static int init_ref = 0;
static int fini_ref = 0;

PG_FUNCTION_INFO_V1(_PG_init);
Datum _PG_init(PG_FUNCTION_ARGS)
{
	int status;
	L = lua_open();

	LUAJIT_VERSION_SYM();
	lua_gc(L, LUA_GCSTOP, 0);
	luaL_openlibs(L);
	lua_gc(L, LUA_GCRESTART, -1);
	dolog("pglj_hook start");

	lua_getglobal(L, "require");
	lua_pushstring(L, "pglj_hook");
	status = lua_pcall(L, 1, 1, 0);
	if (status)
		pg_throw("pglj_hook loading error");

	lua_getfield(L, 1, "_PG_init");
	init_ref  = luaL_ref(L, LUA_REGISTRYINDEX);

	lua_getfield(L, 1, "_PG_fini");
	fini_ref  = luaL_ref(L, LUA_REGISTRYINDEX);


	lua_settop(L, 0);
	lua_rawgeti(L, LUA_REGISTRYINDEX, init_ref);
	status = lua_pcall(L, 0, 0, 0);

	if (status == 0){
		PG_RETURN_VOID();
	}

	if( status == LUA_ERRRUN) {
		pg_throw("%s %s","Error:",lua_tostring(L, -1));
	} else if (status == LUA_ERRMEM) {
		pg_throw("%s %s","Memory error:",lua_tostring(L, -1));
	} else if (status == LUA_ERRERR) {
		pg_throw("%s %s","Error:",lua_tostring(L, -1));
	}

	pg_throw("pllj unknown error");

	PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(_PG_fini);
Datum _PG_fini(PG_FUNCTION_ARGS) {

	lua_settop(L, 0);
	lua_rawgeti(L, LUA_REGISTRYINDEX, fini_ref);
	lua_pcall(L, 0, 0, 0);

	lua_close(L);
	PG_RETURN_VOID();
}
