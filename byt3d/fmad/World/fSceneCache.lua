--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:47 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

//********************************************************************************************************************
//
// fmad llc 2008
//
// scene cache
//
//********************************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <Common/fCommon.h>
#include <Network/fNetwork.h>
#include <Module/Render/fRealize.h>

#include "fSceneObject.h"
#include "fSceneCache.h"

#define RENDERNODE_MAGIC		0x13370009
#define COLLECT_CRC			0xc00113c7

//********************************************************************************************************************

#define NetIDMax 32
typedef struct fSceneCacheObject_t
    {
        u32				MessageID;
u32				SceneID;
u32				NodeID;
u32				ObjectID;
u32				CRC32[NetIDMax];

bool				Collect;

u32				StreamPos[128];

u32				PartTotal;
u32*				PartCRC32;

struct fSceneCacheObject_t*	Next;
struct fSceneCacheObject_t*	Prev;

struct fSceneCacheObject_t*	WayPrev;
struct fSceneCacheObject_t*	WayNext;

} fSceneCacheObject_t;

typedef struct fSceneCache_t
    {
        struct fMultiCastNode_t*	Net;
struct fSceneCacheObject_t*	NetObjectHead;
struct fSceneCacheObject_t*	NetObjectTail;

double				LastUpdate;

u32				NetEnable[NetIDMax];
u32				NetRefCount[NetIDMax];

s32				StreamBW;
u32				SendCount;

u32				StatInDgrams;
u32				StatOutDgrams;

u32				StatInErrors;
u32				StatOutErrors;

u32				StatRecvErrors;
u32				StatSendErrors;

u32				DropHistoryPos;
u32				DropHistory[32];

u32				PacketSent;

double				StartTime;
u32 				Magic;

fSceneCacheObject_t*		ObjectSet[4096];

} fSceneCache_t;

//********************************************************************************************************************
static inline u32 SetHash(const u32 NodeID, const u32 ObjectID)
    {
        u32 SetID = (ObjectID ^ NodeID) & 0xfff;
return SetID;
}

//********************************************************************************************************************

static fSceneCacheObject_t* fSceneCache_NodeObject(fSceneCache_t* Cache, u32 SceneID, u32 NodeID, u32 ObjectID)
{
u32 SetID = SetHash(NodeID, ObjectID);

// first object in way

fSceneCacheObject_t*	Way 	= Cache->ObjectSet[SetID];

fSceneCacheObject_t* N = Way;
fSceneCacheObject_t* L = Way;
while (N)
{
if ((N->NodeID == NodeID) && (N->ObjectID == ObjectID))
{
return N;
}
L = N;
N = N->WayNext;
}

// create a node
if (N == NULL)
{
N = fMalloc(sizeof(fSceneCacheObject_t));
memset(N, 0, sizeof(fSceneCacheObject_t));

fAssert(NodeID < 0x10000000);
fAssert(ObjectID < 0x10000000);

N->NodeID	= NodeID;
N->ObjectID	= ObjectID;
N->Collect	= false;
N->MessageID	= 0;
N->SceneID	= SceneID;

// add to set list
if (Way != NULL)
{
N->WayPrev = L;
L->WayNext = N;
}
else
{
// first in set
Cache->ObjectSet[SetID] = N;
}

// add to linked list
if (Cache->NetObjectHead == NULL)
{
Cache->NetObjectHead = N;
Cache->NetObjectTail = N;

N->Next = NULL;
N->Prev = NULL;
}
else
{
N->Prev		= Cache->NetObjectTail;
N->Next		= NULL;

if (Cache->NetObjectTail) Cache->NetObjectTail->Next = N;

Cache->NetObjectTail = N;
}
}
return N;
}

//********************************************************************************************************************

