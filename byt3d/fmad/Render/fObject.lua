--
-- Created by David Lannan
-- User: grover
-- Date: 9/05/13
-- Time: 8:30 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--
-- //********************************************************************************************************************

fObj = require("byt3d/fmad/Render/fObject_h")

-- //********************************************************************************************************************

OL_MAGIC	    = 0xbabebabe

-- //********************************************************************************************************************

ObjectValid = {}
ObjectValid[fObj.fObject_Camera]        =  1
ObjectValid[fObj.fObject_LightDir]      =  1
ObjectValid[fObj.fObject_TriMesh]       =  1
ObjectValid[fObj.fObject_XForm]         =  1
ObjectValid[fObj.fObject_Material]      =  1
ObjectValid[fObj.fObject_Texture]       =  1
ObjectValid[fObj.fObject_Line]          =  1
ObjectValid[fObj.fObject_HeightMap]     =  1
ObjectValid[fObj.fObject_Icon]          =  1
ObjectValid[fObj.fObject_Skin]          =  1

-- //********************************************************************************************************************

fObject_t = {

    NodeID      = 0,
    ObjectID    = 0,

    WayNext     = nil,
    WayPrev     = nil,

    FrameCount  = 0,
    Type        = 0,
    CRC32       = 0,

    Local2World = nil,
    iLocal2World = nil,

    Min         = { 0, 0, 0 },
    Max         = { 0, 0, 0 },

    RefType     = 0,
    RefID       = 0,
    Object      = nil,

    -- // linear linked list
    Next        = nil,
    Prev        = nil,
}

-- //********************************************************************************************************************

fObjectList_t = {

    Magic   = -1,

    LastUpdate  = 0,
    LastFrame   = nil,

    CameraCount = 0,
    Camera      = nil,				-- // only one active camera at a time

    Shadow      = nil,				-- // shadow map light

    LightCount  = 0,
    Light       = {},               -- // list of lights

    TriMeshCount = 0,
    TriMesh     = {},               --	// list of tri meshs

    SkinCount   = 0,
    Skin        = {},               --	// list of skins

    LineCount   = 0,
    Line        = {},               --	// list of line objects

    HeightMapCount = 0,
    HeightMap   =  {},              --	// list of heightmaps objects

	MaterialCount = 0,
    Material    = {},               --	// list of materials

    IconCount   = 0,
    Icon        = {},               --	// list of materials

    -- // list of all objects
    ObjectCount = 0 ,                --	// for debug/verify only
    ObjectHead  = nil,
    ObjectTail  = nil,

    ObjectSet   = {},

    UpdateFrame = 0,                --	// current update frame no
    UpdateCount = 0,                --	// number of received xforms for the frame
    UpdateTotal = 0,                --	// total number of xforms for the frame
    UpdateDone  = 0,                --	// all xforms for a frame received

    FrameCount  = 0,                --	// number of entire frames received
}


-- //********************************************************************************************************************
function	toObjectList(OL, File, Line)

    fAssertFL(OL ~= nil, File, Line)
    fAssertFL(OL.Magic == OL_MAGIC, File, Line)

    return OL
end

-- //********************************************************************************************************************
function toObject( O, File, Line)

    fAssertFL(O ~= nil, File, Line)
    -- //fAssertFL(O->Magic == OL_MAGIC, File, Line)
    return O
end

-- //********************************************************************************************************************

function SetID( NodeID, ObjectID )

    return bit.band(bit.bxor(NodeID, ObjectID), 0xfff)
end

-- //********************************************************************************************************************

function fObject_Find( OL, NodeID, ObjectID )

--    // get set
    local Set = OL.ObjectSet[SetID(NodeID, ObjectID)]

    local O = Set
    while (O) do

--        //printf("%08x %08x\n", O->NodeID, O->ObjectID);
        if ( (O.NodeID == NodeID) and (O.ObjectID == ObjectID)) then
            return O
        end
        O = O.WayNext
    end
    return nil
