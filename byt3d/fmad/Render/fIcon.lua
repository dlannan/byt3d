--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 7:31 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

require("byt3d/fmad/Render/fIcon_t")

-- //********************************************************************************************************************

ICON_MAGIC	= 0x1284beef

-- //********************************************************************************************************************

function fIcon_Packet( N, ObjectID, Data, Size, User)

    local H 	= ffi.cast("fRealizeHeader_t*", Data)
    local R		= fRealize_SceneIDFind(H.SceneID)
    if (R == nil) then return end

    -- // find object
    local OL	= fRealize_ObjectList(R)
    fAssert(OL)

    -- // get/make object
    local O		= fObject_Get(OL, fObject_Icon, H.NodeID, H.ObjectID)
    fAssert(O)

    -- // allocaet tri mesh
    local PPtr = ffi.cast("fIcon_t*", O.Object)
    if (PPtr == nil) then

        local PPtr = ffi.new("fIcon_t[1]")
        ffi.fill(PPtr, ffi.sizeof("fIcon_t"), 0)

        PPtr[0].Magic = ICON_MAGIC
        O.Object = PPtr
    end

    -- // send ack
        -- // header is use to key if entire object is dirty or not. so send the current crc state
        -- // not the final state
    if(H.CmdID == fRealizeCmdID_Update) then

        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack.NetID	= fMultiCast_ObjectID(N)
        Ack.NodeID	= H.NodeID
        Ack.ObjectID	= H.ObjectID
        Ack.CRC32	= H.CRC32
        Ack.PartPos	= H.PartPos
        Ack.PartTotal	= H.PartTotal
        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, Ack, ffi.sizeof(Ack))
    end

    -- // crc matches then dont waste cycles processing it
    if (O.CRC32 == H.CRC32) then

        return
    end

    -- // process it
    if (H.CmdID == fRealizeCmdID_Update) then
        local RP = ffi.cast("fRealizeIcon_t*", Data)

        P.MaterialID 	= RP.MaterialID
        P.DiffuseID 	= RP.DiffuseTextureID

        P.Ox 		= RP.Ox
        P.Oy 		= RP.Oy
        P.Oz 		= RP.Oz

        P.Tx 		= RP.Tx
        P.Ty 		= RP.Ty
        P.Tz 		= RP.Tz

        P.MinX 	= RP.MinX
        P.MinY 	= RP.MinY
        P.MinZ 	= RP.MinZ

        P.MaxX 	= RP.MaxX
        P.MaxY 	= RP.MaxY
        P.MaxZ 	= RP.MaxZ

        strncpy(P.Name, RP.Name, sizeof(P.Name))
        strncpy(P.Desc, RP.Desc, sizeof(P.Desc))

        P.Online	= true
    end
end

