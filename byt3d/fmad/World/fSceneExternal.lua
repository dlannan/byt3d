--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:46 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

//********************************************************************************************************************
//
// fmad llc 2008
//
// scene external interface
//
//********************************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <X11/X.h>
#include <X11/Xlib.h>
#include <GL/gl.h>
#include <GL/glx.h>
#include <GL/glu.h>
#include  <GL/glext.h>

#include <Common/fCommon.h>
#include <Network/fNetwork.h>
#include "fScene.h"
#include "fSceneObject.h"
#include "fSceneExternal.h"

//********************************************************************************************************************
#define SCENEEXTERNAL_MAGIC	0xbeefcac3

typedef struct fSceneExternal_t
    {
        struct fScene_t*	Scene;
struct fUniCastNode_t*	U;


u32 Magic;

} fSceneExternal_t;

#define fSceneExternal_PacketID_3f		1

typedef struct
    {
        char	Path[128];
char	Function[64];

u32	Type;

double	x;
double	y;
double	z;

double	i;
double	j;
double	k;
double	l;

//char	Data[128];

} fSceneExternalPacket_t;

//********************************************************************************************************************
struct fSceneExternal_t* toSceneExternal(lua_State* L, int index)
    {
        fSceneExternal_t* E = lua_touserdata(L, index);
fAssert(E);
fAssert(E->Magic == SCENEEXTERNAL_MAGIC);

return E;
}

//********************************************************************************************************************
static void fSceneExternal_ObjectCreate(
struct fUniCastNode_t* N,
struct fUniCastClient_t* C,
void* Data,
u32 Size,
void* User)
{
fSceneExternal_t* E = User;
fAssert(E);

printf("obj add\n");

fScene_MessagePush(E->Scene, "ObjectAdd", Data, Size);
}

//********************************************************************************************************************
static void fSceneExternal_NodeCreate(
struct fUniCastNode_t* N,
struct fUniCastClient_t* C,
void* Data,
u32 Size,
void* User)
{
fSceneExternal_t* E = User;
fAssert(E);

printf("node add\n");

fScene_MessagePush(E->Scene, "NodeAdd", Data, Size);
}

//********************************************************************************************************************
static void fSceneExternal_ObjectPacket(
struct fUniCastNode_t* N,
struct fUniCastClient_t* C,
void* Data,
u32 Size,
void* User)
{
fSceneExternal_t* E = User;
fAssert(E);

// get packet
fSceneExternalPacket_t* P = Data;

// search for object
fSceneObject_t* O= fScene_ObjectFind(E->Scene, P->Path);
if (!O)
{
ftrace("fSceneExternal_ObjectPacket: unable to find object [%s]\n", P->Path);
return;
}

lua_getglobal(O->lvm, P->Function);
if (lua_isnil(O->lvm, -1))
{
printf("no function named [%s]\n", P->Function);
lua_pop(O->lvm, 1);
return;
}

// add args

u32 ParamCount = 0;
switch (P->Type)
{
case fSceneExternal_PacketID_3f:
/*
lua_getglobal(O->lvm, "Translate");

lua_pushnumber(O->lvm, P->x);
lua_setfield(O->lvm, -2, "x");

lua_pushnumber(O->lvm, P->y);
lua_setfield(O->lvm, -2, "y");

lua_pushnumber(O->lvm, P->z);
lua_setfield(O->lvm, -2, "z");

lua_pop(O->lvm, 1);
*/
lua_pushnumber(O->lvm, P->x);
lua_pushnumber(O->lvm, P->y);
lua_pushnumber(O->lvm, P->z);
ParamCount = 3;
break;

default:
ftrace("undefined packet type: %08x\n", P->Type);
lua_pop(O->lvm, 1);
return;
}

// call

lua_pcall(O->lvm, ParamCount, 0, 0);
//lua_pop(O->lvm, 1);
}

//********************************************************************************************************************

struct fSceneExternal_t* fSceneExternal_Create(lua_State* L, struct fScene_t* S, void* ExternNet)
{
fSceneExternal_t* E = fMalloc(sizeof(fSceneExternal_t));
memset(E, 0, sizeof(fSceneExternal_t));
E->Magic = SCENEEXTERNAL_MAGIC;

// scene its attached to

E->Scene = S;

// unicast object

E->U = ExternNet;
fAssert(E->U);

// object command dispatchs

fUniCast_PacketHandler(E->U, fSceneExternalID_ObjectCreate,		fSceneExternal_ObjectCreate, E);
fUniCast_PacketHandler(E->U, fSceneExternalID_NodeCreate,		fSceneExternal_NodeCreate, E);
fUniCast_PacketHandler(E->U, fSceneExternalID_ObjectPacket,		fSceneExternal_ObjectPacket, E);

return E;
}

//********************************************************************************************************************
static int lSceneExternal_Destroy(lua_State* L)
{
return 1;
}

//********************************************************************************************************************

int fSceneExternal_Register(lua_State* L)
{
//lua_table_register(L, -1, "SceneExternal_Update",	lSceneExternal_Update);
return 0;
}