end

-- //********************************************************************************************************************

function fObject_Get( OL, Type, NodeID, ObjectID )

--    // get set

    local SetHash = SetID(NodeID, ObjectID)
    local OS = OL.ObjectSet[SetHash]

    local L = OS
    local O = OS
    while (O ~= nil ) do

        if ( (O.NodeID == NodeID) and (O.ObjectID == ObjectID)) then

            ftrace("Found Object Type: %d  NodeID: %d, ObjectID: %d\n", Type, NodeID, ObjectID)
            return O
        end

        L = O
        O = O.WayNext
    end

    --    // not found so create it
    O = deepcopy(fObject_t)

    ftrace("Creating New Object Type: %d  NodeID: %d, ObjectID: %d\n", Type, NodeID, ObjectID)

    O.Type		    = Type
    O.NodeID	    = NodeID
    O.ObjectID	    = ObjectID
    O.CRC32	        = 0xffffffff
    O.Local2World	= fMat44_Identity()
    O.iLocal2World	= fMat44_Identity()
    O.Object	    = nil
    O.FrameCount	= OL.FrameCount

    O.Prev		= OL.ObjectTail
    O.Next		= nil

--    // update master list
    if (OL.ObjectTail ~= nil) then
        OL.ObjectTail.Next = O
    end
    OL.ObjectTail 	= O

    if (OL.ObjectHead == nil) then

        OL.ObjectHead = O
        OL.ObjectTail = O
    end

    --    // update way list
    if (OS == nil) then

        OL.ObjectSet[SetHash]	= O
        O.WayNext		= nil
        O.WayPrev		= nil
    else

--    // append at end
        L.WayNext		= O
        O.WayPrev		= L
        O.WayNext		= nil
    end

    OL.ObjectCount=OL.ObjectCount + 1
--    //ftrace("create object %08x %08x : %08x\n", O->NodeID, O->ObjectID, O);

    fObjectList_Verify(OL)
    return O
end

-- //********************************************************************************************************************

function fObject_Collect(OL)

--    // 10sec collect
    local FrameOut_General 	    = 30*10
    local FrameOut_Material 	= 120*10

    fObjectList_Verify(OL)

    local O = OL.ObjectHead
    while (O) do

        local Next = O.Next

        local Remove	= false
        local Force	    = false

--        // for xform objects, kick after 2 frames(these are Node hierarchy transforms)
--        // so when a node gets deleted, its xform here is also immedielty deleted
        if ((O.NodeID == fRealizeNodeID_XForm) and ((OL.FrameCount - O.FrameCount) > 3)) then

--            //ftrace("force node collection %08x %08x : type %08x\n", O.NodeID, O.ObjectID, O.Type)
            Force = true
        end

--        // collect timeout
        if (bit.bor(((OL.FrameCount - O.FrameCount) > FrameOut_General) , Force) > 0) then

            if(O.Type == fObject_TriMesh) then

                dtrace("collect trimesh: %08x : %i\n", O.ObjectID, OL.FrameCount - O.FrameCount)
                fTriMesh_Destroy(O)
                Remove = true

            elseif(O.Type == fObject_Skin) then
                dtrace("collect skin: %08x : %i\n", O.ObjectID, O.FrameCount)
                fSkin_Destroy(O)
                Remove = true

            elseif(O.Type == fObject_LightDir) then
                dtrace("collect lightdir: %08x : %i\n", O.ObjectID, O.FrameCount)
                fLightDir_Destroy(O)
                Remove = true

            elseif(O.Type == fObject_XForm) then
--                //dtrace("collect xform\n");
                Remove = true
