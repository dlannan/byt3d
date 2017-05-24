--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:35 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

-- //********************************************************************************************************************
-- //
-- // fmad llc 2008
-- //
-- // scene object. common abstract interface for all scene objects
-- //
-- //********************************************************************************************************************

SCENEOBJECT_MAGIC	    = 0x42424242

-- //********************************************************************************************************************

require "byt3d/fmad/Common/fCommon_h"
require "byt3d/fmad/World/fScene_h"
require "byt3d/fmad/fSceneObject_h"
require "byt3d/fmad/fSceneCache_h"
require "byt3d/fmad/fImage_h"
require "byt3d/fmad/Render/fRealize_h"

-- //********************************************************************************************************************
-- // interface specification

--typedef int lSceneObject_Create_f		(struct fScene_t* S, fSceneObject_t* O)
--typedef int lSceneObject_Destroy_f		(struct fScene_t* S, fSceneObject_t* O)
--typedef int lSceneObject_UserControl_f		(lua_State* L, struct fSceneNode_t* N, fSceneObject_t* O)
--typedef int lSceneObject_ObjectInfo_f		(lua_State* L, fSceneObject_t* O)
--typedef int lSceneObject_DynamicInfo_t		(lua_State* L, struct fSceneNode_t* N, fSceneObject_t* O, fSceneObject_t* C)
--typedef int lSceneObject_RealizeEncode_f	(struct fScene_t* S, fSceneObject_t* O)
--typedef int lSceneObject_RealizeSend_f		(fSceneObject_t* O, u32* StreamLength, u32* StreamSize, void** Stream)
--typedef int lSceneObject_Update_f		(fSceneObject_t* O, double t)
--typedef int lSceneObject_NodeXForm_f		(fSceneObject_t* O, fMat44* Local, fMat44* iLocal)
--typedef int lSceneObject_BoundingSphere_f	(fSceneObject_t* O, float* Center, float* Radius)
--typedef int lSceneObject_BoundingBox_f		(fSceneObject_t* O, float* Min, float* Max)
--typedef int lSceneObject_TriSoup_f		(fSceneObject_t* O, fMat44* XForm, u32 PosOffset, u32 PosMax, float* Vertex)

-- //********************************************************************************************************************
-- // list of scene object defenitions

s_SceneObjectDefCount   = 0
s_SceneObjectDef        = {}

-- //********************************************************************************************************************

fLua_ExternByteCode(lSceneObject)
m_LuaInclude =  ffi.new("LuaInclude_t[1]",
{
    { "lSceneObject.lua", 	"Module/World/lSceneObject.lua", fLua_ByteCode(lSceneObject)	},
}  )

s_NodeListnil = { }

-- //********************************************************************************************************************

function lSceneObject_dtrace(L)

    -- TODO: Not exactly sure what this is - I think I can just use normal dtrace. Will need to check.
--    lua_pushvalue(L, lua_upvalueindex(2))
--    lua_insert(L, 1)
--    lua_call(L, lua_gettop(L) - 1, 1)
--
--    if (lua_isstring(L, 1)) then
--
--        lua_getglobal(L, "ObjectName")
--        const char* Name = lua_tostring(L, -1)
--        lua_pop(L, 1)
--
--        printf("SceneObject %020s: %s", Name, lua_tostring(L, 1))
--    end
    return 0
end

function lSceneObject_ftrace( L)

-- TODO: This also looks like we can use normal ftrace - will check.
--    lua_pushvalue(L, lua_upvalueindex(2))
--    lua_insert(L, 1)
--    lua_call(L, lua_gettop(L) - 1, 1)
--
--    if (lua_isstring(L, 1))
--    {
--        lua_getglobal(L, "ObjectName")
--        const char* Name = lua_tostring(L, -1)
--        lua_pop(L, 1)
--
--        ftrace("SceneObject %020s: %s", Name, lua_tostring(L, 1))
--    }
    return 0
end

function lSceneObject_etrace( L)

    return 0
end

-- //********************************************************************************************************************

function luaCallCheck( O)

    if (O.lvm[1] == nil) then

        ftrace("SceneObject[%s]: Error %s\n", O.Name, tostring(O.lvm[1]) )
    end
end

-- //********************************************************************************************************************

function toSceneObjectEx( L, File, Line )

    local O = L
    fAssertFL(O ~= nil, File, Line)
    fAssertFL(O.Magic2 == SCENEOBJECT_MAGIC, File, Line)
    return O
end

-- //********************************************************************************************************************
-- // accessor
function fSceneObject_NodeGet( O)

    return O.NodeList[0]
end

-- //********************************************************************************************************************
-- // note: its assume Def is a static value
function fSceneObject_Define( Def)

    -- // check for collision
    for i=0 ,s_SceneObjectDefCount-1 do

        if(s_SceneObjectDef[i].Magic == Def.Magic) then

            ftrace("SceneObject magic clash [%s] and [%s]\n", s_SceneObjectDef[i].Desc, Def.Desc)
            fAssert(false)
        end
    end
    ffi.copy(s_SceneObjectDef[s_SceneObjectDefCount], Def, ffi.sizeof(fSceneObjectDef_t))
    s_SceneObjectDefCount = s_SceneObjectDefCount + 1
    ftrace("SceneObject[%30s] Defined\n", Def.Desc)
end

-- //********************************************************************************************************************

function fSceneObject_DefFindType( ID)

    for i=0 ,s_SceneObjectDefCount-1 do

        if (s_SceneObjectDef[i].ObjectType == ID) then return s_SceneObjectDef[i] end
    end

    -- // always return a valid object
    ftrace("ID: %08x\n", ID)
    fAssert(false)
    return nil
