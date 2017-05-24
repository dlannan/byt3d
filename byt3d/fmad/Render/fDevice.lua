--
-- Created by David Lannan
-- User: grover
-- Date: 5/05/13
-- Time: 3:39 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )
local gl   = require( "ffi/OpenGLES2" )

local fDv = require("byt3d/fmad/Render/fDevice_h")

require("byt3d/scripts/platform/wm")
require("byt3d/framework/byt3dShader")

-- //********************************************************************************************************************

DEVICE_MAGIC	= 0x04200000

-- //********************************************************************************************************************
-- // device shaders

require("byt3d/fmad/shaders/fmadShaders")

require("byt3d/shaders/base_models")

-- //********************************************************************************************************************

m_LastFrameTS = 0

--// cuda capabilities
--
--typedef struct
--    {
--        CUdevice_attribute  attrib;
--char* str;
--
--} cuDeviceCap_t;
--
--static cuDeviceCap_t s_Cap[] =
--{
--    { CU_DEVICE_ATTRIBUTE_CLOCK_RATE,		"clock rate (khz)"},
--    { CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK,	"max threads per block"},
--    { CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_X,		"max block dim x"},
--    { CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Y,		"max block dim y"},
--    { CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Z,		"max block dim z"},
--
--    { CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_X,		"max grid dim x"},
--    { CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Y,		"max grid dim y"},
--    { CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Z,		"max grid dim z"},
--
--    { CU_DEVICE_ATTRIBUTE_SHARED_MEMORY_PER_BLOCK,	"shared mem per bock"},
--    { CU_DEVICE_ATTRIBUTE_TOTAL_CONSTANT_MEMORY,	"total const mem"},
--    { CU_DEVICE_ATTRIBUTE_WARP_SIZE,		"warp size"},
--    { CU_DEVICE_ATTRIBUTE_MAX_PITCH,		"max pitch"},
--    { CU_DEVICE_ATTRIBUTE_REGISTERS_PER_BLOCK,	"registers per block"},
--    { CU_DEVICE_ATTRIBUTE_TEXTURE_ALIGNMENT,	"texture alignment"},
--    { CU_DEVICE_ATTRIBUTE_GPU_OVERLAP,		"gpu overlap"},
--};
--
-- //********************************************************************************************************************

function CHECK_CG( result )

    local error_no = gl.glGetError()
    if( error_no ~= gl.GL_NO_ERROR ) then

        if( error_no == gl.GL_INVALID_ENUM) then
            ftrace("OpenGLES Error: GL_INVALID_ENUM \n")
        elseif( error_no == gl.GL_INVALID_VALUE) then
            ftrace("OpenGLES Error: GL_INVALID_VALUE \n")
        elseif( error_no == gl.GL_INVALID_OPERATION) then
            ftrace("OpenGLES Error: GL_INVALID_OPERATION \n")
        elseif( error_no == gl.GL_INVALID_FRAMEBUFFER_OPERATION) then
            ftrace("OpenGLES Error: GL_INVALID_FRAMEBUFFER_OPERATION \n")
        elseif( error_no == gl.GL_OUT_OF_MEMORY) then
            ftrace("OpenGLES Error: GL_OUT_OF_MEMORY \n")
        end
        fAssert(false)
    end
end

-- //********************************************************************************************************************

function toDevice( D,  File,  Line )

    fAssert(D ~= nil)
    fAssert(D.Magic == DEVICE_MAGIC)
    return D
end

-- //********************************************************************************************************************

function  Device_ShaderCompileCg( D, Profile, Name, Src, Entry, args)

    if (Entry == nil) then Entry = "main" end

    local Program = cgCreateProgram(D.CgCtx, CG_SOURCE, Src, Profile, Entry, args);

    -- // check for compile error
    local error = ffi.new("CGerror[1]")
    local str = cgGetLastErrorString(error)
    if (error[0] ~= CG_NO_ERROR) then

        ftrace("DeviceShader: error %s\n", str);
    end
    if (error[0] == CG_COMPILER_ERROR) then

        ftrace("DeviceShader: %s\n", cgGetLastListing(D.CgCtx))
        fAssert(false)
        return nil
    end

    CHECK_CG(cgGLLoadProgram(Program));

    ftrace("	[%-30s@%s]\n", Name, cgGetProgramString( Program, CG_PROGRAM_ENTRY));
    return Program
end

-- //********************************************************************************************************************

function  Device_ShaderCompile( Profile, Src, Name )

    if (Entry == nil) then Entry = "main" end

    local Shader = byt3dShader:LoadAShader( Src, Profile )  -- gl.GL_VERTEX_SHADER or gl.GL_FRAGMENT_SHADER
    local Program = gl.glCreateProgram()
    ftrace("\tDeviceShader: %s %d %d\n", Name, Shader, Program)

    -- local Program = cgCreateProgram(D.CgCtx, CG_SOURCE, Src, Profile, Entry, args);
    gl.glAttachShader( Program, Shader )

    gl.glLinkProgram( Program )
    gl.glUseProgram( Program )

    return Program
end

--//********************************************************************************************************************
--// readback the device image

function Device_ReadbackColor(b, g, r, D)

    printf("fill %02x %02x %02x\n", r, g, b)

    local buffer = ffi.cast("u32", D.ReadbackBuffer1)
    local color = bit.bor(bit.lshift(0xff,24) , bit.lshift(r,16) , bit.lshift(g,8) , bit.lshift(b,0) )

    for i=0, D.RtHeight*D.RtWidth-1 do

        buffer[i] = color;
    end

    return 1
end

-- //********************************************************************************************************************

function Device_SetContext( D )

    glXMakeCurrent(D.disp, D.win, D.GLCtx);
end

--//********************************************************************************************************************
--// device setup init blah all api/lib things done here
--//********************************************************************************************************************

