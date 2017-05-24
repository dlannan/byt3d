--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 12:15 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

require("byt3d/fmad/Render/fLightDir_h")

--//********************************************************************************************************************
LIGHT_MAGIC	        = 0x11111111
--//********************************************************************************************************************

function tofLightDirEx(I, File, Line)

    fAssertFL(I, File, Line)
    fAssertFL(I.Magic == LIGHT_MAGIC, File, Line)
end

--//********************************************************************************************************************

function fLightDir_Packet( N, ObjectID, Data, Size, User)

    local RL	= ffi.cast("fRealizeLightDir_t*", Data)
    local R		= fRealize_SceneIDFind(RL.Header.SceneID)
    if (R == nil) then return end

--    // find object
    local OL	= fRealize_ObjectList(R)
    fAssert(OL)

    local O		= fObject_Get(OL, fObject_LightDir, RL.Header.NodeID, RL.Header.ObjectID)
    fAssert(O)

--    // new camera object
    local IPtr = O.Object
    if (IPtr == nil) then

        IPtr = ffi.new("fLightDir_t[1]")
        IPtr[0].Magic = LIGHT_MAGIC
        O.Object = IPtr
    end

--    // process the command
    if(RL.Header.CmdID == fRealizeCmdID_Update) then

--        // send ack of packet
        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack[0].NetID		= fMultiCast_ObjectID(N)
        Ack[0].NodeID		= RL.Header.NodeID
        Ack[0].ObjectID		= RL.Header.ObjectID
        Ack[0].CRC32		= RL.Header.CRC32
        Ack[0].PartPos		= RL.Header.PartPos
        Ack[0].PartTotal		= RL.Header.PartTotal

        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, AckPtr, ffi.sizeof(Ack))

--        // crc matches then dont waste cycles processing it
        if (O.CRC32 == RL.Header.CRC32) then

            return
        end
        O.CRC32 = RL.Header.CRC32

--        // copy fields
        I.ColorDiffuseR	= RL.ColorDiffuseR
        I.ColorDiffuseG	= RL.ColorDiffuseG
        I.ColorDiffuseB	= RL.ColorDiffuseB

        I.ColorSpecularR	= RL.ColorSpecularR
        I.ColorSpecularG	= RL.ColorSpecularG
        I.ColorSpecularB	= RL.ColorSpecularB

        I.PositionX		= RL.PositionX
        I.PositionY		= RL.PositionY
        I.PositionZ		= RL.PositionZ

        I.DirectionX		= RL.DirectionX
        I.DirectionY		= RL.DirectionY
        I.DirectionZ		= RL.DirectionZ

        I.Intensity		= RL.Intensity
        I.Falloff0		= RL.Falloff0
        I.Falloff1		= RL.Falloff1
        I.Falloff2		= RL.Falloff2

        I.ShadowMapBias	    = RL.ShadowMapBias
        I.ShadowEnable		= RL.ShadowEnable

        I.View			= RL.View
        I.iView		    = RL.iView

        I.Projection		= RL.Projection
        I.iProjection		= RL.iProjection

    elseif(RL.Header.CmdID == fRealizeCmdID_Collect) then

        printf("collect light\n")
        --        // send ack of packet
        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack.NetID		= fMultiCast_ObjectID(N)
        Ack.NodeID		= RL.Header.NodeID
        Ack.ObjectID		= RL.Header.ObjectID
        Ack.CRC32		= RL.Header.CRC32
        Ack.PartPos		= RL.Header.PartPos
        Ack.PartTotal		= RL.Header.PartTotal

        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, AckPtr, ffi.sizeof(Ack))
    end
end

--//********************************************************************************************************************
--// render singl.e directional lights & merge shadow buffer (if required)

function lLightDir_Render(IO, OL, F)

    F	= toFrame(F)
    local D	= fFrame_Device(F)
    OL = toObjectList(OL)

--    // xform . ref
    local OX		= toObject(IO)

--    // ref . light
    local O		= OX.Object
    fAssert(O)

    local I = ffi.cast("fLightDir_t *", O.Object)
    fAssert(I ~= nil)

--    // update reference to light
    O.FrameCount		= fObjectList_FrameNo(OL)

--    // camera
    local OC = fObjectList_CameraGet(OL)
    if (OC == nil) then return 0 end

    local C = OC.Object
    fAssert(C)

    local fWidth = fFrame_Width(F)
    local  fHeight = fFrame_Height(F)

    local DtoF_Width  = fWidth/ D.RtWidth
    local DtoF_Height = fHeight/D.RtHeight

