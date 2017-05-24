--
-- Created by IntelliJ IDEA.
-- User: David Lannan
-- Date: 5/05/13
-- Time: 1:06 PM
-- To change this template use File | Settings | File Templates.
--
local ffi  = require( "ffi" )

ffi.cdef[[

enum {
    fRealizeMultiCast_Scene			= (fMultiCastID_User+0),
    fRealizeMultiCast_ObjectAck		= (fMultiCastID_User+1),
    fRealizeMultiCast_Camera		= (fMultiCastID_User+2),
    fRealizeMultiCast_TriMesh		= (fMultiCastID_User+3),
    fRealizeMultiCast_LightDir		= (fMultiCastID_User+4),
    fRealizeMultiCast_Material		= (fMultiCastID_User+5),
    fRealizeMultiCast_Texture		= (fMultiCastID_User+6),
    fRealizeMultiCast_Collect		= (fMultiCastID_User+7),
    fRealizeMultiCast_Line			= (fMultiCastID_User+8),
    fRealizeMultiCast_HeightMap		= (fMultiCastID_User+9),
    fRealizeMultiCast_Icon			= (fMultiCastID_User+10),
    fRealizeMultiCast_Skin			= (fMultiCastID_User+11),

    fRealizeCmdID_Update			= 0x1,
    fRealizeCmdID_Reset			    = 0x2,

    fRealizeCmdID_TriMeshHeader		= 0x100,
    fRealizeCmdID_TriMeshVertex		= 0x101,
    fRealizeCmdID_TriMeshIndex		= 0x102,

    fRealizeCmdID_SceneHeader		= 0x200,

    fRealizeCmdID_Collect			= 0x300,

    fRealizeCmdID_HeightMapHeader	= 0x400,
    fRealizeCmdID_HeightMapDepth	= 0x401,
    fRealizeCmdID_HeightMapDiffuse	= 0x402,

    fRealizeCmdID_SkinHeader		= 0x500,
    fRealizeCmdID_SkinVertex		= 0x501,
    fRealizeCmdID_SkinIndex			= 0x502,
    fRealizeCmdID_SkinBone			= 0x503,

    fRealizeCmdID_Compressed		= 0x8000,

    fRealizeType_TriMesh			= 1,
    fRealizeType_Camera			    = 2,
    fRealizeType_LightDir			= 3,
    fRealizeType_Line			    = 4,
    fRealizeType_HeightMap			= 5,
    fRealizeType_Icon			    = 6,
    fRealizeType_Skin			    = 7,

    fRealizeTextureFormat_RGBA8		= 1,
    fRealizeTextureFormat_U16		= 2,

    fRealizeTextureLayout_2D		= 1,
    fRealizeTextureLayout_CUBE		= 2,

    // reserved node ids
    fRealizeNodeID_XForm			= 0x10,

--//********************************************************************************************************************
--// render network physical capabilities

enum {
    //fRealize_MTU		= 1500,		// standard udp
    fRealize_MTU		= 9000,		// jumbo frames
};

static const u32 fRealizeSceneList_Max	= (fRealize_MTU - sizeof(fRealizeHeader_t) - 12) / sizeof(fRealizeObject_t);

};

]]

fRealizeHeader_t =  {
        CmdID       = 0x0000,
        NodeID      = 0x0000,
        ObjectID    = 0x0000,
        SceneID     = 0x0000,

        PartTotal   = 0,
        PartPos     = 0,
        CRC32       = 0
}

fRealizePack_t =  {
        CmdID       = 0x0000,       -- // must have fRealizeCmdID_Compressed bit set
        Magic       = 0x0000,       -- // compressor magic key
        RawLength   = 0,             -- // raw length of data
        -- // compressed data follows
}

fRealizeObject_t =  {
        -- // node id
        NodeID      = 0x0000,
        ObjectID    = 0x0000,

        -- // object id the node points to (e.g. for instancing)
        RefType     = 0x0000,
        RefID       = 0x0000,

        -- // full local -> world xform
        L2W         = nil,  -- Mat44
        iL2W        = nil,  -- Mat44

        -- // world space bounding box
        Min = { 0.0, 0.0, 0.0 },
        Max = { 0.0, 0.0, 0.0 },
}

--//********************************************************************************************************************
--// top level scene info (xforms)

fRealizeScene_t = {
        Header      = nil,

        ObjectTotal = 0,        --	// total objects in the scene
        ObjectCount = 0,        --	// objects in this packet
        ObjectOffset = 0,       --	// offset the object list starts at
        FrameNo     = 0,        -- // frame for this xform list

        List        = {}
}

fRealizeObjectAct_t = {
        NetID           = 0,
        NodeID          = 0,
        ObjectID        = 0,

        CRC32           = 0x0000,

        PartPos         = 0,
        PartTotal       = 0,
}