--            else
--                //dtrace("collect type: %02x ID:%08x unsupported\n", O->Type, O->ObjectID);
            end
        end

        if (bit.bor(((OL.FrameCount - O.FrameCount) > FrameOut_Material) , Force) > 0) then

            if (O.Type == fObject_Material) then
                dtrace("collect material: %08x : %i\n", O.ObjectID, O.FrameCount)
                fMaterial_Destroy(O)
                Remove = true
            elseif (O.Type == fObject_Texture) then
                dtrace("collect texture: %08x : %i\n", O.ObjectID, O.FrameCount)
                fTexture_Destroy(O)
                Remove = true
            end
        end

--        // remove object
        if (Remove == true) then

--            //printf("remove start: %08x %03x:%03x : n %08x p %08x : ty:%i : ol %08x %08x\n", O, O->NodeID, O->ObjectID, O->Next, O->Prev, O->Type, OL->ObjectHead, OL->ObjectTail);
            fObjectList_Verify(OL)

            if (O.Prev) then 			O.Prev.Next = O.Next end
            if (O.Next) then 			O.Next.Prev = O.Prev end

            if (OL.ObjectHead == O)	then OL.ObjectHead = O.Next end
            if (OL.ObjectTail == O)	then OL.ObjectTail = O.Prev end

--            // update hash lookup
            if (O.WayPrev) then 		O.WayPrev.WayNext = O.WayNext end
            if (O.WayNext) then	    	O.WayNext.WayPrev = O.WayPrev end

            local SetHash = SetID(O.NodeID, O.ObjectID)
            if (OL.ObjectSet[SetHash] == O) then

                OL.ObjectSet[SetHash] = O.WayNext
            end

            ffi.fill(O, ffi.sizeof("fObject_t"), 0)
            fFree(O)

            OL.ObjectCount=OL.ObjectCount-1
            fObjectList_Verify(OL)
        end
        O = Next
    end
    fObjectList_Verify(OL)
end

--//********************************************************************************************************************

function fObjectList_Reset( OL)

--    //printf("reset scene\n");

    local O = OL.ObjectHead;
    while (O) do

--        //printf("delete object: %08x %08x: %i : %08x %08x\n", O, O.Next, O.Type, O.NodeID, O.ObjectID);
        local Next = O.Next
        if (O.Object) then

            if (O.Type == fObject_Camera) then fCamera_Destroy(O)
            elseif (O.Type == fObject_LightDir) then fLightDir_Destroy(O)
            elseif (O.Type == fObject_TriMesh) then fTriMesh_Destroy(O)
            elseif (O.Type == fObject_Skin) then fSkin_Destroy(O)
            elseif (O.Type == fObject_Material) then fMaterial_Destroy(O)
            elseif (O.Type == fObject_Texture) then fTexture_Destroy(O)
            elseif (O.Type == fObject_Line) then fLine_Destroy(O)
            elseif (O.Type == fObject_HeightMap) then fHeightMap_Destroy(O)
            elseif (O.Type == fObject_Icon) then fIcon_Destroy(O)
--            // no object attached
--            elseif (O.Type == fObject_XForm) then
            end
        end

        ffi.fill(O, ffi.sizeof("fObject_t"), 0)
        fFree(O)
        O = Next
    end

    OL.ObjectHead = nil
    OL.ObjectTail = nil

    ffi.fill(OL.ObjectSet, ffi.sizeof(OL.ObjectSet), 0)
--    // reset list

    OL.LightCount		= 0
    OL.TriMeshCount	    = 0
    OL.SkinCount		= 0
    OL.LineCount		= 0
    OL.MaterialCount	= 0
    OL.HeightMapCount	= 0
    OL.IconCount		= 0

    OL.Camera		= nil
    OL.Shadow		= nil

--    //printf("reset done\n");
end

--//********************************************************************************************************************
--// object updates

function fObject_Packet(N, ObjectID, Data, Size, User)

    local RS = ffi.cast("struct fRealizeScene_t*", Data)
    local R	= fRealize_SceneIDFind(RS.Header.SceneID)
    if (R == nil) then return end

    local OL	= fRealize_ObjectList(R)

    local FrameEnd = false
    local t = os.clock()

