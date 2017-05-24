--
-- Created by David Lannan
-- User: grover
-- Date: 16/05/13
-- Time: 7:14 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--
-- -- //********************************************************************************************************************

local fSc = require("byt3d/fmad/World/fScene_h")

-- -- //********************************************************************************************************************

SCENE_MAGIC		    = 0xbeef7777
SCENE_NODE_MAGIC	= 0x13370003

-- -- //********************************************************************************************************************

function toScene( L )

    local S = L
    fAssert(S ~= nil)
    fAssert(S.Header.Magic == fSc.SCENE_MAGIC)

    -- // causes huge perf penelty as checks the entire scene. use only for debug
    -- //fScene_Validate(S)

    return S
end

-- //********************************************************************************************************************

function toSceneNode( L )

    local N = L
    fAssert(N ~= nil)
    fAssert(N.Magic == fSc.SCENE_NODE_MAGIC)
    return N
end

-- //********************************************************************************************************************
-- // HOST
-- //********************************************************************************************************************
-- //
-- //********************************************************************************************************************
-- // create a host entry
function fSceneHost_Create( S, Name )

    local H = ffi.new("fSceneHost_t")
    ffi.fill(H, ffi.sizeof("fSceneHost_t"), 0)

    H.Scene = S
    H.Name = Name
    H.URL = string.format("node:-- //%s/", Name)

    -- // create root node
    H.NodeRoot = Node_Create("/", fSc.fSceneNode_Flag_ROOT)
    fSceneHost_NodeAdd(H, H.NodeRoot)

    H.HostNext	= nil
    H.HostPrev	= nil

    return H
end

-- //********************************************************************************************************************
-- // find a host
function fSceneHost_Find( S, Name )

    local H = S.HostHead
    while (H ~= nil) do

        if (H.Name == Name) then

            return H
        end
        H = H.HostNext
    end
    return nil
end

-- //********************************************************************************************************************
-- // add a node
function fSceneHost_NodeAdd( H, N )

    if (H.NodeTail ~= nil) then

        H.NodeTail.NodeNext = N
    end

    N.NodePrev = H.NodeTail
    H.NodeTail = N

    -- // first node ?
    if (H.NodeHead == nil) then

        H.NodeHead = N
        H.NodeTail = N
    end

    H.NodeCount = H.NodeCount + 1
    N.Host		= H

    return H.NodeCount-1
end

-- //********************************************************************************************************************
-- // delete a node
function fSceneHost_NodeDel( H, N )

    fAssertP(H, "host invalid")
    fAssertP(N, "node invalid")

    if (H.NodeHead == N) then H.NodeHead = N.NodeNext end
    if (H.NodeTail == N) then H.NodeTail = N.NodePrev end
    H.NodeCount = H.NodeCount -1

    -- // nodify cache
    fAssert (H.Scene ~= nil)

    -- // remove node from scene cache
    fSceneCache_NodeDel(H.Scene.Cache, N.ID)
end

-- //********************************************************************************************************************
-- // add a object
function fSceneHost_ObjectAdd( H, O )

    O.HostNext = H.ObjectHead
    H.ObjectHead = O
    H.ObjectCount = H.ObjectCount + 1

    -- // whos your daddy?
    O.Host = H
    -- //ftrace("scene object add: %08x %s . %08x\n", O, O.Name, O.HostNext)
end

-- //********************************************************************************************************************
-- // delete a node
function fSceneHost_ObjectDel( H, O )

    local P = H.ObjectHead
    while (P ~= nil ) do

        if (P.HostNext == O) then

            P.HostNext = O.HostNext
            break
        end
        P = P.HostNext
    end
    if (H.ObjectHead == O) then

        H.ObjectHead = O.HostNext
    end
    O.HostNext = nil

    -- // delete node child
    for i=0, O.NodeCount-1 do

        local N		= O.NodeList[i]
        fAssert(N ~= nil)

        -- // rebuild new list. take note if object is referenced multiple times in a node
        local NewCount = 0
        local NewList = ffi.new("fSceneObject_tPtr["..N.ObjectCount.."]")
        for i=0, N.ObjectCount-1 do

            if (N.ObjectList[i] ~= O) then
                NewList[NewCount] = N.ObjectList[i]
                NewCount = NewCount + 1
            end
        end

        fFree(N.ObjectList)
        N.ObjectCount = NewCount
        N.ObjectList = NewList
    end

    -- // remove from spacial hierarchy (if present)
    fSceneSpace_Remove(H.Scene.Space, O)
end

-- //********************************************************************************************************************
-- // lua create a host
function lScene_HostAdd( L, HostName )

    local S		= toScene(L)

    -- // create it
    local H = fSceneHost_Create(S, HostName)

    -- // append it
    H.HostPrev		    = S.HostTail
    S.HostTail.HostNext	= H
    S.HostTail		    = H

    return H
end

-- //********************************************************************************************************************
-- // delete a host
function lScene_HostDel( L, HostName )

    local S		= toScene(L)

    local H = fSceneHost_Find(S, HostName)
    if (H == nil) then return nil end

    -- // free it
    if (H.HostPrev) then H.HostPrev.HostNext = H.HostNext end
    if (H.HostNext) then H.HostNext.HostPrev = H.HostPrev end

    if (S.HostHead == H) then S.HostHead = H.HostNext end
    if (S.HostTail == H) then S.HostTail = H.HostPrev end

    -- // delete all objects
    local O = H.ObjectHead
    while (O ~= nil) do

        local ONext = O.HostNext
        fSceneObject_Destroy(S, O)
        O = ONext
    end

    -- // delete all node object
    local N = H.NodeHead
    while (N ~= nil) do

        local Next = N.NodeNext
        fScene_NodeDestroy(S, N)

        N = Next
    end

    -- // clear and free
    ffi.fill(H, ffi.sizeof("fSceneHost_t"), 0)
    fFree(H)

    return 0
end

-- //********************************************************************************************************************
-- // lua create a host
function lScene_HostFind( L, HostName )

    local S		= toScene(L)

    local H		= fSceneHost_Find(S, HostName)
    if (H == nil) then return 0 end

    -- // found
    return H
end

-- //********************************************************************************************************************
-- // host root node
function lScene_HostRoot( L )

    local H		= fAssertP( ffi.cast("fSceneHost_t*",L), "invalid host parameter")

    fAssert(H.NodeRoot)
    return H.NodeRoot
end

-- //********************************************************************************************************************
-- // returns list of current host names
function lScene_HostList( L )

    local S		= toScene(L)

    local tbl = {}
    local H = S.HostHead
    local Count = 1
    while (H ~= nil) do

        tbl[Count] = H.Name
        Count = Count + 1
        H = H.HostNext
    end
    return tbl
end

-- //********************************************************************************************************************
-- // host url
function fSceneHost_URL( H )

    fAssert(H)
    return H.URL
end

-- //********************************************************************************************************************
-- // host name
function fSceneHost_Name( H)

    fAssert(H)
    return H.Name
end

-- //********************************************************************************************************************
-- // scene name
function fSceneHost_SceneName( H)

    fAssert(H)
    local S = fAssertP(H.Scene, "invalid scene")
    return S.Name
end

-- //********************************************************************************************************************
-- // scene object
function fSceneHost_Scene( H)

    fAssert(H)
    return H.Scene
end

-- //********************************************************************************************************************
-- // host frame count
function fSceneHost_FrameNo( H )

    fAssert(H)
    return H.FrameCount
