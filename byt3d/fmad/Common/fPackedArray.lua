--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:26 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

/**************************************************************************************************************/
//
// fmad llc 2008
//
// packed array type
//
/**************************************************************************************************************/

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <Common/fCommon.h>

/**************************************************************************************************************/

typedef struct fPackedArray_t
    {
        u32	Magic;

u32	Type;
u32	Stride;
u32	Len;
u32	Max;
u32	BlockSize;
union
    {
        float*	f32;
        u32*	i32;
        u16*	i16;
        u8*	i8;
        void*	v;

    } Data;

} fPackedArray_t;

/**************************************************************************************************************/
enum
    {
        pType_Integer = 0,
        pType_Float = 1,
    };

/**************************************************************************************************************/

#define PARRAY_MTABLE	"parray_mt"

/**************************************************************************************************************/
static int lPackedArray_Destroy(lua_State* L)
    {
if (lua_isnil(L, -1)) return 0;

// object data
fPackedArray_t* A = lua_getfield_userdata(L, -1, "Object", NULL);
if (A == NULL)
    {
        ftrace("no valid array\n");
return 0;
}

fAssert(A->Magic == MAGIC_PACKED_ARRAY);
if (A->Data.v != NULL)
    {
        fFree(A->Data.v);
        A->Data.v = NULL;
}

ftrace("destroy packed array: %iB\n", A->Max);
fAssert(0);

memset(A, 0, sizeof(fPackedArray_t));
fFree(A);

return 0;
}

/**************************************************************************************************************/

static struct fPackedArray_t* fPackedArray_CreateEx(lua_State* L, const char* Format, u32 BlockSize)
    {
        // default block size
BlockSize = (BlockSize == 0) ? 1*1024 : BlockSize;

// hints
//fPackedArray_t*	A = (fPackedArray_t*)fMalloc( sizeof(fPackedArray_t));
fPackedArray_t* A	= (fPackedArray_t*)lua_newuserdata(L, sizeof(fPackedArray_t));
memset(A, 0, sizeof(fPackedArray_t));
fAssert(A != NULL);

// set metatabale
luaL_getmetatable(L, PARRAY_MTABLE);
lua_setmetatable(L, -2);
//ftrace("create packed %08x %i\n", A, __LINE__);

if (strcmp(Format, "f32")==0)
    {
        A->Type		= pType_Float;
A->Stride	= 4;
}
else if (strcmp(Format, "u32")==0)
    {
        A->Type		= pType_Integer;
A->Stride	= 4;
}

// defaults

A->Len		= 0;
A->BlockSize 	= BlockSize;
A->Max	 	= 0;

//printf("block size: %i\n", A->BlockSize);

A->Magic = MAGIC_PACKED_ARRAY;

return A;
}

/**************************************************************************************************************/
// pushes a raw packed array onto the lua stack
struct fPackedArray_t*  fPackedArray_Create(lua_State* L, const char* Format, u32 BlockSize)
    {
        // object table
lua_newtable(L);

// raw object
fPackedArray_t* A = fPackedArray_CreateEx(L, Format, BlockSize);
lua_setfield(L, -2, "Object");

// get function top
lua_getglobal(L, "fPackedArray");
fAssert(!lua_isnil(L, -1));

// get meta table
lua_getfield(L, -1, "MT");
fAssert(!lua_isnil(L, -1));

// apply to object
lua_setmetatable(L, -3);

// fPackedArray pop
lua_pop(L, 1);

return A;
}
/**************************************************************************************************************/
static int lPackedArray_Create(lua_State* L)
    {
        lua_getfield(L, -2, "Format");
        const char* Format = lua_tostring(L, -1);
lua_pop(L, 1);

u32 BlockSize = lua_getfield_number(L, -1, "BlockSize", 16*1024);

// creates it on the stack
fPackedArray_t* A = fPackedArray_CreateEx(L, Format, BlockSize);

//lua_pushlightuserdata(L, A);
return 1;
}

/**************************************************************************************************************/
// sets an element
void fPackedArray_Set(struct fPackedArray_t* A, u32 index, double value)
    {
        fAssert(A);
        fAssert(A->Magic == MAGIC_PACKED_ARRAY);

        // new array needed?

u32 Offset = index*A->Stride;
if (Offset >= A->Len)
    {
        u32 NextSize = (Offset+A->BlockSize-1)&(~(A->BlockSize-1));
NextSize = (A->Len == 0) ? A->BlockSize : NextSize;		// init when offset/len == 0

A->Data.v = realloc(A->Data.v, NextSize);
A->Len = NextSize;
//printf("new block %p %08x blksize:%i %08x\n ", A->Data.v, A->Len, A->BlockSize, NextSize);
}
fAssert(index < A->Len);
switch (A->Type)
    {
        case pType_Float:	A->Data.f32[index] = value; 		break;
case pType_Integer:	A->Data.i32[index] = value;		break;
}

A->Max = (A->Max < index) ? index : A->Max;
return;
}