end

-- //********************************************************************************************************************

function fSceneObject_DefFindMagic( Magic)

    for i=0, s_SceneObjectDefCount-1 do

        if (s_SceneObjectDef[i].Magic == Magic) then return s_SceneObjectDef[i] end
    end

    -- // always return a valid object
    printf("Magic: %08x\n", Magic)
    fAssert(false)
    return nil
end

-- //********************************************************************************************************************
-- // globals set value
function lSceneObject_GlobalSet( G, Key )

    fAssert(G)
    fAssert(Key)

    return fSceneGlobal_Set(G, Key)
end

-- //********************************************************************************************************************
-- // globals get value
function lSceneObject_GlobalGet( Key )

    local G = _G.fGlobal
    fAssert(G)
    fAssert(Key)

    return fSceneGlobal_Get(G, Key)
end

-- //********************************************************************************************************************
-- // retreives the object from lua state
function fSceneObject_toObject(S)

    local O = toSceneObject(S.fObject)
    return O
end

-- //********************************************************************************************************************
-- // converts world space into local space (scene object)

function lSceneObject_World2Local( L )

    local wx = L[1]
    local wy = L[2]
    local wz = L[3]

    local O = fSceneObject_toObject(L)

    local iL2W = ffi.new("fMat44[1]")
    fScene_Node_iLocal2World(O.NodeList[0], iL2W)

    local lx = iL2W[0].m00*wx + iL2W[0].m01*wy + iL2W[0].m02*wz + iL2W[0].m03
    local ly = iL2W[0].m10*wx + iL2W[0].m11*wy + iL2W[0].m12*wz + iL2W[0].m13
    local lz = iL2W[0].m20*wx + iL2W[0].m21*wy + iL2W[0].m22*wz + iL2W[0].m23

    local T = {}

    T.x = lx
    T.y = ly
    T.z = lz

    return T
end

-- //********************************************************************************************************************
-- // converts local space into world space (scene object)
function lSceneObject_Local2World( L)

    local lx = L[1]
    local ly = L[2]
    local lz = L[3]

    local O = fSceneObject_toObject(L)

    local L2W = ffi.new("fMat44[1]")
    fScene_Node_Local2World(O.NodeList[0], L2W)

    local wx = L2W[0].m00*lx + L2W[0].m01*ly + L2W[0].m02*lz + L2W[0].m03
    local wy = L2W[0].m10*lx + L2W[0].m11*ly + L2W[0].m12*lz + L2W[0].m13
    local wz = L2W[0].m20*lx + L2W[0].m21*ly + L2W[0].m22*lz + L2W[0].m23

    local T = {}
    T.x = wx
    T.y = wy
    T.z = wz

    return T
end

-- //********************************************************************************************************************
-- // lua object space . world
function lSceneObject_SendQueue(SO, Path, GID, Payload)

    local O	= fSceneObject_toObject(SO)
    local PayloadLen		= ffi.sizeof(Payload)
    local S	= fSceneHost_Scene(O.Host)
    fScene_MessagePush(S, "SendPacket", Payload, PayloadLen)

    -- //ftrace("send [%s:%s] %i\n", GID, Path, PayloadLen)
    return 0
end

-- //********************************************************************************************************************
-- // gid where this object lives
function lSceneObject_thisGID( SO )

    local O = fSceneObject_toObject(SO)
    local gid = fModule_GID()
    -- //ftrace("lua this gid [%s]\n", gid)

    return grid
end

-- //********************************************************************************************************************
-- // name of the host where the object libes
function lSceneObject_thisHostName( L )

    local O = fSceneObject_toObject(L)
    local HostName = fSceneHost_Name(O.Host)
    -- //ftrace("lua host name[%s]\n", HostName)

    return HostName
end

-- //********************************************************************************************************************
-- // scene name where the host lies

function lSceneObject_thisSceneName( SO )

    local O = fSceneObject_toObject(SO)
    local SceneName = fSceneHost_SceneName(O.Host)
    -- //ftrace("lua scene name[%s]\n", SceneName)

    return SceneName
end

-- //********************************************************************************************************************
-- // url to this object

function lSceneObject_thisObjectURL(SO)

    local O = fSceneObject_toObject(SO)
    return O.URL
end

-- //********************************************************************************************************************
-- // request to fetch data from the web
function lSceneObject_HTTPGet(SO, Payload)

    local O 	= fSceneObject_toObject(SO)
    local S	    = fSceneHost_Scene(O.Host)
    fAssert(S)

    local PayloadLen		= ffi.sizeof(Payload)
    fScene_MessagePush(S, "HTTPGet", Payload, PayloadLen)

    return 0
end

-- //********************************************************************************************************************
-- // post data to the web

function lSceneObject_HTTPPost(SO, URL)

    local O = fSceneObject_toObject(SO)
    ftrace("http POST somthing to [%s]\n", URL)

    return 0
end

-- //********************************************************************************************************************
-- // fetch L2W xform for the specified node
function lSceneObject_NodeL2W(SO, URL)

    local O	= fAssertP(fSceneObject_toObject(SO), "no object?")
    local S	= fAssertP(fSceneHost_Scene(O.Host), "no scene!")
    -- //ftrace("fetch url [%s]\n", URL)

    local N	= fScene_Node_Find(S, URL)
    if (N == nil) then return 0 end

    local	L2W = ffi.new("fMat44[1]")
    fScene_Node_Local2World(N, L2W)
    return L2W
end

