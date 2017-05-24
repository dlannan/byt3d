--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:32 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

#include <fTypes.h>
#include <fMemory.h>
#include <fTrace.h>
#include <fPTable.h>
#include <fAssert.h>

#define __USE_BSD 1
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <Tools/db/build_unix/db.h>

/**************************************************************************************************************/
#define DB_MAGIC	0xb33fcac3
typedef struct fPTable_t
    {
        u32	Magic;
DB*	db;

} fPTable_t;

/**************************************************************************************************************/

static DB_ENV*	s_envp = NULL;
static int count = 0;

/**************************************************************************************************************/
static inline fPTable_t* toDB(lua_State* L, int index)
    {
        fPTable_t* T = fAssertP(lua_touserdata(L, index), "invalid DB index");
fAssert(T->Magic == DB_MAGIC);
return T;
}

/**************************************************************************************************************/

static int lPTable_Open(lua_State* L)
{
const char* DBName = fAssertP(lua_tostring(L, -1), "db name invalid");

fPTable_t* T = fMalloc(sizeof(fPTable_t));
T->Magic = DB_MAGIC;

// create structure
fAssert(s_envp != NULL);
int ret = db_create(&T->db, s_envp, 0);
if (ret != 0)
{
ftrace("PTableOpen failed: %s\n", db_strerror(ret));
return 0;
}
DB* db = T->db;

// errors

db->set_errfile(db, stderr);
db->set_errpfx(db, DBName);


// create it
ret = db->open(db, NULL, DBName, NULL, DB_BTREE, DB_CREATE | DB_AUTO_COMMIT | DB_THREAD, 0);
if (ret != 0)
{
ftrace("PTableOpen open failed: %s\n", db_strerror(ret));
return 0;
}

lua_pushlightuserdata(L, T);

return 1;
}

/**************************************************************************************************************/
static int lPTable_Close(lua_State* L)
{
fPTable_t* T = toDB(L, -1);

T->db->close(T->db, 0);
T->db = NULL;

fFree(T);

return 0;
}

/**************************************************************************************************************/
static int lPTable_Get(lua_State* L)
{
fPTable_t* T = toDB(L, -2);

DBT Key;
memset(&Key, 0, sizeof(Key));
Key.data = (void *)lua_tolstring(L, -1, &Key.size);

DBT Data;
memset(&Data, 0, sizeof(Data));
Data.flags = DB_DBT_MALLOC;

fAssert(s_envp != NULL);
int ret = T->db->get(T->db, NULL, &Key, &Data, 0);

// key doesnt exist
if (ret == DB_NOTFOUND)
{
//dtrace("no key: %s\n", Key.data);
return 0;
}
// some other error
if (ret != 0)
{
ftrace("PTableOpen get: %s\n", db_strerror(ret));
return 0;
}
//dtrace("get key [%s] = %s\n", Key.data, Data.data);

lua_pushlstring(L, Data.data, Data.size);
return 1;
}

/**************************************************************************************************************/
static int lPTable_Put(lua_State* L)
{
fPTable_t* T = toDB(L, -3);

DBT Key;
memset(&Key, 0, sizeof(Key));
Key.data = (void *)lua_tolstring(L, -2, &Key.size);

DBT Data;
memset(&Data, 0, sizeof(Data));
Data.data = (void *)lua_tolstring(L, -1, &Data.size);

dtrace("put [%s] = %s (%i)\n", Key.data, Data.data, Data.size);

fAssert(s_envp != NULL);
int ret = T->db->put(T->db, NULL, &Key, &Data, 0);
if (ret != 0)
{
ftrace("PTablePut failed: %s %i\n", db_strerror(ret), ret);
return 0;
}
T->db->sync(T->db, 0);

return 0;
}

/**************************************************************************************************************/
static int lPTable_KeyList(lua_State* L)
{
fPTable_t* T = toDB(L, -1);

// get cursor
DBC* Cursor = NULL;
int ret = T->db->cursor(T->db, NULL, &Cursor, 0);
if (ret != 0)
{
ftrace("failed to create curosr\n");
return 0;
}

lua_newtable(L);

DBT Key;
DBT Data;
memset(&Key, 0, sizeof(Key));
memset(&Data, 0, sizeof(Data));

char KeyData[1024];
while (true)
{
int ret = Cursor->get(Cursor, &Key, &Data, DB_NEXT);
if (ret != 0)
{
break;
}

memcpy(KeyData, Key.data, Key.size);
KeyData[Key.size] = 0;

lua_pushstring(L, KeyData);
lua_rawseti(L, -2, lua_objlen(L, -2) + 1);
//ftrace("key [%s]\n", Key.data);
}

Cursor->close(Cursor);
return 1;
}

/**************************************************************************************************************/
int fPTable_Register(lua_State* L)
{
lua_register(L, "_ptable_open",		lPTable_Open);
lua_register(L, "_ptable_close",	lPTable_Close);
lua_register(L, "_ptable_get",		lPTable_Get);
lua_register(L, "_ptable_put",		lPTable_Put);
lua_register(L, "_ptable_key_list",	lPTable_KeyList);


// create enviroment (only 1 per process)
{
int ret = db_env_create(&s_envp, 0);
if (ret != 0)
{
ftrace("PTableOpen faield to create enviornment: %s\n", db_strerror(ret));
return 0;
}

//s_envp->set_lk_detect(s_envp, DB_LOCK_MINWRITE);
u32 env_flags =
DB_CREATE     |  // Create the environment if it does not exist
DB_INIT_LOCK  |  // Initialize the locking subsystem
DB_INIT_LOG   |  // Initialize the logging subsystem
DB_INIT_TXN   |  // Initialize the transactional subsystem. This also turns on logging.
DB_INIT_MPOOL |  // Initialize the memory pool (in-memory cache)
DB_THREAD          // Cause the environment to be free-threaded

// recovery will fuck this for unknown reasons... settle for resting LSN anytime
// the enviroment changes
//DB_RECOVER    |  // Run normal recovery.
//DB_SYSTEM_MEM |
//DB_REGISTER		// allow recovery
;

//s_envp->set_shm_key(s_envp, 0xbeef);


ret = s_envp->open(s_envp, "/mnt/develop/fmad/db", env_flags, 0);
if (ret != 0)
{
ftrace("PTableOpen faield open enviornment: %08x %s\n", ret, db_strerror(ret));
fAssert(false);
return 0;
}
}

return 0;
}