-- // setup basic x11
function x11Init( L, D )

    ftrace("X11 init\n")
    D.disp = XOpenDisplay(nil)
    if (D.disp == nil) then

        ftrace("Cannt connect to X server\n");
        return 0
    end
    D.root = DefaultRootWindow(D.disp)
    D.screen = DefaultScreen(D.disp)

    -- // requested sizes
    D.DisWidth	= L.DisplayWidth
    D.DisHeight	= L.DisplayHeight

    D.RtWidth 	= L.MaxWidth
    D.RtHeight 	= L.MaxHeight

    fAssert(D.RtWidth >= D.DisWidth)
    fAssert(D.RtHeight >= D.DisHeight)

    ftrace("	setup render context at Display[%ix%i] max Render[%ix%i]\n", D.DisWidth, D.DisHeight, D.RtWidth, D.RtHeight)

    -- // locked fps ?
    D.FPS = 0;
    D.FPS = L.fps

    -- // attribs want
    attrib  = ffi/new("u32[?]",
    {
        GLX_RGBA,
        GLX_DOUBLEBUFFER,
        GLX_RED_SIZE,
        8,
        GLX_GREEN_SIZE,
        8,
        GLX_BLUE_SIZE,
        8,
        GLX_DEPTH_SIZE,
        24,
        GLX_STENCIL_SIZE,
        8,
        0
    } )

    -- // try find somthing render to
    D.vi = glXChooseVisual(D.disp, D.screen, attrib)
    if(D.vi == nil) then

        ftrace("no appropriate visual found")
        return 0
    end
    ftrace("	selcted visual: %08x", D.vi.visualid)

    -- // color map
    D.cmap = XCreateColormap(D.disp, D.root, D.vi.visual, AllocNone)

    -- // window info
    ffi.fill(D.swa, ffi.sizeof(D.swa), 0)
    D.swa.colormap = D.cmap
    D.swa.event_mask = bit.bor(ExposureMask, KeyPressMask)

    local mask = ffi.new("u32")
    mask = bit.bor(CWBackPixel , CWColormap , CWOverrideRedirect , CWSaveUnder , CWBackingStore , CWEventMask)

    D.win = XCreateWindow(D.disp, D.root, 0, 0, D.DisWidth, D.DisHeight, 0, D.vi.depth, InputOutput, D.vi.visual, mask, D.swa)
    if (D.win <= 0) then

        ftrace("failed to create window\n")
        return 0
    end

    XMapWindow(D.disp, D.win)
    XStoreName(D.disp, D.win, "VERY SIMPLE APPLICATION")

    -- // remove borders
    local hints = ffi.new("WinHints[1]",  {  2, 0, 0, 0, 0 } )
    XChangeProperty (D.disp, D.win,
    XInternAtom (D.disp, "_MOTIF_WM_HINTS", False),
    XInternAtom (D.disp, "_MOTIF_WM_HINTS", False),
    32, PropModeReplace,
    ffi.cast("const unsigned char *", hints), 4)

    XFlush(D.disp)

    return 1
end

-- //********************************************************************************************************************
-- // Using SDL to init window information (more x platform capable)

TempWindow = nil

function glSDLInit( L, D )

    -- // requested sizes
    D.DisWidth	= L.DisplayWidth
    D.DisHeight	= L.DisplayHeight

    D.RtWidth 	= L.MaxWidth * 3
    D.RtHeight 	= L.MaxHeight

    fAssert(D.RtWidth >= D.DisWidth)
    fAssert(D.RtHeight >= D.DisHeight)

    ftrace("	setup render context at Display[%ix%i] max Render[%ix%i]\n", D.DisWidth, D.DisHeight, D.RtWidth, D.RtHeight)

    -- // locked fps ?
    D.FPS = 0;
    D.FPS = L.fps

    TempWindow = InitSDL(D.DisWidth, D.DisHeight)
end

-- //********************************************************************************************************************
-- // basic gl setup

-- NOTE: This has been 'windozed' to use OpenGLES, so it may not work well on Linux any more
--       Need some testing.

Temp_eglInfo = nil

function glInit( L, D )

    ftrace("GL Init")
