--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:45 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

-- //********************************************************************************************************************
-- //
-- // fmad llc 2008
-- //
-- // scene spacial management
-- //
-- //********************************************************************************************************************

require("fmad/World/Common/fCommon_h")
require("fmad/World/Network/fNetwork_h")
require("fmad/World/Render/fRealize_h")
require("fmad/World/fScene_h")
require("fmad/World/fSceneGlobal_h")
require("fmad/World/fSceneObject_h")
require("fmad/World/fSceneSpace_h")


-- //********************************************************************************************************************
-- // create
function fSceneSpace_Create( S)

    local Space = ffi.sizeof("fSceneSpace_t")
    fAssert(Space)
    ffi.fill(Space, ffi.sizeof("fSceneSpace_t"), 0)

    Space.RSceneMax	    = 1024
    Space.RScene		= ffi.new("fRealizeScene_t["..Space.RSceneMax.."]")

    return Space
end

-- //********************************************************************************************************************
-- // free
function fSceneSpace_Destroy( A)

    if (A == nil) then return end

    local U = A.SpaceHead
    while (U) do

        local Next = U.Next
        ffi.fill(U, ffi.sizeof("fSpaceObject_t"), 0)
        fFree(U)
        U = Next
    end
    A.SpaceHead = nil

    -- // relese scene
    fFree(A.RScene)

    ffi.fill(A, ffi.sizeof("fSceneSpace_t"), 0)
    fFree(A)
end

-- //********************************************************************************************************************
function fSceneSpace_Insert(  A, Path, L2W, iL2W, Host, Node, Object, SpaceID )
    fAssert(Object)

    local U = ffi.new("fSpaceObject_t")
    fAssert(U)

    -- // defaults
    U.Host		= Host
    U.Node		= Node
    U.Object 	= Object
    U.Local2World	= L2W[0]
    U.iLocal2World = iL2W[0]

    strncpy(U.Path, Path, sizeof(U.Path))

    -- // get bouding sphere
    local Center = ffi.new("float[3]")
    local Radius
    fSceneObject_BoundingSphere(Object, Center, Radius)

    -- // xform into world space
    local WCx 	= L2W.m00*Center[0] + L2W.m01*Center[1] + L2W.m02*Center[2] + L2W.m03
    local WCy 	= L2W.m10*Center[0] + L2W.m11*Center[1] + L2W.m12*Center[2] + L2W.m13
    local WCz 	= L2W.m20*Center[0] + L2W.m21*Center[1] + L2W.m22*Center[2] + L2W.m23

    -- // update sphere
    U.SphereX	= WCx
    U.SphereY	= WCy
    U.SphereZ	= WCz
    U.SphereRadius = Radius
    U.SphereRadius2 = Radius*Radius
    U.SpaceID	= SpaceID

    -- // append
    U.Next = A.SpaceHead
    A.SpaceHead = U
end

-- //********************************************************************************************************************
function fSceneSpace_Remove( A, Object)

    if (A == nil) then

        ftrace("no scene space created yet\n")
        return
    end

    local U = A.SpaceHead
    local P = nil
    while (U ~= nil) do

        local Next = U.Next

        -- // delete it
        if (U.Object == Object) then

            ffi.fill(U, ffi.sizeof("fSpaceObject_t"), 0)
            fFree(U)

            if (A.SpaceHead == U) then A.SpaceHead = Next end
            if (P ~= nil)then P.Next = Next end

            U = P
        end
        P = U
        U = Next
    end
end

-- //********************************************************************************************************************
-- // return a list of objects with their world space co-ordinates (used for editor hit lists)