end

-- //********************************************************************************************************************
-- // NODE
-- //********************************************************************************************************************

-- //********************************************************************************************************************
-- // create it
function Node_Create( Name, Flag )

    local N = ffi.new("fSceneNode_t")
    fAssert(N ~= nil)

    ffi.fill(N, ffi.sizeof("fSceneNode_t"), 0)
    if (Name ~= nil) then

        N.Name = Name
    end

    if bit.band(Flag, fSc.fSceneNode_Flag_ROOT)then

        N.Path = Name
    end

    -- // reset xforms
    N.Local2World		= fMat44_Identity()
    N.iLocal2World		= fMat44_Identity()

    N.Local		        = fMat44_Identity()
    N.iLocal		    = fMat44_Identity()

    N.ControllerName[0]	= 0
    N.Controller		= nil

    N.LastUpdate		= 0
    N.Flag			    = Flag
    N.ID			    = 0
    N.Locked		    = false

    N.Parent		    = nil
    N.Child		        = nil
    N.Sibling		    = nil

    N.NodePrev		    = nil
    N.NodeNext		    = nil

    N.ObjectCount		= 0
    N.ObjectList		= nil

    N.Magic		        = fSc.SCENE_NODE_MAGIC

    return N
end

-- //********************************************************************************************************************
-- // add a new object
function lScene_NodeCreate( L )

    local S = toScene(L.Scene)

    local Name	= L.Name
    local Host	= L.Host

    -- // make sure host exists
    local H	= fSceneHost_Find(S, Host)
    if (H == nil) then

        ftrace("unable to find host [%s] failed to create node\n", Host)
        return 0
    end

    -- //printf("name: %s\n", Name)
    local N = Node_Create(Name, 0)

    -- // set host parent
    N.Host	= H

    -- // unique per scene node id
    N.ID	= fScene_NodeID_New(S)

    -- // set lock state
    N.Locked = L.Locked

    -- // add to the scene list
    fSceneHost_NodeAdd(N.Host, N)

    return N
end

-- //********************************************************************************************************************

function fScene_NodeDestroy( S, N )

    -- // remove parent child list
    local P  = N.Parent
    if (P ~= nil) then

        -- // remove from list
        local C = P.Child
        while (C ~= nil) do

            if (C.Sibling == N) then

                C.Sibling = N.Sibling
                break
            end
            C = C.Sibling
        end

        if (P.Child == N) then

            P.Child = N.Sibling
        end
    end

    -- // remove from child, parent

    local C = N.Child
    while (C ~= nil) do

        C.Parent = nil
        C = C.Sibling
    end

    -- // remove node from leaf objects
    for i=0, N.ObjectCount-1 do

        local O = N.ObjectList[i]
        local NodeCount = 0
        local NewList = ffi.new("fSceneNode_tPtr[128]")
        for j=0, O.NodeCount-1 do

            if (O.NodeList[j] ~= N) then

                NewList[NodeCount] = O.NodeList[j]
                NodeCount = NodeCount + 1
                O.NodeList[j] = nil
            end
        end
        ffi.copy(O.NodeList, NewList, NodeCount*ffi.sizeof("void *"))
        O.NodeCount = NodeCount
    end

    -- // remove from sibling list

    if (N.NodePrev) then N.NodePrev.NodeNext = N.NodeNext end
    if (N.NodeNext) then N.NodeNext.NodePrev = N.NodePrev end

    -- // remove from host list
    fSceneHost_NodeDel(N.Host, N)

    -- // free node list
    if (N.ObjectList) then

        ffi.fill(N.ObjectList, ffi.sizeof("fSceneObject_t *")*N.ObjectCount, 0)
        fFree(N.ObjectList)
    end

    -- // key list
    if (N.ObjectKey) then

        for i=0, N.ObjectCount-1 do

            if (N.ObjectKey[i] ~= nil) then

                fFree(N.ObjectKey[i])
                N.ObjectKey[i] = nil
            end
        end

        fFree(N.ObjectKey)
        ffi.fill(N.ObjectKey, ffil.sizeof("char *")*N.ObjectCount, 0)
    end

    -- // relese
    ffi.fill(N, ffi.sizeof("fSceneNode_t"), 0)
    fFree(N)

    return 0
end

-- //********************************************************************************************************************
-- // destroy a node
function lScene_NodeDestroy( L, N )

    local S	= toScene(L)
    N	= toSceneNode(N)

    fScene_NodeDestroy(S, N)
    return 0
end

-- //********************************************************************************************************************
-- // finds a path from a host
function fScene_NodeFind( S, H, Path, MatchLength)

    local StrLen		= MatchLength 			-- // how much of the Path to match
    local Pos			= 0
    local Node	        = H.NodeRoot

    -- //ftrace("find parent [%s] host[%s]\n", Parent, H.Name)
    while (Pos < StrLen) do

        -- // next parth level
        local NextLevel = 0
        for i=Pos+1, StrLen-1 do

            if (Path[i] == '/') then

                Pos		    = i
                Path[Pos]	= 0
                NextLevel	= i
                break
            end
        end
        if ((NextLevel == 0) and (Node.Path == Path)) then

            -- //ftrace("full path matched [%s] [%s]\n", Path, Parent)
            break
        end

        -- // update
        -- //ftrace("search string [%i] [%s]\n", Pos, Path)

        -- // search child nodes
        local N = Node.Child
        local Child = nil
        while (N ~= nil) do

            -- //ftrace("node [%s] : %s\n", N.Path, Path)
            if (N.Path == Path) then

                Child = N
                break
            end
            N = N.Sibling
        end
        -- //ftrace("child : %08x\n", Child)

        if (Child == nil) then

            -- //ftrace("child not found full path [%s]\n", Path)
            return nil
        end

        -- // restore path
        if (NextLevel ~= 0) then Path[NextLevel] = '/' end

        -- // is this a link node ?
        -- // man.. this is nasty ass code
        if (Child.HostLink[0] ~= 0) then

            -- // is this the end node? if so then dont recurse to host
            -- // as the Object will be in current Host not the linked nost
            local End = true
            if (NextLevel ~= 0) then

                -- //ftrace("host link [%s]\n", Child.HostLink)
                local LinkHost = fSceneHost_Find(S, Child.HostLink)
                if (LinkHost == nil) then

                    ftrace("faild to find linked host [%s] on path [%s]\n", Child.HostLink, Path)
                    return nil
                end
                fAssert(LinkHost.NodeRoot)

                -- // recurse
                Node = LinkHost.NodeRoot

                -- // update search path
                Path = Path[Pos]

            else

                -- //ftrace("link recurse [%s] %i %i\n", Child.Path, Pos, NextLevel)
                Node = Child
            end

        else

            -- //ftrace("recurse [%s]\n", Child.Path)
            -- // recurse to next level
            Node = Child
        end
    end
    return Node
end

-- //********************************************************************************************************************
-- // find by url parts

