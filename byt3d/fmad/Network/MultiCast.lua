--
-- Created by David Lannan
-- User: grover
-- Date: 4/05/13
-- Time: 1:16 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

ws2 = require("byt3d/ffi/network")

--struct fMultiCastNode_t;
--typedef void PacketFunc_f(struct fMultiCastNode_t* N, u32 ObjectID, void* Data, u32 Size, void* User);
--
--void fMultiCast_Register(lua_State* L);
--bool fMultiCast_Send(struct fMultiCastNode_t* N, u32 ObjectID, void* Payload, u32 PayloadSize);
--void fMultiCast_Update(struct fMultiCastNode_t* N);
--
--void fMultiCast_PacketHandler(struct fMultiCastNode_t* N, const u32 ID, PacketFunc_f* Func, void* User);
--struct fMultiCastNode_t* toMultiCast(lua_State* L, int index);
--u32 fMultiCast_ObjectID(struct fMultiCastNode_t* N);
-- /**************************************************************************************************************/

local s_PacketCount = 0

-- /**************************************************************************************************************/

function toMultiCast(N)
    fAssert(N ~= nil)
    fAssert(N.Magic == ws2.MULTICAST_NODE_MAGIC)
    return N
end

-- /**************************************************************************************************************/
function fMultiCast_DispatchDiscover( N, ObjectID, Data, Size, User)

    local CheckID = ffi.new("uint32_t[1]", { Data })

    -- // hits me so send ack
    if (N.ObjectID == CheckID[0]) then

        -- // send alive packet
        fMultiCast_Send(N, ws2.fMultiCastID_Alive, CheckID, ffi.size(CheckID[0]));
    end
end

-- /**************************************************************************************************************/

function fMultiCast_DispatchAlive( N, ObjectID, Data, Size, User)

    local CheckID = ffi.new("uint32_t", Data)

    if (N.DiscoverID == CheckID) then

        N.DiscoverFound = true
    end
end

-- /**************************************************************************************************************/
-- // keep broadcasting ID`s till no one replys

function fMultiCast_DiscoverID( N )

    for i = ws2.fMultiCastID_User, N.DispatchMax-1 do
        N.DiscoverID = i
        local sID = ffi.new("u32[1]", { i } )

        -- // send discover
        N.DiscoverFound = false
        fMultiCast_Send(N, ws2.fMultiCastID_Discover, sID, ffi.sizeof("u32"))

        -- // bit dogey.. but non the less
        local ts = os.clock()
        while ((os.clock() - ts) < 0.5) do

            fMultiCast_Update(N)
            if (N.DiscoverFound) then break; end
        end

        if (N.DiscoverFound == false) then

            ftrace("multicast found ID: %08x\n", N.DiscoverID)
            break
        end
    end

    return N.DiscoverID
end

-- /**************************************************************************************************************/

