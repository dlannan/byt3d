--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:28 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

/* fmad llc 2008 */

#include <Common/fCommon.h>
#include <Tools/Lua/fLua.h>

#include <unistd.h>
#include <fcntl.h>

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>
#include <string.h>
#include <sys/unistd.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>

/**************************************************************************************************************/

int common_version(lua_State* L)
    {
        lua_pushnumber(L, 1234);
return 1;
}

/**************************************************************************************************************/

void usleep(int usec);
int lua_usleep(lua_State* L)
{
double t = lua_tonumber(L, -1);
usleep( (u32)t );
luaC_step(L);
return 0;
}

/**************************************************************************************************************/

int lua_time_sec(lua_State* L)
{
struct timeval t;
gettimeofday(&t, NULL);
double sec = ((double)t.tv_sec) + ( (double)t.tv_usec) / 1000000.0;

lua_pushnumber(L, sec);
return 1;
}

/**************************************************************************************************************/

double time_sec(void)
{
struct timeval t;
gettimeofday(&t, NULL);
double sec = ((double)t.tv_sec) + ( (double)t.tv_usec) / 1000000.0;
return sec;
}

/**************************************************************************************************************/
// create full path
const char* fCommon_FullPath(lua_State* L, const char* semi)
{
// lua includes
static char path[128];
lua_getglobal(L, "fBase");
const char* base_dir = lua_tostring(L, -1);
sprintf(path, "%s/%s", base_dir, semi);
return path;
}

/**************************************************************************************************************/

static int gid_serialize(lua_State* L)
{
lua_getfield(L, -1, "id0");
if (lua_isnil(L, -1))
{
etrace("id0 is null!\n");
}
const char*id0 = lua_tostring(L, -1);
lua_pop(L, 1);

lua_getfield(L, -1, "id1");

static const char id_nil[1] = {0};
const char* id1 = id_nil;
if (!lua_isnil(L, -1))
{
id1 = lua_tostring(L, -1);
}
lua_pop(L, 1);

char flat[64];
for (int i=0; i < 32; i++)
{
flat[ 0+i] = id0[i];
flat[32+i] = id1[i];
}
lua_pushlstring(L, flat, 64);
return 1;
}

/**************************************************************************************************************/

static int gid_deserialize(lua_State* L)
{
const char*flat = lua_tostring(L, -1);

char id0[64];
char id1[64];
for (int i=0; i < 32; i++)
{
id0[i] = flat[ 0+i];
id1[i] = flat[32+i];
}
lua_newtable(L);

lua_pushstring(L, "id0");
lua_pushlstring(L, id0, 32);
lua_rawset(L, -3);

lua_pushstring(L, "id1");
lua_pushlstring(L, id1, 32);
lua_rawset(L, -3);

return 1;
}

/**************************************************************************************************************/
// string to use 7bit chars
static int lua_string_to4b(lua_State* L)
{
u32 len = 0;
const char* str = lua_tolstring(L, -1, &len);

char* s = malloc(len*2+1);

// meh 4 bit encode
for (int i=0; i < len; i++)
{
s[i*2+0] = (str[i]&0xF) + '0';
s[i*2+1] = ((str[i]>>4)&0xF) + '0';
}
s[len<<1] = 0;

lua_pushstring(L, s);
return 1;
}

static int lua_string_from4b(lua_State* L)
{
u32 len = 0;
const char* str = lua_tolstring(L, -1, &len);
char* s = malloc(len);

// meh 4 bit encode
for (int i=0; i < (len>>1); i++)
{
u32 lo = (str[i*2+0]-'0');
u32 hi = (str[i*2+1]-'0');
s[i] = (hi<<4) | (lo);
}
s[len>>1] = 0;

lua_pushstring(L, s);
return 1;
}
/**************************************************************************************************************/