function lScene_NodeFind( L, Source )

    local S = toScene(L)

    local Host  = nil
    local Path  = nil
    local Proto = nil

    -- // passed a URL
    if (lua_isstring(Source)) then

        local URL	= fAssertP(lua_tostring(Source), "invalid pointer")

        -- // get full path
        local _Proto = ffi.new("char[1024]")
        local _Host = ffi.new("char[1024]")
        local _Path = ffi.new("char[1024]")
        Host = _Host
        Path = _Path
        Proto = _Proto
        if (fSceneURL_Parse(URL, Proto, nil, Host, nil, Path, nil, nil) == nil) then return 0 end

    -- // passed info struct
    elseif (lua_istable(Source)) then

        Proto	= Source.Proto
        Host	= Source.Host
        Path	= Source.Path

    else

        ftrace("unsupported NodeFind lua type %i\n", lua_type(L, -1))
        return 0
    end

    -- // has to be node protocol
    if(Proto == "node") then

        ftrace("lScene_NodeFind: invalid protocol %s [%s]\n", Proto)
        return 0
    end

    -- // find the host

    local H = fSceneHost_Find(S, Host)
    if (H == nil) then

        ftrace("unable to find host [%s]\n", Host)
        return 0
    end

    -- // find the node
    local N = fScene_NodeFind(S, H, Path, strlen(Path))
    if (N ~= nil) then

        return N
    end
    return nil
end

-- //********************************************************************************************************************
-- // find by url parts
function fScene_Node_Find( S, URL)

    -- // get full path
    local Proto = ffi.new("char[1024]")
    local Host = ffi.new("char[1024]")
    local Path = ffi.new("char[1024]")

    if (fSceneURL_Parse(URL, Proto, nil, Host, nil, Path, nil, nil) == nil) then

        return nil
    end

    -- // has to be node protocol
    if(Proto == "node") then

        ftrace("lScene_NodeFind: invalid protocol %s [%s]\n", Proto)
        return 0
    end

    -- // find the host
    local H = fSceneHost_Find(S, Host)
    if (H == nil) then

        ftrace("unable to find host [%s]\n", Host)
        return 0
    end

    -- // find the node
    local N = fScene_NodeFind(S, H, Path, strlen(Path))
    return N
end

-- //********************************************************************************************************************
-- // generates list of all nodes in the scene
function lScene_NodeList( L )

    local S = toScene(L, -1)

    local Count = 1
    local tbl = {}

    local H = S.HostHead
    while (H ~= nil) do

        local N = H.NodeHead
        while (N) do

            tbl[Count] = N
            Count = Count + 1
            N = N.NodeNext
        end
        H = H.HostNext
    end
    return tbl
end

-- //********************************************************************************************************************
-- // generates a list of nodes from the specified node and recursing to all leafs
function fScene_TraceNode( T, N, Count )

    T[Count] = N
    Count = Count + 1

    local C = N.Child
    while (C) do

        Count = fScene_TraceNode(T, C, Count)
        C = C.Sibling
    end
    return Count
end

function lScene_NodeTrace(L)

    local N = toSceneNode(L)

    local T = {}
    local Total = fScene_TraceNode(T, N, 1)
    ftrace("TraceNode %i total nodes\n", Total)

    return T
end

-- //********************************************************************************************************************
-- // output a  list of objects which a node tree references
function fScene_TraceNodeObject( T, N, Count)

    for i=0, N.ObjectCount-1 do

        T[Count] = N.ObjectList[i]
        Count = Count + 1
    end

    local C = N.Child
    while (C ~= nil) do

        Count = fScene_TraceNodeObject(T, C, Count)
        C = C.Sibling
    end
    return Count
end

function lScene_NodeTraceObject( L )

    local N = toSceneNode(L)

    local T = {}
    local Total = fScene_TraceNodeObject(T, N, 1)
    return T
end

-- //********************************************************************************************************************
-- // attachs a node to a node

function lScene_NodeAttach( L )

    local S= toScene(L.Scene)
    local P= toSceneNode(L.Parent)
    local C= toSceneNode(L.Child)

    -- // insert
    C.Sibling = P.Child
    P.Child = C
    C.Parent = P

    fSceneObject_FullPath(C.Path, ffi.sizeof(P.Path), P.Path, C.Name)
    return 0
end

-- //********************************************************************************************************************

function lScene_NodeObjectAdd( L )

    local S= toScene(L.Scene)
    local N= toSceneNode(L.Node)
    local O= toSceneObject(L.Object)

    if L.Name == nil then L.Name = "Undefined" end
    local Key		= L.Name

    -- // its a real object
    fSceneObject_Validate(O)

    -- // add object to list
    -- // note: due to instancing every node has its own object list
    local OldList = N.ObjectList
    local OldKey	= N.ObjectKey
    N.ObjectList	= ffi.new("fSceneObject_tPtr["..(N.ObjectCount+1).."]" )
    N.ObjectKey	    = ffi.new("charPtr["..(N.ObjectCount+1).."]")
    if (OldList) then

        ffi.copy(N.ObjectList, OldList, ffi.new("fSceneObject_tPtr["..(N.ObjectCount).."]"))
        ffi.copy(N.ObjectKey, OldKey, ffi.new("charPtr["..(N.ObjectCount).."]" ))
        fFree(OldList)
        fFree(OldKey)
    end

    -- // add to list
    N.ObjectList[N.ObjectCount]	= O
    N.ObjectKey[N.ObjectCount]	= (Key)
    N.ObjectCount = N.ObjectCount + 1

    -- // an object can be referenced by multiple
    local NList = ffi.new("voidPtr["..(O.NodeCount+1).."]")
    if (O.NodeCount > 0) then ffi.copy(NList, O.NodeList, ffi.sizeof("void *")*(O.NodeCount)) end
    NList[O.NodeCount] = N

    if (O.NodeCount > 0) then

        ffi.fill(O.NodeList, ffi.sizeof("void *")*(O.NodeCount-1), 0)
        fFree(O.NodeList)
    end

    O.NodeList = NList
    O.NodeCount = O.NodeCount + 1

    -- // save how this is looked up
    -- //strncpy(O.Key, Key, sizeof(O.Key))

    -- // new path
    -- //fSceneObject_FullPath(O.Path, sizeof(O.Path), N.Path, Key)

    -- //printf("	node obj add: %08x [%s/%s] obj:%s ObjPath[%s]\n", O, N.Path, Key, O.Name, O.Path)
    return 0
end

-- //********************************************************************************************************************
-- // link a host as a child node

function lScene_NodeHostLink( L )

    local S= fAssertP(toScene(L.Scene), "invalid scene")
    local N= fAssertP(toSceneNode(L.Node), "invalid node")
    local HostName = fAssertP(lua_tostring(L.HostName), "invalid host name")

    -- // set it
    N.HostLink = HostName

    return 0
end

-- //********************************************************************************************************************
-- // unlink a host as a child node

function lScene_NodeHostUnlink( L )

    fAssert(false)
    return 0
end

-- //********************************************************************************************************************
-- // return the host name

function lScene_NodeHostName( L )

    local N= fAssertP(toSceneNode(L), "invalid node")

    if (N.Host == nil) then

        ftrace("node [%s] has no host!\n", N.URL)
        return 0
    end

    return N.Host.Name
end

-- //********************************************************************************************************************
-- // generate a tri soupe for this nodes mesh objects

function fScene_NodeTriSoup( S, N, XForm, VertexPos, VertexMax, Vertex, Recurse )

    for o=0, N.ObjectCount-1 do

        local O	= fAssertP(N.ObjectList[o], "invalid object")
        VertexPos = fSceneObject_TriSoup(O, XForm, VertexPos, VertexMax, Vertex)
    end

    -- // recurse nodes
    if (Recurse) then

        local C = N.Child
        while (C) do

            local XFormChild = fMat44_Mul(XForm, C.Local)
            VertexPos = fScene_NodeTriSoup(S, C, XFormChild, VertexPos, VertexMax, Vertex, Recurse)
            C = C.Sibling
        end
    end
    return VertexPos
