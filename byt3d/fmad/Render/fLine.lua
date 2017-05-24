--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 12:20 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--
--//********************************************************************************************************************

require("byt3d/fmad/Render/fLine_h")

local gl   = require( "ffi/OpenGLES2" )

--//********************************************************************************************************************

LINELIST_MAGIC	    = 0x1234beef

--//********************************************************************************************************************

function fLine_Packet( N, ObjectID, Data, Size, User)

    local RL 	= ffi.cast("fRealizeLine_t *", Data)
    local R	    = fRealize_SceneIDFind(RL.Header.SceneID)
    if (R == nil) then return end

--    // find object
    local OL = fRealize_ObjectList(R)
    fAssert(OL)

--    // get/make object
    local O		= fObject_Get(OL, fObject_Line, RL.Header.NodeID, RL.Header.ObjectID)
    fAssert(O)

    local LPtr = O.Object
    if (LPtr == nil) then

        LPtr = ffi.new("fLine_t[1]")
        ffi.fill(LPtr, ffi.sizeof("fLine_t"), 0)
        LPtr[0].Magic = LINELIST_MAGIC
        O.Object = LPtr
    end

    local L = LPtr[0]
--    // build the packets
    if(RL.Header.CmdID == fRealizeCmdID_Update) then

        if (L.VertexCount ~= RL.TotalCount) then

            if (L.VertexList) then

                fFree(L.VertexList)
            end

            L.VertexCount = RL.TotalCount
            L.VertexList = ffi.new("float["..(L.VertexCount*3).."]")

            L.PacketCount = (1+L.VertexCount/fRealizeLineCount)
            L.PacketCRC = ffi.new("u32["..L.PacketCount.."]")
        end

--        // copy
        fAssert(RL.ListOffset < L.VertexCount)
        ffi.fill(L.VertexList[RL.ListOffset*3], RL.ListCount*ffi.sizeof("float[3]"), RL.List)

--        // color
        L.ColorR	= RL.ColorR
        L.ColorG	= RL.ColorG
        L.ColorB	= RL.ColorB

        L.DepthTest	= RL.DepthTest

--        // generate new crc
        L.PacketCRC[RL.Header.PartPos] = RL.Header.CRC32
    end

--    // online flag
    local temp = false
    if (L.FinalCRC == RL.FinalCRC) then temp = L.Online end
    L.Online =  temp

--    // acc crc
    if (L.PacketCRC) then

        L.FinalCRC = 0
        for i=0, L.PacketCount-1 do

            L.FinalCRC = L.FinalCRC + L.PacketCRC[i]
        end

        L.FinalCRC = L.FinalCRC + AsU32(L.ColorR)
        L.FinalCRC = L.FinalCRC + AsU32(L.ColorG)
        L.FinalCRC = L.FinalCRC + AsU32(L.ColorB)
        L.FinalCRC = L.FinalCRC + L.DepthTest

--        // send ack
        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack.NetID	= fMultiCast_ObjectID(N)
        Ack.NodeID	= RL.Header.NodeID
        Ack.ObjectID	= RL.Header.ObjectID
        Ack.CRC32	= L.FinalCRC
        Ack.PartPos	= 0
        Ack.PartTotal	= 0

        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, AckPtr, ffi.sizeof(Ack))
    end

--    // all data is recevied
    if ((L.FinalCRC == RL.FinalCRC) and (L.Online == false) ) then

        L.Online = true

        if (L.VertexVBO) then

            gl.glDeleteBuffers(1, L.VertexVBO)
            L.VertexVBO = 0
        end

--        // generate GL resources
        gl.glGenBuffers(1, L.VertexVBO)

        fAssert(L.VertexVBO)
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, L.VertexVBO)
        gl.glBufferData(gl.GL_ARRAY_BUFFER, L.VertexCount*ffi.sizeof("float")*3, L.VertexList, gl.GL_STATIC_READ)
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)

--        // its online
        L.Online 	= true
    end
end

--//********************************************************************************************************************
--// render linez

function lLine_Render( L )

    local FPtr = L.Frame
    local F = FPtr[0]
    local D = fFrame_Device(F)

    local OLPtr = toObjectList(L.ObjectList)
    local OL = OLPtr[0]
    local Mode = L.Mode

--    // get default shaders
    local ShaderVertexDefault = nil
    local ShaderFragmentDefault = nil

    if (Mode == "GEOMETRY") then
--        // geom buffer
        ShaderVertexDefault	= D.ShaderGeomV;
        ShaderFragmentDefault	= D.ShaderGeomF;
    end