static void fSceneCache_NodeDestroy(fSceneCache_t* Cache, fSceneCacheObject_t* NO)
{
// remove from list

if (Cache->NetObjectHead == NO) Cache->NetObjectHead = NO->Next;
if (Cache->NetObjectTail == NO) Cache->NetObjectTail = NO->Prev;

if (NO->Prev) NO->Prev->Next = NO->Next;
if (NO->Next) NO->Next->Prev = NO->Prev;

// remove from way
if (Cache->ObjectSet[SetHash(NO->NodeID, NO->ObjectID)] == NO)
{
Cache->ObjectSet[SetHash(NO->NodeID, NO->ObjectID)] = NO->WayNext;
}
if (NO->WayPrev) NO->WayPrev->WayNext = NO->WayNext;
if (NO->WayNext) NO->WayNext->WayPrev = NO->WayPrev;

// release lists
if (NO->PartCRC32)
{
fFree(NO->PartCRC32);
NO->PartCRC32 = NULL;
}

// free
memset(NO, 0, sizeof(fSceneCacheObject_t));
fFree(NO);
}

//********************************************************************************************************************

static void fSceneCache_ResetCRC(fSceneCache_t* Cache, u32 NetID)
{
fSceneCacheObject_t* N = Cache->NetObjectHead;
fSceneCacheObject_t* L = Cache->NetObjectHead;
while (N)
{
// reset entire object

N->CRC32[NetID] = 0;

// reset each part

for (int i=0; i < N->PartTotal; i++)
{
N->PartCRC32[i*NetIDMax+NetID] = 0;
}
N = N->Next;
}
return N;
}

//********************************************************************************************************************
static void fSceneCache_ObjectAck(struct fMultiCastNode_t* N, u32 ObjectID, void* Data, u32 Size, void* User)
{
fSceneCache_t* Cache 		= User;
struct fRealizeObjectAct_t* RA	= Data;

fSceneCacheObject_t* NO = fSceneCache_NodeObject(Cache, 0, RA->NodeID, RA->ObjectID);

fAssert(RA->PartPos < 0x1000000);
fAssert(RA->PartTotal < 0x1000000);

// update CRC

NO->CRC32[RA->NetID] = RA->CRC32;

// part list ?
if ((NO->PartCRC32 == NULL) && (RA->PartTotal > 0))
{
NO->PartCRC32 = fMalloc(RA->PartTotal*NetIDMax*sizeof(u32));
memset(NO->PartCRC32, 0, RA->PartTotal*NetIDMax*sizeof(u32));

NO->PartTotal = RA->PartTotal;
//printf("new object ack part: %08x\n", RA->PartTotal);
}

// set part crc
if (RA->PartTotal > 0)
{
NO->PartCRC32[RA->PartPos*NetIDMax + RA->NetID] = RA->CRC32;
}
//ftrace("ACK ID:%08x Scene:%i Node:%08x Obj:%08x objects CRC:%08x\n", RA->NetID, NO->SceneID, RA->NodeID, RA->ObjectID, RA->CRC32);
}

//********************************************************************************************************************
// destroy an object
void fSceneCache_ObjectDel(struct fSceneCache_t* C, struct fSceneObject_t* O)
{
fSceneCacheObject_t* N = C->NetObjectHead;
while (N)
{
if (N->ObjectID == O->ID)
{
break;
}
N = N->Next;
}

if (N == NULL)
{
//ftrace("SceneCache: failed to collect objectID:%08x\n", O->ID);
return;
}

// set to collect

N->Collect = true;
}

//********************************************************************************************************************
// destroy a node
void fSceneCache_NodeDel(struct fSceneCache_t* C, u32 NodeID)
{
fSceneCacheObject_t* N = C->NetObjectHead;
while (N)
{
if (N->NodeID == NodeID)
{
ftrace("collect node object %08x:%08x\n", N->NodeID, N->ObjectID);
N->Collect = true;
}
N = N->Next;
}
}

//********************************************************************************************************************

struct fSceneCache_t* toSceneCacheEx(lua_State* L, int Index, const char* File, const u32 Line)
{
fSceneCache_t* RN = lua_touserdata(L, Index);
fAssertFL(RN, File, Line);
fAssertFL(RN->Magic == RENDERNODE_MAGIC, File, Line);

return RN;
}