-- //********************************************************************************************************************
-- // fetch hosts frame no
function lSceneObject_HostFrameNo(SO, HostName)

    local O	= fAssertP(fSceneObject_toObject(SO), "no object?")
    local S	= fAssertP(fSceneHost_Scene(O.Host), "no scene!")

    if (HostName == nil) then return 0 end

    -- // search for it
    local H	= fSceneHost_Find(S, HostName)
    if (H == nil) then return 0 end

    -- // get the frame no !
    local FrameNo = fSceneHost_FrameNo(H)
    return FrameNo
end

-- //********************************************************************************************************************

function fSceneObject_LuaCreate(S, O, Type, Flag, arg, arglen, lIncCount, lInc)

    -- // allocate lua state
    O.lvm = {}
    O.lvm.fBase = getenv("FMAD_ROOT")

    -- // bind global object
    O.lvm.fGlobal = fScene_Global(S)

    -- // bind this scene object
    O.lvm.fObject = O

    lua_gettable(O.lvm, -3)
    lua_pushliteral(O.lvm, "format")
    lua_gettable(O.lvm, -3)

    O.lvm.ftrace = lSceneObject_ftrace

    O.lvm.etrace=lSceneObject_etrace
    O.lvm.fGlobal_Get=lSceneObject_GlobalGet
    O.lvm.fWorld2Local=lSceneObject_World2Local
    O.lvm.fLocal2World=lSceneObject_Local2World
    O.lvm.SendQueue=lSceneObject_SendQueue
    O.lvm.thisGID=lSceneObject_thisGID
    O.lvm.thisSceneName=lSceneObject_thisSceneName
    O.lvm.thisHostName=lSceneObject_thisHostName
    O.lvm.thisObjectURL=lSceneObject_thisObjectURL
    O.lvm.NodeL2W=lSceneObject_NodeL2W
    O.lvm.HostFrameNo=lSceneObject_HostFrameNo

    -- // access to the web
    O.lvm.HTTPGet=lSceneObject_HTTPGet
    O.lvm.HTTPPost=lSceneObject_HTTPPost

    O.Type			= Type
    O.Flag			= Flag
    O.ID			= fScene_ObjectID_New(S)

    O.PacketTx_Head	= nil
    O.PacketTx_Tail	= nil

    O.PacketRx_Head	= nil
    O.PacketRx_Tail	= nil

    -- // init code
--    luainc_load(O.lvm, sizeof(m_LuaInclude)/sizeof(LuaInclude_t), m_LuaInclude, true)

    -- // object specific pre-defines
    -- // note: these functions can be overwritten by the user
    if (lInc ~= nil) then

        --luainc_load(O.lvm, lIncCount, lInc, true)
    end

    -- // init the object
    O.lvm.Setup(arg)

    -- // object has custom constructor ?
    if (O.lvm.Init ~= nil) then
        O.lvm.Init()
    end

    local ObjectName = O.lvm.ObjectName
    local ObjectPath = O.lvm.ObjectPath

    O.Name = ObjectName
    O.Path = ObjectPath

    -- // default nil
    O.NodeCount = 0
    O.NodeList = s_NodeListnil

    -- // set magic
    O.Magic2 = SCENEOBJECT_MAGIC

    return 1
end

-- //********************************************************************************************************************
-- // wild card entry
function fSceneObject_LuaDestroy( S, O)

    -- // object has custom desrut ?
    fScene_Validate(S)

    if (O.lvm.Shutdown ~= nil) then
        O.lvm.Shutdown()
    end

    -- // call appropriate destruct
    O.lvm = nil
end

-- //********************************************************************************************************************

function fSceneObject_BoundingSphere( O, Center, Radius)

    -- // default
    Center[0] = 0.0
    Center[1] = 0.0
    Center[2] = 0.0
    Radius[0] = 0.0

    -- // call update method
    local Def = fSceneObject_DefFindMagic(O.Magic)

    -- // interface exists?
    if (Def.FnBoundingSphere == nil) then return false end

    -- // get it
    Def.FnBoundingSphere(O, Center, Radius)

    return true
end

-- //********************************************************************************************************************

function fSceneObject_BoundingBox( O, Min, Max)

    -- // default
    Min[0] = 10e6
    Min[1] = 10e6
    Min[2] = 10e6

    Max[0] = -10e6
    Max[1] = -10e6
    Max[2] = -10e6

    -- // call update method
    local Def = fSceneObject_DefFindMagic(O.Magic)

    -- // interface exists?
    if (Def.FnBoundingBox == nil) then return false end

    -- // get it
    Def.FnBoundingBox(O, Min, Max)

    return true
end

-- //********************************************************************************************************************
-- // check if scene object is valid
function fSceneObject_ValidateEx( O, File, Line)

    if (O.Magic2 ~= SCENEOBJECT_MAGIC) then

        ftrace("invalid object: magic invalid %08x\n", O)
        fAssertFL(false, File, Line)
    end

    -- // make sure its a valid type
    local Valid = false
    for i=0, s_SceneObjectDefCount-1 do

        if (s_SceneObjectDef[i].ObjectType == O.Type) then

            Valid = true
            break
        end
    end
    fAssertFL(Valid, File, Line)

    return true
end

-- //********************************************************************************************************************
-- // send packet to a scene object
function lSceneObject_Packet(S, SO, Cmd, Serial)

    S	= toScene(S)
    fAssert(SO)
    fAssert(SO.Magic2 == SCENEOBJECT_MAGIC)

    if (Cmd == nil) then

        ftrace("lSceneObject_Packet: invalid command\n")
        return 0
    end

    -- // serailzied data
    local SerialLen = ffi.sizeof(Serial)
    fAssert(Serial)

    -- // queue local packet
    local P = ffi.new("fSceneObjectPacket_t")
    ffi.copy(P.Cmd, Cmd, ffi.sizeof(P.Cmd))

    P.PayloadSize	= SerialLen
    P.Payload	= fMalloc(P.PayloadSize)
    fAssert(P.Payload)
    ffi.copy(P.Payload, Serial, P.PayloadSize)
    P.Next = nil

    if (SO.PacketRx_Tail == nil) then

        SO.PacketRx_Head = P
        SO.PacketRx_Tail = P
    else

        SO.PacketRx_Tail.Next = P
        SO.PacketRx_Tail = P
    end

    -- // send same packet to all slave objects
    -- // ..
    return 0
