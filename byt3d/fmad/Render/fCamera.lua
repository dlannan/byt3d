--
-- Created by David Lannan
-- User: grover
-- Date: 10/05/13
-- Time: 6:15 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

require("byt3d/fmad/Render/fCamera_h")

--//********************************************************************************************************************
--// converts from realizer object into render object

function fCamera_RealizeDecode( C, RC )

    fAssert(C)
    fAssert(RC)

    C.Local2World	= RC.Local2World
    C.iLocal2World	= RC.iLocal2World

    C.View		= RC.View
    C.iView	    = RC.iView

    C.Projection	= RC.Projection
    C.iProjection	= RC.iProjection
end

--//********************************************************************************************************************

function fCamera_Packet( N, ObjectID, Data, Size, User )

    print(Size, ffi.sizeof("fRealizeCamera_t"))
    fAssert(Size == ffi.sizeof("fRealizeCamera_t"))
    local RC = ffi.cast("fRealizeCamera_t *", Data)

    local R	= fRealize_SceneIDFind(RC[0].Header.SceneID)
    if (R == nil) then return end

--    // find object
    local OL	= fRealize_ObjectList(R)
    fAssert(OL)

    localO		= fObject_Get(OL, fObject_Camera, RC.Header.NodeID, RC.Header.ObjectID)
    fAssert(O)

--    // new camera object
    local C = O.Object
    if (C == nil) then

        C = fMalloc(sizeof(fCamera_t))
        O.Object = C
    end

    if (RC.Header.CmdID == fRealizeCmdID_Update) then

--        // send ack of packet
        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack.NetID	    = fMultiCast_ObjectID(N)
        Ack.NodeID	    = RC.Header.NodeID
        Ack.ObjectID	= RC.Header.ObjectID
        Ack.CRC32	    = RC.Header.CRC32
        Ack.PartPos	    = RC.Header.PartPos
        Ack.PartTotal	= RC.Header.PartTotal

        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, AckPtr, sizeof(Ack))

--        // crc matches then dont waste cycles processing it
        if (O.CRC32 ~= RC.Header.CRC32) then

            O.CRC32 = RC.Header.CRC32
--            // copy data
            fCamera_RealizeDecode(C, RC)
        end

--        // set camera object
        fObjectList_CameraSet(OL, O)

    elseif (RC.Header.CmdID == fRealizeCmdID_Collect) then

        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack.NetID	    = fMultiCast_ObjectID(N)
        Ack.NodeID	    = RC.Header.NodeID
        Ack.ObjectID	= RC.Header.ObjectID
        Ack.CRC32	    = RC.Header.CRC32
        Ack.PartPos	    = RC.Header.PartPos
        Ack.PartTotal	= RC.Header.PartTotal

        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, AckPtr, sizeof(Ack))
    end
end

--//********************************************************************************************************************

function lCamera_RealizeDecode(OL, Data)

    OL= toObjectList(OL)
    local DataLen = ffi.sizeof(Data)
    fAssert(DataLen > 0);

    local O		= fObject_Get(OL, fObject_Camera, 0, 1)
    fAssert(O)

--    // create camera object is not present
    local CPtr = O.Object
    if (CPtr == nil) then

        local CPtr = ffi.new("fCamera_t[1]")
        ffi.fill(CPtr, ffi.sizeof("fCamera_t"), 0)

        O.Object = C
    end

--    // de-realize
    fCamera_RealizeDecode(C, Data)

--    // return camera
    return C
end

--//********************************************************************************************************************

function fCamera_Destroy( O)

    C = O.Object
    fAssert(C)

    ffi.fill(C, ffi.sizeof("fCamera_t"), 0)
    fFree(C)
end

--//********************************************************************************************************************

--function fCamera_Register(lua_State* L)
--{
--lua_table_register(L, -1, "Camera_RealizeDecode",		lCamera_RealizeDecode);
--return 0;
--}