end

function lScene_NodeTriSoup( S, N, R )

    S		= fAssertP(toScene(S), "invalid scene")
    N		= fAssertP(toSceneNode(N), "invalid node")

    -- // recurse nodes children
    local Recurse		= R

    -- // allocate temp buffer 1M tris
    local	VertexMax	= 1024*1024
    local	Vertex		= ffi.new("float["..(VertexMax*3).."]")
    local   XForm		= fMat44_Identity()

    local VertexCount = fScene_NodeTriSoup(S, N, XForm, 0, VertexMax, Vertex, Recurse)

    ftrace("node tri soup %i\n", VertexCount)

    -- // make packed array
    local V = fPackedArray_Create(L, "f32", 128*1024)
    for i=0, VertexCount*3-1 do

        fPackedArray_Set(V, i, Vertex[i])
    end

    ftrace("node[%s] soup total vertex count %i\n", N.URL, VertexCount)
    fFree(Vertex)

    return 1
end

-- //********************************************************************************************************************
-- // set the nodes controller
function lScene_NodeControllerSet( L, CName )

    local N		= fAssertP(toSceneNode(L), "invalid node")
    N.ControllerName = CName

    -- // search for controller name in list
    for i=0, N.ObjectCount-1 do

        ftrace("search [%s] [%s]\n", N.ObjectKey[i], CName)
        if (N.ObjectKey[i] == CName) then

            ftrace("NodeControllerSet found\n")
            N.Controller = N.ObjectList[i]
            return true
        end
    end

    -- // no controller
    ftrace("NodeControllerSet NOT found\n")
    N.Controller = nil

    return false
end

-- //********************************************************************************************************************
-- // get the nodes controller
function lScene_NodeControllerGet( L )



    return 0
end

-- //********************************************************************************************************************
-- // dumps the tree
function fScene_NodeDump( N, Msg, Level )

    local Indent = string.rep(" ", Level)

    ftrace("%s[%-30s] Node\n", Indent, N.Name)

    for i=0, N.ObjectCount-1 do

        local O = N.ObjectList[i]
        ftrace("%s  [%-30s] Object %s %04x type:%s\n", Indent, N.ObjectKey[i], O.Path, O.ID, fSceneObject_TypeToStr(O.Type))
    end
    local C = N.Child
    while (C ~= nil) do

        fScene_NodeDump(C, Msg, Level+1)
        C = C.Sibling
    end
end

function lScene_NodeDump( L, Msg )

    local S	= toScene(L)

    local H = S.HostHead
    while (H ~= nil) do

        local N	= H.NodeRoot

        ftrace("node dump %s\n", Msg, H.Name)
        fScene_NodeDump(N, Msg, 0)

        H = H.HostNext
    end
end

-- //********************************************************************************************************************
-- // set a nodes locked state

function lScene_NodeLock( L, Locked )

    local N		= toSceneNode(L)
    N.Locked	= Locked

    ftrace("[%s] lock state %i\n", N.URL, N.Locked)
    return 0
end

-- //********************************************************************************************************************
-- // serailize node into a string

function lScene_NodeSerialize( L, TopPath )

    local N		= toSceneNode(L)

    T = {}
    T.Path = N.Path
    T.Name = N.Name

    if (N.ControllerName[0] ~= 0) then
        T.Controller = N.ControllerName
    end

    T.Flag      = N.Flag
    T.ID        = N.ID
    T.Local2World =	N.Local2World
    T.iLocal2World = N.iLocal2World
    T.Local =	N.Local
    T.iLocal =	N.iLocal
    T.Locked =	N.Locked

    if (N.Parent ~= nil) then
        T.Parent =  N.Parent.Path
    else
        T.Parent =  "/"
    end

    -- // child ids
    local Count = 1
    T.Child = {}
    for i=0, N.ObjectCount-1 do

        local O = N.ObjectList[i]
        T.Child[O.ID] = N.ObjectKey[i]
    end
    return T
end

-- //********************************************************************************************************************
-- // accessor

function fScene_Node_iLocal2World( N, M )

    if (N == nil) then

        M[0] = fMat44_Identity()
        return
    end
    M[0] = N.iLocal2World
end

function fScene_Node_Local2World( N, M)

    if (N == nil) then

        M[0] = fMat44_Identity()
        return
    end
    M[0] = N.Local2World
end

function fScene_Node_iLocal( N, M )

    if (N == nil) then

        M[0] = fMat44_Identity()
        return
    end
    M[0] = N.iLocal
end

function fScene_Node_Local( N, M)

    if (N == nil) then

        M[0] = fMat44_Identity()
        return
    end
    M[0] = N.Local
end

function fScene_Node_URL( N )

    if (N.Host == nil) then return N.Path end

    fSceneURL_Generate(N.URL, "node", N.Host.Name, N.Path, nil, nil)
    return N.URL
end

function fScene_Node_Name( N )

    fAssert(N ~= nil)
    return N.Name
end

function fScene_Node_LockedGet( N )

    fAssert(N ~= nil)
    return N.Locked
end

function fScene_Node_LockedSet( N, State)

    Assert(N ~= nil)
    N.Locked = State
end

function fScene_Node_Path( N )

    return N.Path
end

-- // object key for this node
function fScene_Node_ObjectKey( N, O)

    -- // search for object
    for i=0, N.ObjectCount-1 do

        if (N.ObjectList[i] == O) then

            return N.ObjectKey[i]
        end
    end
    return ""
end

function fScene_Node_ID( N )

    return N.ID
end

-- // hmm not so great..
function fScene_Node_XFormPtr( N, Local, iLocal)

    Local[0]	= N.Local
    iLocal[0]	= N.iLocal

    return N.Controller
end

function fScene_Node_Parent( N )

    return N.Parent
end

function fScene_Node_Host( N )

    return N.Host
end

-- //********************************************************************************************************************
-- // bounding box for node and its entire contents. note uses aabb for objects&child so not the
-- // most optimally forming aabb..