end

-- //********************************************************************************************************************
-- // enum to string
function fSceneObject_TypeToStr( Type)

    -- // check for collision
    for i=0, s_SceneObjectDefCount-1 do

        if (s_SceneObjectDef[i].ObjectType == Type) then return s_SceneObjectDef[i].Desc end
    end
    return "Undefined"
end

-- //********************************************************************************************************************
-- // string to mask

function fSceneObject_StrToType(Str)

    if (Str == nil) then

        ftrace("fSceneObject_StrToType: invalid string\n")
        return 0
    end

    -- // check for collision
    for i=0, s_SceneObjectDefCount-1 do

        local Desc = s_SceneObjectDef[i].Desc
        if (Desc[0] == Str[0]) then

            if (strcmp(Desc, Str) == 0) then

                return s_SceneObjectDef[i].ObjectType
            end
        end
    end
    return 0
end

-- //********************************************************************************************************************
function lSceneObject_Serialize( SO )

    local O = toSceneObject(SO)
    local T = {}
    T.Name = O.Name
    T.Path = O.Path
    T.Type = fSceneObject_TypeToStr(O.Type)
    T.Flag = O.Flag
    T.ID = O.ID

    -- // serailize objects _G[] table
    local Ser = O.lvm.Serialize
    local res = Ser(T)

    -- // probs here, duno how you detect returning a string as error vs function returning an error string
    local len = string.length(res)

    T.LVM = res
    ftrace("[%s] persist lvm size: %i\n", O.URL, len)
    return T
end

-- //********************************************************************************************************************
-- // retreive dynamics info about an object (if it exists)
function lSceneObject_Dynamic( SN, SO )

    local N	= toSceneNode(SN)
    local O	= toSceneObject(SO)

    -- // table fo info
    local T = {}

    -- // does it have a dynamics node ?
    local D = fScene_Node_Dynamic(N)
    if (D == nil) then

        dtrace("Node[%s] has no dynamics object\n", fScene_Node_Path(N))
        return 1
    end
    ftrace("get dynamics info [%s]\n", fScene_Node_Path(N))

    -- // process dynamics object
    if (D.Def.FnDynamicInfo ~= nil) then

        T = D.Def.FnDynamicInfo( T, N, O, D)
    end
    return T
end

-- //********************************************************************************************************************
-- // fetch command info
function lSceneObject_Info( SO )

    local O	= toSceneObject(SO)

    -- // table fo info
    local T = {}

    -- // process dynamics object
    if (O.Def.FnObjectInfo ~= nil) then

        O.Def.FnObjectInfo( T, O)
    end
    return T
end

-- //********************************************************************************************************************
-- // recurse from global space to the specified object