--    // shadow map adujstment (-1, 1) . (0, 1)
    local ShadowAdjust
    ShadowAdjust.m00 = 0.5
    ShadowAdjust.m01 = 0.0
    ShadowAdjust.m02 = 0.0
    ShadowAdjust.m03 = 0.5

    ShadowAdjust.m10 = 0.0
    ShadowAdjust.m11 = 0.5
    ShadowAdjust.m12 = 0.0
    ShadowAdjust.m13 = 0.5

    ShadowAdjust.m20 = 0.0
    ShadowAdjust.m21 = 0.0
    ShadowAdjust.m22 = 1.0
    ShadowAdjust.m23 = 0.0

    ShadowAdjust.m30 = 0.0
    ShadowAdjust.m31 = 0.0
    ShadowAdjust.m32 = 0.0
    ShadowAdjust.m33 = 1.0

--    CHECK_CG(cgGLBindProgram(D.ShaderLightV))
--    CHECK_CG(cgGLBindProgram(D.ShaderLightF))

--    // light space . view space
    local World2View = fMat44_Mul(C.View, C.iLocal2World)
    local Light2View = fMat44_Mul(World2View, OX.Local2World)

--    // light in view space (position in light space, not light view space)
    local PLx = I.PositionX
    local PLy = I.PositionY
    local PLz = I.PositionZ

    local PVx = PLx*Light2View.m00 + PLy*Light2View.m01 + PLz*Light2View.m02 + Light2View.m03
    local PVy = PLx*Light2View.m10 + PLy*Light2View.m11 + PLz*Light2View.m12 + Light2View.m13
    local PVz = PLx*Light2View.m20 + PLy*Light2View.m21 + PLz*Light2View.m22 + Light2View.m23

--    // direction into view space
    local DVx = Light2View.m00*I.DirectionX + Light2View.m01*I.DirectionY + Light2View.m02*I.DirectionZ
    local DVy = Light2View.m10*I.DirectionX + Light2View.m11*I.DirectionY + Light2View.m12*I.DirectionZ
    local DVz = Light2View.m20*I.DirectionX + Light2View.m21*I.DirectionY + Light2View.m22*I.DirectionZ

--    // view . world
    local View2World = fMat44_Mul(C.Local2World, C.iView)

--    // shadow proj matrix
    local Camera2Light = fMat44_Mul(OX.iLocal2World, View2World)
    local ShadowViewProj0 = fMat44_Mul(I.Projection, fMat44_Mul(I.View, Camera2Light))

--    // remap (-1, 1) . (0, 1)
    local ShadowViewProj = fMat44_Mul(ShadowAdjust, ShadowViewProj0)

--    /*
--    fMat44_dtrace(&OX.iLocal2World, "il2w")
--    fMat44_dtrace(&OX.Local2World, "l2w")
--    fMat44_dtrace(&Camera2Light, "C2L")
--    fMat44_dtrace(&I.iProjection, "iShadowProj")
--    fMat44_dtrace(&ShadowViewProj, "Shadow")
--    */

    local	pLightColorDiffuse	= cgGetNamedParameter(D.ShaderLightF, "LightColorDiffuse")
    local	pLightColorSpecular	= cgGetNamedParameter(D.ShaderLightF, "LightColorSpecular")
    local	pLightPos		    = cgGetNamedParameter(D.ShaderLightF, "LightPos")
    local	pLightDir		    = cgGetNamedParameter(D.ShaderLightF, "LightDir")
    local	pShadowEnable		= cgGetNamedParameter(D.ShaderLightF, "ShadowEnable")
    local	pShadowProj		    = cgGetNamedParameter(D.ShaderLightF, "ShadowXForm")
    local	pShadowBias		    = cgGetNamedParameter(D.ShaderLightF, "ShadowBias")
    local	pShadowDelta		= cgGetNamedParameter(D.ShaderLightF, "ShadowDelta")

    local	pLightIntensity		= cgGetNamedParameter(D.ShaderLightF, "LightIntensity")
    local	pFalloff		    = cgGetNamedParameter(D.ShaderLightF, "Falloff")


