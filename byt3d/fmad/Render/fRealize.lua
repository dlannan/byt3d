--
-- Created by IntelliJ IDEA.
-- User: ddddddddddddddddd
-- Date: 5/05/13
-- Time: 1:25 PM
-- To change this template use File | Settings | File Templates.
--
-- //********************************************************************************************************************

local ffi  = require( "ffi" )
fRz = require("byt3d/fmad/Render/fRealize_h")

--#include <Common/fCommon.h>
--#include <Network/fNetwork.h>
--#include <fRealize.h>
--#include "fObject.h"
--#include "fCamera.h"
--#include "fTriMesh.h"
--#include "fLightDir.h"
--#include "fMaterial.h"
--#include "fTexture.h"
--#include "fLine.h"
--#include "fHeightMap.h"
--#include "fIcon.h"
--#include "fSkin.h"

REALIZE_MAGIC		= 0x13370009

-- //********************************************************************************************************************

function fRealizePayloadCount(header, unit)
    return ((fRz.fRealize_MTU - ffi.sizeof(fRz.fRealizeHeader_t) - header - 4) / unit )		-- // JUMBO frame 800MTU
end

-- //********************************************************************************************************************

s_Realize = nil

-- //********************************************************************************************************************

function lRealize_Create(McN, obj)
    
    local RPtr 	    = ffi.new("fRealize_t[1]")
    local R         = RPtr[0]
    R.Net		    = toMultiCast(McN)
    R.ObjectList	= toObjectList(obj)

    -- // register callbacks
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_Scene,	    fObject_Packet, 	nil)
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_Camera,	    fCamera_Packet, 	nil)
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_LightDir,	    fLightDir_Packet, 	nil)
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_TriMesh,	    fTriMesh_Packet, 	nil)
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_Material,	    fMaterial_Packet, 	nil)
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_Texture,	    fTexture_Packet, 	nil)
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_Line,	        fLine_Packet, 		nil)
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_HeightMap,	fHeightMap_Packet, 	nil)
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_Icon,	        fIcon_Packet, 		nil)
    fMultiCast_PacketHandler(R.Net, fRz.fRealizeMultiCast_Skin,	        fSkin_Packet, 		nil)

    R.Act = nil

    -- // add
    R.Next		= s_Realize
    s_Realize 	= RPtr

    return RPtr
end

-- //********************************************************************************************************************

function lRealize_Destroy(RPtr)

    if (RPtr == nil) then return 0 end

    -- // remove from scene list
    local RN = s_Realize
    local RL = nil
    while (RN ~= nil) do

        if (RN == RPtr) then

            if (RL) then RL.Next	= RN.Next end
            if (RL == nil) then
                s_Realize	= RN.Next
                break
            end
        end

        RL = RN
        RN = RN.Next
    end

    -- // free memory
    ffi.fill(RPtr, 0, ffi.sizeof("fRealize_t"))
    fFree(RPtr)

    return 0
end

-- //********************************************************************************************************************
-- // returns the realizer instance for the specified NetID

function fRealize_SceneIDFind(SceneID)

    local RPtr = s_Realize
    while (RPtr ~= nil) do

        local R = RPtr[0]
        if (R.SceneID == SceneID) then

            return R
        end
        RPtr = R.Next
    end
    return nil
end

--//********************************************************************************************************************
--// acks are done over tcp

function fRealize_Ack( R, NodeID, ObjectID, CRC)

    local A     = ffi.new("fAct_t")
    A.NodeID    = NodeID
    A.ObjectID  = ObjectID
    A.CRC32     = CRC

    A.Next      = R.Act
    R.Act       = A
end

-- //********************************************************************************************************************

function fRealize_ObjectList( RPtr )

    local R = RPtr[0]
    return R.ObjectList
end

-- //********************************************************************************************************************
function lRealize_SceneIDSet(RPtr, SceneID)

    fAssert(RPtr)
    local R = RPtr[0]
    R.SceneID = SceneID
    return 0
end

-- //********************************************************************************************************************

function fRealize_SceneID(RPtr)

    local R = RPtr[0]
    return R.SceneID
end

-- //********************************************************************************************************************
--
--function fRealize_Register()
--
--    lua_table_register(L, -1, "Realize_Create",		lRealize_Create)
--    lua_table_register(L, -1, "Realize_Destroy",		lRealize_Destroy)
--    lua_table_register(L, -1, "Realize_SceneIDSet",		lRealize_SceneIDSet)
--
--    return 0
--end