--    D.GLCtx = glXCreateContext(D.disp, D.vi, nil, GL_TRUE)
--    glXMakeCurrent(D.disp, D.win, D.GLCtx)

    Temp_eglInfo = InitEGL(TempWindow)

    gl.glClearColor(1.0, 0.0, 0.0, 1.0)
    gl.glClear(gl.GL_COLOR_BUFFER_BIT)
    gl.glFlush()
    egl.eglSwapBuffers( Temp_eglInfo.dpy, Temp_eglInfo.surf )

    --// readback buffer ids
    local id = ffi.new("u32[1]")
    gl.glGenBuffers(1, id);
    D.ReadbackBID = id[0]
    D.ReadbackBuffer0 = ffi.new("u8["..(D.RtWidth*D.RtHeight*16).."]")
    D.ReadbackBuffer1 = ffi.new("u8["..(D.RtWidth*D.RtHeight*16).."]")
    D.ReadbackBuffer2 = ffi.new("u8["..(D.RtWidth*D.RtHeight*16).."]")
    D.ReadbackBuffer3 = ffi.new("u8["..(D.RtWidth*D.RtHeight*16).."]")
    D.ReadbackBuffer4 = ffi.new("u8["..(D.RtWidth*D.RtHeight*16).."]")
    D.ReadbackBuffer5 = ffi.new("u8["..(D.RtWidth*D.RtHeight*16).."]")
    D.ReadbackBuffer6 = ffi.new("u8["..(D.RtWidth*D.RtHeight*16).."]")
    D.ReadbackBuffer7 = ffi.new("u8["..(D.RtWidth*D.RtHeight*16).."]")

    -- // mrt setup
    local maxBuffers    = 128
    local maxColor      = 16
    local maxRend       = 128
    --gl.glGetIntegerv(gl.GL_MAX_DRAW_BUFFERS, maxBuffers)
    --gl.glGetIntegerv(gl.GL_MAX_COLOR_ATTACHMENTS, maxColor)
    --gl.glGetIntegerv(gl.GL_MAX_RENDERBUFFER_SIZE, maxRend)
    --gl.glGetIntegerv(gl.GL_MAX_DRAW_BUFFERS, maxBuffers)
    ftrace("	Max draw buffers: %i %i %i\n", maxBuffers, maxColor, maxRend)

    -- // common depth buffer
    gl.glGenRenderbuffers(1, id)
    D.DepthRbID = id[0]
    gl.glBindRenderbuffer(gl.GL_RENDERBUFFER, D.DepthRbID);
    gl.glRenderbufferStorage(gl.GL_RENDERBUFFER, gl.GL_DEPTH_COMPONENT16, D.RtWidth, D.RtHeight)

    gl.glBindRenderbuffer(gl.GL_RENDERBUFFER, 0)
    ftrace("	Depth Buffer %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER))
    fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE)

    gl.glGenTextures(1, id)
    D.DepthTexID = id[0]
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
    -- //gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_DEPTH_COMPONENT, D.Width, D.Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, 0)
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0);

    -- // tmp debug buffer
    local ids = ffi.new("u32[4]")
    gl.glGenTextures(4, ids)
    for i=0, 3 do
        D.TmpTexID[i] = ids[i]
        gl.glBindTexture(gl.GL_TEXTURE_2D, D.TmpTexID[i]);
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, 256, 256, 0, gl.GL_RGBA, gl.GL_FLOAT, nil)
        --gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA32F_ARB, 256, 256, 0, gl.GL_RGBA, gl.GL_FLOAT, 0)
    -- //gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, D->Width, D->Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, 0)
    end

    gl.glGenFramebuffers(4, D.TmpFbID)
    -- // bind render buffers to frame buffer
    -- //gl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, D->DepthRbID);
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.TmpFbID[0])
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.TmpTexID[0], 0)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.TmpFbID[1])
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.TmpTexID[1], 0)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.TmpFbID[2])
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.TmpTexID[2], 0)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.TmpFbID[3])
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.TmpTexID[3], 0)

    ftrace("	Tmp Debug Buffer %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER))
    fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    -- // offscreen output buffer
    gl.glGenTextures(1, id)
    D.OutputTexID = id[0]

    gl.glBindTexture(gl.GL_TEXTURE_2D, D.OutputTexID)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, D.RtWidth, D.RtHeight, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, nil)

    gl.glGenFramebuffers(1, id)
    D.OutputFbID = id[0]
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.OutputFbID)

    -- // bind render buffers to frame buffer
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.OutputTexID, 0)
    gl.glFramebufferRenderbuffer(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_RENDERBUFFER, D.DepthRbID)

    ftrace("	Output Buffer %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER));
    fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    -- // scanout buffer always 0
    D.ScanoutFbID = 0

    -- // default white texture
    local DefTexture = ffi.new("u32[16*16]")
    ffi.fill(DefTexture, 16*16*4, 0xFF)

    gl.glGenTextures(1, id)
    D.DefaultTextureID = id[0]
    gl.glBindTexture(gl.GL_TEXTURE_2D, D.DefaultTextureID)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, 16, 16, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, DefTexture);

    -- // allocate reports
    D.PerfQuery = ffi.new("u32[1024]")
    -- TODO: How to do this? I dont know.
    -- gl.glGenQueries(1024, D.PerfQuery)
end

--//********************************************************************************************************************
--// defered shading setup