--//********************************************************************************************************************

fRealizeCamera_t = {
        Header          = nil,

        Local2World     = nil,      -- fMat44
        iLocal2World    = nil,

        View            = nil,
        iView           = nil,

        Projection      = nil,
        iProjection     = nil,
}

--//********************************************************************************************************************
--// tri mesh header info

fRealizeTriMesh_t = {
        Header      = nil,

        MaterialID  = 0,
        IndexCount  = 0,
        VertexCount = 0,

}

--//-----------------------------------------------------------------------------------------------------------------------
--// vertex info

fRealizeTriMeshVertex_Payload_t = {
        Px      = 0.0,
        Py      = 0.0,
        Pz      = 0.0,
        rgba    = 0x0000,

        u       = 0.0,
        v       = 0.0,
        pad     = 0,

        Nx      = 0.0,
        Ny      = 0.0,
        Nz      = 0.0,
        Tx      = 0.0,
        Ty      = 0.0,
        Tz      = 0.0,
        Bx      = 0.0,
        By      = 0.0,
        Bz      = 0.0,
}

fRealizeTriMeshVertex_t = {
        Header  = nil,

        Sequence    = 0,
        VertexCount = 0,        -- // number of vertices in this packet
        VertexOffset = 0,       -- // where these vertices start

        IndexTotal  = 0,
        VertexTotal = 0,

        List    = {},
}

--//-----------------------------------------------------------------------------------------------------------------------
--// tri mesh index info

fRealizeTriMeshIndex_Payload_t = {
        p0  = 0,
        p1  = 0,
        p2  = 0,

}

fRealizeTriMeshIndex_t = {
        Header = nil,

        Sequence        = 0,
        IndexCount      = 0,        --	// number of indicies in this packet
        IndexOffset     = 0,        --	// where this index starts

        IndexTotal      = 0,
        VertexTotal     = 0,

        List            = {},

}

--//********************************************************************************************************************
--// skin  header info

fRealizeSkin_t = {
        Header      = nil,

        MaterialID  = 0,

        IndexCount  = 0,
        VertexCount = 0,
        BoneCount   = 0,

        -- // full data stream crcs
        VertexCRC   = 0x0000,
        IndexCRC    = 0x0000,
        BoneCRC     = 0x0000,
        MaterialCRC = 0x0000,
}

--//-----------------------------------------------------------------------------------------------------------------------
--// skin vertex info

fRealizeSkinVertexPL_t = {
        Px      = 0.0,
        Py      = 0.0,
        Pz      = 0.0,
        rgba    = 0x0000,

        u       = 0.0,
        v       = 0.0,
        pad     = 0,

        Nx      = 0.0,
        Ny      = 0.0,
        Nz      = 0.0,

        Tx      = 0.0,
        Ty      = 0.0,
        Tz      = 0.0,

        Bx      = 0.0,
        By      = 0.0,
        Bz      = 0.0,

        Weight  = {},
        Bone    = {},
}

fRealizeSkinVertex_t = {
        Header  = nil,

        Sequence        = 0,
        VertexCount     = 0,        --	// number of vertices in this packet
        VertexOffset    = 0,        --	// where these vertices start

        IndexTotal      = 0,
        VertexTotal     = 0,

        List            = {},

}

--//-----------------------------------------------------------------------------------------------------------------------
--// skin index info

fRealizeSkinIndexPL_t = {
        p0      = 0,
        p1      = 0,
        p2      = 0,
}

fRealizeSkinIndex_t = {
        Header  = nil,

        Sequence        = 0,
        IndexCount      = 0,    --	// number of indicies in this packet
        IndexOffset     = 0,    --	// where this index starts

        IndexTotal      = 0,
        VertexTotal     = 0,

        List            = {},

}

--//-----------------------------------------------------------------------------------------------------------------------
--// skin bone xform

fRealizeSkinBonePL_t = {
        m00 = 0.0,
        m01 = 0.0,
        m02 = 0.0,
        m03 = 0.0,

        m10 = 0.0,
        m11 = 0.0,
        m12 = 0.0,
        m13 = 0.0,

        m20 = 0.0,
        m21 = 0.0,
        m22 = 0.0,
        m23 = 0.0
}

fRealizeSkinBone_t = {
        Header  = nil,

        Sequence        = 0,
        BoneTotal       = 0,        --	// total number of bones in the model
        BoneCount       = 0,        --	// number bones in this packet
        BaseID          = 0,        --  // base bone offset
        BoneFinalCRC    = 0x0000,   --	// crc for all bones in this object

        List            = {},
}

--//********************************************************************************************************************