//********************************************************************************************************************
static int lSceneCache_Create(lua_State *L)
{
fSceneCache_t* RN	= (fSceneCache_t* )fMalloc(sizeof(fSceneCache_t));
memset(RN, 0, sizeof(fSceneCache_t));

RN->Net		= toMultiCast(L, -1);
RN->StreamBW	= 1024*1024;
RN->Magic 	= RENDERNODE_MAGIC;

// object crc32 ack

fMultiCast_PacketHandler(RN->Net, fRealizeMultiCast_ObjectAck, fSceneCache_ObjectAck, RN);

// set

RN->StartTime	= time_sec();

lua_pushlightuserdata(L, RN);
return 1;
}

//********************************************************************************************************************
static int lSceneCache_Destroy(lua_State* L)
{
fSceneCache_t* RN = toSceneCache(L, -1);

fFree(RN);
return 0;
}
//********************************************************************************************************************
// returns if the CRC matches all active nodes
static bool fSceneCache_IsDirty(fSceneCache_t* RN, fSceneCacheObject_t* NO, u32 CRC32_Check)
{
// all CRC32s are the same
bool Same = true;
bool Zero = true;
for (int i=0; i < NetIDMax; i++)
{
u32 CRC = NO->CRC32[i];
Same &= RN->NetEnable[i] ? (CRC == CRC32_Check) : true;
}

// cache is up to date
return (!Same);
}

//********************************************************************************************************************
// returns if part is dirty
bool fSceneCache_IsDirtyPart(struct fSceneCache_t* RN, u32 NodeID, u32 ObjectID, u32 PartPos, u32 CRC32_Check)
{
// find node object
fSceneCacheObject_t* NO = fSceneCache_NodeObject(RN, 0, NodeID, ObjectID);
if (NO->PartCRC32 == NULL)
{
return true;
}
if (PartPos >= NO->PartTotal)
{
return true;
}

// all CRC32s are the same
bool Same = true;
for (int i=0; i < NetIDMax; i++)
{
u32 CRC = NO->PartCRC32[PartPos*NetIDMax + i];
Same &= RN->NetEnable[i] ? (CRC == CRC32_Check) : true;
}

// cache is up to date
return (!Same);
}

//********************************************************************************************************************
// multicast string -> multicast id
static int lSceneCache_MultiCastID(lua_State* L)
{
lua_newtable(L);
lua_setfield_number(L, -1, "Scene",		fRealizeMultiCast_Scene);
lua_setfield_number(L, -1, "Camera",		fRealizeMultiCast_Camera);
lua_setfield_number(L, -1, "TriMesh",		fRealizeMultiCast_TriMesh);
lua_setfield_number(L, -1, "LightDir",		fRealizeMultiCast_LightDir);
lua_setfield_number(L, -1, "Material",		fRealizeMultiCast_Material);
lua_setfield_number(L, -1, "Texture",		fRealizeMultiCast_Texture);
lua_setfield_number(L, -1, "SplineCatmull",	fRealizeMultiCast_Line);
lua_setfield_number(L, -1, "HeightMap",		fRealizeMultiCast_HeightMap);
lua_setfield_number(L, -1, "Icon",		fRealizeMultiCast_Icon);

return 1;
}

//********************************************************************************************************************
// enables a specific net id
static int lSceneCache_EnableID(lua_State* L)
{
fSceneCache_t* RN 	= toSceneCache(L, -2);
u32 NetID 		= lua_tonumber(L, -1);

fAssert(NetID < NetIDMax);

// enable NetID

RN->NetEnable[NetID] = 0xffffffff;
//ftrace("ID:%i ref count %i\n", NetID, RN->NetRefCount[NetID]);

// first enable for the render node ?
//if (RN->NetRefCount[NetID] == 0)
{
// reset current crcs(done on both enable/disable to be safe)

fSceneCache_ResetCRC(RN, NetID);
}

// new scene on the specified render node, so up the ref count

RN->NetRefCount[NetID]++;

return 0;
}

//********************************************************************************************************************
// used to throttle update packets based on previous frames send size
u32 fSceneCache_StreamBW(struct fSceneCache_t* RN)
{
// fixed for now
return RN->StreamBW;
}