--    // update xforms
    if((RS.Header.CmdID == fRealizeCmdID_Update) or
            (RS.Header.CmdID == fRealizeCmdID_SceneHeader)) then

--        // note: screen reset is global
        if (fRealize_SceneID(R) ~= RS.Header.SceneID) then return end

--        // next frame starts ?
        if (OL.UpdateFrame < RS.FrameNo) then

--            // usuall means some xfrom udp packets got dropped (e.g. frame complete bellow isnt called)
--            // so a full frames worth was not received. but the frame ended
--            // and we need to check for collection as long string of semi frames
--            // could be sent resulting in xforms which should be collected not being collected
            if (not OL.UpdateDone) then

                FrameEnd  = true

--                //dtrace("reset frame count %08x\n", OL.UpdateCount);
                local dt = t - OL.LastFrame
                OL.LastFrame = t
                ftrace("semi frame %0.4f %i/%i\n", dt*1e3, OL.UpdateCount, OL.UpdateTotal)
            end
            OL.UpdateFrame = RS.FrameNo
            OL.UpdateCount = 0
            OL.UpdateDone	= false
        end

        local temp = 0
        if(OL.UpdateFrame == RS.FrameNo) then temp = RS.ObjectCount end
        OL.UpdateCount = OL.UpdateCount + temp

        local dt = t - OL.LastUpdate
        OL.LastUpdate = t

        for i=0, RS.ObjectCount-1 do

            local RO = RS.List[i]

--            // find/create the object
            local O	= fObject_Get(OL, fObject_XForm, RO.NodeID, RO.ObjectID)

            O.Local2World	= RO.L2W
            O.iLocal2World = RO.iL2W

            O.Min[0]	= RO.Min[0]
            O.Min[1]	= RO.Min[1]
            O.Min[2]	= RO.Min[2]

            O.Max[0]	= RO.Max[0]
            O.Max[1]	= RO.Max[1]
            O.Max[2]	= RO.Max[2]

--            // its just a reference
            O.RefType	= RO.RefType
            O.RefID	    = RO.RefID
            O.FrameCount	= OL.FrameCount
        end

--        // frame done ?
--        //ftrace("packet frame:%08x : %08x / %08x\n", RS.FrameNo, OL.UpdateCount);
        if (OL.UpdateFrame == RS.FrameNo) then

            if (RS.Header.CmdID == fRealizeCmdID_SceneHeader) then

                OL.UpdateTotal = RS.ObjectTotal
--                //dtrace("new object total %08x : %08x\n", RS.FrameNo, RS.ObjectTotal)
            end

--            // have received a full frames worth of xforms so inc the frame counter
            if (OL.UpdateCount >= OL.UpdateTotal) then

--                // full frame`s worth of xforms received

                local dt	    = t - OL.LastFrame
                OL.LastFrame	= t
                OL.UpdateDone	= true

--                /*
--                // trace when a frame is dropped
--                if (dt*1e3 > 36)
--                {
--                dtrace("full frame %0.4f %i xforms\n", dt*1e3, OL.UpdateCount);
--                }
--                */

--                // collect any un-used xforms
                FrameEnd  = true
            end
        end

     elseif (RS.Header.CmdID == fRealizeCmdID_Reset) then

--        // reset and clear everything
        fObjectList_Reset(OL)
    end

    if (FrameEnd) then

--        // collect any un-used xforms
        fObject_Collect(OL)
--        // update frame counter
        OL.FrameCount=OL.FrameCount+1
    end
end

--//********************************************************************************************************************

function fObjectList_CameraSet( OL,  O )

    O.FrameCount	= OL.FrameCount
    OL.Camera	    = O
end

function fObjectList_CameraGet( OLPtr )

    return OL.Camera
end

--//********************************************************************************************************************

function lObjectList_Create()

    OL = deepcopy(fObjectList_t)
    OL.Magic = OL_MAGIC
    return OL