static int lPackedArray_Set(lua_State* L)
{
fPackedArray_t* A = (fPackedArray_t*)lua_touserdata(L, -3);
fAssert(A->Magic == MAGIC_PACKED_ARRAY);

if (!lua_isnumber(L, -2))
{
ftrace("PackedArray_Set: attempting to index with non number\n");
return 0;
}
int index  = lua_tonumber(L, -2);

double value = 0;
if (!lua_isnumber(L, -1))
{
//ftrace("PackedArray_Set: attempting to set a non number\n");
//return 0;
}
else
{
value = lua_tonumber(L, -1);
}

fPackedArray_Set(A, index, value);
return 0;
}

/**************************************************************************************************************/
// gets an element
static int lPackedArray_Get(lua_State* L)
{
fPackedArray_t* A = (fPackedArray_t*)lua_touserdata(L, -2);

if (!lua_isnumber(L, -1))
{
ftrace("PackedArray_Set: attempting to index with non number\n");
return 0;
}
int index  = lua_tonumber(L, -1);

// new array needed?

u32 Offset = index*A->Stride;
if (index > A->Max)
{
ftrace("PackedArray_set: index out of range %08x [0,%08x]\n", index, A->Max);
return 0;
}

switch (A->Type)
{
case pType_Float:
lua_pushnumber(L, A->Data.f32[index]);
break;
case pType_Integer:
lua_pushnumber(L, A->Data.i32[index]);
break;
}
return 1;
}

/**************************************************************************************************************/
// persist array
void* fPackedArray_Persist(lua_State* L, void* Data, u32* Len)
{
fPackedArray_t* A = (fPackedArray_t*)Data;
fAssert(A);

//ftrace("persist array now %iKB\n", A->Len/1024);

u32* Block = (u32 *)fMalloc(A->Len + 16*sizeof(int));
fAssert(Block != NULL);
Block[0] = A->Magic;
Block[1] = A->Type;
Block[2] = A->Stride;
Block[3] = A->Len;
Block[4] = A->Max;
Block[5] = A->BlockSize;

memcpy((void *)&Block[16], A->Data.v, A->Len);

Len[0] = A->Len + 16;
return Block;
}

/**************************************************************************************************************/
// persist array
void fPackedArray_Unpersist(lua_State* L, void* Data, u32 Len)
{
//ftrace("unpersist packed array\n");

u32* Block = (u32*)Data;

//fPackedArray_t* A = (fPackedArray_t*)fMalloc(sizeof(fPackedArray_t));
fPackedArray_t* A = (fPackedArray_t*)lua_newuserdata(L, sizeof(fPackedArray_t));
fAssert(A);
memset(A, 0, sizeof(fPackedArray_t));

// set metatabale
luaL_getmetatable(L, PARRAY_MTABLE);
lua_setmetatable(L, -2);

fAssert(Block[0] == MAGIC_PACKED_ARRAY);
A->Magic	= Block[0];
A->Type		= Block[1];
A->Stride	= Block[2];
A->Len		= Block[3];
A->Max		= Block[4];
A->BlockSize 	= Block[5];
A->Data.v	= NULL;

//ftrace("unpersist packed array: type: %08x\n",				A->Type);
//ftrace("unpersist packed array: stride: %08x\n",			A->Stride);
//ftrace("unpersist packed array: max: %08x\n",				A->Max);
//ftrace("unpersist packed array: Len: %08x : %08x max: %08x\n",		A->Len, Len, A->Max*A->Stride);

// sanity check (< 128MB)
fAssert(A->Max*A->Stride <= A->Len);
fAssert(A->Len < 128*1024*1024);
//fAssert(A->Len <= (Len-16*sizeof(int)));

if (A->Len > 0)
{
A->Data.v = fMalloc(A->Len);
fAssert(A->Data.v);
}
memcpy(A->Data.v, &Block[16], A->Len);

//lua_pushuserobject(L, A);
return;
}

/**************************************************************************************************************/

struct fPackedArray_t* fPackedArray_to(lua_State* L, int index)
{
fPackedArray_t* A = lua_touserdata(L, index);
fAssert(A);
fAssert(A->Magic == MAGIC_PACKED_ARRAY);

return (struct fPackedArray_t*)A;
}

/**************************************************************************************************************/
u32 fPackedArray_ArrayLen(struct fPackedArray_t* A)
{
if (A == NULL) return 0;

fAssert(A->Magic == MAGIC_PACKED_ARRAY);
return A->Max;
}
float* fPackedArray_ArrayFloat(struct fPackedArray_t* A)
{
if (A == NULL) return NULL;
fAssert(A->Magic == MAGIC_PACKED_ARRAY);
fAssert(A->Type == pType_Float);
return A->Data.f32;
}
u32* fPackedArray_ArrayInt(struct fPackedArray_t* A)
{
if (A == NULL) return NULL;
fAssert(A->Magic == MAGIC_PACKED_ARRAY);
fAssert(A->Type == pType_Integer);
return A->Data.i32;
}