static u32 fSceneCache_StreamBW_Add(struct fSceneCache_t* RN, int Delta)
{
RN->StreamBW += Delta;

RN->StreamBW = (RN->StreamBW < 1024) ? 1024 : RN->StreamBW;
RN->StreamBW = (RN->StreamBW > 1024*1024) ? 1024*1024 : RN->StreamBW;
}

//********************************************************************************************************************
// disable a specific net id
static int lSceneCache_DisableID(lua_State* L)
{
fSceneCache_t* RN 	= toSceneCache(L, -2);
u32 NetID 		= lua_tonumber(L, -1);

fAssert(NetID < NetIDMax);
//ftrace("ID:%i disable stream id %I\n", NetID, RN->NetRefCount[NetID]);

// remove ref count
RN->NetRefCount[NetID]--;
if (RN->NetRefCount[NetID] == 0)
{
// disable update check

RN->NetEnable[NetID] = 0x0;

// reset CRC for every object

fSceneCache_ResetCRC(RN, NetID);
}
return 0;
}

//********************************************************************************************************************
// resets crcr for a net id / scene id combo
static int lSceneCache_ResetSceneID(lua_State* L)
{
fSceneCache_t* Cache 	= toSceneCache(L, -3);
u32 NetID 		= lua_tonumber(L, -2);
u32 SceneID 		= lua_tonumber(L, -1);

fAssert(NetID < NetIDMax);
//ftrace("NetID:%i SceneID:%i reset crc\n", NetID, SceneID);

for (fSceneCacheObject_t* N = Cache->NetObjectHead; N != NULL; N = N->Next)
{
//ftrace("scene id:%i:%i node:%08x obj:%08x\n", N->SceneID, SceneID, N->NodeID, N->ObjectID);

// dosent belong the scene id
if (N->SceneID != SceneID) continue;

// top level reset

N->CRC32[NetID] = 0;

// part reset

for (int i=0; i < N->PartTotal; i++)
{
N->PartCRC32[i*NetIDMax+NetID] = 0;
}
}
return 0;
}

//********************************************************************************************************************
// resets scene crs
static int lSceneCache_ResetCRC(lua_State* L)
{
fSceneCache_t* RN 	= toSceneCache(L, -2);
u32 NetID 		= lua_tonumber(L, -1);
fSceneCache_ResetCRC(RN, NetID);

return 0;
}

//********************************************************************************************************************
// throttle bandwidth
static void fSceneCache_Throttle(fSceneCache_t* Cache)
{
u32 IssueTotal = 0;
u32 IssueFail = 0;
u32 IssuePass = 0;

FILE* F = fopen("/proc/net/snmp", "r");
if (F)
{
char buffer[3][4096];
int b = 0;

while (!feof(F))
{
u32 pos = 0;

char c0 = fgetc(F);
char c1 = fgetc(F);
char c2 = fgetc(F);
char c3 = fgetc(F);

bool hit = true;
hit &= c0 == 'U';
hit &= c1 == 'd';
hit &= c2 == 'p';
hit &= c3 == ':';

while (true)
{
buffer[b][pos] = fgetc(F);
if (buffer[b][pos] == '\n')
{
break;
}
fAssert(pos < sizeof(buffer));
pos += hit;

if (feof(F)) break;
}
buffer[b][pos] = 0;
b += hit;
}
fclose(F);

u32 InDgrams = 0;
u32 NoPorts = 0;
u32 InErrors = 0;
u32 OutDgrams = 0;
u32 RecvErrors = 0;
u32 SendErrors = 0;

sscanf(buffer[1], "%i %i %i %i %i %i", &InDgrams, &NoPorts, &InErrors, &OutDgrams, &RecvErrors, &SendErrors);

IssueTotal = (InDgrams - Cache->StatInDgrams);
IssueFail = (InErrors - Cache->StatInErrors);
IssuePass = IssueTotal;

Cache->StatInDgrams = InDgrams;
Cache->StatInErrors = InErrors;

Cache->StatRecvErrors = RecvErrors;
Cache->StatSendErrors = SendErrors;
/*
static count = 0;
if ((IssueTotal > 0) && (count++ == 16))
{
count = 0;
printf("%-5i %-5i %-5i : BW:%-5iKB sent:%-5i\n", IssueTotal, IssuePass, IssueFail, Cache->StreamBW/1024, Cache->SendCount);
}
*/
/*
printf("%s\n", buffer[0]);
printf("%s\n", buffer[1]);
printf("%0i\n", RecvErrors);
*/
if (IssueFail > 0)
{
// backed up so throttle send amount
Cache->StreamBW = Cache->StreamBW/2;
}

Cache->DropHistory[Cache->DropHistoryPos] = IssueFail;
Cache->DropHistoryPos = (Cache->DropHistoryPos+1)&0x1f;

// last 32 frames there were no dropped packets
u32 TotalDropped = 0;
for (u32 i=0; i < 32; i++) TotalDropped += Cache->DropHistory[i];

if (TotalDropped == 0)
{
// add le room
Cache->StreamBW = Cache->StreamBW*2;
}
}

//printf("%i %i\n", Cache->IssueFail, Cache->IssuePass);

Cache->StreamBW = (Cache->StreamBW < 128*1024) ? 128*1024 : Cache->StreamBW;
Cache->StreamBW = (Cache->StreamBW > 8*1024*1024) ? 8*1024*1024 : Cache->StreamBW;

// reset
Cache->SendCount	= 0;
}

