--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:29 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

// global user data types
#define MAGIC_PACKED_ARRAY 	0x13370001



#ifdef WIN32
// only bits are supported  on  windowz

#include <Common/fTypes.h>
#include <assert.h>
#include <Common/fURL.h>

#define fAssert		assert
#define fMalloc		malloc
#define fFree		free

#else

#include <Common/fTypes.h>
#include <Common/fTrace.h>
#include <Common/fCrypt.h>
#include <Common/fFIFO.h>
#include <Common/fMemory.h>
#include <Common/fAssert.h>
#include <Common/fProfile.h>
#include <Common/fVector3.h>
#include <Common/fMath.h>
#include <Common/fPackedArray.h>
#include <Common/fPTable.h>

#include <Tools/Lua/fLua.h>
#include <Common/fCuda.h>
#include <Common/fURL.h>

typedef struct
{
const char* Name;
const char* FileName;
const char* ByteCodeStart;
const char* ByteCodeEnd;
} LuaInclude_t;

void 		fMkdir(const char* Path);
void 		luaopen_common(lua_State* L);
void 		luainc_load(lua_State* L, u32 count, LuaInclude_t* Inc, bool StackPop);
const char* 	fCommon_FullPath(lua_State* L, const char* semi);
void 		fCommon_Deepcopy(lua_State* D, lua_State* S);
double 		time_sec(void);
u32		fCommon_CRC32(void* Data, u32 Len);

static u32 WordSwap(u32 w)
{
return (((w>>0)&0xFF)<<24) | (((w>>8)&0xFF)<<16) | (((w>>16)&0xFF)<<8) | (((w>>24)&0xFF)<<0);
}