function lSceneSpace_QueryBox(S, L)

    S	= toScene(S)
    fAssert(S)

    -- // what kinds of objects
    local TypeMask = 0
    if (lua_isstring(L)) then

        local ObjectType	= lua_tostring(L)
        TypeMask = fSceneObject_StrToType(ObjectType)

    elseif (lua_istable(L)) then
        for k,v in pairs(L) do

            local ObjectType	= lua_tostring(v)
            TypeMask = bit.bor(TypeMask, fSceneObject_StrToType(ObjectType))
        end
    else
        ftrace("lScene_QueryBox: unknown query type\n")
        return 0
    end

    local FlagMask = 0xffffffff

    -- // node need to iterate the nodes, due to instancing
    local T = {}

    -- // get the scene space
    local A = fScene_SpaceGet(S)
    if (A == nil) then

        ftrace("scene has no space object!\n")
        return T
    end

    -- // search all of them
    local U = A.SpaceHead
    while (U ~= nil) do

        local O = U.Object
        if bit.band(O.Flag , FlagMask) > 0 then

            -- // type pass
            if bit.band(O.Type, TypeMask) > 0 then

                local NT = {}

                NT.Type = fSceneObject_TypeToStr(O.Type)
                NT.Obj = O
                NT.Node = U.Node
                NT.Host = U.Host

                T[U.Path] = NT
            end
        end
        U = U.Next
    end
    return T
end

-- //********************************************************************************************************************
-- // sphere check

function fSceneSpace_QuerySphere( A, FlagMask, CenterX, CenterY, CenterZ, Radius, Result, ResultMax)

    local r2 = Radius*Radius
    local Count = 0

    -- // needs to change... but takes fa time for the moment
    local U = A.SpaceHead
    while (U ~= nil) do

        if bit.band(U.Object.Flag, FlagMask) > 0 then

            -- // check dist
            local dx = U.SphereX - CenterX
            local dy = U.SphereY - CenterY
            local dz = U.SphereZ - CenterZ

            local dist2 = (dx*dx + dy*dy + dz*dz)

            -- //printf("[%30s] %f %f %f\n", U.Object.Name, dist2, r2, U.SphereRadius2)

            if ((dist2+U.SphereRadius2) < r2) then

                Result[Count].Px	= U.SphereX
                Result[Count].Py	= U.SphereY
                Result[Count].Pz	= U.SphereZ
                Result[Count].Radius	= U.SphereRadius
                Result[Count].Distance2	= dist2
                Result[Count].Object	= U.Object
                Count = Count + 1
                if (Count >= ResultMax) then return Count end
            end
        end
        U = U.Next
    end
    return Count
end

-- //********************************************************************************************************************
-- // this is wired, for perf reasons only...

function RealizeType(SceneObjectType)

    if (SceneObjectType == fSceneObject_Type_TriMesh) then
        return fRealizeType_TriMesh
    elseif (SceneObjectType == fSceneObject_Type_Camera) then
        return fRealizeType_Camera
    elseif (SceneObjectType == fSceneObject_Type_LightDir) then
        return fRealizeType_LightDir
    elseif (SceneObjectType == fSceneObject_Type_SplineCatmull) then
        return fRealizeType_Line
    elseif (SceneObjectType == fSceneObject_Type_HeightMap) then
        return fRealizeType_HeightMap
    elseif (SceneObjectType == fSceneObject_Type_Icon) then
        return fRealizeType_Icon
    elseif (SceneObjectType == fSceneObject_Type_Skin) then
        return fRealizeType_Skin
    else
        return 0
    end

    fAssert(0)
end

-- //********************************************************************************************************************
-- // reallize encode all scene objects. this should be a spacial query, but for now just copy everything