function lMultiCast_Create(config, loop)

    local S = ffi.new("fMultiCastNode_t")
    fAssert(S)

    -- // port number

    S.Port	= tonumber(config.Port)
    fAssert(S.Port ~= nil)

    -- // multi cast group
    if config.McGroup == nil then config.McGroup = "225.0.0.1" end
    S.McGroup = config.McGroup

    -- // create it
    S.Socket = ws2.socket(ws2.AF_INET, ws2.SOCK_DGRAM, 0)
    if (S.Socket < 0) then

        ftrace("MultiCast_Server: failed to create socket\n")
        return 0
    end

    local reuse_addr = ffi.new("u32[1]", { 1 } )
    ws2.setsockopt(S.Socket, ws2.SOL_SOCKET, ws2.SO_REUSEADDR, ffi.cast("const char *", reuse_addr), ffi.sizeof("u32"))

    -- // nice big large buffers
    local sock_buf_size = ffi.new("u32[1]", {8*1024*1024} )
    fAssert(ws2.setsockopt(S.Socket, ws2.SOL_SOCKET, ws2.SO_SNDBUF, ffi.cast("const char *", sock_buf_size), ffi.sizeof("u32") )>=0)
    fAssert(ws2.setsockopt(S.Socket, ws2.SOL_SOCKET, ws2.SO_RCVBUF, ffi.cast("const char *", sock_buf_size), ffi.sizeof("u32") )>=0)

    local addr = ffi.new("struct sockaddr_in[1]")
    addr[0].sin_family		= ws2.AF_INET
    addr[0].sin_port		= ws2.htons(S.Port)
    addr[0].sin_addr.s_addr	= ws2.INADDR_ANY

    local ret = ws2.bind(S.Socket, ffi.cast("struct sockaddr *", addr), ffi.sizeof(addr[0]))
    if (ret < 0) then

        ftrace("MultiCast_Server: bind failed: %08x %08x\n", ret, errno)
        return 0
    end

    -- // enable multicast
    local maddr = ffi.new("struct in_addr[1]")
    maddr[0].s_addr = ws2.INADDR_ANY
    ret = ws2.setsockopt(S.Socket, ws2.IPPROTO_IP, ws2.IP_MULTICAST_IF, ffi.cast("const char *", maddr), ffi.sizeof(maddr[0]))
    if (ret < 0) then

        ftrace("MultiCast_Server: failed to enable multicast %08x %08x\n", ret, errno)
        return 0
    end

    -- // enable looping
    local tloop = ffi.new("u32[1]", { loop } )
    ret = ws2.setsockopt(S.Socket, ws2.IPPROTO_IP, ws2.IP_MULTICAST_LOOP,  ffi.cast("const char *",tloop), ffi.sizeof("u32"))
    if (ret < 0) then

        ftrace("MultiCast_Server: failed to enable multicast loop %08x %08x\n", ret, errno)
        return 0
    end

    -- // add membership
    local mreq = ffi.new("struct ip_mreq[1]")
    mreq[0].imr_multiaddr.s_addr = ws2.inet_addr(S.McGroup)
    mreq[0].imr_interface.s_addr = ws2.INADDR_ANY
    ret = ws2.setsockopt(S.Socket, ws2.IPPROTO_IP, ws2.IP_ADD_MEMBERSHIP,  ffi.cast("const char *",mreq), ffi.sizeof(mreq[0]))
    if (ret < 0) then

        ftrace("MultiCast_Server: failed to add multicast membershipt %08x %08x\n", ret, errno)
        return 0
    end

    S.Magic = ws2.MULTICAST_NODE_MAGIC
    S.ObjectID = 0

    -- // allocate dispatch handlers
    S.DispatchMax = 64*1024;
    S.Dispatch = ffi.new("PacketFunc_fPtr["..S.DispatchMax.."]")
    S.DispatchUser = ffi.new("voidPtr["..S.DispatchMax.."]")
    fAssert(S.Dispatch)
    fAssert(S.DispatchUser)
    ffi.fill(S.Dispatch, ffi.sizeof("PacketFunc_fPtr")*S.DispatchMax, 0)
    ffi.fill(S.DispatchUser, ffi.sizeof("voidPtr")*S.DispatchMax, 0)

    -- // tmp buffers
    S.BufferSize = 16*1024
    S.BufferTx = ffi.new("char["..(S.BufferSize).."]")
    S.BufferRx = ffi.new("char["..(S.BufferSize).."]")

    -- // discovery handler
    fMultiCast_PacketHandler(S, ws2.fMultiCastID_Discover,	fMultiCast_DispatchDiscover,	nil)
    fMultiCast_PacketHandler(S, ws2.fMultiCastID_Alive,		fMultiCast_DispatchAlive,	nil)

    -- // discover an object id
    S.ObjectID = fMultiCast_DiscoverID(S)

    ftrace("multicast done\n")

    return S
end

-- /**************************************************************************************************************/

function build_select_list( N)

    FD_ZERO(N.Sock)

    -- // listen socket
    FD_SET(N.Socket, N.Sock)

    -- // client sockets
    N.SockHigh = N.Socket
--    /*
--    // clients
--    fClient_t* C = S->Client;
--    while (C)
--    {
--    fAssert (C->Socket != 0);
--
--    FD_SET(C->Socket,&S->Sock);
--    if (C->Socket > S->SockHigh)
--    S->SockHigh = C->Socket;
--
--    C = C->Next;
--    }
--    */
end

-- /**************************************************************************************************************/
-- // check for incomming

function lMultiCast_Update( N )

    N = toMultiCast( N )
    fMultiCast_Update( N )
    return 0
end

-- /**************************************************************************************************************/