function deferInit( L,  D )

    -- // max number of perf queries really no other limitations
    D.LightMax = 0x100

    -- // G Buffer MRT & buffers & crud
    local ids = ffi.new("u32[4]")
    local id = ffi.new("u32[1]")

    gl.glGenTextures(1, id)
    D.GBufTexID = id[0]
    gl.glBindTexture(gl.GL_TEXTURE_2D, D.GBufTexID)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, D.RtWidth, D.RtHeight, 0, gl.GL_RGBA, gl.GL_FLOAT, nil)
        -- //gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, D.Width, D.Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, 0)

    gl.glGenFramebuffers(1, id)
    D.GBufFbID = id[0]
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.GBufFbID)

    -- // bind render buffers to frame buffer
    gl.glFramebufferRenderbuffer(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_RENDERBUFFER, D.DepthRbID)
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.GBufTexID, 0)

    ftrace("	Geometry Buffer %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER))
    fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    -- // L Buffer MRT & buffers & crud
    ids = ffi.new("u32[2]")
    gl.glGenTextures(2, ids)
    for i=0, 1 do

        D.LBufTexID[i] = ids[i]
        gl.glBindTexture(gl.GL_TEXTURE_2D, D.LBufTexID[i])
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, D.RtWidth, D.RtHeight, 0, gl.GL_RGBA, gl.GL_FLOAT, nil)
        -- //gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, D.Width, D.Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, 0)
    end

    gl.glGenFramebuffers(1, id)
    D.LBufFbID = id[0]
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.LBufFbID)

    -- // bind render buffers to frame buffer
    gl.glFramebufferRenderbuffer(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_RENDERBUFFER, D.DepthRbID)
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.LBufTexID[0], 0)
    -- gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT1, gl.GL_TEXTURE_2D, D.LBufTexID[1], 0)

    ftrace("	Light Buffer %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER))
    fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    -- // translucency buffer
    gl.glGenTextures(2, ids)
    for i=0, 1 do

        D.TranslucentTexID[i] = ids[i]
        gl.glBindTexture(gl.GL_TEXTURE_2D, D.TranslucentTexID[i])
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, D.RtWidth, D.RtHeight, 0, gl.GL_RGBA, gl.GL_FLOAT, nil)
        -- //gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, D.Width, D.Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, 0)
    end

    gl.glGenFramebuffers(1, id)
    D.TranslucentFbID = id[0]
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.TranslucentFbID)

    -- // bind render buffers to frame buffer
    gl.glFramebufferRenderbuffer(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_RENDERBUFFER, D.DepthRbID)
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.TranslucentTexID[0], 0)

    -- gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT1, gl.GL_TEXTURE_2D, D.TranslucentTexID[1], 0)

    ftrace("	Translucent Buffer %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER))
    fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    -- // tone map
    gl.glGenTextures(1, id)
    D.ToneMapTexID = id[0]
    gl.glBindTexture(gl.GL_TEXTURE_2D, D.ToneMapTexID)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST)	-- // otherwise will blend r/g/b curves..
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)

    -- // plain borring linear ramp for the moment
    for i=0, 4095 do

        D.ToneMap[0*4096+i] = (i*0x10000)/4096;
        D.ToneMap[1*4096+i] = (i*0x10000)/4096;
        D.ToneMap[2*4096+i] = (i*0x10000)/4096;
    end

    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_LUMINANCE, 4096, 4, 0, gl.GL_LUMINANCE, gl.GL_UNSIGNED_SHORT, D.ToneMap)

    -- // boom  buffer
    -- // hmm.. should start re-using buffers at some point..
    for b=0, 3 do

        gl.glGenFramebuffers(1, id)
        D.BloomFbID[b] = id[0]
        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.BloomFbID[b])

        local Width = D.RtWidth / (1+b);
        local Height = D.RtHeight / (1+b);

        gl.glGenTextures(2, ids)
        for i=0, 1 do

            D.BloomTexID[b][i] = ids[i]
            gl.glBindTexture(gl.GL_TEXTURE_2D, D.BloomTexID[b][i])
            gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
            gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
            gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
            gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
            gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, Width, Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, nil)
        end

        -- // bind render buffers to frame buffer
        --//gl.glFramebufferRenderbuffer(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_RENDERBUFFER, D.DepthRbID)
        gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.BloomTexID[b][0], 0)
        -- gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT1, gl.GL_TEXTURE_2D, D.BloomTexID[b][1], 0)

        ftrace("	Bloom Buffer %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER));
        fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE);
    end

    -- // ambient occlusion buffer
    D.AmbientOcclusionTexID = ffi.new("u32[2]")
    gl.glGenTextures(2, D.AmbientOcclusionTexID)
    D.AmbientOcclusionFbID = ffi.new("u32[2]")
    gl.glGenFramebuffers(2, D.AmbientOcclusionFbID)
    for i=0, 1 do

        gl.glBindTexture(gl.GL_TEXTURE_2D, D.AmbientOcclusionTexID[i])
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, D.RtWidth, D.RtHeight, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, nil)

        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.AmbientOcclusionFbID[i])
        gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.AmbientOcclusionTexID[i], 0)

        ftrace("	Ambient Occlusion %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER))
        fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE)
        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0);
    end

    -- // material texture
    gl.glGenTextures(1, id)
    D.MaterialTexID = id[0]
    gl.glBindTexture(gl.GL_TEXTURE_2D, D.MaterialTexID)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST)	-- // otherwise will blend r/g/b curves..
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)


    -- // post process buffer
    D.PBufTexID = ffi.new("u32[1]")
    gl.glGenTextures(1, D.PBufTexID)
    for i=0, 0 do

        gl.glBindTexture(gl.GL_TEXTURE_2D, D.PBufTexID[i])
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, D.RtWidth, D.RtHeight, 0, gl.GL_RGBA, gl.GL_FLOAT, nil)
        -- //gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, D.Width, D.Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, 0)
    end

    gl.glGenFramebuffers(1, id)
    D.PBufFbID = id[0]
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.PBufFbID)

    -- // bind render buffers to frame buffer
    gl.glFramebufferRenderbuffer(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_RENDERBUFFER, D.DepthRbID)
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.PBufTexID[0], 0)

    ftrace("	Post Buffer %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER))
    fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    -- // translucency buffer id
    gl.glGenBuffers(1, id)
    D.TranslucentVBO = id[0]
    gl.glGenBuffers(1, id)
    D.TranslucentIBO = id[0]

    -- // light 1d texture
    gl.glGenTextures(1, id)
    D.LightTexID = id[0]
    gl.glBindTexture(gl.GL_TEXTURE_2D, D.LightTexID)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST)	-- // otherwise will blend r/g/b curves..
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)

    -- // gl.global environment map
    gl.glGenTextures(1, id)
    D.EnvTexID = id[0]
    gl.glBindTexture(gl.GL_TEXTURE_CUBE_MAP, D.EnvTexID)
    gl.glTexParameterf(gl.GL_TEXTURE_CUBE_MAP, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_CUBE_MAP, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_CUBE_MAP, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_CUBE_MAP, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)

--    local EnvWidth	= 16
--    local EnvHeight	= 16
--    local Map = ffi.new("u8["..(EnvWidth*EnvHeight*4*6).."]")
--    ffi.fillt(Map, EnvWidth*EnvHeight*4*6, 0xff)

--    /*
--    for (int i=0; i < EnvHeight; i++)
--    {
--    for (int j=0; j < EnvWidth; j++)
--    {
--    Map[(i*EnvWidth+j)*4 + 0] = 0xff;
--    Map[(i*EnvWidth+j)*4 + 1] = 0x00;
--    Map[(i*EnvWidth+j)*4 + 2] = 0x00;
--    Map[(i*EnvWidth+j)*4 + 3] = 0x00;
--    }
--    }
--    */
--    gl.glTexImage2D(gl.GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, gl.GL_RGBA, EnvWidth, EnvHeight, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, Map)
--    gl.glTexImage2D(gl.GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, gl.GL_RGBA, EnvWidth, EnvHeight, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, Map)
--
--    gl.glTexImage2D(gl.GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, gl.GL_RGBA, EnvWidth, EnvHeight, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, Map)
--    gl.glTexImage2D(gl.GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, gl.GL_RGBA, EnvWidth, EnvHeight, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, Map)
--
--    gl.glTexImage2D(gl.GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, gl.GL_RGBA, EnvWidth, EnvHeight, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, Map)
--    gl.glTexImage2D(gl.GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, gl.GL_RGBA, EnvWidth, EnvHeight, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, Map)
--
--    fFree(Map)

    gl.glBindTexture(gl.GL_TEXTURE_CUBE_MAP, 0)