function fScene_Node_BoundingBox( N, ParentXForm, Min, Max )

    -- // nothing!
    if ((N.ObjectCount == 0) and (N.Child == nil)) then return false end

    -- // find extents for this level
    local LocalValid = false
    local ChildValid = false
    local HostValid	= false

    -- // minmax in node space
    local NMin = ffi.new("float[3]", { 10e6,  10e6,  10e6} )
    local NMax = ffi.new("float[3]", {-10e6, -10e6, -10e6} )
    for i=0, N.ObjectCount-1 do

        local OMin = ffi.new("float[3]")
        local OMax = ffi.new("float[3]")
        if (fSceneObject_BoundingBox(N.ObjectList[i], OMin, OMax) ~= nil) then
            -- //ftrace("object [%s] [%f %f %f]-[%f %f %f]\n", N.ObjectKey[i], OMin[0], OMin[1], OMin[2], OMax[0], OMax[1], OMax[2])

            -- // local aabb is set
            LocalValid = true
            if(NMin[0] > OMin[0]) then NMin[0] = OMin[0] end
            if(NMin[1] > OMin[1]) then NMin[1] = OMin[1] end
            if(NMin[2] > OMin[2]) then NMin[2] = OMin[2] end

            if(NMax[0] < OMax[0]) then NMax[0] = OMax[0] end
            if(NMax[1] < OMax[1]) then NMax[1] = OMax[1] end
            if(NMax[2] < OMax[2]) then NMax[2] = OMax[2] end
        end
    end
    -- //ftrace("[%-30s] object min[%f %f %f]-[%f %f %f]\n", N.Name, NMin[0],NMin[1],NMin[2],NMax[0],NMax[1],NMax[2])

    -- // parent * local
    local Local2Parent = fMat44_Mul(ParentXForm, N.Local)

    -- // min max in parents space
    local LMin = ffi.new("float[3]", { 10e6,  10e6,  10e6} )
    local LMax = ffi.new("float[3]", {-10e6, -10e6, -10e6} )

    -- // assume invalid
    if (LocalValid == true) then

        -- // corners of the aabb
        local lBB0 = ffi.new("fVector3", {NMin[0], NMin[1], NMin[2]} )
        local lBB1 = ffi.new("fVector3", {NMin[0], NMin[1], NMin[2]} )
        local lBB2 = ffi.new("fVector3", {NMax[0], NMax[1], NMin[2]} )
        local lBB3 = ffi.new("fVector3", {NMin[0], NMax[1], NMin[2]} )

        local lBB4 = ffi.new("fVector3", {NMin[0], NMin[1], NMax[2]} )
        local lBB5 = ffi.new("fVector3", {NMin[0], NMin[1], NMax[2]} )
        local lBB6 = ffi.new("fVector3", {NMax[0], NMax[1], NMax[2]} )
        local lBB7 = ffi.new("fVector3", {NMin[0], NMax[1], NMax[2]} )

        -- // xform into parent space
        local BB = ffi.new("float[8]")
        BB[0] = fMat44_MulVec(Local2Parent, lBB0)
        BB[1] = fMat44_MulVec(Local2Parent, lBB1)
        BB[2] = fMat44_MulVec(Local2Parent, lBB2)
        BB[3] = fMat44_MulVec(Local2Parent, lBB3)

        BB[4] = fMat44_MulVec(Local2Parent, lBB4)
        BB[5] = fMat44_MulVec(Local2Parent, lBB5)
        BB[6] = fMat44_MulVec(Local2Parent, lBB6)
        BB[7] = fMat44_MulVec(Local2Parent, lBB7)

        -- // find aabb in parents space
        for i=0, 8 do

            if(LMin[0] > BB[i].x) then LMin[0] = BB[i].x end
            if(LMin[1] > BB[i].y) then LMin[1] = BB[i].y end
            if(LMin[2] > BB[i].z) then LMin[2] = BB[i].z end

            if(LMax[0] < BB[i].x) then LMax[0] = BB[i].x end
            if(LMax[1] < BB[i].y) then LMax[1] = BB[i].y end
            if(LMax[2] < BB[i].z) then LMax[2] = BB[i].z end
        end

        -- //ftrace("[%-30s] l2w0 %f %f %f %f\n", N.Name, N.Local2World.m00, N.Local2World.m01, N.Local2World.m02, N.Local2World.m03)
        -- //ftrace("[%-30s] l2w1 %f %f %f %f\n", N.Name,N.Local2World.m10, N.Local2World.m11, N.Local2World.m12, N.Local2World.m13)
        -- //ftrace("[%-30s] l2w2 %f %f %f %f\n", N.Name,N.Local2World.m20, N.Local2World.m21, N.Local2World.m22, N.Local2World.m23)
    end
    -- //ftrace("[%-30s] local min[%f %f %f]-[%f %f %f]\n", N.Name, LMin[0],LMin[1],LMin[2],LMax[0],LMax[1],LMax[2])

    -- // get extents for child nodes
    local Child = N.Child
    while (Child) do

        -- // recurse
        local CMin = ffi.new("float[3]")
        local CMax = ffi.new("float[3]")
        if (fScene_Node_BoundingBox(Child, Local2Parent, CMin, CMax) ~= nil) then

            ChildValid = true
            if(LMin[0] > CMin[0]) then LMin[0] = CMin[0] end
            if(LMin[1] > CMin[1]) then LMin[1] = CMin[1] end
            if(LMin[2] > CMin[2]) then LMin[2] = CMin[2] end

            if(LMax[0] < CMax[0]) then LMax[0] = CMax[0] end
            if(LMax[1] < CMax[1]) then LMax[1] = CMax[1] end
            if(LMax[2] < CMax[2]) then LMax[2] = CMax[2] end
        end
        Child = Child.Sibling
    end
    -- //ftrace("[%-30s] child min[%f %f %f]-[%f %f %f]\n", N.Name, LMin[0],LMin[1],LMin[2],LMax[0],LMax[1],LMax[2])

    -- // host link
    if (N.HostLink[0] ~= 0) then

        fAssert(N.Host)
        local H = fSceneHost_Find(N.Host.Scene, N.HostLink)
        if (H and H.NodeRoot) then

            -- // recurse
            local CMin = ffi.new("float[3]")
            local CMax = ffi.new("float[3]")
            if (fScene_Node_BoundingBox(H.NodeRoot, Local2Parent, CMin, CMax) ~= nil ) then

                HostValid = true
                if(LMin[0] > CMin[0]) then LMin[0] = CMin[0] end
                if(LMin[1] > CMin[1]) then LMin[1] = CMin[1] end
                if(LMin[2] > CMin[2]) then LMin[2] = CMin[2] end

                if(LMax[0] < CMax[0]) then LMax[0] = CMax[0] end
                if(LMax[1] < CMax[1]) then LMax[1] = CMax[1] end
                if(LMax[2] < CMax[2]) then LMax[2] = CMax[2] end
            end
        end
    end

    -- // xform into local space
    Min[0] = LMin[0]
    Min[1] = LMin[1]
    Min[2] = LMin[2]

    Max[0] = LMax[0]
    Max[1] = LMax[1]
    Max[2] = LMax[2]

    -- //ftrace("box [%-30s] [%f %f %f]-[%f %f %f]\n", N.Name, Min[0], Min[1], Min[2], Max[0], Max[1], Max[2])
    return (LocalValid == true or ChildValid == true or HostValid == true)
end

-- //********************************************************************************************************************

function fScene_NodeObjectPath( N, O)

    for i=0, N.ObjectCount-1 do

        if (N.ObjectList[i] == O) then

            local path = string.format( "%s/%s", N.Path, N.ObjectKey[i])
            return path
        end
    end
    fAssert(false)
end

-- //********************************************************************************************************************
-- // generate full node url for the object

function fScene_NodeObjectURL( N, O, url )

    local Key = nil
    for i=0, N.ObjectCount-1 do

        if (N.ObjectList[i] == O) then

            Key = N.ObjectKey[i]
            break
        end
    end
    fAssert(Key)

    -- // get host
    local H = N.Host
    fAssert(H)

    url = string.format( "node:-- //%s%s/%s", H.Name, N.Path, Key)
    return url
end

-- //********************************************************************************************************************
-- // return the nodes xform controller
function fScene_Node_XForm( N)

    for i=0, N.ObjectCount-1 do

        local O = N.ObjectList[i]
        if bit.band(O.Flag, fSceneObject_Flag_XForm) > 0 then

            return O
        end
    end
    return nil
end

-- //********************************************************************************************************************
-- // return the nodes dynamics controller

function fScene_Node_Dynamic( N)

    for i=0, N.ObjectCount-1 do

        local O = N.ObjectList[i]
        if bit.band(O.Flag, fSceneObject_Flag_Dynamic) > 0 then

            return O
        end
    end
    return nil