function fSceneObject_TableFind(path, id)

    local pathid = _G

    local top = 0
    local pos = 0
    local depth = 0
    local idpos = 0
    while (pos < #path) do

        local c = string.sub(path, pos, pos)
        if (c == 0) or (c == '/') then

            printf("level: [%s]\n", id)
            local pathid = pathid[id]
            depth = depth + 1

            if (pathid == nil) then

                printf("unable to find field [%s] %s\n", id, path)
                return depth -1
            end

            top = pos+1
            pos = top
            id  = ""
        end
        id = id..c
        pos = pos + 1
    end

    -- // note: pos < strlen(path) means nil string for final object isnt processed above

    return depth
end

-- //********************************************************************************************************************
-- // set a variable in an object

function lSceneObject_VariableSet( SO, name, value)

    local O = toSceneObject(SO)
    fAssert(name)

    -- // find the table
    local id = ""
    local depth = fSceneObject_TableFind(name, id)
    if (depth == -1) then

        return 0
    end

    -- TODO: Need to sort this: I think we can use s simple deepcopy of a variable.
    -- // copy variable (L[-1]) to scene object
--    lua_deep_copy(O.lvm, L)
--
--    -- // set it
--    lua_setfield(O.lvm, -2, id)
--
--    -- // pop table hier
--    lua_pop(O.lvm, depth+1)

    return 1
end

-- //********************************************************************************************************************
-- // set a variable in an object
function lSceneObject_VariableDelete(SO, name)

    local O = toSceneObject(SO)
    fAssert(name)

    -- // find the table
    local id = ""
    local depth = fSceneObject_TableFind(name, id)
    if (depth == -1) then

        return 0
    end
    -- //printf("new: %s\n", id)

    -- // set to nil
--    lua_pushnil(O.lvm)
--    lua_setfield(O.lvm, -2, id)
--
--    -- // release all including _G
--    lua_pop(O.lvm, depth+1)

    return 0
end

-- //********************************************************************************************************************
-- // set a variable in an object
function lSceneObject_VariableCreate(SO, path)

    local O = toSceneObject(SO)
    fAssert(path)

    -- // find the table
    -- //printf("variable create [%s]\n", path)
    local id = ""
    local depth = fSceneObject_TableFind( path, id)
    if (depth == -1) then

        return 0
    end

    ftrace("id [%s]\n", id)

--    lua_checkstack(O.lvm, 3)
--    lua_pushstring(O.lvm, "")
--    lua_setfield(O.lvm, -2, id)
--
--    -- // release all including _G
--    lua_pop(O.lvm, depth+1)

    return 0
end

-- //********************************************************************************************************************
-- // get a variable in an object
function lSceneObject_VariableType(SO, path)

    local O 	= toSceneObject(SO)
    path	    = fAssertP(path, "invalid variable path")

    -- // find the table
    local id = ""
    local depth = fSceneObject_TableFind(path, id)
    if (depth == -1) then

        return 0
    end

    -- // get the type
--    lua_getfield(O.lvm, -1, id)
--    if (lua_isnil(O.lvm, -1))
--    {
--    ftrace("lSceneObject_VariableType: field [%s] not found in path [%s]\n", id, path)
--    lua_pop(O.lvm, depth+2)
--
--    lua_pushnil(L)
--    return 1
--    }
--
--    const char* type = lua_typename(O.lvm, lua_type(O.lvm, -1))
--    lua_pop(O.lvm, depth+2)

    -- // type name
    -- lua_pushstring(L, type)
    fAssert(false)
    return "Uknown"
end

-- //********************************************************************************************************************
-- // gets entire objects source

function lSceneObject_SourceGet(SO)

    local O = toSceneObject(SO)

    -- // fetch source (if it exists)
    local src = O.lvm.getSource()

    if (src == nil) then

        return ".. no source found .."
    end

    return tostring(src)
end

-- //********************************************************************************************************************
-- // sets an entire objects source
function lSceneObject_SourceSet( SO, Source )

    local O = toSceneObject(SO)

    -- // fetch source (if it exists)
    local res = O.lvm.setSource(Source)

    if (res == nil) then
        return ".. no source found .."
    end
    return res
end

-- //********************************************************************************************************************
-- // gets function source code
function lSceneObject_FnSourceGet(SO, FnName)

    local O = toSceneObject(SO)
    -- // fetch source (if it exists)
    local src = O.lvm.getFunctionSource(FnName)

    if (src == nil) then

        return ".. no source found .."
    end

    return src
end

-- //********************************************************************************************************************
-- // sets function code
function lSceneObject_FunctionSet(SO, FnName, Code)

    local O	= toSceneObject(SO)
    local CodeLen		= string.length(Code)

    ftrace("code len %i\n", CodeLen)
    -- // fetch source (if it exists)

    O.lvm.setFunction(FnName, Code)
    return 0
end

-- //********************************************************************************************************************

function lSceneObject_Create( SO, , S, arg)
{
    const char* Type = lua_getfield_string(L, -4, "Type", nil)
    fAssert(Type)

    const char* Host = lua_getfield_string(L, -4, "Host", nil)
    fAssert(Host)

    struct fScene_t* S = toScene(L, -2)

    u32 arglen = 0
    const char* arg = lua_tolstring(L, -1, &arglen)

    -- // add to host list
    struct fSceneHost_t* H = fSceneHost_Find(S, Host)
    if (!H)
    {
    ftrace("no host named [%s]\n", Host)
    return 0
    }
    fAssert(H)

    -- // search
    fSceneObjectDef_t* Def = fSceneObject_DefFindType(fSceneObject_StrToType(Type))
    fAssert(Def)

    -- // allocate mem

    fSceneObject_t* O = fMalloc(Def.StructSize)
    memset(O, 0, Def.StructSize)

    -- // set interfaace

    O.Def 	= Def

    -- // create object
    fAssert(Def.ObjectType ~= 0)
    fSceneObject_LuaCreate(S, O, Def.ObjectType, Def.ObjectFlag, arg, arglen, Def.lScriptCount, Def.lScript)

    -- // set object magic number

    O.Magic = Def.Magic

    -- // object specific settings

    ((lSceneObject_Create_f *)Def.FnCreate)(S, O)

    -- // add to host
    fSceneHost_ObjectAdd(H, O)

    -- // set full url
    fSceneURL_Generate(O.URL, "object", fSceneHost_Name(H), O.Path, nil, nil)
    -- // return it

    lua_pushlightuserdata(L, O)
    return 1
end

-- //********************************************************************************************************************

static int lSceneObject_Destroy(lua_State* L)
{
struct fScene_t* S = toScene(L, -2)
struct fSceneObject_t* O = lua_touserdata(L, -1)
if (O == nil)
{
ftrace("sceneobject_destroy no object\n")
return 0
}
return fSceneObject_Destroy(S, O)
}

-- //********************************************************************************************************************

int fSceneObject_Destroy(struct fScene_t* S, struct fSceneObject_t* O)
{
-- // get definition
fSceneObjectDef_t* Def = O.Def
fAssert(Def)

-- // get host
struct fSceneHost_t* H = O.Host
fAssert(H)

fScene_Validate(S)

-- // custom destroy

((lSceneObject_Destroy_f *)Def.FnDestroy)(S, O)

-- // relese scene object

fSceneObject_LuaDestroy(S, O)

-- // remove from scene

fSceneHost_ObjectDel(H, O)

-- // notify cache
fSceneCache_ObjectDel(fScene_Cache(S), O)

-- // flag magic
O.Magic = 0xdeaddead
fScene_Validate(S)

-- // delete node list
if (O.NodeList && (O.NodeList ~= s_NodeListnil) )
{
memset(O.NodeList, 0, O.NodeCount*sizeof(struct fSceneNode_t*))
fFree(O.NodeList)
O.NodeList = nil
}

-- // release struct
memset(O, 0, Def.StructSize)
fFree(O)

fScene_Validate(S)

return 1
}

-- //********************************************************************************************************************
-- // updates the objects internal and returns the lustate where the top argument is the returned values
void fSceneObject_Update(fSceneObject_t* O, double t)
{
-- // process packets
fSceneObjectPacket_t* P = O.PacketRx_Head
while (P)
{
fSceneObjectPacket_t* N = P.Next

-- // call
lua_getglobal(O.lvm, "DispatchPacket")
fAssert(!lua_isnil(O.lvm, -1))

lua_pushstring(O.lvm, P.Cmd)
lua_pushlstring(O.lvm, P.Payload, P.PayloadSize)
lua_pcall(O.lvm, 2, 0, 0)

-- // free payload
fFree(P.Payload)

-- // release and next

fFree(P)
P = N
}
O.PacketRx_Head = nil
O.PacketRx_Tail = nil

-- //ftrace("scene obj update %s\n", O.Name)
u32 TopPre = lua_gettop(O.lvm)
lua_getglobal(O.lvm, "Update")
bool Called = false
if (!lua_isnil(O.lvm, -1))
{
-- // update it
lua_pushnumber(O.lvm, t)
lua_pcall(O.lvm, 1, 0, 0)
luaCallCheck(O)
Called = true
}
else
{
-- // remove the nil
lua_pop(O.lvm, 1)
}
u32 TopPost = lua_gettop(O.lvm)

if (TopPre ~= TopPost)
{
ftrace("[%-30s] scene object leak %i:%i : called%i\n", O.URL, TopPre, TopPost, Called)
}

-- // call update method
-- //fSceneObjectDef_t* Def = fSceneObject_DefFindMagic(O.Magic)
fSceneObjectDef_t* Def = O.Def

if (Def.FnUpdate)
{
((lSceneObject_Update_f *)Def.FnUpdate)(O, t)
}

-- // update node xforms
if ((O.Flag & fSceneObject_Flag_XForm) && Def.FnNodeXForm)
{
-- // update all parent nodes
for (int n=0 n < O.NodeCount n++)
{
struct fSceneNode_t* N = O.NodeList[n]

-- // get address of xform
fMat44* Local, *iLocal
struct fSceneObject_t* Controller = fScene_Node_XFormPtr(N, &Local, &iLocal)

-- // this controller shouldnt update the nodes xform
if ((Controller ~= nil) && (Controller ~= O))
{
Local = nil
iLocal = nil
}

-- // update it
((lSceneObject_NodeXForm_f *)Def.FnNodeXForm)(O, Local, iLocal)
}
}
}

-- //********************************************************************************************************************

static int lSceneObject_UserControl(lua_State* L)
{
const char* LocalPath	= fAssertP(lua_tostring(L, -4), "invalid local path")
struct fSceneNode_t* N	= lua_touserdata(L, -3)
fAssert(N)

fSceneObject_t* O	= lua_touserdata(L, -2)
-- //fAssert(O.Magic == Def.Magic)
struct fSceneHost_t* H	= fScene_Node_Host(N)

-- // search
fSceneObjectDef_t* Def	= O.Def
fAssert(Def)

-- // generate user controls
int objlen = 0
if (Def.FnUserControl)
{
objlen = ((lSceneObject_UserControl_f *)Def.FnUserControl)(L, N, O)
}

-- // default fields for the client side to uniquely identify each object
if (objlen > 0)
{
-- // node
char NodeURL[1024]
sprintf(NodeURL, "node:-- //localhost%s", LocalPath)
for (int i=strlen(NodeURL) i > 0 i--)
{
if (NodeURL[i] == '/')
{
NodeURL[i] = 0
break
}
}

-- // node xforms
fMat44 L2W, iL2W, Local, iLocal
fScene_Node_Local2World(N, &L2W)
fScene_Node_iLocal2World(N, &iL2W)

fScene_Node_Local(N, &Local)
fScene_Node_iLocal(N, &iLocal)

/*
-- // get node bounding box (assposed to objects) this includes all children
-- // note: want the box in nodes local xform, thus passing iLocal instead
-- // of ident as the parent xform
float LMin[3], LMax[3]
fScene_Node_BoundingBox(N, iLocal, LMin, LMax)

lua_setfield_xyz(L, -1, "NodeOrigin",	 	0, 0, 0)
lua_setfield_xyz(L, -1, "NodeMin",		LMin[0], LMin[1], LMin[2])
lua_setfield_xyz(L, -1, "NodeMax",		LMax[0], LMax[1], LMax[2])
*/

-- // this objects xform url
char XFormURL[1024]
fScene_NodeObjectURL(N, fScene_Node_XForm(N), XFormURL)
lua_setfield_string(L, -1, "XFormURL", XFormURL)
-- //ftrace("XForm URL: [%s]\n", XFormURL)

-- // object
char ObjectURL[1024]
sprintf(ObjectURL, "node:-- //localhost%s", LocalPath)
-- //printf("[%-30s] [%-30s]\n", NodeURL, ObjectURL)

-- // get last part of local path
int Start
for (Start=strlen(NodeURL)-1 Start > 0 Start--)
{
if (NodeURL[Start] == '/') break
}
Start = (Start < 1) ? 1 : Start

char LocalName[1024]
strncpy(LocalName, &NodeURL[Start+1], sizeof(LocalName))

-- // base fields

lua_setfield_string(L, -1, "Key", 		fScene_Node_ObjectKey(N, O))
lua_setfield_string(L, -1, "Type", 		Def.Desc)
lua_setfield_string(L, -1, "Name", 		LocalName)
lua_setfield_string(L, -1, "NodeURL",	 	NodeURL)
lua_setfield_string(L, -1, "ObjectURL",		ObjectURL)
lua_setfield_boolean(L, -1, "Locked",		fScene_Node_LockedGet(N) )

-- // parent path

const char ParentURL[1024]
fSceneURL_Parent(ParentURL, NodeURL)
lua_setfield_string(L, -1, "NodeParentURL",	ParentURL)

-- // l2w xform in rotation / translation
lua_setfield_matrix44(L, -1, "L2W",		(float*)&L2W)
lua_setfield_matrix44(L, -1, "iL2W",		(float*)&iL2W)

-- // decompose into R/T

float Q[4]
float T[3]
float S[3]
fMat44_Decompose(&L2W, Q, T, S)
lua_setfield_xyz(L, -1, "tL2W",			T[0], T[1], T[2])
lua_setfield_xyzw(L, -1, "rL2W",		Q[0], Q[1], Q[2], Q[3])

-- // local xform

lua_setfield_matrix44(L, -1, "Local",		(float*)&Local)
lua_setfield_matrix44(L, -1, "iLocal",		(float*)&iLocal)

fMat44_Decompose(&Local, Q, T, S)
lua_setfield_xyz(L, -1, "tLocal",		T[0], T[1], T[2])
lua_setfield_xyzw(L, -1, "rLocal",		Q[0], Q[1], Q[2], Q[3])
}
return objlen
}

-- //********************************************************************************************************************
-- // extract tri soupe
int fSceneObject_TriSoup(struct fSceneObject_t* O, fMat44* XForm, u32 Offset, u32 Max, float* Vertex)
{
fSceneObjectDef_t* Def	= fAssertP(O.Def, "no object definition!")

-- // not renderable so def not a mesh
if ((O.Flag & fSceneObject_Flag_Render) == 0) return Offset

-- // get realized streams
u32 StreamLength[128]		-- // number of packets in each stream
u32 StreamSize[128]		-- // size in bytes of 1 packet of the stream
void* Stream[128]		-- // array of packets

-- // append packets to send in the table
u32 Streams = ((lSceneObject_RealizeSend_f *)Def.FnRealizeSend)(O, StreamLength, StreamSize, Stream)

-- // is it tri mesh?
fRealizeHeader_t* H = Stream[0]
if (H.CmdID ~= fRealizeCmdID_TriMeshHeader)
{
-- // renderable but not a tri mesh
return Offset
}

-- // build tmp vertex list
fRealizeTriMesh_t* RM = Stream[0]
float* MVertex = fMalloc(3*sizeof(float)*RM.VertexCount)

fRealizeTriMeshVertex_t* RV = Stream[2]
for (int i=0 i < StreamLength[2] i++)
{
fAssert(RV.Header.CmdID == fRealizeCmdID_TriMeshVertex)
for (int j=0 j < RV.VertexCount j++)
{
float x = RV.List[j].Px
float y = RV.List[j].Py
float z = RV.List[j].Pz

u32 Index = RV.VertexOffset + j
fAssert(Index < RM.VertexCount)
MVertex[Index*3 + 0] = XForm.m00*x + XForm.m01*y + XForm.m02*z + XForm.m03
MVertex[Index*3 + 1] = XForm.m10*x + XForm.m11*y + XForm.m12*z + XForm.m13
MVertex[Index*3 + 2] = XForm.m20*x + XForm.m21*y + XForm.m22*z + XForm.m23
}
RV++
}

-- // add tris
fRealizeTriMeshIndex_t* RI = Stream[1]
float *V = &Vertex[Offset*3]
for (int i=0 i < StreamLength[1] i++)
{
fAssert(RI.Header.CmdID == fRealizeCmdID_TriMeshIndex)
for (int j=0 j < RI.IndexCount j++)
{
if (Offset >= Max) break

u32 p0 = RI.List[j].p0
u32 p1 = RI.List[j].p1
u32 p2 = RI.List[j].p2

V[0*3 + 0] = MVertex[p0*3+0]
V[0*3 + 1] = MVertex[p0*3+1]
V[0*3 + 2] = MVertex[p0*3+2]

V[1*3 + 0] = MVertex[p1*3+0]
V[1*3 + 1] = MVertex[p1*3+1]
V[1*3 + 2] = MVertex[p1*3+2]

V[2*3 + 0] = MVertex[p2*3+0]
V[2*3 + 1] = MVertex[p2*3+1]
V[2*3 + 2] = MVertex[p2*3+2]
V += 3*3
Offset += 3
}
RI++
}

-- // release temp vertex
fFree(MVertex)

-- // new vertex count
return Offset
}

-- //********************************************************************************************************************

int fSceneObject_RealizeEncode
(
lua_State*		L,
struct fScene_t*	S,
u32			SceneID,
struct fSceneCache_t*	Cache,
fSceneObject_t*		O,
const char*		Mode
){
fSceneObjectDef_t* Def	= O.Def
fAssert(Def)

fSceneObject_Assert(O, Def.Magic)

-- // not realizable
if (Def.FnRealizeEncode == nil)
{
return 0
}
fAssert(Def.FnRealizeSend)	-- // if theres an encoding there must be a send

-- // get current object crc32

u32 TopCRC32 = ((lSceneObject_RealizeEncode_f *)Def.FnRealizeEncode)(S, O)

-- // get stream info

u32 StreamLength[128]		-- // number of packets in each stream
u32 StreamSize[128]		-- // size in bytes of 1 packet of the stream
void* Stream[128]		-- // array of packets

-- // append packets to send in the table
u32 Streams = ((lSceneObject_RealizeSend_f *)Def.FnRealizeSend)(O, StreamLength, StreamSize, Stream)

-- // update cache
switch (Mode[0])
{
case 'T'/*TABLE*/:
return fSceneCache_Table(L, Cache, 0, O.ID, TopCRC32, Streams, StreamLength, StreamSize, Stream)

case 'N'/*NETWORK*/:
fSceneCache_Stream(Cache, 0, O.ID, Def.RealizeType, SceneID, TopCRC32, Streams, StreamLength, StreamSize, Stream)
break
default:
printf("Realize mode [%s]\n", Mode)
fAssert(false)
break
}

return 0
}

-- //********************************************************************************************************************

static int lSceneObject_Realize(lua_State* L)
{
struct fScene_t* S	= toScene(L, -5)
u32 SceneID		= lua_tonumber(L, -4)

struct fSceneCache_t* Cache = toSceneCache(L, -3)

fSceneObject_t* O	= lua_touserdata(L, -2)
const char* Mode	= lua_tostring(L, -1)

return fSceneObject_RealizeEncode(L, S, SceneID, Cache, O, Mode)
}

-- //********************************************************************************************************************
-- // exports the specified object to disk
static int lSceneObject_Export(lua_State* L)
{
fSceneObject_t* O	= toSceneObject(L, -2)
const char* OutputFile	= lua_tostring(L, -1)

-- // call lua export function (if it exists)
lua_getglobal(O.lvm, "ObjectExport")
if (!lua_isnil(O.lvm, -1))
{
-- // export it
lua_pushstring(O.lvm, OutputFile)
lua_pcall(O.lvm, 1, 0, 0)
luaCallCheck(O)
}
return 0
}

-- //********************************************************************************************************************
-- // helper to convert node + object into full path
void fSceneObject_FullPath(char* Path, u32 MaxLen, const char* NodePath, const char* Key)
{
if (strcmp(NodePath, "/") == 0)
{
if (Key[0] == '/')
{
strcpy(Path, Key)
return
}
sprintf(Path, "/%s", Key)
return
}

const char* msg = (NodePath[strlen(NodePath)-1] == '/') ? "%s%s" : "%s/%s"
sprintf(Path, msg, NodePath, Key)
}

-- //********************************************************************************************************************
-- // creates a new scene object
static fSceneExternal_t		s_SceneExternal
static int lSceneObject_Define(lua_State* L)
{
const char* Desc = lua_tostring(L, -2)
printf("scene object define: [%s]\n", Desc)

u32 BCLen	= 0
const char* _Buf= lua_tolstring(L, -1, &BCLen)

-- // need to nil terminiate it...
char* BC = (char *)fMalloc(BCLen+1)
memcpy(BC, _Buf, BCLen)
BC[BCLen] = 0

printf("byte code: %i\n", BCLen)

-- // generate the module code
char EntryPoint[128]
sprintf(EntryPoint, "%s_Open", Desc)
printf("scene object entry point [%s]\n", EntryPoint)

fExecuteJIT(BC, BCLen, EntryPoint, &s_SceneExternal)
fFree(BC)

return 0
}

---- //********************************************************************************************************************
--
--int fSceneObject_Register(lua_State* L)
--{
--lua_table_register(L, -1, "SceneObject_Packet",		lSceneObject_Packet)
--lua_table_register(L, -1, "SceneObject_Serialize",	lSceneObject_Serialize)
--lua_table_register(L, -1, "SceneObject_VariableSet",	lSceneObject_VariableSet)
--lua_table_register(L, -1, "SceneObject_VariableType",	lSceneObject_VariableType)
--lua_table_register(L, -1, "SceneObject_VariableDelete",	lSceneObject_VariableDelete)
--lua_table_register(L, -1, "SceneObject_VariableCreate",	lSceneObject_VariableCreate)
---- //lua_table_register(L, -1, "SceneObject_FunctionGet",	lSceneObject_FunctionGet)
--lua_table_register(L, -1, "SceneObject_FunctionSet",	lSceneObject_FunctionSet)
--
--lua_table_register(L, -1, "SceneObject_SourceGet",	lSceneObject_SourceGet)
--lua_table_register(L, -1, "SceneObject_SourceSet",	lSceneObject_SourceSet)
--
--lua_table_register(L, -1, "SceneObject_Define",		lSceneObject_Define)
--lua_table_register(L, -1, "SceneObject_Create",		lSceneObject_Create)
--lua_table_register(L, -1, "SceneObject_Destroy",	lSceneObject_Destroy)
--lua_table_register(L, -1, "SceneObject_UserControl",	lSceneObject_UserControl)
--lua_table_register(L, -1, "SceneObject_Dynamic",	lSceneObject_Dynamic)
--lua_table_register(L, -1, "SceneObject_Info",		lSceneObject_Info)
--lua_table_register(L, -1, "SceneObject_Realize",	lSceneObject_Realize)
--lua_table_register(L, -1, "SceneObject_Export",		lSceneObject_Export)
--
---- // external interfaces for scene objects
--
--s_SceneExternal.SceneObject_Define	= fSceneObject_Define
--s_SceneExternal.SceneNode_Local2World	= fScene_Node_Local2World
--s_SceneExternal.SceneNode_iLocal2World	= fScene_Node_iLocal2World
--s_SceneExternal.SceneNode_XForm		= fScene_Node_XForm
--s_SceneExternal.SceneNode_Dynamic	= fScene_Node_Dynamic
--s_SceneExternal.SceneObject_Find	= fScene_ObjectFindURL
--s_SceneExternal.SceneHost_FrameNo	= fSceneHost_FrameNo
--
--s_SceneExternal.Image_Load		= fImage_Load
--s_SceneExternal.Image_Save		= fImage_Save
--s_SceneExternal.Image_Free		= fImage_Free
--}