//********************************************************************************************************************
// re-send any collected objects
static void fSceneCache_Collect(fSceneCache_t* Cache)
{
int count = 0;

fSceneCacheObject_t* NO = Cache->NetObjectHead;
while (NO)
{
fSceneCacheObject_t* Next = NO->Next;
if (NO->Collect)
{
// all CRC32s are the same e.g. its been collected
bool Same = true;
for (int i=0; i < NetIDMax; i++)
{
Same &= Cache->NetEnable[i] ? (NO->CRC32[i] == COLLECT_CRC) : true;
}

// all nodes ack it, so delete the object
// or it was never sent (messageid == 0)
if (Same || (NO->MessageID == 0))
{
ftrace("collect node! %08x\n", NO->ObjectID);
fSceneCache_NodeDestroy(Cache, NO);
}
else
{
// issue collect

fRealizeCollect_t	C;
C.Header.CmdID 		= fRealizeCmdID_Collect;
C.Header.SceneID 	= NO->SceneID;
C.Header.NodeID 	= NO->NodeID;
C.Header.ObjectID 	= NO->ObjectID;
C.Header.CRC32	 	= COLLECT_CRC;
C.Header.PartPos 	= 0;
C.Header.PartTotal 	= 0;

fMultiCast_Send(Cache->Net, NO->MessageID, &C, sizeof(C));
Cache->SendCount++;
//ftrace("issue collect %08x\n", NO->ObjectID);
}
}
NO = Next;
}
}

//********************************************************************************************************************
// adjusts stream bandwidth
static int lSceneCache_Update(lua_State* L)
{
fSceneCache_t* Cache = toSceneCache(L, -1);

// send resets for 1 seccond
if ((time_sec() - Cache->StartTime) < 1)
{
fRealizeHeader_t H;
H.CmdID 	= fRealizeCmdID_Reset;
H.ObjectID	= 0;
H.NodeID	= 0;
H.PartTotal	= 0;
H.PartPos	= 0;
H.CRC32		= 0;
fMultiCast_Send(Cache->Net, fRealizeMultiCast_Scene, &H, sizeof(H));
}

// update stats every 33ms

double t = time_sec();
if ((t - Cache->LastUpdate) < 1.0/30.0) return 0;
Cache->LastUpdate = t;

// update throttling

fSceneCache_Throttle(Cache);

// update collected objects

fSceneCache_Collect(Cache);
}

