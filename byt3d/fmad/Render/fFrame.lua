--
-- Created by David Lannan
-- User: grover
-- Date: 9/05/13
-- Time: 1:34 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local fDv = require("byt3d/fmad/Render/fDevice_h")
require("byt3d/fmad/Render/fMaterial_h")
require("byt3d/fmad/Render/fFrame_h")

local gl   = require( "ffi/OpenGLES2" )

-- //********************************************************************************************************************
-- // prviate structure

fFrame_t =  {
        Device  = nil,

        -- // target rez
        Width       = 1024,
        Height      = 768,
        Aspect      = 1.333,
        FPS         = 60,
        Scanout     = false,

        -- // clear color
        ClearEnable = false,
        ClearR      = 1.0,
        ClearG      = 0.0,
        ClearB      = 1.0,

        -- // camera object
        Camera      = nil,

        -- // light count
        LightCount  = 0,

        -- // shadow count
        ShadowCount = 0,

        -- // per frame draw lists
        -- //struct fSceneList_t*	DrawList;

        -- // frame material list
        MaterialList    = {},
        MaterialCount   = 0,
        MaterialMax     = MATERIAL_MAX,
        MaterialTex     = {},

        Readback        = nil,
        ReadbackSec     = 0.0,		-- // read back time for this frame

        Magic           = 0x0000,
}

-- //********************************************************************************************************************

FRAME_MAGIC 	= 0xbeef0008

-- //********************************************************************************************************************
-- // frame about to start

function lFrame_Begin( D )

    -- // get params
    local Device	= toDevice(D.Device)

    local Width		    = D.Width
    local Height		= D.Height
    local Aspect		= D.Aspect
    local Readback		= D.Readback
    local Scanout		= D.Scanout


    local ClearR		= D.ClearColor.r
    local ClearG		= D.ClearColor.g
    local ClearB		= D.ClearColor.b

    -- print( string.format("%f %f %f\n", ClearR, ClearG, ClearB) )
--    //dtrace("aspect %f\n", Aspect);

--    // get the camera
    local OL 	= D.ObjectList
    local Camera = fObjectList_CameraGet(OL)

    fObjectList_Verify(OL)

--    // create the lua userobject
    local F         = deepcopy(fFrame_t)

--    // render device
    F.Device		=  Device

--    // general stats
    F.Width		    = Width
    F.Height		= Height
    F.Aspect		= Aspect
    F.Scanout		= Scanout
    F.Readback		= Readback
    F.ReadbackSec		= 0

--    // clear
    F.ClearEnable		= true
    F.ClearR		= ClearR
    F.ClearG		= ClearG
    F.ClearB		= ClearB

--    // materials
    F.MaterialMax		= fDv.MATERIAL_MAX
    F.MaterialCount	    = 0
    F.MaterialTex       = {}
    F.MaterialList      = {}

--    // reset shadow and lights
    F.ShadowCount   = 0
    F.LightCount	= 0
    F.Camera		= Camera
    F.Magic		    = FRAME_MAGIC

--    // clear output buffer (so as not to encode previous render job)
--    /*
--    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fFrame_OutputFbID(F));
--    gl.glViewport(0, 0, Width, Height);
--    gl.glScissor(0, 0, Width, Height);
--
--    gl.glClearColor(1.0, 0.0, 0.0, 0.0);
--    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
--    */

--    // clear light buffer
--    // note: when the scene continas nothing (including no lights) then the light buffer
--    // will contain the previous scenes data, thus clear it here and not in lightbegin
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, Device.LBufFbID)

--    u32 buffers[] = { gl.GL_COLOR_ATTACHMENT0, gl.GL_COLOR_ATTACHMENT1};
--    gl.glDrawBuffers(2, buffers);

    gl.glViewport(0, 0, Width, Height)
    gl.glScissor( 0, 0, Width, Height)

    gl.glClearColor(0.0, 0.0, 0.0, 0.0)
    gl.glClear(gl.GL_COLOR_BUFFER_BIT)

    return F
end

-- //********************************************************************************************************************
-- // frame end, free any loose resources

function lFrame_End( F, S )

    F = toFrame(F)
    fAssert(F.Magic == FRAME_MAGIC)

    local D = fFrame_Device(F)
    F.MaterialCount = 0

--    // munge profile crap
    local tGeom		= 0
    local tShadow		= 0
    local tBloom		= 0
    local tAA		= 0
    local tAO		= 0
    local tParticle		= 0
    local tRessolve		= 0

--    // gather lights
--    local Light = 0
--    for i=0, F.LightCount-1 do
--
--        local tLight		= 0
--        gl.glGetQueryObjectiv(D.PerfQuery[PerfLight + i],	gl.GL_QUERY_RESULT, tLight)
--        Light = Light + tLight*(1.0/1e9)
--    end

