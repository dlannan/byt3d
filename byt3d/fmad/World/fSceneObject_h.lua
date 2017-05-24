--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:34 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--


local ffi  = require( "ffi" )

ffi.cdef[[

// common header for all objects
enum {
        fSceneObject_Type_None		= (0<<0),
        fSceneObject_Type_TriMesh	= (1<<0),
        fSceneObject_Type_Camera	= (1<<1),
        fSceneObject_Type_LightDir	= (1<<2),
        fSceneObject_Type_XFormPRS	= (1<<3),
        fSceneObject_Type_XFormLookAt	= (1<<4),
        fSceneObject_Type_Texture	= (1<<5),
        fSceneObject_Type_ParticleSys	= (1<<6),
        fSceneObject_Type_Material	= (1<<7),
        fSceneObject_Type_SplineCatmull	= (1<<8),
        fSceneObject_Type_XFormBot	= (1<<9),
        fSceneObject_Type_MasterBot	= (1<<10),
        fSceneObject_Type_HeightMap	= (1<<11),
        fSceneObject_Type_Icon		= (1<<12),
        fSceneObject_Type_Scene		= (1<<13),
        fSceneObject_Type_XFormDynamic	= (1<<14),
        fSceneObject_Type_Dynamic	= (1<<15),
        fSceneObject_Type_XFormBiped	= (1<<16),
        fSceneObject_Type_Biped		= (1<<17),
        fSceneObject_Type_Skin		= (1<<18),
        fSceneObject_Type_SphereTree	= (1<<19),
        fSceneObject_Type_Command	= (1<<20),
    };

enum {
        fSceneObject_Flag_NULL		= (1<<0),		// bit 0 for arse
        fSceneObject_Flag_Render	= (1<<1),		// object is renderable
        fSceneObject_Flag_XForm		= (1<<2),		// object is an xform controller
        fSceneObject_Flag_Light		= (1<<3),		// object is a light
        fSceneObject_Flag_Particle	= (1<<4),		// object is a particle of some sort
        fSceneObject_Flag_Material	= (1<<6),		// object is a material
        fSceneObject_Flag_Camera	= (1<<7),		// object is a camera
        fSceneObject_Flag_Util		= (1<<8),		// object is various utility
        fSceneObject_Flag_Texture	= (1<<9),		// object is texture
        fSceneObject_Flag_Dynamic	= (1<<10),		// object is dynamics object
        fSceneObject_Flag_Collision	= (1<<11),		// object is collision object
    };

struct fScene_t;
struct fSceneNode_t;
struct fSceneCache_t;
struct fRealizeHeader_t;


// scene object interface
typedef struct fSceneObjectDef_t
    {
        u32			Magic;
u32			StructSize;
char*			Desc;

u32			ObjectType;
u32			ObjectFlag;

// lua init

u32 			lScriptCount;
LuaInclude_t* 		lScript;

// realize

u32			RealizeType;

// functions

void*			FnCreate;
void*			FnDestroy;
void*			FnUserControl;		// world space information about the object, so UI can manipulate / control it
void*			FnObjectInfo;		// just object info
void*			FnDynamicInfo;		// dynamics information
void*			FnRealizeEncode;
void*			FnRealizeSend;

void*			FnUpdate;
void*			FnNodeXForm;
void*			FnBoundingSphere;
void*			FnBoundingBox;
void*			FnTriSoup;

} fSceneObjectDef_t;

typedef struct fSceneObjectPacket_t
    {
        char			Cmd[128];

u32			PayloadSize;
char*			Payload;

struct fSceneObjectPacket_t*	Next;

} fSceneObjectPacket_t;

typedef struct fSceneObject_t
    {
        u32				Magic;
u32				Magic2;
char				Name[512];
char				Path[512];
char				URL[1024];

u32				Type;
u32				Flag;
u32				ID;
u32				CRC32;

// parent host
struct fSceneHost_t*		Host;

// parent nodes child list

u32				NodeCount;
struct fSceneNode_t**		NodeList;

// packet queue

struct fSceneObjectPacket_t*	PacketTx_Head;
struct fSceneObjectPacket_t*	PacketTx_Tail;

struct fSceneObjectPacket_t*	PacketRx_Head;
struct fSceneObjectPacket_t*	PacketRx_Tail;

// in global scene list

struct fSceneObject_t*		HostNext;
struct fSceneObject_t*		HostPrev;

struct lua_State* 		lvm;
struct fSceneObjectDef_t*	Def;

} fSceneObject_t;

// material item
typedef struct fSceneMaterial_t
    {
        float			Roughness;
float			Attenuation;
float			Ambient;

// linked list from device object
struct fSceneMaterial_t*	DeviceNext;

} fSceneMaterial_t;

//********************************************************************************************************************
// scene object scene interfaces

typedef void			fSceneObject_Define_f(struct fSceneObjectDef_t* );
typedef void 			fSceneNode_XForm_f(struct fSceneNode_t* N, fMat44* M);
typedef struct fSceneObject_t*	fSceneNode_XFormObject_f(struct fSceneNode_t* N);
typedef struct fSceneObject_t*	fSceneNode_DynamicObject_f(struct fSceneNode_t* N);
typedef struct fSceneObject_t*	fSceneObject_Find(struct fScene_t* S, struct fSceneHost_t* HostDefault, const char* Path);
typedef u32			fSceneHost_FrameNo_f(struct fSceneHost_t* H);
typedef struct fImage_t*	fImage_Load_f(const char* Format, lua_State* L);
typedef void			fImage_Free_f(struct fImage_t* I);

typedef struct fSceneExternal_t
    {
        fSceneObject_Define_f*		SceneObject_Define;
        fSceneNode_XForm_f*		SceneNode_Local2World;
        fSceneNode_XForm_f*		SceneNode_iLocal2World;

        fSceneNode_XFormObject_f*	SceneNode_XForm;
        fSceneNode_DynamicObject_f*	SceneNode_Dynamic;

        fSceneObject_Find*		SceneObject_Find;
        fSceneHost_FrameNo_f*		SceneHost_FrameNo;

        fImage_Load_f*			Image_Load;
        void*				Image_Save;
        fImage_Free_f*			Image_Free;

    } fSceneExternal_t;

//********************************************************************************************************************

#define toSceneObject(a, b)		toSceneObjectEx(a, b, __FILE__, __LINE__)
#define fSceneObject_Validate(a)	fSceneObject_ValidateEx(a, __FILE__, __LINE__)
#define fSceneObject_Assert(a, magic)	fAssert(a); fAssert( ((fSceneObject_t*)a)->Magic == magic)

fSceneObject_t* 	toSceneObjectEx(lua_State* L, int index, const char* File, const u32 Line);
bool 			fSceneObject_ValidateEx(fSceneObject_t* O, const char* File, const u32 Line);
int 			fSceneObject_Create(struct fScene_t* S, fSceneObject_t* O,  const u32 Type, const u32 Flag,  const char* arg, u32 arglen, u32 lIncCount, LuaInclude_t* lInc);
void			fSceneObject_Update(fSceneObject_t* Obj, double t);
int 			fSceneObject_Register(lua_State* L);
struct fSceneNode_t*	fSceneObject_NodeGet(struct fSceneObject_t* O);
const char*		fSceneObject_TypeToStr(const u32 Type);
const u32 		fSceneObject_StrToType(const char* Str);
bool 			fSceneObject_BoundingSphere(fSceneObject_t* O, float* Center, float* Radius);
bool 			fSceneObject_BoundingBox(fSceneObject_t* O, float* Min, float* Max);
int 			fSceneObject_TriSoup(struct fSceneObject_t* O, fMat44* XForm, u32 Offset, u32 Max, float* Vertex);
void			fSceneObject_FullPath(char* Path, u32 MaxLen, const char* NodePath, const char* Key);
int fSceneObject_ReaelizeEncode
(
lua_State*		L,
struct fScene_t*	S,
u32			SceneID,
struct fSceneCache_t*	Cache,
fSceneObject_t*		O,
const char*		Mode
);

int			fSceneObject_Destroy(struct fScene_t* S, struct fSceneObject_t* O);

void			fSceneObject_Define(fSceneObjectDef_t* Def);
fSceneObjectDef_t* 	fSceneObject_DefFindType(u32 ID);
fSceneObjectDef_t* 	fSceneObject_DefFindMagic(u32 Magic);

#endif