end

--//********************************************************************************************************************
--// shadow buffers

function shadowInit(L, D)

    local Width     = 512
    local Height    = 512

    -- // max number of perf queries
    D.ShadowMax     = 16

    local id = ffi.new("u32[1]")
    gl.glGenTextures(1, id)
    D.ShadowTexID = id[0]
    gl.glBindTexture(gl.GL_TEXTURE_2D, D.ShadowTexID)

    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)

    -- //gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST)
    -- //gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST)

    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
    -- local borderColor = ffi.new("float[4]", {1.0, 1.0, 1.0, 1.0} )
    -- gl.glTexParameterfv(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_BORDER_COLOR, borderColor)

    -- gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_COMPARE_MODE_ARB, gl.GL_COMPARE_R_TO_TEXTURE)

--    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_COMPARE_FUNC_ARB, gl.GL_LEQUAL)
--    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_DEPTH_TEXTURE_MODE, gl.GL_INTENSITY)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_DEPTH_COMPONENT16, Width, Height, 0, gl.GL_DEPTH_COMPONENT, gl.GL_UNSIGNED_BYTE, nil)

    -- // dummy color buffer
    gl.glGenTextures(1, id)
    D.ShadowColorTexID = id[0]
    gl.glBindTexture(gl.GL_TEXTURE_2D, D.ShadowColorTexID)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, Width, Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, nil)

    -- // allocate mem & bind texture
    gl.glGenFramebuffers(1, id)
    D.ShadowFbID = id[0]
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.ShadowFbID)

    gl.glGenRenderbuffers(1, id)
    D.ShadowRbID = id[0]
    gl.glBindRenderbuffer(gl.GL_RENDERBUFFER, D.ShadowRbID)
    gl.glRenderbufferStorage(gl.GL_RENDERBUFFER, gl.GL_DEPTH_COMPONENT16, Width, Height)

    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, D.ShadowColorTexID, 0)
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_RENDERBUFFER, D.ShadowRbID, 0)

    ftrace("	Shadow Buffer %08x\n", gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER))
    fAssert(gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) == gl.GL_FRAMEBUFFER_COMPLETE)

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)
end

-- //********************************************************************************************************************

--function voxelInit(L, D)
--
--    // Collision Buffer MRT & buffers & crud
--    gl.glGenTextures(8, D->CBufTexID);
--    for (int i=0; i < 8; i++)
--    {
--    gl.glBindTexture(gl.GL_TEXTURE_2D, D->CBufTexID[i]);
--    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
--    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
--    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
--    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
--    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, 256, 256, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, 0);
--    }
--
--    gl.glGenFramebuffersEXT(1, &D->CBufFbID);
--    gl.glBindFramebufferEXT(gl.GL_FRAMEBUFFER_EXT, D->CBufFbID);
--
--    // bind render buffers to frame buffer
--    gl.glFramebufferTexture2DEXT(gl.GL_FRAMEBUFFER_EXT, gl.GL_COLOR_ATTACHMENT0_EXT, gl.GL_TEXTURE_2D, D->CBufTexID[0], 0);
--    gl.glFramebufferTexture2DEXT(gl.GL_FRAMEBUFFER_EXT, gl.GL_COLOR_ATTACHMENT1_EXT, gl.GL_TEXTURE_2D, D->CBufTexID[1], 0);
--    gl.glFramebufferTexture2DEXT(gl.GL_FRAMEBUFFER_EXT, gl.GL_COLOR_ATTACHMENT2_EXT, gl.GL_TEXTURE_2D, D->CBufTexID[2], 0);
--    gl.glFramebufferTexture2DEXT(gl.GL_FRAMEBUFFER_EXT, gl.GL_COLOR_ATTACHMENT3_EXT, gl.GL_TEXTURE_2D, D->CBufTexID[3], 0);
--    gl.glFramebufferTexture2DEXT(gl.GL_FRAMEBUFFER_EXT, gl.GL_COLOR_ATTACHMENT4_EXT, gl.GL_TEXTURE_2D, D->CBufTexID[4], 0);
--    gl.glFramebufferTexture2DEXT(gl.GL_FRAMEBUFFER_EXT, gl.GL_COLOR_ATTACHMENT5_EXT, gl.GL_TEXTURE_2D, D->CBufTexID[5], 0);
--    gl.glFramebufferTexture2DEXT(gl.GL_FRAMEBUFFER_EXT, gl.GL_COLOR_ATTACHMENT6_EXT, gl.GL_TEXTURE_2D, D->CBufTexID[6], 0);
--    gl.glFramebufferTexture2DEXT(gl.GL_FRAMEBUFFER_EXT, gl.GL_COLOR_ATTACHMENT7_EXT, gl.GL_TEXTURE_2D, D->CBufTexID[7], 0);
--
--    ftrace("	Collision Buffer %08x %i\n", gl.glCheckFramebufferStatusEXT(gl.GL_FRAMEBUFFER_EXT), __LINE__);
--    fAssert(gl.glCheckFramebufferStatusEXT(gl.GL_FRAMEBUFFER_EXT) == gl.GL_FRAMEBUFFER_COMPLETE_EXT);
--    gl.glBindFramebufferEXT(gl.GL_FRAMEBUFFER_EXT, 0);
--
--    // for MRT -> singl.gle texture
--    gl.glGenFramebuffersEXT(8, D->CBufFbIDT);
--    for (int i=0; i < 8; i++)
--    {
--    gl.glBindFramebufferEXT(gl.GL_FRAMEBUFFER_EXT, D->CBufFbIDT[i]);
--    gl.glFramebufferTexture2DEXT(gl.GL_FRAMEBUFFER_EXT, gl.GL_COLOR_ATTACHMENT0_EXT, gl.GL_TEXTURE_2D, D->CBufTexID[i], 0);
--    }
--    gl.glBindFramebufferEXT(gl.GL_FRAMEBUFFER_EXT, 0);
--end