end

function lScene_NodeDynamicGet(L)

    local N	= toSceneNode(L)

    local Dynamic = fScene_Node_Dynamic(N)
    if (Dynamic == nil) then

        ftrace("dynamics count %i %s\n", N.ObjectCount, N.URL)
        for i=0, N.ObjectCount-1 do

            ftrace("dynamcis [%s]\n", N.ObjectKey[i])
        end
        return 0
    end

    return Dynamic
end

-- //********************************************************************************************************************
-- // general info about the nodes current state
function lScene_NodeInfo( L)

    local N	= toSceneNode(L)

    local T = {}

    T.Path = N.Path
    T.Name = N.Name
    T.URL = N.URL

    if (N.Host)	then	T.Host = N.Host.Name end
    if (N.Controller) then	T.Controller = N.Controller.URL  end

    T.L2W       = N.Local2World
    T.iL2W      = N.iLocal2World

    T.Local     = N.Local
    T.iLocal    = N.iLocal

    if (N.Parent) then

        T.Parent_L2W   = N.Parent.Local2World
        T.Parent_iL2W  = N.Parent.iLocal2World

    else

        local Ident = fMat44_Identity()
        T.Parent_L2W    = Ident
        T.Parent_iL2W   = Ident
    end

    return T
end

-- //********************************************************************************************************************
-- // get nodes unique id
function fScene_NodeID_New( S)

    s_NodeInc = s_NodeInc + 1
    return s_NodeInc
end

-- //********************************************************************************************************************
-- // Scene
-- //********************************************************************************************************************

-- //********************************************************************************************************************
-- // creates a new scene
function lScene_Create( L)

    local S = ffi.new("fScene_t")
    fAssert(S ~= nil)
    ffi.fill(S, ffi.sizeof("fScene_t"), 0)

    -- // create root host
    S.HostHead	= fSceneHost_Create(S, "localhost")
    S.HostTail	= S.HostHead

    S.FrameCount	= 1

    -- // scene . outside interface
    S.MsgQueueHead	= nil
    S.MsgQueueTail	= nil

    -- // create global object
    S.Global	= fSceneGlobal_Create()

    -- // scene cache object
    S.Cache	= L.Cache
    fAssert(S.Cache)

    -- // scenes name
    -- //
    S.Name = L.Name

    -- // Scene structure is passed as scene object in some cases, so fill in sane info
    ffi.fill(S.Header, ffi.sizeof(S.Header), 0)
    S.Header.Magic	= SCENE_MAGIC
    S.Header.ID	    = 0
    S.Header.Type	= fSceneObject_Type_Scene
    S.Header.Flag	= 0
    S.Header.CRC32	= 0
    S.Header.Def 	= fSceneObject_DefFindMagic(SCENE_MAGIC)

    return S
end

-- //********************************************************************************************************************
function lScene_Destroy( L )

    local S = toScene(L)

    fSceneGlobal_Destroy(S.Global)
    S.Global = nil

    fFree(S)
    return 0
end

-- //********************************************************************************************************************
function fScene_List( S, N )

    local T = {}

    -- // top level info
    T.Name = N.Name
    T.Path = N.Path

    -- // push attached objects
    local NO = {}
    for i=0, N.ObjectCount-1 do

        local O = N.ObjectList[i]
        local TT = {}

        TT.Type = fSceneObject_TypeToStr(O.Type)
        TT.Name = O.Name
        TT.Path = O.Path
        TT.Key = N.ObjectKey[i]
        NO[i] = TT
    end
    T.Object = NO

    local NP = {}
    local	C = N.Child
    while (C ~= nil) do

        local SL = fScene_List( S, C)
        NP[C.Name] = SL
        C = C.Sibling
    end
    T.Child = NP

    return T
end

function lScene_List( L )

    local S = toScene(L)

    local T = {}
    local H = S.HostHead
    while(H ~= nil) do

        local N = H.NodeRoot
        while (N ~= nil) do

            local SL = fScene_List(S, N)
            T[N.Name] = SL
            N = N.Sibling
        end
        H = H.HostNext
    end
    return T
end

-- //********************************************************************************************************************
function fScene_ObjectID_New( S )

    s_ObjectInc = s_ObjectInc + 1
    return s_ObjectInc
end

-- //********************************************************************************************************************
-- // find an object based on object path
function fScene_ObjectFindOPath( S,Host, Path )

    if (Host == nil) then

        ftrace("object find: invalid host\n")
        return nil
    end
    if (Path == nil) then

        ftrace("ObjectFind: invalid path\n")
        return nil
    end
    local H		= fSceneHost_Find(S, Host)
    if (H == nil) then return nil end

    -- //ftrace("object find %08x\n", H.ObjectHead)
    local O = H.ObjectHead
    while (O ~= nil) do

        -- //ftrace("[%s] : %s\n", O.Path, Path)
        if (O.Path == Path) then

            return O
        end
        O = O.HostNext
    end
    return nil
end

-- //********************************************************************************************************************
-- // find an object based on a node path
function fScene_ObjectFindNPath( S, Host, Parent, Name )

    if (Host == nil) then

        ftrace("object find: invalid host\n")
        return nil
    end
    if (Parent == nil) then

        ftrace("ObjectFind: invalid parent path\n")
        return nil
    end
    if (Name == nil) then

        ftrace("ObjectFind: invalid object name\n")
        return nil
    end


    local PathStr   = Parent
    local Path      = PathStr

    -- // host
    local H		= fAssertPointer(fSceneHost_Find(S, Host), "invalid host")

    -- // find node
    local Node = fScene_NodeFind(S, H, Path, strlen(Parent))
    if (Node == nil) then

        ftrace("ObjectNodeFindPath [%s] no such object\n", Path)
        return 0
    end

    -- //ftrace("node object count %i [%s]\n", Node.ObjectCount, Node.Path)
    -- // find node key
    local O = nil
    for i=0, Node.ObjectCount-1 do

        -- //ftrace("key %s %s\n", Node.ObjectKey[i], Name)
        if (Node.ObjectKey[i] == Name) then

            -- //ftrace("match\n")
            O = Node.ObjectList[i]
            break
        end
    end

    if (O == nil) then

        ftrace("failed to find key [%s] path[%s]\n", Name, Path)
        return nil
    end

    -- // object found
    -- //ftrace("path OK\n")
    return O
end

-- //********************************************************************************************************************
-- // host is the host of the callee object

function fScene_ObjectFindURL( S, HostCaller, URL)

    -- // get full path
    local Proto = ffi.new("char[1024]")
    local Scene = ffi.new("char[1024]")
    local Host = ffi.new("char[1024]")
    local Type = ffi.new("char[1024]")
    local Path = ffi.new("char[1024]")
    local Parent = ffi.new("char[1024]")
    local Name = ffi.new("char[1024]")
    if (fSceneURL_Parse(URL, Proto, Scene, Host, Type, Path, Parent, Name) == nil) then return 0 end

    -- // set host, so set it to callers host (if avaliable)
    if ((HostCaller ~= nil) and (Host[0] == 0)) then

        Host = HostCaller.Name
    end

    if (Proto == "object") then

        return fScene_ObjectFindOPath(S, Host, Path)

    elseif (Proto == "node") then

        return fScene_ObjectFindNPath(S, Host, Parent, Name)
    end
end