fRealizeTexture_t = {
        Header  = nil,

        Width       = 32,
        Height      = 32,
        Bpp         = 3,
        Format      = 0x0000,
        Layout      = 0,

        CompressPos = 0,
        CompressCount   = 0,
        CompressSize    = 0,
    	CompressCRC     = 0,

        Offset          = 0,
        Len             = 0,

        Data            = nil,
}

--//********************************************************************************************************************
--// height map

fRealizeHeightMap_t = {
        Header      = nil,
        FinishCRC   = 0x0000,

        -- // width/height of area
        GeomWidth   = 0.0,
        GeomHeight  = 0.0,
        GeomDepth   = 0.0,

        -- // number of segments
        StepU       = 0,
        StepV       = 0,

        MaterialID  = 0,

        -- // grid origin (lower left corner)
        Ox          = 0.0,
        Oy          = 0.0,
        Oz          = 0.0,

        -- // up vector
        Up          = 0.0,

        -- // u vector
        Ux          = 0.0,
        Uy          = 0.0,
        Uz          = 0.0,

        -- // v vector
        Vx          = 0.0,
		Vy          = 0.0,
		Vz          = 0.0,

        -- // texutre ids
		DepthMapObjectID    = 0,
		DiffuseMapObjectID  = 0,
}

//********************************************************************************************************************

// directional light

typedef struct fRealizeLightDir_t
    {
        fRealizeHeader_t	Header;

float			ColorDiffuseR;
float			ColorDiffuseG;
float			ColorDiffuseB;

float			ColorSpecularR;
float			ColorSpecularG;
float			ColorSpecularB;

float			PositionX;
float			PositionY;
float			PositionZ;

float			DirectionX;
float			DirectionY;
float			DirectionZ;

float			Intensity;

float			Falloff0;
float			Falloff1;
float			Falloff2;

float 			ShadowMapBias;
bool 			ShadowEnable;

fMat44			View;
fMat44			iView;

fMat44			Projection;
fMat44			iProjection;

} fRealizeLightDir_t;

//********************************************************************************************************************

typedef struct fRealizeMaterial_t
    {
        fRealizeHeader_t	Header;

// maps

bool			TextureEnable;
u32			MapDiffuseObjectID;
u32			MapNormalObjectID;
u32			MapEnvObjectID;
u32			MapOpacityObjectID;

// surface proporties

float			Roughness;
float			Attenuation;
float			Ambient;

// translucent ?

bool			Translucent;
float			Opacity;

// basaic albedo

float			DiffuseR;
float			DiffuseG;
float			DiffuseB;

} fRealizeMaterial_t;

//********************************************************************************************************************

// line list info
static const u32 fRealizeLineCount = 112;

typedef struct fRealizeLine_t
    {
        fRealizeHeader_t	Header;

float			Time;			// time of the current spline position

float			ColorR;			// color it should be rendered as
float			ColorG;
float			ColorB;
bool			DepthTest;		// enable depth testing

u32			FinalCRC;		// crc of all vertices

u32			TotalCount;		// total number of vertices

u32			ListCount;		// number of elements
u32			ListOffset;		// this packets element

struct
    {
        float x, y, z;
} List[fRealizeLineCount];

} fRealizeLine_t;

//********************************************************************************************************************

// request to delete an objecct
typedef struct fRealizeCollect_t
    {
        fRealizeHeader_t	Header;

} fRealizeCollect_t;

//********************************************************************************************************************

// point sprite
typedef struct fRealizeIcon_t
    {
        fRealizeHeader_t	Header;

u32			MaterialID;
u32			DiffuseTextureID;

// origin

float			Ox;
float			Oy;
float			Oz;

// where the tip goes

float			Tx;
float			Ty;
float			Tz;

// aabb for hit selection

float			MinX;
float			MinY;
float			MinZ;

float			MaxX;
float			MaxY;
float			MaxZ;

// text

char			Name[128];
char			Desc[512];

} fRealizeIcon_t;

//********************************************************************************************************************

//********************************************************************************************************************

typedef struct fAct_t
    {
        u32				NodeID;
u32				ObjectID;
u32				CRC32;

struct fAct_t*			Next;

} fAct_t;

typedef struct fRealize_t
    {
        struct fRealize_t*		Next;
struct fMultiCastNode_t*	Net;

struct fObjectList_t*		ObjectList;

u32				NetID;
u32				SceneID;

fAct_t*				Act;

u32 				Magic;

} fRealize_t;

//********************************************************************************************************************


--struct fRealize_t;
--struct fObjectList_t;
--
--int 			fRealize_Register(lua_State* L);
--u32 			fRealize_SceneID(struct fRealize_t* R);
--struct fObjectList_t*	fRealize_ObjectList(struct fRealize_t* R);
--void 			fRealize_Ack(struct fRealize_t* R, u32 NodeID, u32 ObjectID, u32 CRC);
--struct fRealize_t*	fRealize_SceneIDFind(const u32 SceneID);


return ffi.C