-- //********************************************************************************************************************
-- // init particle texture

function particleInit( L, D )

    local id = ffi.new("u32[1]")
    gl.glGenTextures(1, id)
    D.ParticleTexID = id[0]

    gl.glBindTexture(gl.GL_TEXTURE_2D, D.ParticleTexID)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)

    Part = ffi.new("char[32*32*4]")
    for i=0,31 do

        local y = (i-16.0)/16.0
        for j=0,31 do

            local x = (j-16.0)/16.0

            local d = math.sqrt(x*x + y*y)
            if (d > 1.0) then d = 1.0 end

            d = 1.0 - math.pow(d, 2)

            Part[(i*32 + j)*4 + 0] = d*0xff;
            Part[(i*32 + j)*4 + 1] = d*0xff;
            Part[(i*32 + j)*4 + 2] = d*0xff;
            Part[(i*32 + j)*4 + 3] = d*0xff;
        end
    end
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, 32, 32, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, Part)
end

-- //********************************************************************************************************************
-- // cg init

--function cgInit( L, D)
--{
--    // setup cg
--    D->CgCtx = cgCreateContext();
--    cgGLSetDebugMode( CG_FALSE );
--    cgGLSetManageTextureParameters(D->CgCtx, CG_TRUE);
--    cgSetParameterSettingMode(D->CgCtx, CG_DEFERRED_PARAMETER_SETTING);
--
--    D->CgProfileVertex	= cgGLGetLatestProfile(CG_gl.GL_VERTEX);
--    D->CgProfileGeometry	= cgGLGetLatestProfile(CG_gl.GL_GEOMETRY);
--    D->CgProfileFragment	= cgGLGetLatestProfile(CG_gl.GL_FRAGMENT);
--
--    fAssert(D->CgProfileGeometry);
--
--    // secret magic make fast thing?
--    cgGLSetOptimalOptions(D->CgProfileVertex);
--    cgGLSetOptimalOptions(D->CgProfileGeometry);
--    cgGLSetOptimalOptions(D->CgProfileFragment);
--
--    cgGLEnableProfile(D->CgProfileVertex);
--    cgGLEnableProfile(D->CgProfileFragment);
--end

-- //********************************************************************************************************************
-- // setup cuda env
--function cudaInit( L, D)
--
--    CUDA_CHECK(cuInit(0));
--    ftrace("cuda init!\n");
--
--    // device caps
--    CUDA_CHECK(cuDeviceGet(&D->CUDev, 0));
--    for (int i=0; i < sizeof(s_Cap)/sizeof(cuDeviceCap_t); i++)
--    {
--    cuDeviceCap_t* C = &s_Cap[i];
--
--    int val = 0;
--    int ret = cuDeviceGetAttribute(&val, C->attrib, D->CUDev);
--    val = (ret == CUDA_SUCCESS) ? val : 0;
--
--    ftrace("	%05i : %s\n", val, C->str);
--    switch (C->attrib)
--    {
--    case CU_DEVICE_ATTRIBUTE_CLOCK_RATE:
--    D->cuGPUFreq = val*1000;
--    break;
--    }
--    }
--
--    s32 VersionMajor;
--    s32 VersionMinor;
--    CUDA_CHECK(cuDeviceComputeCapability(&VersionMajor, &VersionMinor, D->CUDev));
--    ftrace("	Compute %i.%i\n", VersionMajor, VersionMinor);
--
--    u32 memsize;
--    CUDA_CHECK(cuDeviceTotalMem(&memsize, D->CUDev));
--    ftrace("	cuda VRAM size %iMB\n", memsize/(1024*1024));
--
--    CUDA_CHECK(cuCtxCreate(&D->CUCtx, 0, D->CUDev));
--
--    // debug buffers
--
--    CUDA_CHECK(cuMemAlloc(&D->CUDebugVid[0],	1024*1024*16));
--    CUDA_CHECK(cuMemAlloc(&D->CUDebugVid[1],	1024*1024*16));
--    CUDA_CHECK(cuMemAlloc(&D->CUDebugVid[2],	1024*1024*16));
--    CUDA_CHECK(cuMemAlloc(&D->CUDebugVid[3],	1024*1024*64));
--
--    D->CUDebugSys[0]	= (u32*)malloc(1024*1024*64);
--    D->CUDebugSys[1]	= (u32*)malloc(1024*1024*16);
--
--    // cuda<->gl.gl interpo
--    cuGLInit();
--
--    return 1;
--end

-- //********************************************************************************************************************
-- // init all shaders

function shaderInit( D )

    -- // device shaders. these are the hardwired shaders for general rendering

    ftrace("Shaders\n")

    D.ShaderSimpleV         = Device_ShaderCompile(gl.GL_VERTEX_SHADER, colour_shader_vert, "colour_shader_vert")
    D.ShaderSimpleF         = Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, colour_shader_frag, "colour_shader_frag")

    -- // default geometry shader
    D.ShaderGeomV			=  Device_ShaderCompile(gl.GL_VERTEX_SHADER, sGeometryVertex_vert  ,"sGeometryVertex_vert" )
    D.ShaderGeomHeightMapV		=  Device_ShaderCompile(gl.GL_VERTEX_SHADER, sGeometryHeightMapVertex_vert  ,"sGeometryHeightMapVertex_vert" )
    D.ShaderGeomSkinV		=  Device_ShaderCompile(gl.GL_VERTEX_SHADER, sGeometrySkinVertex_vert  ,"sGeometrySkinVertex_vert" )
    D.ShaderGeomF			=  Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sGeometryFragment_frag  ,"sGeometryFragment_frag" )

    D.ShaderShadowV		=  Device_ShaderCompile(gl.GL_VERTEX_SHADER, sShadowVertex_vert  ,"sShadowVertex_vert" )
    D.ShaderShadowSkinV		=  Device_ShaderCompile(gl.GL_VERTEX_SHADER, sShadowSkinVertex_vert  ,"sShadowSkinVertex_vert" )
    D.ShaderShadowF		=  Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sShadowFragment_frag  ,"sShadowFragment_frag" )

    D.ShaderLightV			=  Device_ShaderCompile(gl.GL_VERTEX_SHADER,sLightVertex_vert  ,"sLightVertex_vert" )
    D.ShaderLightF			=  Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sLightFragment_frag  ,"sLightFragment_frag" )