-- //********************************************************************************************************************

function lScene_ObjectFind( L )

    local S = toScene(L)

    local Host = nil
    local Path = nil
    local Proto = nil
    local Parent = nil
    local Name = nil

    -- // passed a URL
    if (lua_isstring(L)) then

        local URL	= fAssertP(lua_tostring(L), "invalid pointer")

        -- // get full path
        local _Proto = ffi.new("char[1024]")
        local _Host = ffi.new("char[1024]")
        local _Path = ffi.new("char[1024]")
        local _Parent = ffi.new("char[1024]")
        local _Name = ffi.new("char[1024]")

        Host		= _Host
        Path		= _Path
        Proto		= _Proto
        Parent		= _Parent
        Name		= _Name

        if (fSceneURL_Parse(URL, Proto, nil, Host, nil, Path, Parent, Name) == nil) then return 0 end

    -- // passed info struct
    elseif (lua_istable(L)) then

        Proto	= L.Proto
        Host	= L.Host
        Path	= L.Path
        Parent	= L.Parent
        Name	= L.Name

    else

        ftrace("unsupported NodeFind lua type %i\n", lua_type(L))
        return 0
    end

    -- // by object path
    local O = nil
    if 	(Proto == "object") then

        fAssert(Host)
        fAssert(Path)
        O = fScene_ObjectFindOPath(S, Host, Path)

    elseif (Proto == "node") then

        fAssert(Host)
        fAssert(Parent)
        fAssert(Name)
        O = fScene_ObjectFindNPath(S, Host, Parent, Name)

    else

        ftrace("ObjectFind: invalid protocol [%s] host[%s] Path[%s] parent[%s] name[%s]\n", Proto, Host, Path, Parent, Name)
        fAssertP(0, "invalid protocol")
    end

    if (O == nil) then return 0 end
    return  O
end

-- //********************************************************************************************************************
-- // generates list of all nodes in the scene

function lScene_ObjectList( L )

--    local S = toScene(L)
--
--    local Count = 1
--    local T = {}
--
--    local O = S.ObjHead
--    while (O) do
--
--        T[Count] = O
--        Count = Count + 1
--
--        O = O.SceneNext
--    end
--    return T
end

-- //********************************************************************************************************************
-- // update all objects

function fScene_UpdateObject( S, t )

    local H = S.HostHead
    while (H ~= nil) do

        -- // update non util objects
        local O = H.ObjectHead
        while (O ~= nil) do

            if (bit.band(O.Flag, fSceneObject_Flag_Util) > 0) then

                fSceneObject_Update(O, t)
            end
            O = O.HostNext
        end
        H = H.HostNext
    end

    -- // update util objects last (usually global * updates)
    H = S.HostHead
    while (H) do

        local O = H.ObjectHead
        while (O ~= nil) do

            if (bit.band(O.Flag, fSceneObject_Flag_Util) > 0) then

                fSceneObject_Update(O, t)
            end
            O = O.HostNext
        end
        H = H.HostNext
    end
end

-- //********************************************************************************************************************
-- // update a single host hierarchy

function fScene_UpdateHierarchyHost( S, H, Parent, iParent, ParentPath )

    -- // flag the hierarchy has been referenced on this update
    H.HierarchyRef = H.HierarchyRef + 1

    -- // update the hierarchy frame count
    H.FrameCount = H.FrameCount + 1

    -- // update the hierarchy
    local N = H.NodeRoot
    while (N ~= nil) do

        -- //dtrace("%08x update node [%s] sib:%08x child:%08x parent:%08x\n", N, N.Path, N.Sibling, N.Child, N.Parent)

        N.Local2World = fMat44_Mul(Parent, N.Local)
        N.iLocal2World = fMat44_Mul(N.iLocal, iParent)

        -- // update scene space
        for i=0, N.ObjectCount-1 do

            local FullPath = string.format( "%s/%s/%s", ParentPath, N.Path, N.ObjectKey[i])
            fSceneURL_Flatten(FullPath)

            local O = N.ObjectList[i]
            fSceneSpace_Insert( S.Space, FullPath,  N.Local2World, N.iLocal2World, H, N, O,
                    bit.bor( bit.lshift(H.HierarchyRef,24), bit.lshift(N.ID,12), O.ID) )
        end

--        /*
--        fMat44_dtrace(Parent, "Parent")
--        fMat44_dtrace(N.Local, "Local")
--        fMat44_dtrace(N.Local2World, "L2W")
--        */
        -- // if its a host link, process that first
        if (N.HostLink ~= nil) then

            -- // find it
            local H = fSceneHost_Find(S, N.HostLink)
            if (H ~= nil) then

                local FullPath = string.format( "%s/%s/", ParentPath, N.Path)
                fSceneURL_Flatten(FullPath)

                if (string.sub(FullPath, -1) ~= '/') then FullPath = FullPath.."/" end
                fScene_UpdateHierarchyHost(S, H, N.Local2World, N.iLocal2World, FullPath)
            end
        end

        -- // process childreen siblings first
        if (N.Child ~= nil) then

            -- //printf("recurse down\n")
            Parent = N.Local2World
            iParent = N.iLocal2World

            N = N.Child
        else

            -- //  sibling
            if (N.Sibling ~= nil) then

                -- //printf("sibling\n")
                N = N.Sibling

            -- // hit the root node
            elseif (N.Parent == nil) then

                -- //printf("root node break\n")
                break

            -- // no children so recurse up
            else

                -- // recurse up the tree till found a sibling or nothing
                while (N ~= nil) do

                    -- // top of tree nothing more to do
                    if (N.Parent == nil) then

                        N = nil
                        break
                    end

                    -- // process parents next node
                    if (N.Parent.Sibling) then

                        -- // parents new xform already calculated
                        N = N.Parent.Sibling

                        -- //printf("recurse up [%s]\n", N.Parent.Path)
                        Parent = N.Parent.Local2World
                        iParent = N.Parent.iLocal2World

                        break
                    else

                        N = N.Parent
                    end
                end
            end
        end
    end
end

-- //********************************************************************************************************************
-- // update the scene hierarchy

function fScene_UpdateHierarchy( S)

    -- // reset referenced flag
    H = S.HostHead
    while ( H ~= nil ) do

        H.HierarchyRef = false
        H = H.HostNext
    end

    -- // reset space
    fSceneSpace_Destroy(S.Space)
    S.Space = fSceneSpace_Create(S)

    -- //printf("scene hierarchy update\n")

    local Parent = fMat44_Identity()
    local iParent= fMat44_Identity()

    -- // start at the top
    local H = fAssertP(fSceneHost_Find(S, "localhost"), "localhost not found!")

    fScene_UpdateHierarchyHost(S, H, Parent, iParent, "")
end

-- //********************************************************************************************************************
-- // verify node & object list is valid
function fScene_ValidateEx( S, File, Line )

    -- //dtrace("secene verify begin\n")

    local NodeCount = 0
    local ObjectRefCount = 0

    -- // node need to iterate the nodes, due to instancing
    local N = S.RootNode
    while (N ~= nil) do

        for i=0, N.ObjectCount-1 do

            local O = N.ObjectList[i]

            fSceneObject_ValidateEx(O, File, Line)
            ObjectRefCount = ObjectRefCount + 1
        end
        N = N.NodeNext
        NodeCount = NodeCount + 1
    end
    -- //dtrace("secene verify end Node:%i Object:%i\n", NodeCount, ObjectRefCount)