--    // calc camera info
    local World2ViewProj, View2World, iView2World
    if (Mode == "GEOMETRY") then

        local OCPtr = fObjectList_CameraGet(OLPtr)
        local OC = OCPtr[0]
        if (OC == nil) then

--            //ftrace("no camera object\n");
            return 0
        end

        local C = ffi.cast("fCamera_t *", OC.Object)
        fAssert(C)

--        // full world.camera xform
        local temp =  fMat44_Mul(C.View, C.iLocal2World)
        World2ViewProj	= fMat44_Mul(C.Projection, temp)
        View2World	    = fMat44_Mul(C.Local2World, C.iView)
        iView2World	    = fMat44_Mul(C.View, C.iLocal2World)
    end

    gl.glEnableVertexAttribArray(0)

    local OList= fObjectList_LineList(OL)
    local ocount = 0
    while (OList[0] ~= nil) do

--        // xform
        local OX = OList[ocount]
        fAssert(OX)
        ocount = ocount + 1

--        // reference mesh object
        local OM = OX.Object
        fAssert(OM)

--        // actuall mesh object
        local L = OM.Object
        fAssert(L)
        fAssert(L.Magic == LINELIST_MAGIC)

--        // mesh is fully loaded ?
        if (not L.Online) then

            -- //dtrace("%08x mesh not online\n", M);
            -- continue;
        end

--        // calc xforms

        local L2V = fMat44_Mul(iView2World, OX.Local2World)
        local L2W = OX.Local2World
        local W2L = OX.iLocal2World
        local L2P = fMat44_Mul(World2ViewProj, OX.Local2World)

--        // shaders are all standard
        local ShaderVertex   = ShaderVertexDefault
        local ShaderFragment = ShaderFragmentDefault

        fAssert(ShaderVertex	~= nil)
        fAssert(ShaderFragment	~= nil)

--        // updates the xforms
        fShader_SetXForm(ShaderVertex, "modelViewProj",	L2P)
        fShader_SetXForm(ShaderVertex, "Local2World",	OX.Local2World)
        fShader_SetXForm(ShaderVertex, "iLocal2World",	OX.iLocal2World)
        fShader_SetXForm(ShaderVertex, "Local2View",	L2V)

--        // tmap Enabled
        fShader_SetParam1i(ShaderFragment, "enableTexture", 0)

--        // diffuse color
        fShader_SetParam3f(ShaderFragment, "diffuseColor", L.ColorR, L.ColorG, L.ColorB)

        local MaterialID = fFrame_MaterialAdd(F, 0, 0, 1.0, 0)
        fShader_SetParam1i(ShaderFragment, "MaterialID", MaterialID)

--        // update to device
        CHECK_CG(gl.glUseProgram(ShaderVertex))
        CHECK_CG(gl.glUseProgram(ShaderFragment))

--        // set it
--        CHECK_CG(cgUpdateProgramParameters(ShaderVertex));
--        CHECK_CG(cgUpdateProgramParameters(ShaderFragment));

--        // overlay or not
        if (L.DepthTest) then
            gl.glEnable(gl.GL_DEPTH_TEST)
        else
            gl.glDisable(gl.GL_DEPTH_TEST)
        end

--        // queue the mesh
        fAssert(L.VertexVBO ~= 0)

        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, L.VertexVBO)
        gl.glVertexAttribPointer(0, 3,	gl.GL_FLOAT, 		false, ffi.sizeof("float")*3, nil)
        gl.glDrawArrays(gl.GL_LINE_STRIP, 0, L.VertexCount)
    end

    gl.glDisableVertexAttribArray(0)
    gl.glEnable(gl.GL_DEPTH_TEST)

    return 0
end

--//********************************************************************************************************************

function fLine_Destroy( O )

    local L = O.Object
    fAssert(L)

    if (L.PacketCRC) then

        fFree(L.PacketCRC)
        L.PacketCRC = nil
    end

    if (L.VertexList) then

        fFree(L.VertexList);
        L.VertexList = nil
    end

    if (L.VertexVBO) then

        gl.glDeleteBuffers(1, L.VertexVBO)
        L.VertexVBO = 0
    end

    ffi.fill(L, ffi.sizeof("fLine_t"), 0)
    fFree(L)
end

--//********************************************************************************************************************

--int fLine_Register(lua_State* L)
--{
--    lua_table_register(L, -1, "Line_Render",		lLine_Render);
--    return 0;
--}