function lSceneSpace_RealizeEncode( _S, S)

    local A 	= fScene_SpaceGet(S)
    fAssert(A)

    A.RSceneCount		= 0
    local U 	        = A.SpaceHead
    if (U == nil) then return 0 end

    local	RS = A.RScene
    fAssert(RS)

    local ObjectTotal 	= 0
    local PackTotal		= 0

    while (U ~= nil) do

        -- // new packet
        RS.Header.CmdID	= fRealizeCmdID_Update
        RS.Header.PartPos	= 0
        RS.Header.PartTotal	= 0 	-- // dont care about ack
        RS.Header.NodeID	= 0 	-- // dont care about ack
        RS.Header.ObjectID	= 0 	-- // dont care about ack

        RS.ObjectCount		= 0
        RS.ObjectOffset	    = 0
        RS.ObjectTotal		= 0
        RS.FrameNo		= fScene_FrameCount(S)

        -- // create new packet
        while ((RS.ObjectCount < fRealizeSceneList_Max) and (U ~= nil)) do

            fAssert(U ~= nil)

            local RType = RealizeType(U.Object.Type)
            if (RType ~= 0) then

                -- // note: xform object is the combination of
                -- // host ref count | node id | object id
                -- // this allows it to instancing of an object on hosts and nodes
                -- //
                -- // render uses the RefID to reference the actually object
                RS.List[RS.ObjectCount].NodeID	    = fRealizeNodeID_XForm		-- //  reserved node id
                RS.List[RS.ObjectCount].ObjectID	= U.SpaceID

                RS.List[RS.ObjectCount].RefType	    = RType
                RS.List[RS.ObjectCount].RefID		= U.Object.ID

                RS.List[RS.ObjectCount].L2W		    = U.Local2World
                RS.List[RS.ObjectCount].iL2W		= U.iLocal2World

                RS.List[RS.ObjectCount].Min[0]	= 0
                RS.List[RS.ObjectCount].Min[1]	= 0
                RS.List[RS.ObjectCount].Min[2]	= 0

                RS.List[RS.ObjectCount].Max[0]	= 0
                RS.List[RS.ObjectCount].Max[1]	= 0
                RS.List[RS.ObjectCount].Max[2]	= 0

                RS.ObjectCount = RS.ObjectCount + 1
                ObjectTotal = ObjectTotal + 1
            end
            U = U.Next
        end

        -- // last packet has the final object count
        if (U == nil) then

            RS.Header.CmdID	= fRealizeCmdID_SceneHeader
            RS.ObjectTotal		= ObjectTotal
        end

    -- // compress the packet
--    /*
--    u32 PackSize = 0
--    void* PackBuffer = fSystem_Compress(RS, sizeof(fRealizeScene_t), &PackSize)
--    PackTotal += PackSize
--    */

        RS = RS + 1
        fAssert( (RS - A.RScene) < A.RSceneMax)
    end
    A.RSceneCount	= RS - A.RScene

    -- // packet stats
    local ratio = PackTotal / (A.RSceneCount*ffi.sizeof("fRealizeScene_t"))
    lastTS = 0

    local t = os.clock()
    local dt = t - lastTS
    lastTS = t

    if (dt*1e3 > 36) then

        ftrace("xform packet count %i raw %iKB comp %iKB %f : %0.4fms\n", A.RSceneCount, (A.RSceneCount*ffi.sizeof("fRealizeScene_t"))/1024, PackTotal/1024, ratio, dt*1e3)
    end

    -- // always send
    return 0
end

-- //********************************************************************************************************************

function lSceneSpace_RealizeSend( S, StreamLength, StreamSize, Stream)

    local A 	= fScene_SpaceGet(S)

    StreamLength[0]		= A.RSceneCount
    StreamSize[0]		= sizeof(fRealizeScene_t)
    Stream[0]		    = A.RScene

    return 1
end

-- //********************************************************************************************************************
function fSceneSpace_Register( L )

    L.Scene_QueryBox = lSceneSpace_QueryBox
    L.Scene_RealizeEncode =	lSceneSpace_RealizeEncode

    -- // general
    local Def = ffi.new("fSceneObjectDef_t[1]")
    ffi.fill(Def, ffi.sizeof(Def[0]), 0)

    Def[0].Magic 		    = 0xbeef7777
    Def[0].StructSize 		= 0
    Def[0].Desc 		    = "Scene"
    Def[0].ObjectType		= fSceneObject_Type_Scene
    Def[0].ObjectFlag		= 0

    Def[0].RealizeType		= fRealizeMultiCast_Scene

    Def[0].lScriptCount	= 0
    Def[0].lScript		    = nil

    -- // interfaces
    Def[0].FnCreate		= nil
    Def[0].FnDestroy		= nil
    Def[0].FnUserControl	= nil
    Def[0].FnRealizeEncode	= lSceneSpace_RealizeEncode
    Def[0].FnRealizeSend	= lSceneSpace_RealizeSend

    fSceneObject_Define(Def)
    return 0
end
