--
-- Created by David Lannan
-- User: grover
-- Date: 5/05/13
-- Time: 3:32 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

ffi.cdef[[

// device specific includes
enum {
    GL_GLEXT_PROTOTYPES     = 1,

    // perf query enums
    PerfGeometry		    = 0,
    PerfBloom		        = 1,
    PerfParticle		    = 2,
    PerfRessolve		    = 3,
    PerfRead		        = 4,
    PerfFrame		        = 5,
    PerfAA			        = 6,
    PerfAmbientOcclusion	= 7,

    // 16 shadow maps max
    PerfShadow		= 0x10,
    PerfShadow0		= 0x10,
    PerfShadow1		= 0x11,
    PerfShadow2		= 0x12,
    PerfShadow3		= 0x13,
    PerfShadow4		= 0x14,
    PerfShadow5		= 0x15,
    PerfShadow6		= 0x16,
    PerfShadow7		= 0x17,
    PerfShadow8		= 0x18,
    PerfShadow9		= 0x19,
    PerfShadowA		= 0x1a,
    PerfShadowB		= 0x1b,
    PerfShadowC		= 0x1c,
    PerfShadowD		= 0x1d,
    PerfShadowE		= 0x1e,
    PerfShadowF		= 0x1f,

    // 256 lights max
    PerfLight		= 0x100,

    // Maximum material handles
    MATERIAL_MAX	= 4096,

};

// These typedefs try to make a more compatible interface for this system
typedef int32_t  EGLint;
typedef unsigned EGLBoolean;
typedef unsigned EGLenum;
typedef u32      XEvent;            // Dont Care
typedef u32      Colormap;          // Dont Care
typedef void*    XWindowAttributes; // Same as EGLConfig;
typedef void*    XSetWindowAttributes;
typedef void*    XVisualInfo;       // Dont Care
typedef void*    GLXContext;        // Same as EGLContext;
typedef void*    Display;           // Same as EGLDisplay;
typedef void*    Window;            // Same as EGLSurface;
typedef void*    EGLClientBuffer;

// master device structure

typedef struct fDevice_t
{
    u32			    Magic;
    Display*		disp;
    Window			root;
    Window			win;
    int			    screen;
    GLXContext              GLCtx;
    XWindowAttributes       gwa;
    XEvent                  xev;
    Colormap		    cmap;
    XVisualInfo*		vi;
    XSetWindowAttributes	swa;

    // display
    u32			DisWidth;
    u32			DisHeight;
    float			FPS;

    // render targets
    u32			RtWidth;
    u32			RtHeight;

    // perf reports
    u32			PerfQuery[1024];

    // cuda

//    int			    cuGPUFreq;
//    CUdevice 		CUDev;
//    CUcontext 		CUCtx;

//    CUdeviceptr		CUDebugVid[8];
//    u32*			CUDebugSys[8];
//    CUtexref		CUTexMap;
//    CUarray			CUMapArray;

    u32			ReadbackBID;
    u8*			ReadbackBuffer0;
    u8*			ReadbackBuffer1;
    u8*			ReadbackBuffer2;
    u8*			ReadbackBuffer3;
    u8*			ReadbackBuffer4;
    u8*			ReadbackBuffer5;
    u8*			ReadbackBuffer6;
    u8*			ReadbackBuffer7;

    // cg

//    CGcontext		CgCtx;
//    CGprofile   		CgProfileVertex;
//    CGprofile   		CgProfileGeometry;
//    CGprofile   		CgProfileFragment;

    // g buffer info

    u32			GBufFbID;
    u32			GBufTexID;

    // light buffer info

    u32			LBufFbID;
    u32			LBufTexID[2];
    u32			LightCount;
    u32			LightMax;

    // particles

    u32			PBufFbID;
    u32			PBufTexID[1];
    u32			ParticleTexID;

    // collision buffer info

    u32			CBufFbID;
    u32			CBufFbIDT[8];
    u32			CBufTexID[8];

    // depth

    u32			DepthRbID;
    u32			DepthTexID;

    // tone map

    u32			ToneMapTexID;
    u16			ToneMap[4*4096];

    // bloom

    u32			BloomFbID[4];
    u32			BloomTexID[4][2];

    // ambient occlusion

    u32			AmbientOcclusionFbID[2];
    u32			AmbientOcclusionTexID[2];

    // shadow maps

    u32			ShadowFbID;
    u32			ShadowRbID;
    u32			ShadowTexID;

    u32			ShadowColorTexID;

    u32			ShadowCount;
    u32			ShadowMax;

    // output buffer (offscreen)

    u32			OutputFbID;
    u32			OutputTexID;

    // scanout buffer

    u32			ScanoutFbID;

    // tmp buffers for whatever

    u32			TmpFbID[4];
    u32			TmpTexID[4];

    // memory and texture info for material info

    u32			MaterialTexID;

    // 1D texture for light proporties (for forward rendering)

    u32			LightTexID;

    // global env map
    u32			EnvTexID;

    // translucent prim buffers
    u32			TranslucentFbID;
    u32			TranslucentTexID[2];
    u32			TranslucentVBO;
    u32			TranslucentIBO;

    // shaders
    u32     ShaderSimpleV;
    u32     ShaderSimpleF;

    u32		ShaderGeomV;
    u32		ShaderGeomHeightMapV;
    u32		ShaderGeomSkinV;
    u32		ShaderGeomF;

    u32		ShaderShadowV;
    u32		ShaderShadowSkinV;
    u32		ShaderShadowF;

    u32		ShaderLightV;
    u32		ShaderLightF;

    u32		ShaderCollisionV;
    u32		ShaderCollisionF;

    u32		ShaderCollisionNormalV;
    u32		ShaderCollisionNormalF;

    u32		ShaderCollisionRenderV;
    u32		ShaderCollisionRenderF;

    u32		ShaderBloomV;
    u32		ShaderBloomHorizF;
    u32		ShaderBloomVertF;

    u32		ShaderResolveV;
    u32		ShaderResolveF;

    u32		ShaderAAV;
    u32		ShaderAAF;

    u32		ShaderAmbientOcclusionV;
    u32		ShaderAmbientOcclusionF;
    u32		ShaderAmbientOcclusionBlurHF;	// horizontal
    u32		ShaderAmbientOcclusionBlurVF;	// vertical
    u32		ShaderAmbientOcclusionResolveF;	// apply to LBuffer

    u32		ShaderTranslucentV;
    u32		ShaderTranslucentF;

    u32		ShaderVoxelV;
    u32		ShaderVoxelG;
    u32		ShaderVoxelF;

    u32		ShaderVoxelMergeV;
    u32		ShaderVoxelMergeG;
    u32		ShaderVoxelMergeF;

    u32		ShaderVoxelMapV;
    u32		ShaderVoxelMapF;

    u32		ShaderParticleRenderV;
    u32		ShaderParticleRenderF;

    u32		ShaderParticleUpdateV;
    u32		ShaderParticleUpdateF;

//    CUmodule		CUModuleParticle;
//    CUfunction		CUModuleParticle_Update;
//    CUfunction		CUModuleParticle_Collision;
//    CUfunction		CUModuleParticle_Force;
//
//    CUmodule		CUModuleVoxel;
//    CUfunction		CUModuleVoxel_BinX;
//    CUfunction		CUModuleVoxel_BinY;
//    CUfunction		CUModuleVoxel_BinZ;

    // small white texture for things with no texture

    u32			DefaultTextureID;

    // profiling info

    double			TimeAccGeom;
    double			TimeAccLight;
    double			TimeAccShadow;
    double			TimeAccBloom;
    double			TimeAccParticle;
    double			TimeAccRessolve;
    double			TimeAccAA;
    double			TimeAccAO;
    double			TimeAccRead;

    u32			TimeAccCount;
    u32			VertexAcc;
    u32			TriAcc;

} fDevice_t;

typedef struct hints {
    u32 flags;
    u32 functions;
    u32 decorations;
    int32_t input_mode;
    u32 status;
} WinHints;

//********************************************************************************************************************

]]

--toDevice(a,b) toDeviceEx(a,b,__FILE__, __LINE__)
--
--struct fDevice_t* 	toDeviceEx(lua_State* L, int index, const char* File, const int Line);
--void 			fDevice_Register(lua_State* L);

return ffi.C