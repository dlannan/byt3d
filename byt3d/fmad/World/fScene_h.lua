--
-- Created by David Lannan
-- User: grover
-- Date: 16/05/13
-- Time: 7:11 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

ffi.cdef[[
//********************************************************************************************************************

enum
    {
        fSceneNode_Flag_ROOT		= (1<<0),
        fSceneNode_Flag_LocalXFORM	= (1<<1),
    };

//********************************************************************************************************************
// internal scene structure

struct fScene_t;
struct fSceneNode_t;
struct fSceneObject_t;
// host object
typedef struct fSceneHost_t
{
	struct fScene_t*	Scene;			// scene this belongs to
	char			Name[1024];		// hosts name
	char			URL[1024];		// host url
	u32			HierarchyRef;		// host is referenced in the hierarchy

	u32			FrameCount;		// host frame count

	u32			NodeCount;
	struct fSceneNode_t*	NodeRoot;		// hierarchical list
	struct fSceneNode_t*	NodeHead;		// linked list
	struct fSceneNode_t*	NodeTail;

	u32			ObjectCount;
	struct fSceneObject_t*	ObjectHead;		// linked list
	struct fSceneObject_t*	ObjectTail;

	struct fSceneHost_t*	HostNext;		// sibling list
	struct fSceneHost_t*	HostPrev;		// sibling list

} fSceneHost_t;

// hierarchy object
typedef struct fSceneNode_t
{
	char			Path[256];
	char			Name[128];
	char			URL[1024];
	u32			LastUpdate;
	u32			Flag;
	u32			ID;
	bool			Locked;

	fMat44			Local2World;
	fMat44			iLocal2World;

	fMat44			Local;
	fMat44			iLocal;

	// parent host
	struct fSceneHost_t*	Host;

	// host ref
	char			HostLink[1024];

	// tree
	struct fSceneNode_t*	Parent;
	struct fSceneNode_t*	Child;
	struct fSceneNode_t*	Sibling;

	// linked list
	struct fSceneNode_t*	NodePrev;
	struct fSceneNode_t*	NodeNext;

	// nodes controler
	char			ControllerName[128];
	fSceneObject_t*		Controller;

	u32			ObjectCount;
	fSceneObject_t**	ObjectList;
	char**			ObjectKey;

	u32			Magic;

} fSceneNode_t;

typedef struct fSceneMsg_t
{
	char			Cmd[64];

	u32			DataLen;
	char*			Data;

	struct fSceneMsg_t*	Next;

} fSceneMsg_t;

// scene container
typedef struct fScene_t
{
	fSceneObject_t		Header;
	char			Name[1024];			// name of the scene

	double			LastTS;
	u32			FrameCount;

	// host list
	struct fSceneHost_t*	HostHead;
	struct fSceneHost_t*	HostTail;

	// spacial list
	struct fSceneSpace_t*	Space;

	// globals
	struct fSceneGlobal_t*	Global;

	// cache
	struct fSceneCache_t*	Cache;

	// packets orignating from the scene requesting attention

	struct fSceneMsg_t*	MsgQueueHead;
	struct fSceneMsg_t*	MsgQueueTail;


} fScene_t;

//********************************************************************************************************************

// epoach base
static double			s_TimeBase	= 0;

// these give every node/object a uniqued ID irrespective of what the world is currently siming
// note: ID < 0x100 are reserved for system use
static u32			s_NodeInc 	    = 0x100;
static u32			s_ObjectInc 	= 0x100;

typedef fScene_t * fSceneObject_tPtr;
typedef fSceneNode_t * fSceneNode_tPtr;

//********************************************************************************************************************

]]

return ffi.C