static int string_unpack(lua_State* L)
{
int len = 0;
const char*str = lua_tolstring(L, -3, &len);

s32 start = lua_tonumber(L, -2);
s32 end = lua_tonumber(L, -1);

start--;
start = (start < 0) ? 0 : start;

if (end == -1) end = len;
if (end < start) end = start;

fAssert(start < 256);
fAssert(end < 256);

char newstr[256];
for (int i=0; i <= end-start; i++)
{
newstr[i] = str[start+i];
}
lua_pushlstring(L, newstr, end-start);
return 1;
}

/**************************************************************************************************************/
// non blocking input check. returns nil if nothing is ready
static int lua_kbhit(lua_State* L)
{
struct timeval tv;
fd_set fds;
tv.tv_sec = 0;
tv.tv_usec = 0;
FD_ZERO(&fds);
FD_SET(0, &fds); //STDIN_FILENO is 0
select(0+1, &fds, NULL, NULL, &tv);
if (FD_ISSET(STDIN_FILENO, &fds))
{
char buf[256];
int i = 0;
while (true)
{
buf[i] = getc(stdin);
if (buf[i] == '\n') { buf[i] = 0; break; }
i++;
}
lua_pushstring(L, buf);
return 1;
}
else
{
lua_pushnil(L);
return 1;
}
}

/**************************************************************************************************************/
void fMkdir(const char* Path)
{
char Buffer[128];
sprintf(Buffer, "mkdir -p %s", Path);
//printf("System [%s]\n", Buffer);
system(Buffer);
}

/**************************************************************************************************************/
// deep copy between lvms
void fCommon_Deepcopy(lua_State* D, lua_State* S)
{
lua_pushnil(S);
while (lua_next(S, -1) != 0)
{
/* uses 'key' (at index -2) and 'value' (at index -1) */
printf("%s - %s\n",
lua_typename(S, lua_type(S, -2)),
lua_typename(S, lua_type(S, -1)));
/* removes 'value'; keeps 'key' for next iteration */
lua_pop(S, 1);
}
}

/**************************************************************************************************************/
// loads in bytecode or loads from file (preference given to file over bytecode)
void luainc_load(lua_State* L, u32 count, LuaInclude_t* Inc, bool StackPop)
{
// lua includes
for (int i=0; i < count; i++)
{
FILE* File = fopen(fCommon_FullPath(L, Inc->FileName), "rb");

if (File == NULL)
{
u32 CodeSize = Inc->ByteCodeEnd - Inc->ByteCodeStart;
//ftrace("%s ... internal (%iKB)\n", Inc->FileName, CodeSize/1024);

// use builtin verion

luaL_loadbuffer(L, Inc->ByteCodeStart, CodeSize, Inc->FileName);
lua_pcall(L, 0, LUA_MULTRET, 0);
}
else
{
fclose(File);
//ftrace("%s ... source\n", Inc->FileName);
luaL_dofile(L, fCommon_FullPath(L, Inc->FileName));
}

// lua includes
while (StackPop && !lua_isnil(L, -1))
{
const char *msg = lua_tostring(L, -1);
ftrace("Error [%s] %s\n", Inc->FileName, msg);
/*
lua_Debug d;
lua_getstack(L, -1, &d);
lua_getinfo(L, ">S", &d);

ftrace("info done\n");
ftrace("line: %i\n", d.linedefined);
*/
lua_pop(L, 1);

}
Inc++;
}
}

/**************************************************************************************************************/
// persist light user objects
void* fCommon_Persist(lua_State* L, void* Data, u32* len)
{
u32* Header = (u32 *)Data;
switch (Header[0])
{
case MAGIC_PACKED_ARRAY:	return fPackedArray_Persist(L, Data, len);
}
return NULL;
}

/**************************************************************************************************************/
// unpersist light user objects
void fCommon_Unpersist(lua_State* L, void* Data, u32 len)
{
u32* Header = (u32 *)Data;
switch (Header[0])
{
case MAGIC_PACKED_ARRAY:	fPackedArray_Unpersist(L, Data, len);
}
}

