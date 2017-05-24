--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 12:11 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--
----********************************************************************************************************************

require("byt3d/fmad/Render/fMaterial_h")

----********************************************************************************************************************

s_Default = nil   -- Default static material

----********************************************************************************************************************

function fMaterial_Packet( N, ObjectID, Data, Size, User)

    local RM = ffi.cast("fRealizeMaterial_t*", Data)
    local R	= fRealize_SceneIDFind(RM.Header.SceneID)
    if (R == nil) then return end

--    -- find object
    local OL	= fRealize_ObjectList(R)
    fAssert(OL)

--    -- get/make object
    local O		= fObject_Get(OL, fObject_Material, RM.Header.NodeID, RM.Header.ObjectID)
    fAssert(O)
--    -- new camera object
    local MPtr = ffi.cast("fMaterial_t*", O.Object)
    if (MPtr == nil) then
        MPtr = ffi.new("fMaterial_t[1]")
        O.Object = MPtr
    end
    local M = MPtr[0]

    if(RM.Header.CmdID == fRealizeCmdID_Update) then

--            -- send ack of packet
        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack.NetID	    = fMultiCast_ObjectID(N)
        Ack.NodeID	    = RM.Header.NodeID
        Ack.ObjectID	= RM.Header.ObjectID
        Ack.CRC32	    = RM.Header.CRC32
        Ack.PartPos	    = RM.Header.PartPos
        Ack.PartTotal	= RM.Header.PartTotal

        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, AckPtr, ffi.sizeof(Ack))

--            -- crc matches then dont waste cycles processing it
        if (O.CRC32 == RM.Header.CRC32) then

            return
        end
        O.CRC32 = RM.Header.CRC32

--            -- copy data
        M.TextureEnable		        = RM.TextureEnable
        M.TextureDiffuseObjectID	= RM.MapDiffuseObjectID
        M.TextureEnvObjectID		= RM.MapEnvObjectID

        M.Roughness			    = RM.Roughness
        M.Attenuation			= RM.Attenuation
        M.Ambient			    = RM.Ambient

        M.Translucent			= RM.Translucent
        M.Opacity			    = RM.Opacity

        M.DiffuseR			= RM.DiffuseR
        M.DiffuseG			= RM.DiffuseG
        M.DiffuseB			= RM.DiffuseB
--            --printf("material update %08x: %08x %08x diffuse %f %f %f : kR:%f kA:%f kD:%f\n", M, O.NodeID, O.ObjectID, M.DiffuseR, M.DiffuseG, M.DiffuseB, M.Roughness, M.Attenuation, M.Ambient)

    elseif(RM.Header.CmdID == fRealizeCmdID_Collect) then
        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack.NetID	= fMultiCast_ObjectID(N)
        Ack.NodeID	= RM.Header.NodeID
        Ack.ObjectID	= RM.Header.ObjectID
        Ack.CRC32	= RM.Header.CRC32
        Ack.PartPos	= RM.Header.PartPos
        Ack.PartTotal	= RM.Header.PartTotal

        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, AckPtr, ffi.sizeof(Ack))
    end
end

----********************************************************************************************************************

function fMaterial_Default()

    return s_Default
end

----********************************************************************************************************************

function fMaterial_Destroy( O)

    local MPtr = ffi.cast("fMaterial_t*", O.Object)
    fAssert(MPtr)

    ffi.fill(MPtr, ffi.sizeof("fMaterial_t"), 0)
    fFree(MPtr)
end

--********************************************************************************************************************
-- searchs for a material id

function fMaterial_Find( OL, MaterialID )

    local ListPtr = fObjectList_MaterialList(OL)
    fAssert(ListPtr)

    -- if (MaterialID == 0) then return fMaterial_Default() end
    local ocount = 0
    while (ListPtr[ocount] ~= nil) do

        local MtlPtr = ListPtr[ocount]
        local Mtl = MtlPtr[0]

        ftrace("found %08x %08x\n", Mtl.ObjectID, MaterialID)
        if (Mtl.ObjectID == MaterialID) then

            fAssert(Mtl.Object)
            -- update reference
            ListPtr[ocount].FrameCount = fObjectList_FrameNo(OL)

            return Mtl
        end

        ocount = ocount + 1
    end

    --printf("default material\n")
    return nil
end

--********************************************************************************************************************
--int	fMaterial_Register(lua_State* L)
--{
---- set default material
--s_Default.TextureEnable = false
--s_Default.Roughness	= 0.5
--s_Default.Attenuation	= 0.5
--s_Default.Ambient	= 0.3
--
--s_Default.DiffuseR	= 1.0
--s_Default.DiffuseG	= 1.0
--s_Default.DiffuseB	= 1.0
--
--return 0
--}
