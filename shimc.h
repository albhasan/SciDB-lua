#ifndef shimc.h
#define shimc.h
static int newsession(lua_State *L);
static int version(lua_State *L);
static int releasesession(lua_State *L);
static int executequery(lua_State *L);
static int cancel(lua_State *L);
static int readlines(lua_State *L);
static int readbytes(lua_State *L);
static int uploadfile(lua_State *L);
static int login(lua_State *L);
static int logout(lua_State *L);
int luaopen_shimclient(lua_State *L);
#endif