--    D.ShaderCollisionV		=  Device_ShaderCompile(gl.GL_VERTEX_SHADER, sCollisionVertex_vert  ,"sCollisionVertex_vert" )
--    D.ShaderCollisionF		=  Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sCollisionFragment_frag  ,"sCollisionFragment_frag" )
--
--    D.ShaderCollisionNormalV	=  Device_ShaderCompile(gl.GL_VERTEX_SHADER, sCollisionNormalVertex_vert  ,"sCollisionNormalVertex_vert" )
--    D.ShaderCollisionNormalF	=  Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sCollisionNormalFragment_frag  ,"sCollisionNormalFragment_frag" )
--
--    D.ShaderCollisionRenderV 	=  Device_ShaderCompile(gl.GL_VERTEX_SHADER, sCollisionRenderVertex_vert  ,"sCollisionRenderVertex_vert" )
--    D.ShaderCollisionRenderF 	=  Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sCollisionRenderFragment_frag  ,"sCollisionRenderFragment_frag" )

    D.ShaderBloomV			=  Device_ShaderCompile(gl.GL_VERTEX_SHADER, sBloomVertex_vert  ,"sBloomVertex_vert" )
    D.ShaderBloomHorizF		=  Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sBloomFragment_frag  ,"sBloomFragment_frag" )
--    D.ShaderBloomVertF		=  Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sBloomFragment_frag  ,"sBloomFragment_frag" )

    D.ShaderResolveV		= Device_ShaderCompile(gl.GL_VERTEX_SHADER, sResolveVertex_vert  ,"sResolveVertex_vert" )
    D.ShaderResolveF		= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sResolveFragment_frag  ,"sResolveFragment_frag" )

    D.ShaderAAV			= Device_ShaderCompile(gl.GL_VERTEX_SHADER, sAAVertex_vert  ,"sAAVertex_vert" )
    D.ShaderAAF			= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sAAFragment_frag  ,"sAAFragment_frag" )

    D.ShaderTranslucentV		= Device_ShaderCompile(gl.GL_VERTEX_SHADER,	sTranslucentVertex_vert  ,"	sTranslucentVertex_vert" )
    D.ShaderTranslucentF		= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sTranslucentFragment_frag  ,"sTranslucentFragment_frag" )

    D.ShaderAmbientOcclusionV	= Device_ShaderCompile(gl.GL_VERTEX_SHADER,	sAmbientOcclusionVertex_vert  ,"	sAmbientOcclusionVertex_vert" )
    D.ShaderAmbientOcclusionF	= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sAmbientOcclusionFragment_frag  ,"sAmbientOcclusionFragment_frag" )
--    D.ShaderAmbientOcclusionBlurHF	= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sAmbientOcclusionFragment_frag  ,"sAmbientOcclusionFragment_frag" )
--    D.ShaderAmbientOcclusionBlurVF	= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sAmbientOcclusionFragment_frag  ,"sAmbientOcclusionFragment_frag" )
--    D.ShaderAmbientOcclusionResolveF= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sAmbientOcclusionFragment_frag  ,"sAmbientOcclusionFragment_frag" )

--    D.ShaderVoxelV			= Device_ShaderCompile(gl.GL_VERTEX_SHADER, 	sVoxelVertex_vert  ,"	sVoxelVertex_vert" )
--    D.ShaderVoxelG			= Device_ShaderCompile(D.CgProfileGeometry,	sVoxelGeom_gcg  ,"	sVoxelGeom_gcg" )
--    D.ShaderVoxelF			= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sVoxelFragment_frag  ,"sVoxelFragment_frag" )
--
--    D.ShaderVoxelMergeV		= Device_ShaderCompile(gl.GL_VERTEX_SHADER, 	sVoxelMergeVertex_vert  ,"	sVoxelMergeVertex_vert" )
--    D.ShaderVoxelMergeG		= Device_ShaderCompile(D.CgProfileGeometry,	sVoxelMergeGeom_gcg  ,"	sVoxelMergeGeom_gcg" )
--    D.ShaderVoxelMergeF		= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sVoxelMergeFragment_frag  ,"sVoxelMergeFragment_frag" )
--
--    D.ShaderVoxelMapV		= Device_ShaderCompile(gl.GL_VERTEX_SHADER, 	sVoxelMapVertex_vert  ,"	sVoxelMapVertex_vert" )
--    D.ShaderVoxelMapF		= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sVoxelMapFragment_frag  ,"sVoxelMapFragment_frag" )

    D.ShaderParticleRenderV	= Device_ShaderCompile(gl.GL_VERTEX_SHADER, 	sParticleRenderVertex_vert  ,"	sParticleRenderVertex_vert" )
    D.ShaderParticleRenderF	= Device_ShaderCompile(gl.GL_FRAGMENT_SHADER, sParticleRenderFragment_frag  ,"sParticleRenderFragment_frag" )