--    CHECK_CG(cgSetMatrixParameterfr(pShadowProj, (float *)&ShadowViewProj))
--
--
--    CHECK_CG(cgSetParameter3f(pLightPos, PVx, PVy, PVz))
--    CHECK_CG(cgSetParameter3f(pLightDir, DVx, DVy, DVz))
--    CHECK_CG(cgSetParameter3f(pLightColorDiffuse, I.ColorDiffuseR, I.ColorDiffuseG, I.ColorDiffuseB))
--    CHECK_CG(cgSetParameter3f(pLightColorSpecular, I.ColorSpecularR, I.ColorSpecularG, I.ColorSpecularB))
--
--    CHECK_CG(cgSetParameter1f(pLightIntensity, I.Intensity))
--    CHECK_CG(cgSetParameter3f(pFalloff, I.Falloff0, I.Falloff1, I.Falloff2))
--
--    CHECK_CG(cgSetParameter1i(pShadowEnable, I.ShadowEnable))
--    CHECK_CG(cgSetParameter1f(pShadowBias, I.ShadowMapBias))
--    CHECK_CG(cgSetParameter2f(pShadowDelta, 1.0f / 512.0, 1.0f/512.0))

    local	GBuffer0 = cgGetNamedParameter(D.ShaderLightF, "samplerGBuffer0")
    local	GBuffer1 = cgGetNamedParameter(D.ShaderLightF, "samplerGBuffer1")
    local	GBuffer2 = cgGetNamedParameter(D.ShaderLightF, "samplerGBuffer2")
    local	GBuffer3 = cgGetNamedParameter(D.ShaderLightF, "samplerGBuffer3")

    local	Material	= cgGetNamedParameter(D.ShaderLightF, "samplerMaterial")
    local	ShadowMap	= cgGetNamedParameter(D.ShaderLightF, "samplerShadowMap")

    setTextureParamter(GBuffer0, D.GBufTexID[0])
    setTextureParamter(GBuffer1, D.GBufTexID[1])
    setTextureParamter(GBuffer2, D.GBufTexID[2])
    setTextureParamter(GBuffer3, D.GBufTexID[3])

    setTextureParamter(Material, D.MaterialTexID)
    setTextureParamter(ShadowMap, D.ShadowTexID)

    fAssert(D.ShaderLightV ~= nil)
    fAssert(D.ShaderLightF ~= nil)

--    CHECK_CG(cgUpdateProgramParameters(D.ShaderLightV))
--    CHECK_CG(cgUpdateProgramParameters(D.ShaderLightF))

    gl.Viewport(0, 0, fWidth, fHeight)
    gl.Disable(gl.GL_DEPTH_TEST)

--    // addative blend
    gl.Enable(gl.GL_BLEND)
    gl.BlendFunc(gl.GL_ONE, gl.GL_ONE)

--    // use a projection!
    gl.Color4f(1.0, 1.0, 1.0, 1.0)
    gl.Begin(gl.GL_TRIANGLE_STRIP)

    gl.TexCoord2f(0.0*DtoF_Width, 0.0*DtoF_Height); gl.Vertex3f(-1.0, -1.0, 0.0)
    gl.TexCoord2f(1.0*DtoF_Width, 0.0*DtoF_Height); gl.Vertex3f( 1.0, -1.0, 0.0)
    gl.TexCoord2f(0.0*DtoF_Width, 1.0*DtoF_Height); gl.Vertex3f(-1.0,  1.0, 0.0)
    gl.TexCoord2f(1.0*DtoF_Width, 1.0*DtoF_Height); gl.Vertex3f( 1.0,  1.0, 0.0)

    gl.End()
    gl.Disable(gl.GL_BLEND)

--    #if 0
--    gl.Finish()
--    //memset(D.ReadbackBuffer0, 0xFF, 300*240*16)
--
--    gl.ReadBuffer(gl.GL_COLOR_ATTACHMENT0_EXT)
--    gl.ReadPixels(0, 0, D.Width, D.Height, gl.GL_RGBA, gl.GL_FLOAT, D.ReadbackBuffer0)
--    gl.Finish()
--    float* p = D.ReadbackBuffer0
--
--    /*
--    for (int i=0 i < 300 i++)
--    {
--    printf("V%03i : %f %f %f %f\n", i,
--    p[(240*i + 120)*4+ 0],
--    p[(240*i + 120)*4+ 1],
--    p[(240*i + 120)*4+ 2],
--    p[(240*i + 120)*4+ 3])
--    }
--    for (int i=0 i < 240 i++)
--    {
--    printf("H%03i : %f %f %f %f\n", i,
--    p[(240*150 + i)*4+ 0],
--    p[(240*150 + i)*4+ 1],
--    p[(240*150 + i)*4+ 2],
--    p[(240*150 + i)*4+ 3])
--    }
--    */
--    printf("H%03i : %f %f %f %f\n", 120,
--    p[(240*50 + 120)*4+ 0],
--    p[(240*50 + 120)*4+ 1],
--    p[(240*50 + 120)*4+ 2],
--    p[(240*50 + 120)*4+ 3])
--
--    #endif

    return 0
end

--//********************************************************************************************************************

function lLightDir_ShadowEnable(OX)

--    // xform . ref
    OX		= toObject(OX)

--    // ref . light
    local O		= OX.Object
    fAssert(O)

    local I = ffi.cast("fLightDir_t*", O.Object)
    if (I == nil) then

        return false
    end
    return I.ShadowEnable
end

--//********************************************************************************************************************

function fLightDir_Destroy( O)

    local I = ffi.cast("fLightDir_t*", O.Object)
    fAssert(I ~= nil)

    ffi.fill(I, ffi.sizeof("fLightDir_t"), 0)
    fFree(I)
end

--//********************************************************************************************************************
--
--int fLightDir_Register(lua_State* L)
--{
--lua_table_register(L, -1, "LightDir_Render",		lLightDir_Render)
--lua_table_register(L, -1, "LightDir_ShadowEnable",	lLightDir_ShadowEnable)
--return 0
--}