u32 fCommon_CRC32(void* Data, u32 Len)
{
u32 CRC = 0;
u32* d = Data;
while (Len >= 4)
{
CRC += *d++;
Len -= 4;
}

char* c = (char *)d;
while (Len > 0)
{
CRC += *c++;
Len--;
}
return CRC;
}

/**************************************************************************************************************/
static int lCommon_CRC32(lua_State* L)
{
u32 len = 0;
const char* buf = lua_tolstring(L, -1, &len);


for (int i=0; i < 16; i++) ftrace("%02x\n", buf[i]);

u32 CRC = fCommon_CRC32(buf, len);

ftrace("crc: %08x %08x %i\n", CRC, buf, len);

lua_pushnumber(L, fCommon_CRC32(buf, len));
return 1;
}

/**************************************************************************************************************/
// directory iterator

static int fCommon_dir_iterator(lua_State* L)
{
DIR* d = *((DIR **)lua_touserdata(L, lua_upvalueindex(1)));
struct dirent* entry = NULL;
while (1)
{
entry = readdir(d);
if (entry == NULL) break;

if (strcmp(entry->d_name, ".") == 0) continue;
if (strcmp(entry->d_name, "..") == 0) continue;

// its good
lua_pushstring(L, entry->d_name);
return 1;
}
return 0;
}

static int fCommon_dir(lua_State* L)
{
const char* Path = lua_tostring(L, -1);

DIR** d = (DIR **)lua_newuserdata(L, sizeof(DIR *));

luaL_getmetatable(L, "LuaBook.dir");
lua_setmetatable(L, -2);

*d = opendir(Path);
if (*d == NULL)
{
luaL_error(L, "cannot open %s : %s\n", Path, strerror(errno));
}

lua_pushcclosure(L, fCommon_dir_iterator, 1);
return 1;
}

static int fCommon_dir_gc(lua_State* L)
{
DIR* d = *(DIR **)lua_touserdata(L, 1);
if (d) closedir(d);
return 0;
}

static void fCommon_dir_metatable(lua_State* L)
{
luaL_newmetatable(L, "LuaBook.dir");

lua_pushstring(L, "__gc");
lua_pushcfunction(L, fCommon_dir_gc);
lua_settable(L, -3);

lua_pop(L, 1);	// metatable
}

/**************************************************************************************************************/
void* fAssertPointerFL(const void* p, const char* msg, const char* file, const int line)
{
if (p != NULL) return (void *)p;

etrace("Assert pointer fail %s %i : %s\n", file, line, msg);
exit(-1);
}

/**************************************************************************************************************/

static int lCommon_Collect(lua_State* L)
{
luaC_fullgc(L);
return 0;
}


/**************************************************************************************************************/
// generate seg fault
int lCommon_SegFault(lua_State* L)
{
u32 * blah = (u32 *)NULL;
blah[0] = 0;
return 0;
}
/**************************************************************************************************************/

void luaopen_common(lua_State* L)
{
fCommon_dir_metatable(L);

// shutdown stack
lua_newtable(L);
lua_setglobal(L, "m_shutdown");
luaopen_trace(L);

luaopen_crypt(L);
luaopen_profile(L);

lua_pushcfunction(L, common_version);
lua_setglobal(L, "CommonVersion");

lua_pushcfunction(L, lua_usleep);
lua_setglobal(L, "usleep");

lua_pushcfunction(L, lua_time_sec);
lua_setglobal(L, "time_sec");

lua_register(L, "gid_serialize", gid_serialize);
lua_register(L, "gid_deserialize", gid_deserialize);
lua_register(L, "string_unpack", string_unpack);
lua_register(L, "kbhit", lua_kbhit);
lua_register(L, "to4b", lua_string_to4b);
lua_register(L, "fr4b", lua_string_from4b);
lua_register(L, "GenCRC32", lCommon_CRC32);

lua_register(L, "dir", fCommon_dir);
lua_register(L, "collect", lCommon_Collect);
lua_register(L, "SegFault", lCommon_SegFault);

fPackedArray_Register(L);
fPTable_Register(L);
}