function fMultiCast_Update( N )

    LastID = 0

    local timeout       = ffi.new("struct timeval[1]")
    timeout[0].tv_sec   = 0
    timeout[0].tv_usec  = 0

    fAssert(N)
    build_select_list(N)

    while (true) do

        -- // check for pending
        local readsocks = ws2.select(N.SockHigh+1, N.Sock, nil, nil, timeout)
        if (readsocks == 0) then break; end

        -- // fetch
        local addr      = ffi.new("struct sockaddr_in[1]")
        local addrlen   = ffi.new("u32[1]")
        local len       = ws2.recvfrom(N.Socket, N.BufferRx, N.BufferSize, 0, ffi.cast("struct sockaddr *", addr), addrlen)
        if (len <= 0) then break; end

        local H = ffi.cast("fMultiHeader_tPtr", N.BufferRx)
        fAssert(H.PayloadSize == len)

--        /*
--        ftrace("RenderNetwork: %08x : %08x\n", H->ObjectID, addr.sin_addr.s_addr);
--        if (H->SeqID != (LastID+1))
--        {
--        printf("dropped: %i\n", H->SeqID);
--        }
--        LastID = H->SeqID;
--        */

        s_PacketCount = s_PacketCount + 1

        -- // dispatch it
        fAssert(H.ObjectID < N.DispatchMax)
        local F = N.Dispatch[H.ObjectID]
        if (F ~= nil) then

            printf("dispatch %08x:%08x\n", H.ObjectID, H.PayloadSize)
            F(N, H.ObjectID, H+1, H.PayloadSize-ffi.size(fMultiHeader_t), N.DispatchUser[H.ObjectID])
        end
    end
end

-- /**************************************************************************************************************/

function lMultiCast_Test(N)

    N = toMultiCast(N)
    while (true) do

        local test = ffi.new("uint32_t[16]")
        fMultiCast_Send(N, 0, test, 16)
    end
end

-- /**************************************************************************************************************/

function fMultiCast_Send( N, ObjectID, Payload, PayloadSize)

    local H = ffi.cast("fMultiHeader_tPtr", N.BufferTx)
    H.PayloadTotal		= PayloadSize+ffi.sizeof("fMultiHeader_t")
    H.PayloadSize		= PayloadSize+ffi.sizeof("fMultiHeader_t")
    H.PayloadOffset	    = 0
    H.ObjectID		    = ObjectID
    H.SeqID		        = N.SeqNumber

    N.SeqNumber = N.SeqNumber + 1

    fAssert((PayloadSize+ffi.sizeof("fMultiHeader_t")) < N.BufferSize)
    ffi.copy(H+1, Payload, PayloadSize)

    local addr = ffi.new("struct sockaddr_in[1]")
    addr[0].sin_family		= ws2.AF_INET
    addr[0].sin_port		= ws2.htons(N.Port)
    addr[0].sin_addr.s_addr	= ws2.inet_addr(N.McGroup)
    local addrlen = ffi.sizeof(addr[0])

    local rem = H.PayloadSize
    local Send = N.BufferTx
    local len = ws2.sendto(N.Socket, Send, rem, 0, ffi.cast("const struct sockaddr *",addr), addrlen)
    return (len == rem)
end

-- /**************************************************************************************************************/

function lMultiCast_Send(N, ObjectID, payload)

    fMultiCast_Send(N, ObjectID, payload, ffi.sizeof(payload))
    return 0
end

-- /**************************************************************************************************************/

function fMultiCast_PacketHandler( N, ID, Func, User)

    fAssert(ID < N.DispatchMax)
    N.Dispatch[ID]		= Func
    N.DispatchUser[ID]	= User
end

-- /**************************************************************************************************************/

function lMultiCast_ObjectID(N)

    N = toMultiCast(N)
    return N.ObjectID
end

-- /**************************************************************************************************************/

function fMultiCast_ObjectID(N)

    return N.ObjectID
end

-- /**************************************************************************************************************/

function lMultiCast_Stats()

    local status = {}

    status.PacketCount = s_PacketCount
    s_PacketCount = 0

    return status
end

-- /**************************************************************************************************************/

--void fMultiCast_Register(lua_State* L)
--{
--lua_register(L, "fMultiCast_Create",	lMultiCast_Create);
--lua_register(L, "fMultiCast_Test",	lMultiCast_Test);
--lua_register(L, "fMultiCast_Update",	lMultiCast_Update);
--lua_register(L, "fMultiCast_ObjectID",	lMultiCast_ObjectID);
--lua_register(L, "fMultiCast_Send",	lMultiCast_Send);
--lua_register(L, "fMultiCast_Stats",	lMultiCast_Stats);
--}