-- //********************************************************************************************************************
-- // extract icons into lua struct
function lIcon_Frame( L)

    local F = toFrame(L.Frame)
    local D = fFrame_Device(F)
    local OL = toObjectList(L.ObjectList)

    -- // list of icons
    Icons = {}

    -- // calc camera info
    local World2ViewProj, View2World, iView2World
    local OC = fObjectList_CameraGet(OL)
    if (OC == nil) then

        -- //ftrace("no camera object\n")
        return 1
    end

    local C = OC.Object
    fAssert(C)

    -- // full world.camera xform
    World2ViewProj	= fMat44_Mul(C.Projection, fMat44_Mul(C.View, C.iLocal2World))
    View2World	= fMat44_Mul(C.Local2World, C.iView)
    iView2World	= fMat44_Mul(C.View, C.iLocal2World)

    local IconCount = 0

    -- // iterate on all icons
    local OList= fObjectList_IconList(OL)
    local ocount = 0
    while (OList[0] ~= nil) do

        -- // xform
        local OX = OList[ocount]
        fAssert(OX)
        ocount = ocount + 1

        -- // reference mesh object
        local OM = OX.Object
        fAssert(OM)

        -- // actuall mesh object
        local PPtr = ffi.new("fIcon_t* ", OM.Object)
        fAssert(PPtr)
        local P = PPtr[0]
        fAssert(P.Magic == ICON_MAGIC)

        -- // mesh is fully loaded ?
        if (P.Online == nil) then

            dtrace("%08x point not online\n", P)
    --        continue
        end

        -- // proj xform
        local L2P = fMat44_Mul(World2ViewProj, OX.Local2World)

        -- // behind the camera
        if (L2P.m23 < 0) then print "continue" end

        -- // tip location
        local pTx = L2P.m00*P.Tx + L2P.m01*P.Ty + L2P.m02*P.Tz + L2P.m03
        local pTy = L2P.m10*P.Tx + L2P.m11*P.Ty + L2P.m12*P.Tz + L2P.m13
        local pTz = L2P.m20*P.Tx + L2P.m21*P.Ty + L2P.m22*P.Tz + L2P.m23
        local pTw = L2P.m30*P.Tx + L2P.m31*P.Ty + L2P.m32*P.Tz + L2P.m33

        local sTx = 0.5*(1.0+(pTx / pTw))
        local sTy = 0.5*(1.0-(pTy / pTw))

        -- // icon aabb
        local pB0x = L2P.m00*P.MinX + L2P.m01*P.MinY + L2P.m02*P.MinZ + L2P.m03
        local pB0y = L2P.m10*P.MinX + L2P.m11*P.MinY + L2P.m12*P.MinZ + L2P.m13
        local pB0z = L2P.m20*P.MinX + L2P.m21*P.MinY + L2P.m22*P.MinZ + L2P.m23
        local pB0w = L2P.m30*P.MinX + L2P.m31*P.MinY + L2P.m32*P.MinZ + L2P.m33

        local sB0x = 0.5*(1.0 + (pB0x / pB0w))
        local sB0y = 0.5*(1.0 - (pB0y / pB0w))

        local pB1x = L2P.m00*P.MaxX + L2P.m01*P.MaxY + L2P.m02*P.MaxZ + L2P.m03
        local pB1y = L2P.m10*P.MaxX + L2P.m11*P.MaxY + L2P.m12*P.MaxZ + L2P.m13
        local pB1z = L2P.m20*P.MaxX + L2P.m21*P.MaxY + L2P.m22*P.MaxZ + L2P.m23
        local pB1w = L2P.m30*P.MaxX + L2P.m31*P.MaxY + L2P.m32*P.MaxZ + L2P.m33

        local sB1x = 0.5*(1.0 + (pB1x / pB1w))
        local sB1y = 0.5*(1.0 - (pB1y / pB1w))

        local sMIx = sB0x
        if (sB0x > sB1x) then sMIx = sB1x end
        local sMAx = sB0x
        if (sB0x < sB1x) then sMAx = sB1x end

        local sMIy = sB0y
        if (sB0y > sB1y) then sMIy = sB1y end
        local sMAy = sB0y
        if (sB0y < sB1y) then sMAy = sB1y end

        local Key = string.format("%s:%i", P.Name, IconCount)

        -- // note: these vars are all exported over the wire into flash space
        -- // use sparingly
        local Icon = {}

        Icon.Px =		sTx
        Icon.Py =		sTy
        Icon.Desc =		P.Desc

        Icon.B0x =		sMIx
        Icon.B0y =		sMIy

        Icon.B1x =		sMAx
        Icon.B1y =		sMAy

        Icon.NodeID =		OX.NodeID
        Icon.ObjectID =		OM.ObjectID

        Icons[IconCount] = Icon
        IconCount = IconCount + 1
    end
    return 1
end

-- //********************************************************************************************************************

function fIcon_Destroy( O)

    local P = ffi.cast("fIcon_t*", O.Object)
    fAssert(P)

    ffi.fill(P, ffi.sizeof("fIcon_t"), 0)
    fFree(P)
end

-- //********************************************************************************************************************
--
--int fIcon_Register(lua_State* L)
--{
--lua_table_register(L, -1, "Icon_Frame",			lIcon_Frame)
--return 0
--}