--    local Shadow = 0
--    for i=0, F.ShadowCount-1 do
--        local tShadow		= 0
--        gl.glGetQueryObjectiv(D.PerfQuery[PerfShadow+i],	gl.GL_QUERY_RESULT, tShadow)
--        Shadow = Shadow + tShadow*(1.0/1e9)
--    end
--
--    gl.glGetQueryObjectiv(D->PerfQuery[PerfGeometry],		gl.GL_QUERY_RESULT, &tGeom);
--    gl.glGetQueryObjectiv(D->PerfQuery[PerfBloom],		gl.GL_QUERY_RESULT, &tBloom);
--    gl.glGetQueryObjectiv(D->PerfQuery[PerfParticle],		gl.GL_QUERY_RESULT, &tParticle);
--    gl.glGetQueryObjectiv(D->PerfQuery[PerfAA],		gl.GL_QUERY_RESULT, &tAA);
--    gl.glGetQueryObjectiv(D->PerfQuery[PerfAmbientOcclusion],	gl.GL_QUERY_RESULT, &tAO);
--    gl.glGetQueryObjectiv(D->PerfQuery[PerfRessolve],		gl.GL_QUERY_RESULT, &tRessolve);

--    // normalize to sec
--    local fGeom 			=  tGeom	*(1.0/1e9)
--    local fBloom 			=  tBloom	*(1.0/1e9)
--    local fParticle 		=  tParticle	*(1.0/1e9)
--    local fAA	 		=  tAA		*(1.0/1e9)
--    local fAO	 		=  tAO		*(1.0/1e9)
--    local fRessolve 		=  tRessolve	*(1.0/1e9)

--    D.TimeAccGeom		= D.TimeAccGeom + fGeom
--    D.TimeAccLight		= D.TimeAccLight + Light
--    D.TimeAccShadow	= D.TimeAccShadow + Shadow
--    D.TimeAccBloom		= D.TimeAccBloom + fBloom
--    D.TimeAccParticle	= D.TimeAccParticle + fParticle
--    D.TimeAccAA		= D.TimeAccAA + fAA
--    D.TimeAccAO		= D.TimeAccAO + fAO
--    D.TimeAccRessolve	= D.TimeAccRessolve + fRessolve
    D.TimeAccCount = D.TimeAccCount + 1

--    // update per scene stats
--    double TimeAccGeom	= lua_getfield_number(L, -1, "TimeAccGeom", 0.0)	+ fGeom;
--    double TimeAccLight	= lua_getfield_number(L, -1, "TimeAccLight", 0.0)	+ Light;
--    double TimeAccShadow	= lua_getfield_number(L, -1, "TimeAccShadow", 0.0)	+ Shadow;
--    double TimeAccBloom	= lua_getfield_number(L, -1, "TimeAccBloom", 0.0)	+ fBloom;
--    double TimeAccParticle	= lua_getfield_number(L, -1, "TimeAccParticle", 0.0)	+ fParticle;
--    double TimeAccAA	= lua_getfield_number(L, -1, "TimeAccAA", 0.0)		+ fAA;
--    double TimeAccAO	= lua_getfield_number(L, -1, "TimeAccAO", 0.0)		+ fAO;
--    double TimeAccRessolve	= lua_getfield_number(L, -1, "TimeAccRessolve", 0.0)	+ fRessolve;
--    double TimeAccRead	= lua_getfield_number(L, -1, "TimeAccRead", 0.0)	+ F->ReadbackSec;

--    S.TimeAccGeom		= S.TimeAccGeom + fGeom
--    S.TimeAccLight		= S.TimeAccLight + Light
--    S.TimeAccShadow	= S.TimeAccShadow + Shadow
--    S.TimeAccBloom		= S.TimeAccBloom + fBloom
--    S.TimeAccParticle	= S.TimeAccParticle + fParticle
--    S.TimeAccAA		= S.TimeAccAA + fAA
--    S.TimeAccAO		= S.TimeAccAO + fAO
--    S.TimeAccRessolve	= S.TimeAccRessolve + fRessolve
    S.TimeAccCount = S.TimeAccCount + 1

--    /*
--    double total = D->TimeAccGeom;
--    total += D->TimeAccLight;
--    total += D->TimeAccBloom;
--    total += D->TimeAccParticle;
--    total += D->TimeAccRessolve;
--
--    printf("%f %f %f %f\n",
--        D->TimeAccGeom/total,
--        D->TimeAccBloom/total,
--        D->TimeAccParticle/total,
--        D->TimeAccRessolve/total);
--
--    printf("geom    :  %08x\n", tGeom);
--    printf("light   : %08x\n", tLight);
--    printf("bloom   : %08x\n", tBloom);
--    printf("particle: %08x\n", tParticle);
--    printf("ressolve: %08x\n", tRessolve);
--    */

    return 0
end

--//********************************************************************************************************************

function lFrame_Collect( F )

    F = toFrame(F)

    F = deepcopy(fFrame_t)
    return 0
end

--//********************************************************************************************************************
--// add material to the list

function fFrame_MaterialAdd( F, Roughness, Attenuation, Ambient, pad1)

    -- // add to linked list
    local ID = F.MaterialCount
    local M = F.MaterialList[F.MaterialCount]
    F.MaterialCount = F.MaterialCount + 1
    fAssert(F.MaterialCount < F.MaterialMax)

    M.Roughness		= Roughness
    M.Attenuation	= Attenuation
    M.Ambient		= Ambient

    return ID
