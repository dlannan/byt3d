--
-- Created by David Lannan
-- User: grover
-- Date: 4/05/13
-- Time: 11:23 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

ws2 = require("byt3d/ffi/network")

--struct fUniCastNode_t;
--struct fUniCastClient_t;
--
--typedef void 		UniFunc_f(struct fUniCastNode_t* N, struct fUniCastClient_t* C, void* Data, u32 Size, void* User);
--
--void 			fUniCast_Register(lua_State* L);
--bool 			fUniCast_Send(struct fUniCastNode_t* N, u32 ClientID, u32 ObjectID, void* Payload, u32 PayloadSize, bool Gaurentee);
--void 			fUniCast_Update(struct fUniCastNode_t* N);
--
--void 			fUniCast_PacketHandler(struct fUniCastNode_t* N, const u32 ID, UniFunc_f* Func, void* User);
--struct fUniCastNode_t*	toUniCast(lua_State* L, int index);
--
--// predefined multicast ids
--#define fUniCastID_ClientCreate		1
--#define fUniCastID_ClientDestroy	2
--#define fUniCastID_Alive		3
--#define fUniCastID_Ack			4
--#define fUniCastID_User			16

local s_PacketCount = 0;

-- /**************************************************************************************************************/

function toUniCast( N )

    fAssert(N)
    fAssert(N.Magic == UNICAST_NODE_MAGIC)
    return N
end

-- /**************************************************************************************************************/

function fUniCast_ClientCreate( N,  H, addr)

    printf("client create: %i.%i.%i.%i\n",
        bit.band(addr.sin_addr.s_addr, 0xFF),
        bit.band(bit.rshift(addr.sin_addr.s_addr,8), 0xFF),
        bit.band(bit.rshift(addr.sin_addr.s_addr,16), 0xFF),
        bit.band(bit.rshift(addr.sin_addr.s_addr,24), 0xFF) )

    local C = ffi.new("fUniCastClient_t")
    ffi.fill(C, ffi.sizeof("fUniCastClient_t"), 0)

    -- // copy addr
    C.addr		= addr[0]
    C.ClientID	= N.ClientSeq
    N.ClientSeq = N.ClientSeq + 1

    C.Prev		= nil
    C.Next		= N.Client

    if (N.Client) then N.Client.Prev = C end

    N.Client	= C
end

-- /**************************************************************************************************************/

function fUniCast_Dispatch_ClientDestroy( N, Data, Size, User)

    printf("client destroyed\n")
end

-- /**************************************************************************************************************/

function fUniCast_Dispatch_Alive( N,  C, Data, Size, User)

    printf("client: %i alive\n", C.ClientID)
end

-- /**************************************************************************************************************/

function lUniCast_Create(config)

    local S = ffi.new("fUniCastNode_t")
    fAssert(S)

    -- // port number
    S.Port	= config.Port
    fAssert(S.Port ~= 0)

    -- // create it
    S.Socket = ws2.socket(AF_INET, SOCK_DGRAM, 0)
    if (S.Socket < 0) then

        ftrace("UniCast_Server: failed to create socket\n")
        return 0
    end

    local reuse_addr = ffi.new("uint32_t", 1)
    ws2.setsockopt(S.Socket, SOL_SOCKET, SO_REUSEADDR, reuse_addr, ffi.sizeof(reuse_addr));

    -- // nice big large buffers
    local sock_buf_size = ffi.new("uin32_t",16*1024*1024)
    fAssert(setsockopt(S.Socket, SOL_SOCKET, SO_SNDBUF, sock_buf_size, ffi.sizeof(sock_buf_size) )>=0);
    fAssert(setsockopt(S.Socket, SOL_SOCKET, SO_RCVBUF, sock_buf_size, ffi.sizeof(sock_buf_size) )>=0);

    -- // non blocking
    setnonblocking(S.Socket)

    local addr = ffi.new("struct sockaddr_in")
    addr.sin_family		= AF_INET
    addr.sin_port		= htons(S.Port)
    addr.sin_addr.s_addr	= INADDR_ANY

    local ret = ws2.bind(S.Socket, addr, ffi.sizeof(addr))
    if (ret < 0) then

        ftrace("UniCast_Server: bind failed: %08x %08x\n", ret, errno)
        return 0
    end

    S.Magic 	= UNICAST_NODE_MAGIC

    -- // allocate dispatch handlers
    S.DispatchMax	= 64*1024
    S.Dispatch	= ffi.new("UniFunc_fPtr["..S.DispatchMax.."]")
    S.DispatchUser = ffi.new("voidPtr["..S.DispatchMax.."]")
    fAssert(S.Dispatch)
    fAssert(S.DispatchUser)
    ffi.fill(S.Dispatch, ffi.sizeof(UniFunc_fPtr)*S.DispatchMax, 0)
    ffi.fill(S.DispatchUser, ffi.sizeof(voidPtr)*S.DispatchMax, 0)

    -- // tmp buffers
    S.BufferSize = 16*1024
    S.BufferTx = ffi.new("char["..(S.BufferSize).."]")
    S.BufferRx = ffi.new("char["..(S.BufferSize).."]")

    -- // reset client list
    S.ClientSeq		= 1
    S.Client		= nil

    -- // discovery handler
    fUniCast_PacketHandler(S, fUniCastID_Alive,		fUniCast_Dispatch_Alive,		nil)
    ftrace("unicast done\n")

    return S
