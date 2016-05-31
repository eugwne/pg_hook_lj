PG_CONFIG ?= pg_config #/usr/local/pgsql/bin/pg_config
PKG_LIBDIR := $(shell $(PG_CONFIG) --pkglibdir)

LUA_INCDIR ?= /usr/local/include/luajit-2.1
LUALIB ?= -L/usr/local/lib -lluajit-5.1
LUA_DIR ?= /usr/local/share/lua/5.1

MODULES = pg_hook_lua
MODULE_big = pg_hook_lua
EXTENSION = pg_hook_lua


OBJS = \
pg_hook_lua.o 

PG_CPPFLAGS = -I$(LUA_INCDIR)
SHLIB_LINK = $(LUALIB)

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
install-module:
	mkdir -p $(LUA_DIR)/pglj_hook
	cp src/pglj_hook.lua $(LUA_DIR)/pglj_hook.lua