--    // cuda modules
--
--    //CUDA_CHECK(cuModuleLoadData(&D->CUModuleVoxel, &DeviceCuda(cVoxel)));
--    //CUDA_CHECK(cuModuleGetFunction(&D->CUModuleVoxel_BinZ,  D->CUModuleVoxel, "BinZ"));
--    //CUDA_CHECK(cuModuleGetFunction(&D->CUModuleVoxel_BinX,  D->CUModuleVoxel, "BinX"));
--    //CUDA_CHECK(cuModuleGetFunction(&D->CUModuleVoxel_BinY,  D->CUModuleVoxel, "BinY"));
--
--    //CUDA_CHECK(cuModuleLoadData(&D->CUModuleParticle, 		&DeviceCuda(cParticle)));
--    //CUDA_CHECK(cuModuleGetFunction(&D->CUModuleParticle_Update,	D->CUModuleParticle, "Update"));
--    //CUDA_CHECK(cuModuleGetFunction(&D->CUModuleParticle_Collision,	D->CUModuleParticle, "Collision"));
--    //CUDA_CHECK(cuModuleGetFunction(&D->CUModuleParticle_Force,	D->CUModuleParticle, "Force"));
--
--    // allocate array and copy image data
--    /*
--    CUarray cu_array;
--    CUDA_ARRAY_DESCRIPTOR desc;
--    desc.Format = CU_AD_FORMAT_UNSIGNED_INT32;
--    desc.NumChannels = 1;
--    desc.Width = 1024;
--    desc.Height = 1024;
--    CUDA_CHECK(cuArrayCreate( &D->CUMapArray, &desc ));
--
--    CUDA_CHECK(cuModuleGetTexRef(&D->CUTexMap, D->CUModuleVoxel, "MapInfo"));
--    CUDA_CHECK(cuTexRefSetArray(D->CUTexMap, D->CUMapArray, CU_TRSA_OVERRIDE_FORMAT));
--    //CUDA_CHECK(cuTexRefSetAddress	(0, D->CUTexMap, m_CUMap, sizeof(Info_t)*1024*1024));
--    CUDA_CHECK(cuTexRefSetFormat	(D->CUTexMap, CU_AD_FORMAT_FLOAT, 4));
--    CUDA_CHECK(cuTexRefSetFilterMode(D->CUTexMap, CU_TR_FILTER_MODE_POINT));
--    CUDA_CHECK(cuTexRefSetFlags	(D->CUTexMap, CU_TRSF_READ_AS_INTEGER));
--    */

--    // cg pisses over the signal handlers.. so restore
--    System_SigSegV();
end

-- //********************************************************************************************************************
-- // init a 3d rendering context

function lDevice_Create( L )

    D = ffi.new("fDevice_t")
    D.Magic = DEVICE_MAGIC

    -- // setup basic x11 bits
    -- fAssert(x11Init(L, D))
    fAssert(glSDLInit(L, D))

    -- // deafult gl.gl state
    glInit(L, D)

--    // cg init
--    cgInit(L, D);

-- Not needed for time being
--    // init cuda
--    //cudaInit(L, D);

    ftrace("Render Init\n")

    -- // defered buffers
    deferInit(L, D)

    -- // shadow buffer
    shadowInit(L, D)

-- One day this will go back in.
--    // voxels
--    voxelInit(L, D);

    -- // particles
    particleInit(L, D)

    -- // hmm
    gl.glDepthRangef(0.0, 1.0)

    -- // shaders
    shaderInit(D)

    return D
end

-- //********************************************************************************************************************

function lDevice_Flip(D, FrameLock)

    gl.glFinish()
    TempWindow.update()

    egl.eglSwapBuffers( Temp_eglInfo.dpy, Temp_eglInfo.surf )

    if(FrameLock) then

        if (D.FPS ~= 0) then

            local dt = 0.0
            repeat

                local t = os.clock()
                dt = t - m_LastFrameTS
            until (dt > 1.0 / D.FPS)
        end
    end

    local t = os.clock()

--    /*
--    local dt = t - m_LastFrameTS
--    count = 0
--    if (count > 20) then
--      count = 0;
--      dtrace("fps: %f dt:%f ms  render:%.2fms encode:%.2fms load: %f\n", 1/dt, dt*1e3, (FrameEndTS-m_LastFrameTS)*1e3, 0*1e3, (FrameEndTS-m_LastFrameTS)/dt);
--    end
--    count = count + 1
--    */
    m_LastFrameTS = t

    return 0
end

-- //********************************************************************************************************************

function lDevice_Stats(D)

    D = toDevice(D)
    local stats = {}

    local Total = D.TimeAccGeom
    Total = Total + D.TimeAccLight
    Total = Total + D.TimeAccShadow
    Total = Total + D.TimeAccBloom
    Total = Total + D.TimeAccParticle
    Total = Total + D.TimeAccRessolve

    local ooC = 1.0 / D.TimeAccCount
    if (D.TimeAccCount == 0.0) then ooC = 1.0 end

    stats.Geometry  =	D.TimeAccGeom * ooC
    stats.Light     =	D.TimeAccLight * ooC
    stats.Shadow    =	D.TimeAccShadow * ooC
    stats.Bloom     =	D.TimeAccBloom * ooC
    stats.Particle  =	D.TimeAccParticle * ooC
    stats.Ressolve  =	D.TimeAccRessolve * ooC
    stats.AA        =	D.TimeAccAA * ooC
    stats.AO        =	D.TimeAccAO * ooC
    stats.Post      = 	(D.TimeAccBloom + D.TimeAccParticle + D.TimeAccRessolve + D.TimeAccAA + D.TimeAccAO) * ooC
    stats.Read      = 	D.TimeAccRead * ooC
    stats.Total     = 	Total * ooC
    stats.Vertex    =  	D.VertexAcc
    stats.Tri       =  	D.TriAcc

    -- // reset
    D.TimeAccGeom		= 0
    D.TimeAccLight		= 0
    D.TimeAccShadow	    = 0
    D.TimeAccBloom 	    = 0
    D.TimeAccParticle	= 0
    D.TimeAccAA		    = 0
    D.TimeAccAO		    = 0
    D.TimeAccRessolve	= 0
    D.TimeAccRead		= 0
    D.TimeAccCount		= 0

    D.VertexAcc		= 0
    D.TriAcc		= 0

    return stats
end

-- //********************************************************************************************************************

--void fDevice_Register(lua_State* L)
--{
--lua_table_register(L, -1, "Device_Create", lDevice_Create);
--lua_table_register(L, -1, "Device_Flip", lDevice_Flip);
--lua_table_register(L, -1, "Device_Stats", lDevice_Stats);
--}