end


-- /**************************************************************************************************************/
-- // check for incomming
function lUniCast_Update(N)

    N = toUniCast(N)
    fUniCast_Update(N)
    return 0
end

-- /**************************************************************************************************************/

function fUniCast_Update( N)

    local LastID = 0

    timeout = ffi.new("struct timeval")
    timeout.tv_sec = 0
    timeout.tv_usec = 0

    fAssert(N)
    build_select_list(N)

    while (true) do

        -- // check for pending

        -- //int readsocks = select(N->SockHigh+1, &N->Sock, (fd_set *) 0,  (fd_set *) 0, &timeout);
        -- //if (readsocks == 0) break;

        -- // fetch
        local addr = ffi.new("struct sockaddr_in")
        local addrlen = ffi.sizeof(addr)
        local len = ws2.recvfrom(N.Socket, N.BufferRx, N.BufferSize, 0, addr, addrlen)
        if (len <= 0) then break; end

        local H = ffi.cast("fUniHeader_tPtr", N.BufferRx)
        fAssert(H.PayloadSize == len)
        s_PacketCount = s_PacketCount + 1

        -- // which client.. nasty
        local C = N.Client
        while (C) do

            if (C.addr.sin_addr.s_addr == addr.sin_addr.s_addr) then break end
            C = C.Next
        end

        -- // garuentee required ?
        if ( bit.band(H.MessageID, bit.lshft(1,31)) > 0 ) then

            local buffer = ffi.new("char[1024]")
            local Ack = ffi.cast("fUniHeader_tPtr", buffer)
            Ack.PayloadSize = ffi.sizeof("fUniHeader_t")+ffi.sizeof("uint32_t")*2
            Ack.MessageID = fUniCastID_Ack
            Ack.SeqID = 0

            local AckID = ffi.cast("uint32_tPtr", Ack+1)
            AckID[0] = bit.band(H.MessageID, 0x7fffffff)
            AckID[1] = H.SeqID

            -- // send ack back to client
            ws2.sendto(N.Socket, Ack, Ack.PayloadSize, 0, addr, ffi.sizeof(addr))
            H.MessageID = bit.band(H.MessageID, 0x7fffffff)
        end

        -- // create client
        if(H.MessageID == fUniCastID_ClientCreate)then

            fUniCast_ClientCreate(N, H, addr)
        else
            if (C == nil) then

                ftrace("fUniCast_Update() unable to find client dropping packet %08x\n", H.MessageID);
                break
            end

            -- // dispatch it
            fAssert(H.MessageID < N.DispatchMax)
            local F = N.Dispatch[H.MessageID]
            if (F ~= nil) then

                -- //printf("dispatch %08x:%08x\n", H->ObjectID, H->PayloadSize);
                F(N, C, H+1, H.PayloadSize-ffi.sizeof("fUniHeader_t"), N.DispatchUser[H.MessageID])
            end
        end
    end
end

-- /**************************************************************************************************************/

function lUniCast_Test(N)

    N = toUniCast(N)
    while (true) do

        local test = ffi.new("uint32_t[16]")
        fUniCast_Send(N, 0, 0, test, 16, true)
    end
end

-- /**************************************************************************************************************/

function fUniCast_Send( N, ClientID, MessageID, Payload, PayloadSize, Gaurentee)

    local H = ffi.cast("fUniHeader_tPtr", N.BufferTx)
    H.PayloadTotal		= PayloadSize+ffi.sizeof("fUniHeader_t")
    H.PayloadSize		= PayloadSize+ffi.sizeof("fUniHeader_t")
    H.PayloadOffset 	= 0
    H.MessageID		    = MessageID
    H.SeqID		        = N.SeqNumber
    N.SeqNumber = N.SeqNumber + 1

    fAssert((PayloadSize+ffi.sizeof("fUniHeader_t")) < N.BufferSize)
    ffi.copy(H+1, Payload, PayloadSize)

    -- // find client
    local C = N.Client
    while (C) do

        if (C.ClientID == ClientID) then break; end
        C = C.Next
    end

    local rem   = H.PayloadSize
    local Send	= N.BufferTx
    local len	= ws2.sendto(N.Socket, Send, rem, 0, C.addr, ffi.sizeof(C.addr))
    return (len == rem)
end

-- /**************************************************************************************************************/

function lUniCast_Send(Payload, MessageID, ClientID, N)

    N = toUniCast(N)

    local plen = string.len(Payload)
    fUniCast_Send(N, ClientID, MessageID, Payload, plen, true)

    return 0
end

-- /**************************************************************************************************************/

function fUniCast_PacketHandler( N, ID, Func, User)

    fAssert(ID < N.DispatchMax)
    N.Dispatch[ID]		= Func
    N.DispatchUser[ID]	= User
end

-- /**************************************************************************************************************/

function lUniCast_Stats()

    status = {}
    status.PacketCount = s_PacketCount

    s_PacketCount = 0;

    return status
end

-- /**************************************************************************************************************/

--void fUniCast_Register(lua_State* L)
--    {
--        lua_register(L, "fUniCast_Create",	lUniCast_Create);
--        lua_register(L, "fUniCast_Test",	lUniCast_Test);
--        lua_register(L, "fUniCast_Update",	lUniCast_Update);
--        lua_register(L, "fUniCast_Send",	lUniCast_Send);
--        lua_register(L, "fUniCast_Stats",	lUniCast_Stats);
--    }