end

-- //********************************************************************************************************************
-- // updates state of everything

function lScene_Update( L )

    local S	= toScene(L)

    local t	= os.clock() - s_TimeBase
    local dt	= t - S.LastTS
    S.LastTS 	= t

    -- // update scene objects
    fScene_UpdateObject(S, t)

    -- // re caclculate hierarchy xforms
    -- // re-generate spacial partition
    fScene_UpdateHierarchy(S)
    S.FrameCount = S.FrameCount + 1

    return 0
end

-- //********************************************************************************************************************
-- // retreive pending packets

function lScene_MessagePop( L)

    local S	= toScene(L)
    if (S.MsgQueueHead == nil) then return 0 end

    -- // pop from top (fifo order)
    local M		        = S.MsgQueueHead
    S.MsgQueueHead		= M.Next
    if (S.MsgQueueHead == nil) then S.MsgQueueTail = nil end

    -- // push cmd and msg
    local T = {}
    T.Cmd = M.Cmd
    ffi.copy(T.Data, M.Data, M.DataLen)
    T.SceneName = "test scene"

    -- // release memory
    fFree(M.Data)
    M.Data = nil
    M.Next = nil

    fFree(M)
    return T
end

-- //********************************************************************************************************************
-- // push a message

function fScene_MessagePush( S, Cmd, Data, DataLen )

    local 	M = ffi.new("fSceneMsg_t")
    ffi.copy(M.Cmd, Cmd, ffi.sizeof(M.Cmd))

    M.DataLen	= DataLen
    M.Data		= ffi.new("char["..DataLen.."]")
    ffi.copy(M.Data, Data, DataLen)

    if (S.MsgQueueTail) then S.MsgQueueTail.Next = M end
    M.Next = nil
    S.MsgQueueTail = M

    if (S.MsgQueueHead == nil) then	S.MsgQueueHead = M end
end

-- //********************************************************************************************************************
-- // bind a global variable to a lua state

function fScene_Global( S )

    return S.Global
end

function fScene_SpaceGet( S )

    return S.Space
end

function fScene_SpaceSet( S, A )

    S.Space = A
end

function fScene_FrameCount( S )

    return S.FrameCount
end

function fScene_Cache( S )

    return S.Cache
end

-- //********************************************************************************************************************
function lScene_GlobalSet( S, Key, L )

    return fSceneGlobal_Set(S.Global, Key, L)
end

-- //********************************************************************************************************************
-- // parse url into its components

function lScene_ParseURL( url )

    -- // get full path
    local Proto = ffi.new("char[1024]")
    local Scene = ffi.new("char[1024]")
    local Host = ffi.new("char[1024]")
    local Type = ffi.new("char[1024]")
    local Path = ffi.new("char[1024]")
    local Parent = ffi.new("char[1024]")
    local Name = ffi.new("char[1024]")
    if (fSceneURL_Parse(url, Proto, Scene, Host, Type, Path, Parent, Name) == nil) then return 0 end

    T = {}

    T.url = url
    T.Proto = Proto
    T.Scene = Scene
    T.Host = Host
    T.Type = Type
    T.Path = Path
    T.Parent = Parent
    T.Name = Name

    return T
end

-- //********************************************************************************************************************

function lScene_Realize( S, ID, C, ValidObjects )

    S	= toScene(S)
    local SceneID		= ID
    local Cache = toSceneCache(C)

    -- // generate object mask
    local Mask = 0
    for k,v in ValidObjects do

        Mask = bit.bor(Mask, fSceneObject_StrToType(k))
    end

    -- // all hosts
    local H = S.HostHead
    while (H ~= nil) do

        -- // not referenced from hierarchy root so dont send it
        if (H.HierarchyRef ~= nil) then

            -- // referenced so kick it
            local O = H.ObjectHead
            while( O ~= nil ) do

                -- // not a valid type
                if (bit.band(O.Type , Mask) > 0) then

                    -- // encode it
                    fSceneObject_RealizeEncode(L, S, SceneID, Cache, O, "NETWORK")
                end
                O = O.HostNext
            end
        end
        H = H.HostNext
    end
    return 0
end

---- //********************************************************************************************************************
--int fScene_Register(lua_State* L)
--{
--lua_table_register(L, -1, "Scene_Create",		lScene_Create)
--lua_table_register(L, -1, "Scene_Destroy",		lScene_Destroy)
--lua_table_register(L, -1, "Scene_NodeCreate",		lScene_NodeCreate)
--lua_table_register(L, -1, "Scene_NodeDestroy",		lScene_NodeDestroy)
--lua_table_register(L, -1, "Scene_NodeFind",		lScene_NodeFind)
--lua_table_register(L, -1, "Scene_NodeAttach",		lScene_NodeAttach)
--lua_table_register(L, -1, "Scene_NodeObjectAdd",	lScene_NodeObjectAdd)
--lua_table_register(L, -1, "Scene_NodeDump",		lScene_NodeDump)
--lua_table_register(L, -1, "Scene_NodeLock",		lScene_NodeLock)
--
--lua_table_register(L, -1, "Scene_NodeHostLink",		lScene_NodeHostLink)
--lua_table_register(L, -1, "Scene_NodeHostUnlink",	lScene_NodeHostUnlink)
--lua_table_register(L, -1, "Scene_NodeHostName",		lScene_NodeHostName)
--
--lua_table_register(L, -1, "Scene_NodeTrace",		lScene_NodeTrace)
--lua_table_register(L, -1, "Scene_NodeTraceObject",	lScene_NodeTraceObject)
--lua_table_register(L, -1, "Scene_NodeTriSoup",		lScene_NodeTriSoup)
--
--lua_table_register(L, -1, "Scene_ObjectFind",		lScene_ObjectFind)
--lua_table_register(L, -1, "Scene_Update",		lScene_Update)
--lua_table_register(L, -1, "Scene_GlobalSet",		lScene_GlobalSet)
--lua_table_register(L, -1, "Scene_List",			lScene_List)
--lua_table_register(L, -1, "Scene_NodeList",		lScene_NodeList)
--lua_table_register(L, -1, "Scene_NodeSerialize",	lScene_NodeSerialize)
--
--lua_table_register(L, -1, "Scene_NodeControllerSet",	lScene_NodeControllerSet)
--lua_table_register(L, -1, "Scene_NodeControllerGet",	lScene_NodeControllerGet)
--lua_table_register(L, -1, "Scene_NodeDynamicGet",	lScene_NodeDynamicGet)
--lua_table_register(L, -1, "Scene_NodeInfo",		lScene_NodeInfo)
--
--lua_table_register(L, -1, "Scene_ObjectList",		lScene_ObjectList)
--
--lua_table_register(L, -1, "Scene_HostFind",		lScene_HostFind)
--lua_table_register(L, -1, "Scene_HostAdd",		lScene_HostAdd)
--lua_table_register(L, -1, "Scene_HostDel",		lScene_HostDel)
--lua_table_register(L, -1, "Scene_HostRoot",		lScene_HostRoot)
--lua_table_register(L, -1, "Scene_HostList",		lScene_HostList)
--
--lua_table_register(L, -1, "Scene_MessagePop",		lScene_MessagePop)
--lua_table_register(L, -1, "Scene_ParseURL",		lScene_ParseURL)
--lua_table_register(L, -1, "Scene_Realize",		lScene_Realize)
--
--s_TimeBase = time_sec()
--
--return 0
--}
