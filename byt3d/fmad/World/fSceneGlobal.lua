--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:37 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

--//********************************************************************************************************************
--//
--// fmad llc 2008
--//
--// scene global state. its a shared luastate between render & scene objects. this is likely to
--// be a bottleneck/hazard once start ramping up the paralleism so placed here as its a point of congestion
--//
--//********************************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <Common/fCommon.h>
#include "fScene.h"
#include "fSceneGlobal.h"

#define SCENEGLOBAL_MAGIC	0xbeefb001

//********************************************************************************************************************

typedef struct fSceneGlobal_t
    {
        u32		Magic;
lua_State*	State;

} fSceneGlobal_t;

//********************************************************************************************************************
int fSceneGlobal_Get(struct fSceneGlobal_t* G, const char* Key, lua_State* L)
    {
        fAssert(G);
        fAssert(G->Magic == SCENEGLOBAL_MAGIC);
        fAssert(Key);

        lua_getglobal(G->State, Key);
if (lua_isnil(G->State, -1))
    {
        lua_pop(G->State, 1);
        //dtrace("fSceneGlobal_Get: failed to find [%s]\n", Key);
return 0;
}

u32 items = lua_deep_copy(L, G->State);
lua_pop(G->State, 1);

// fetch a global
return items;
}

//********************************************************************************************************************
int fSceneGlobal_Set(struct fSceneGlobal_t* G, const char* Key, lua_State* L)
    {
        fAssert(G);
        fAssert(G->Magic == SCENEGLOBAL_MAGIC);
        fAssert(Key);

        //ftrace("set global [%s]\n", Key);

        lua_deep_copy(G->State, L);
        lua_setglobal(G->State, Key);

        // set a global
return 0;
}

//********************************************************************************************************************
// creates 1 instance per scene or so
struct fSceneGlobal_t* fSceneGlobal_Create(void)
    {
        fSceneGlobal_t* G = fMalloc(sizeof(fSceneGlobal_t));
fAssert(G);

G->State = lua_open();
fAssert(G->State);

G->Magic = SCENEGLOBAL_MAGIC;
return G;
}

//********************************************************************************************************************
void fSceneGlobal_Destroy(struct fSceneGlobal_t* G)
{
lua_close(G->State);
G->State = NULL;

memset(G, 0, sizeof(fSceneGlobal_t));
fFree(G);
}


//********************************************************************************************************************
// register with module
int fSceneGlobal_Register(lua_State* L)
{
return 0;
}