//********************************************************************************************************************
// create a table with all streamed packets
int fSceneCache_Table(lua_State* L, struct fSceneCache_t* Cache, u32 NodeID, u32 ObjectID, u32 TopCRC32, u32 Streams, u32* StreamLength, u32* StreamSize, void** Stream)
{
// find node object
fSceneCacheObject_t* NO = fSceneCache_NodeObject(Cache, 0, NodeID, ObjectID);

// index... lua urgh
u32 PacketCount = 1;
lua_newtable(L);

// send everything for the moment
for (int j=0; j < Streams; j++)
{
u32 Count = StreamLength[j];
u32 UnitSize = StreamSize[j];
u8* Packet = Stream[j];

// add all packets
for (int i=0; i < Count; i++)
{
fRealizeHeader_t* RH = (fRealizeHeader_t* )(Packet + i*UnitSize);

//printf("send %i %i : %08x : %i / %i : %i\n", j, i, RH->ObjectID, RH->PartPos, RH->PartTotal, PacketCount);
lua_pushlstring(L, (const char*)RH, UnitSize);
lua_rawseti(L, -2, PacketCount++);
Cache->PacketSent++;
}
}
return 1;
}

//********************************************************************************************************************
// send all packets out onto the network
void fSceneCache_Stream(	struct fSceneCache_t* Cache,
u32 NodeID,
u32 ObjectID,
u32 RealizeMsgID,
u32 SceneID,
u32 TopCRC32,
u32 Streams,
u32* StreamLength,
u32* StreamSize,
void** Stream)
{
// find node object
fSceneCacheObject_t* NO = fSceneCache_NodeObject(Cache, SceneID, NodeID, ObjectID);

// all ok
if ((TopCRC32 != 0) && (!fSceneCache_IsDirty(Cache, NO, TopCRC32))) return 0;

// update send typeo
NO->MessageID = RealizeMsgID;

// send everything for the moment
for (int j=0; j < Streams; j++)
{
u32 Count = StreamLength[j];
u32 UnitSize = StreamSize[j];
u8* Packet = Stream[j];

// nothing in this stream, so skip
if (Count == 0) continue;

//printf("%08x : %i %i\n", ObjectID, j, Count);

//fAssert(Count > 0);
fAssert(UnitSize > 0);
fAssert(Count < 1000000);
fAssert(UnitSize < fRealize_MTU); // check it fits in the udp frame

// start index

u32 Index = NO->StreamPos[j];
Index = (Index >= Count) ? 0 : Index;		// in case the mesh shrinks

// send in bits
u32	Sent = 0;
for (int i=0; i < Count; i++)
{
fRealizeHeader_t* RH = (fRealizeHeader_t* )(Packet + Index*UnitSize);
if (fSceneCache_IsDirtyPart(Cache, NodeID, ObjectID, RH->PartPos, RH->CRC32) || (RH->PartTotal == 0))
{
RH->SceneID = SceneID;

// send fail so rest will prolly fail
if (!fMultiCast_Send(Cache->Net, RealizeMsgID, RH, UnitSize)) break;

Sent++;
}

Index++;
Index = (Index >= Count) ? 0 : Index;

if (Sent > 64) break;
}
NO->StreamPos[j] = Index;
Cache->PacketSent += Sent;
}
}

//********************************************************************************************************************

void fSceneCache_Register(lua_State* L)
{
lua_table_register(L, -1, "SceneCache_Create",		lSceneCache_Create);
lua_table_register(L, -1, "SceneCache_Destroy",		lSceneCache_Destroy);
lua_table_register(L, -1, "SceneCache_MultiCastID",	lSceneCache_MultiCastID);
lua_table_register(L, -1, "SceneCache_EnableID",	lSceneCache_EnableID);
lua_table_register(L, -1, "SceneCache_DisableID",	lSceneCache_DisableID);
lua_table_register(L, -1, "SceneCache_Update",		lSceneCache_Update);
lua_table_register(L, -1, "SceneCache_Reset",		lSceneCache_ResetCRC);
lua_table_register(L, -1, "SceneCache_ResetSceneID",	lSceneCache_ResetSceneID);
}