/**************************************************************************************************************/
static int lPackedArray_Length(lua_State* L)
{
fPackedArray_t* A = fPackedArray_to(L, -1);
lua_pushnumber(L, A->Max);
return 1;
}

/**************************************************************************************************************/
static int lPackedArray_LengthMT(lua_State* L)
{
fPackedArray_t* A = fPackedArray_to(L, -2);
lua_pushnumber(L, A->Max);
return 1;
}

/**************************************************************************************************************/

static int lPackedArray_GC(lua_State* L)
{
fPackedArray_t* A = fPackedArray_to(L, -1);

//ftrace("packed array gc %08x %08x %iB\n", A, A->Data.v, A->Len);
if (A->Data.v != NULL)
{
fFree(A->Data.v);
A->Data.v = NULL;
}
//	memset(A, 0, sizeof(fPackedArray_t));
return 0;
}
/**************************************************************************************************************/
static int lPackedArray_Persist(lua_State* L)
{
fPackedArray_t* A = fPackedArray_to(L, -3);

u32* Block = (u32 *)fMalloc(A->Len + 16*sizeof(int));
fAssert(Block != NULL);
Block[0] = A->Magic;
Block[1] = A->Type;
Block[2] = A->Stride;
Block[3] = A->Len;
Block[4] = A->Max;
Block[5] = A->BlockSize;

memcpy((void *)&Block[16], A->Data.v, A->Len);
u32 Len = A->Len + 16*sizeof(int);

//ftrace("pserisist packed array: %08x\n", Len);

lua_pushlstring(L, (void *)Block, Len);

// release buffer
memset(Block, 0, 16*sizeof(int));
fFree(Block);

return 1;
}

/**************************************************************************************************************/

static int lPackedArray_GetMT(lua_State* L)
{
if (lua_type(L, -1) != LUA_TNUMBER)
{
ftrace("get %i %i %i\n", lua_type(L, -1), lua_type(L, -2));
ftrace("packed array get, index is not a number!\n");
return 0;
}

u32 Index = lua_tonumber(L, -1);
fPackedArray_t* A = fPackedArray_to(L, -2);

// new array needed?

u32 Offset = Index*A->Stride;
if (Index > A->Max)
{
ftrace("PackedArray_get: index out of range %08x [0,%08x]\n", Index, A->Max);
return 0;
}

switch (A->Type)
{
case pType_Float:
lua_pushnumber(L, A->Data.f32[Index]);
break;
case pType_Integer:
lua_pushnumber(L, A->Data.i32[Index]);
break;
}
return 1;
}

/**************************************************************************************************************/

static int lPackedArray_SetMT(lua_State* L)
{
ftrace("set %i %i %i\n", lua_type(L, -1), lua_type(L, -2), lua_type(L, -3));
if (lua_type(L, -1) != LUA_TNUMBER)
{
ftrace("packed array set, index is not a number!\n");
return 0;
}

double value	= lua_tonumber(L, -1);
u32 Index	= lua_tonumber(L, -2);
fPackedArray_t* A = fPackedArray_to(L, -3);

fPackedArray_Set(A, Index, value);
return 0;
}

/**************************************************************************************************************/
void fPackedArray_Register(lua_State* L)
{
lua_pushcfunction(L, lPackedArray_Create);
lua_setglobal(L, "fPackedArray_Create");

lua_pushcfunction(L, lPackedArray_Destroy);
lua_setglobal(L, "fPackedArray_Destroy");

lua_pushcfunction(L, lPackedArray_Set);
lua_setglobal(L, "fPackedArray_Set");

lua_pushcfunction(L, lPackedArray_Get);
lua_setglobal(L, "fPackedArray_Get");

lua_pushcfunction(L, lPackedArray_Length);
lua_setglobal(L, "fPackedArray_Length");

// create metatable
luaL_newmetatable(L, PARRAY_MTABLE);  /* create metatable for file handles */
lua_pushcfunction(L, lPackedArray_GC);
lua_setfield(L, -2, "__gc");

lua_pushcfunction(L, lPackedArray_Persist);
lua_setfield(L, -2, "__persist");

//lua_pushcfunction(L, lPackedArray_LengthMT);
//lua_setfield(L, -2, "__len");

//lua_pushcfunction(L, lPackedArray_GetMT);
//lua_setfield(L, -2, "__index");

//lua_pushcfunction(L, lPackedArray_SetMT);
//lua_setfield(L, -2, "__newindex");

//lua_getglobal(L, "fPackedArray_Unpersist");
//lua_setfield(L, -2, "__unpersist");
}