end

--//********************************************************************************************************************
--// bin objects into their respective types

function lObjectList_Sort(OL)

    local OL = toObjectList(OL)

--    // link all objects up
--    local O = OL.ObjectHead
--    while O ~= nil do
--
--        local relink = true
--        if (O.NodeID == 0) or (O.RefType == 0) then
--            relink = false
--        end
--
--        if relink == true then
----        // ids match
--            local OR = ffi.cast("fObject_t *", O.Object)
--            if (OR) then
--                if (OR.NodeID == 0) then
--                    if(OR.ObjectID == O.RefID) then
--                        relink = false
--                    end
--                end
--            end
--
--            if relink == true then
--        --        // otherwise re-link
--                O.Object = fObject_Find(OL, 0, O.RefID)
--                if (O.Object == nil) then
--
--    --                //dtrace("unable to find objectID:%i:%08x\n", O.RefType, O.RefID)
--                end
--            end
--        end
--        O = O.Next
--    end

--    // bin the valid objects
    OL.LightCount		= 0
    OL.TriMeshCount	    = 0
    OL.SkinCount		= 0
    OL.MaterialCount	= 0
    OL.LineCount		= 0
    OL.HeightMapCount	= 0
    OL.IconCount		= 0
    OL.CameraCount		= 0

    local XFormCount = 0
    local O = OL.ObjectHead

    while (O ~= nil) do

        if  ((O.Type == fObj.fObject_XForm) and (O.Object ~= nil)) then

            ftrace("Object Found: %d  %d\n", O.Type, O.RefType)
            if (O.RefType == fRz.fRealizeType_Camera) then
                OL.CameraCount=OL.CameraCount + 1
            elseif (O.RefType == fRz.fRealizeType_LightDir) then
                OL.Light[OL.LightCount] = O
                OL.LightCount = OL.LightCount + 1
            elseif (O.RefType == fRz.fRealizeType_TriMesh) then
                OL.TriMesh[OL.TriMeshCount] = O
                OL.TriMeshCount = OL.TriMeshCount + 1
            elseif (O.RefType == fRz.fRealizeType_Skin) then
                OL.Skin[OL.SkinCount] = O
                OL.SkinCount = OL.SkinCount + 1
            elseif (O.RefType == fRz.fRealizeType_Line) then
                OL.Line[OL.LineCount] = O
                OL.LineCount = OL.LineCount + 1
            elseif (O.RefType == fRz.fRealizeType_HeightMap) then
                OL.HeightMap[OL.HeightMapCount] = O
                OL.HeightMapCount = OL.HeightMapCount + 1
            elseif (O.RefType == fRz.fRealizeType_Icon) then
                OL.Icon[OL.IconCount] = O
                OL.IconCount = OL.IconCount + 1
            end
            XFormCount = XFormCount + 1
        end

--        // things which have no xform attached
        if (O.Type == fObj.fObject_Material) then

            ftrace("Material Found: %d\n", O.Type)
            OL.Material[OL.MaterialCount] = O
            OL.MaterialCount = OL.MaterialCount + 1
        end

        O = O.Next
    end

    ftrace("Cameras: %d\n", OL.CameraCount)
    ftrace("Meshes: %d\n", OL.TriMeshCount)
    ftrace("XForms: %d\n", XFormCount)

    fAssert(OL.LightCount < fObj.OBJECTLIST_MAX)
    fAssert(OL.TriMeshCount < fObj.OBJECTLIST_MAX)
    fAssert(OL.MaterialCount < fObj.OBJECTLIST_MAX)
    fAssert(OL.LineCount < fObj.OBJECTLIST_MAX)
    fAssert(OL.HeightMapCount < fObj.OBJECTLIST_MAX)
    fAssert(OL.IconCount < fObj.OBJECTLIST_MAX)

    --ftrace("Light:%i TriMesh:%i Line:%i Material:%i XForm:%i Cam:%i\n", OL.LightCount, OL.TriMeshCount, OL.LineCount, OL.MaterialCount, XFormCount, OL.CameraCount);
    return OL
