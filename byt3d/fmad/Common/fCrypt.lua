--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:27 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

#define lua_c
#include <Tools/Lua/lua.h>
#include <Tools/Lua/lauxlib.h>
#include <Tools/Lua/lualib.h>

#include <fTypes.h>
#include <fTrace.h>
#include "fMemory.h"
#include "fCrypt.h"
#include "fProfile.h"


#include <openssl/engine.h>
#include <openssl/sha.h>
#include <openssl/hmac.h>


/**************************************************************************************************************/
// sha256 = sha_create(string)
static int sha_create(lua_State* L)
    {
        static u32 counter = 0;

// check parameter is a string
if (!lua_isstring(L, 1))
    {
        ftrace("argument is not a string!\n");
return 0;
}

u32 length = 0;
const char* str = lua_tolstring(L, 1, &length);

//ftrace("create sha %i\n", length);
SHA256_CTX* sha= (SHA256_CTX* )lua_newuserdata(L, sizeof(SHA256_CTX));

SHA256_Init(sha);
SHA256_Update(sha, str, length);

u8 hash[32];
SHA256_Final(hash, sha);
/*
for (int i=0; i < 32; i++)
{
printf("%02x ", hash[i]);
}
printf("\n");
*/

lua_pushlstring(L, hash, sizeof(hash));
return 1;
}

/**************************************************************************************************************/
// sha256 the contents of a file
static int sha_file(lua_State* L)
{
const char* Filename = lua_tostring(L, -1);
fAssert(Filename);

FILE* File = fopen(Filename, "rb");
if (!File)
{
ftrace("sha_file: filename [%s] dosent exist\n", Filename);
lua_pushnil(L);
return 1;
}

//ftrace("create sha %i\n", length);
SHA256_CTX* sha= (SHA256_CTX* )lua_newuserdata(L, sizeof(SHA256_CTX));
SHA256_Init(sha);

char buffer[256];
while (!feof(File))
{
fread(buffer, sizeof(buffer), 1, File);
SHA256_Update(sha, buffer, sizeof(buffer));
}

u32 hash[32/4];
SHA256_Final((u8*)hash, sha);

// convert to readable/printable version
u8 hash_str[64];
sprintf(hash_str, "%08x%08x%08x%08x%08x%08x%08x%08x",
hash[0],
hash[1],
hash[2],
hash[3],
hash[4],
hash[5],
hash[6],
hash[7]);

printf("%s\n", hash_str);
/*
for (int i=0; i < 32; i++)
{
printf("%02x ", hash[i]);
}
printf("\n");
*/
lua_pushstring(L, hash_str);
return 1;
}

/**************************************************************************************************************/
void fCrypt_SHA256Print(char*str, const u32 * hash)
{
sprintf(str, "%08x%08x%08x%08x%08x%08x%08x%08x",
hash[0],
hash[1],
hash[2],
hash[3],
hash[4],
hash[5],
hash[6],
hash[7]);
}

/**************************************************************************************************************/

static int sha_format(lua_State* L)
{
u8 str[32*2];
if (lua_isnil(L, 1))
{
for (int i=0; i < 32*2; i++) str[i] = 0;
}
else
{
// check parameter is a string
if (!lua_isstring(L, 1))
{
ftrace("argument is not a string!\n");
return 0;
}

u32 length = 0;
const u32* hash = (const u32*)lua_tolstring(L, 1, &length);
fCrypt_SHA256Print(str, hash);
}

lua_pushlstring(L, str, sizeof(str));

return 1;
}

/**************************************************************************************************************/

static int sha_unformat(lua_State* L)
{
const char* str = lua_tostring(L, -1);
if (!str)
{
ftrace("sha_unformat is not a string!\n");
return 0;
}

u32 hash[8];
sscanf(str, "%08x%08x%08x%08x%08x%08x%08x%08x",
&hash[0],
&hash[1],
&hash[2],
&hash[3],
&hash[4],
&hash[5],
&hash[6],
&hash[7]);

lua_pushlstring(L, (char*)hash, 32);

return 1;
}
/**************************************************************************************************************/

bool fCrypt_SHA256(u32* Hash, void* buffer, const u32 len)
{
fAssert(len > 0);

SHA256_CTX sha;
SHA256_Init(&sha);
SHA256_Update(&sha, buffer, len);
SHA256_Final((u8*)Hash, &sha);
return true;
}

/**************************************************************************************************************/

void luaopen_crypt(lua_State* L)
{
ENGINE_load_builtin_engines();
ENGINE_register_all_complete();


HMAC_CTX ctx;

HMAC_CTX_init(&ctx);
HMAC_CTX_cleanup(&ctx);


lua_register(L, "sha_create",	sha_create);
lua_register(L, "sha_format",	sha_format);
lua_register(L, "sha_unformat",	sha_unformat);
lua_register(L, "sha_file", 	sha_file);

ftrace("lua crypt...\n");
}

/**************************************************************************************************************/