end

-- //********************************************************************************************************************
-- // build material texture

function fFrame_MaterialArray( F )

    for i=0, F.MaterialCount-1 do

        local M = F.MaterialList[i]

        F.MaterialTex[i*4 + 0] = M.Roughness
        F.MaterialTex[i*4 + 1] = M.Attenuation
        F.MaterialTex[i*4 + 2] = M.Ambient
        F.MaterialTex[i*4 + 3] = 0
        -- //printf("[%03i] %f %f\n", i, M->Roughness, M->Attenuation);
    end
    return F.MaterialTex
end

-- //********************************************************************************************************************

function fFrame_MaterialMax( F )

    return F.MaterialMax
end

-- //********************************************************************************************************************

function toFrame(F,  File, Line)

    fAssertFL(F ~= nil, File, Line)
    fAssertFL(F.Magic == FRAME_MAGIC, File, Line)

    return F
end

-- //********************************************************************************************************************

function fFrame_Width( F )

    return F.Width
end

function fFrame_Height( F )

    return F.Height
end

function fFrame_Aspect( F )

    return F.Aspect * F.Width / F.Height
end

function fFrame_Readback( F )

    return F.Readback
end

function fFrame_Device( F )

    return F.Device
end

function fFrame_OutputFbID( F )

    if (F.Scanout) then return 0 end
    return F.Device.OutputFbID
end

function fFrame_LightID( F )

    return F.LightCount
end

function fFrame_ShadowID( F )

    return F.ShadowCount
end

function fFrame_LightNext( F )

    fAssert(F.LightCount < F.Device.LightMax)
    F.LightCount = F.LightCount + 1
end

function fFrame_ShadowNext( F )

    fAssert(F.ShadowCount < F.Device.ShadowMax)
    F.ShadowCount = F.ShadowCount + 1
end

function fFrame_LightTotal( F )

    return F.LightCount
end

function fFrame_ShadowTotal( F )

    return F.ShadowCount
end

function fFrame_ClearColorR( F )

    return F.ClearR
end

function fFrame_ClearColorG( F )

    return F.ClearG
end

function fFrame_ClearColorB( F )

    return F.ClearB
end

-- //********************************************************************************************************************
-- // geometry projection matrix

function fFrame_ProjectionGet( F )

    if (F.Camera == nil) then return fMat44_Identity() end

    local C = F.Camera.Object
    fAssert(C)
    return C.Projection
end

function fFrame_iProjectionGet( F )

    if (F.Camera == NULL) then return fMat44_Identity() end

    local C = F.Camera.Object
    fAssert(C)
    return C.iProjection
end

-- //********************************************************************************************************************
-- // readback the device image

function lFrame_Readback( F )

    local F = toFrame( F )
    local D = fFrame_Device(F)

    if (F.Readback == nil) then

        ftrace("Frame_Readback: requested on frame with no readback enabled!\n")
        return 0
    end

    local sTime = os.clock()
    gl.glFinish()

    local sRead = os.clock()

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fFrame_OutputFbID(F))
    gl.glReadBuffer(gl.GL_COLOR_ATTACHMENT0)
    gl.glReadPixels(0, 0, F.Width, F.Height, gl.GL_BGRA, gl.GL_UNSIGNED_BYTE, D.ReadbackBuffer0)
    gl.glFinish()
    local eRead = os.clock()

--    // flip and flop wtf ? z axis wrong..
    for i=0, F.Height do

        local Dst = (F.Readback + (F.Height-i-1)*F.Width*4)
        local Src = (D.ReadbackBuffer0 + i*F.Width*4)
        Src = Src + F.Width - 1

        for j=0, F.Width do
            Dst[j] = Src[j];
        end

--        //memcpy(F->Readback + (F->Height-i-1)*F->Width*4, D->ReadbackBuffer0 + i*F->Width*4, F->Width*4);
--        //memcpy(F->Readback + i*F->Width*4, D->ReadbackBuffer0 + i*F->Width*4, F->Width*4);
    end

    local eTime = os.clock()
    D.TimeAccRead = D.TimeAccRead + (eTime - sTime)
    F.ReadbackSec = (eTime - sTime)

--    //dtrace("readbck %fms\n", (eRead-sRead)*1000);
    return L
end

-- //********************************************************************************************************************

function lFrame_toString(F)

    return "Frame object"
end

-- //********************************************************************************************************************

--function fFrame_Register(F)
--{
--// metatable
--luaL_newmetatable(L, "fFrame");
--lua_table_register(L, -1, "__gc",		lFrame_Collect);
--lua_table_register(L, -1, "__tostring",		lFrame_toString);
--lua_pop(L, 1);	// metatable
--
--// module methods
--lua_table_register(L, -1, "Frame_Begin",	lFrame_Begin);
--lua_table_register(L, -1, "Frame_End",		lFrame_End);
--lua_table_register(L, -1, "Frame_Readback",	lFrame_Readback);
--}