end

--//********************************************************************************************************************

function lObjectList_LightList(OL)

    OL = toObjectList(OL)

    local Lights = {}
    for i=0, OL.LightCount-1 do

        Light[i] = OL.Light[i]
    end
    return Light
end

--//********************************************************************************************************************
--// sets a camera for the object list

function lObjectList_CameraSet( OL, C )

    if C == nil then return -1 end

    OL	    = toObjectList(OL)
    C		= toObject(C)

    fObjectList_CameraSet(OL, C)
    return 0
end

--//********************************************************************************************************************

function lObjectList_CameraGet(OL)

    OL	= toObjectList(OL)
    local C		= fObjectList_CameraGet(OL)

    if (C == nil) then return 0 end
    return C
end

--//********************************************************************************************************************

function fObjectList_FrameNo(OL)

    return OL.FrameCount
end

--//********************************************************************************************************************

function fObjectList_TriMeshList(OL)

    return OL.TriMesh
end

--//********************************************************************************************************************

function fObjectList_SkinList( OL)

    return OL.Skin
end

--//********************************************************************************************************************

function fObjectList_MaterialList( OL)

    return OL.Material
end

--//********************************************************************************************************************

function fObjectList_LineList( OL)

    return OL.Line
end

--//********************************************************************************************************************

function fObjectList_HeightMapList( OL)

    return OL.HeightMap
end

--//********************************************************************************************************************

function fObjectList_IconList( OL)

    return OL.Icon
end

--//********************************************************************************************************************

function fObjectList_LightList( OL)

    return OL.Light
end

--//********************************************************************************************************************
--// make sure the object list is sane

function fObjectList_Verify( OL, File, Line)

--    /*
--    // verify list is still sane
--    local TO = OL.ObjectHead
--    if (TO == nil) then return end
--
--    fAssert(TO.Prev == nil)
--
--    local Count = 0
--    local L = nil
--    while (TO ~= nil) do
--
--        fAssertFL(Count < 100000, "fObject", 648)
--        Count = Count + 1
--
----        //printf("%08x : %08x:%08x  %04x:%04x\n", TO, TO.Prev, TO>Next, TO.NodeID, TO.ObjectID);
--        if (TO.Prev ~= nil) then
--            fAssertFL(TO.Prev == L, "fObject", tostring(TO.Prev))
--        else
--            fAssertFL(TO == OL.ObjectHead, "fObject", 655)
--        end
--
--        if(ObjectValid[TO.Type] == nil) then
--            ftrace("ObjectType: %d\n", TO.Type)
--            fAssert(false)
--        end
--
--        if (TO.Next == nil) then break end
--        L = TO
--        TO = TO.Next
--    end
--    fAssert(OL.ObjectTail == TO)
--
----    //dtrace("%i %i\n", Count, OL.ObjectCount);
--    fAssertFL(Count == OL.ObjectCount, File, Line)
--
----    // verfy set
--    for i=0, 4095 do
--        local Count = 0
--        local O = OL.ObjectSet[i]
--        while (O ~= nil) do
--
--            fAssertFL(Count < 1000, File, Line)
--            Count = Count + 1
--            O = O .WayNext
--        end
--    end
--    */
end

--//********************************************************************************************************************
--
--int fObject_Register(lua_State* L)
--{
--lua_table_register(L, -1, "ObjectList_Create",		lObjectList_Create);
--lua_table_register(L, -1, "ObjectList_Sort",		lObjectList_Sort);
--lua_table_register(L, -1, "ObjectList_LightList",	lObjectList_LightList);
--lua_table_register(L, -1, "ObjectList_CameraSet",	lObjectList_CameraSet);
--lua_table_register(L, -1, "ObjectList_CameraGet",	lObjectList_CameraGet);
--}

