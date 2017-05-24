--
-- Created by David Lannan
-- User: grover
-- Date: 2/05/13
-- Time: 11:10 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi   = require( "ffi" )
local ws2   = require("byt3d/ffi/network")

-- /**************************************************************************************************************/
-- This is probably a touch bad.. should probably leave gc to do its job.

function fFree(d)
    ffi.C.free(ffi.gc(d, nil)) -- Manually free the memory.
end

-- /**************************************************************************************************************/
-- static void fServer_ObjectRx(lua_State* L, fServer_t* S, fClient_t* C);
-- static int fServer_ObjectTx(lua_State* L);
-- /**************************************************************************************************************/

function setnonblocking(sock)

    local opts = ffi.new("uint32_t[1]")
    local res = ws2.ioctlsocket(sock, FIONREAD, opts)
    if (res < 0) then
        ftrace("fcntl(F_GETFL): ", bit.tohex(FIONREAD), "   " )
    end
    opts[0] = 1 -- bit.bor(opts[0], 1)
    res = ws2.ioctlsocket(sock, FIONBIO, opts)
    if(res < 0) then
        ftrace("fcntl(F_SETFL): ", bit.tohex(FIONBIO), "   ", opts[0])
    end
end

-- /**************************************************************************************************************/

function toServer( server )
    local S = server   -- should be iof type fServer_t *
    fAssert(S)
    fAssert(S.Magic == fSERVER_MAGIC)
    return S
end

-- /**************************************************************************************************************/

function fServer_ClientConnect( S, newsock )

    -- //ftrace("new connection requested!\n");

    -- // disable nagle
    local flag = ffi.new("char[1]")
    flag[0] = 1
    ws2.setsockopt(newsock, ws2.IPPROTO_TCP, ws2.TCP_NODELAY, flag, ffi.sizeof("char") )

    local sock_buf_size = ffi.new("uint32_t[1]", 1024*1024 )
    ws2.setsockopt(newsock, ws2.SOL_SOCKET, ws2.SO_SNDBUF, ffi.cast("char *", sock_buf_size), ffi.sizeof("uint32_t") )
    ws2.setsockopt(newsock, ws2.SOL_SOCKET, ws2.SO_RCVBUF, ffi.cast("char *", sock_buf_size), ffi.sizeof("uint32_t") )

    -- // find home for it
    local C = ffi.new("fClient_t")
    C.Socket 	= newsock;
    C.id 		= S.ClientSeq+1

    C.RxState	= 0
    C.RxPos	= 0
    C.RxLen	= 0
    C.RxMax	= 1024*1024
    C.Rx		= ffi.new("char["..C.RxMax.."]")
    C.RxHeader	= ffi.cast("PacketHeader_tPtr", C.Rx)

    C.TxPos	= 0
    C.TxLen	= 0
    C.TxMax	= 1024*1024
    C.Tx		= ffi.new("char["..C.TxMax.."]")
    C.TxHeader	= ffi.cast("PacketHeader_tPtr", C.Tx)

    C.Next		= nil
    C.Prev		= nil

    -- // first entry ?
    if(S.Client == nil) then
        S.Client = C
    else
        local T = S.Client
        while (T.Next ~= nil) do
            T = T.Next
        end

        T.Next = C
        C.Prev = T
    end
end

-- /**************************************************************************************************************/

function fServer_ClientDisconnect(S, C)

    -- // tell lua side
    if (S.HangupValid) then
        if( S.HangupFunc ) then
            _G[S.HangupFunc](S.Port, C.id)
        end
    end

    -- // remove client from list
    ftrace("client disconnected: %i : %08x %08x\n", errno, S.Client, C)

    -- // head of list
    if (S.Client == C) then

        S.Client = C.Next
    else
        if (C.Prev) then C.Prev.Next = C.Next  end
        if (C.Next) then C.Next.Prev = C.Prev  end
    end

    -- // close the socket
    ws2.close(C.Socket, 0)

    -- // release memory
    fFree(C.Tx)
    fFree(C.Rx)
    C.Tx = nil
    C.Rx = nil

    C.Next = 0
    C.Prev = 0
end

-- /**************************************************************************************************************/

function fServer_ClientFind( S, id )

    C = S.Client
    while (C) do

        if (C.id == id) then return C end
        C = C.Next
    end

    ftrace("unable to find client: %i\n", id);
    fAssert(false);

    -- // cant find object
    return 0
end

-- /**************************************************************************************************************/

function fServer_ClientData( S, C )

    if (C.RxState == 0 ) then
        --  // waiting for head data
        local len = ws2.recv(C.Socket, C.Rx[C.RxPos], ffi.size(PacketHeader_t)-C.RxPos, MSG_NOSIGNAL)
        -- // anything but eagain means hangup
        if ((len <= 0) and (errno ~= EAGAIN)) then
            fServer_ClientDisconnect(S, C)
            return
        end

        if (len <= 0) then len = 0 end
        C.RxPos = C.RxPos + len

        -- //ftrace("[%02i] header data %08x: %08x errno:%i\n", C->id, len, C->RxHeader->Length, errno);
        if (C.RxPos >= ffi.size(PacketHeader_t)) then
            -- // header has arrived so advnace to next stage
            C.RxLen = ffi.size(PacketHeader_t) + C.RxHeader.Length
            C.RxState = 1

            -- // check magic
            if (C.RxHeader.Magic ~= PACKET_MAGIC) then
                ftrace("[%02i] packet missing magic number, closing connection\n")
                fServer_ClientDisconnect(S, C)
                return
            end

            -- // make sure length is reasonable
            if (C.RxHeader.Length > 128*1024*1024) then
                ftrace("[%02i] requesting packet of length: %08x\n", C.id, C.RxHeader.Length)
                ftrace("[%02i] dropping the connection as something is arsed\n", C.id)
                fServer_ClientDisconnect(S, C)
                return
            end

            -- // buffer too small_
            if (C.RxHeader.Length > C.RxMax) then
                -- // increase buffer size
                C.RxMax = bit.band( (C.RxHeader.Length+1024*1024-1), bit.bnot(1024*1024-1) )

                local OldBuffer = C.Rx
                C.Rx = ffi.new("char["..C.RxMax.."]", OldBuffer)
                -- memcpy(C->Rx, OldBuffer, C->RxPos);
                C.RxHeader = C.Rx

                fFree(OldBuffer)
                ftrace("new receive buffer size:%iMB\n", C.RxMax/(1024*1024))
            end
        end
    end

    -- // double switch so can do header+data in one call (if there)
    if (C.RxState == 1) then
        -- // continue fetch
        local len = ws2.recv(C.Socket, C.Rx[C.RxPos], C.RxLen-C.RxPos, MSG_NOSIGNAL)
        -- //ftrace("[%02i] received more data %i/%i : %i\n", C->id, C->RxPos, C->RxLen, len);

        -- // anything but eagain means hangup
        if ((len == -1) and (errno ~= EAGAIN)) then
            fServer_ClientDisconnect(L, S, C);
            return
        end

        if (len <= 0) then len = 0 end
        C.RxPos = C.RxPos + len

        -- // all there ?
        if (C.RxPos == C.RxLen) then
            -- // process the object
            fServer_ObjectRx(S, C)

            -- //ftrace("[%i] recevied all data\n", id);
            C.RxLen = 0;
            C.RxPos = 0;
            C.RxState = 0;
        end
    end
end

-- /**************************************************************************************************************/

function fServer_ClientResend( S, C )

    -- //ftrace("resend %i : %i %i %p\n", C->Socket, C->TxPos, C->TxLen, C->Tx);
    local ret = ws2.send(C.Socket, C.Tx[C.TxPos], C.TxLen-C.TxPos, bit.bor(MSG_DONTWAIT,MSG_NOSIGNAL) )
    if (ret > 0) then
        C.TxPos = C.TxPos + ret

        -- //ftrace("local send backed up %i/%i -> sent %i\n", C->TxPos, C->TxLen, ret);
        if (C.TxPos == C.TxLen) then
            -- //ftrace("backed up object done\n");
            C.TxPos = 0
            C.TxLen = 0
        else

            -- //ftrace("socket still backed up\n");
            return false
        end
    end

    if (ret < 0) then

        -- // what kind of error
        if(errno ~= EAAGAIN) then
            -- // connection broken
            fServer_ClientDisconnect(S, C)
        end
        return false
    end

    return true
end

-- /**************************************************************************************************************/

function build_select_list( S )

    ws2.FD_ZERO(S.Sock)

    -- // listen socket
    ws2.FD_SET(S.Listen, S.Sock)

    -- // client sockets
    S.SockHigh = S.Listen

    -- // clients
    local C = S.Client
    while (C) do
        fAssert (C.Socket ~= 0)

        ws2.FD_SET( C.Socket, S.Sock)
        if (C.Socket > S.SockHigh) then
            S.SockHigh = C.Socket

            C = C.Next
        end
    end
end

-- /**************************************************************************************************************/

function fServer_Select( S )

    build_select_list(S)

    local timeout = ffi.new("timeval")
    timeout.tv_sec = 0
    timeout.tv_usec = 0

    -- //printf("%i %i\n", m_server_listen, m_server_highsock);
    -- // max of 16packets thru the loop
    local PacketCount = 0
    while (PacketCount < 16) do

        -- //check socket
        local readsocks = ws2.select(S.SockHigh+1, S.Sock, 0,  0, timeout)
        if (readsocks <= 0) then break end

        -- // new connection ?
        if ((S.Listen ~= 0) and FD_ISSET(S.Listen, S.Sock)) then

            -- //printf("new connection\n");
            local newsock = ws2.accept(S.Listen, 0, 0)
            fServer_ClientConnect(S, newsock)
        end

        -- // check for data
        local C = S.Client
        while (C ~= 0) do

            fAssert (C.Socket ~= 0)
            if (ws2.FD_ISSET(C.Socket, S.Sock)) then

                fServer_ClientData(S, C)
            end

            C = C.Next
        end
    end

    -- // check for outstanding Tx
    local C = S.Client
    while (C ~= 0) do

        -- // outstanding data
        if (C.TxLen ~= 0) then

            fServer_ClientResend(S, C)
        end
        C = C.Next
    end

    return 0
end

-- /**************************************************************************************************************/

function fServer_ObjectRx( S, C )
    -- // hash check
    if (C.RxHeader.Type ~= kPacketType_RAW ) then
        -- // verify
        local Hash = {}
        fCrypt_SHA256(Hash, C.Rx+ffi.size(PacketHeader_t), C.RxLen-ffi.size(PacketHeader_t))

        local error = 0
        for i=0, 32/4 - 1 do

            -- //ftrace("%08x : %08x : %08x\n", Hash[i] ^ C->RxHeader->Hash[i], Hash[i], C->RxHeader->Hash[i]);
            error = bit.bor(error, bit.bxor(Hash[i], C.RxHeader.Hash[i]))
        end
        fAssert(error == 0)
    end

    -- //ftrace("received new object %i %i\n", C->id, C->RxLen-sizeof(PacketHeader_t));

    -- // add to connection list
    S.FifoName = {}
    S.FifoName.data = ffi.string(C.Rx+ffi.size(PacketHeader_t), C.RxLen-ffi.size(PacketHeader_t) )
    S.FifoName.client = C.id
end

-- /**************************************************************************************************************/

function fServer_ObjectTx(S, id, buf)

    local C = fServer_ClientFind(S, id)
    if (C == 0) then
        -- // tell lua side
        if (S.HangupValid) then
            _G[S.HangupFunc]( S.Port, id )
        end

        return false
    end
    fAssert(C.Socket > 0)

    -- // there a pending packet?
    if (C.TxLen ~= 0) then

        if (fServer_ClientResend(S, C) == false) then

            return false
        end
    end

    -- // get client
    if (C.Socket <= 0) then
        return false
    end

    -- // get string
    local len = ffi.size(buf)
    if (C.TxMax < len) then

        -- // re-allocate send buffer up
        C.TxMax = bit.band( (len+1024*1024-1), bit.bnot(1024*1024-1))
        fFree(C.Tx)
        C.Tx = ffi.new("char["..C.TxMax.."]")
        C.TxHeader = C.Tx

        ftrace("new buffer send size: %iMB\n", C.TxMax/(1024*1024))
    end
    fAssert(C.TxMax > len)

    local Header = ffi.new("PacketHeader_t")
    Header.Length = len
    Header.Magic = PACKET_MAGIC
    Header.Type = kPacketType_LUA

    Seq = 0
    Header.Seq = Seq; Seq = Seq + 1
    -- //ftrace("\nSeq %08x\n", Header.Seq);

    -- // sha1 the data
    fCrypt_SHA256(Header.Hash, buf, len);

    --/*
    --for (int i=0; i < 32/4; i++)
    --    {
    --        ftrace("hash %08x\n", Header.Hash[i]);
    --    }
    --*/

    local ret = ws2.send(C.Socket, Header, ffi.size(Header), bit.bor(MSG_DONTWAIT, MSG_NOSIGNAL))
    if (ret < 0) then

        ftrace("send failed header: %i %i\n", ret, errno);

        -- // what kind of error
        if(errno ~= EAGAIN) then
            fServer_ClientDisconnect(S, C)
        end
        return false
    end

    if ((ret > 0) and (ret ~= ffi.size(Header))) then

        -- //ftrace("send failure header %i: %i\n", ret, len);

        -- // copy to temp buffer
        fAssert(C.TxMax > len)
        ffi.copy(C.Tx, Header, ffi.size(Header))
        ffi.copy(C.Tx+ffi.size(Header), buf, len)

        C.TxPos = ret
        C.TxLen = ffi.size(Header)+len
        return true
    end

    -- //ftrace("send packet %iB %p\n", len, buf);

    -- // send over
    ret = ws2.send(C.Socket, buf, len, bit.bor(MSG_DONTWAIT, MSG_NOSIGNAL))
    if ((ret == -1) and (errno ~= EAGAIN)) then

        fServer_ClientDisconnect(S, C)
        return false
    elseif (ret ~= len) then

        -- //ftrace("send failure %i: %i\n", ret, len);

        -- // copy to temp buffer
        fAssert(C.TxMax > len)
        ffi.copy(C.Tx, buf, len)
        if(ret < 0) then ret = 0 end
        C.TxPos = ret
        C.TxLen = len
        return true
    end

    return true
end

--/**************************************************************************************************************/
--//
--// create a server
--//
function fServer_Create(port, hfunc, fifoname)

    S = ffi.new("fServer_t")
    fAssert(S)
    S.Magic     = ws2.fSERVER_MAGIC
    S.Mode      = ws2.fServerMode_Listen
    S.ClientSeq = 0
    S.Port      = port

    -- // copy lua fifo name
    S.FifoName  = fifoname

    -- // copy hangup function name
    S.HangupFunc = hfunc
    S.HangupValid = (hfunc ~= nil)
    -- //printf("hangup func [%s]\n", S->HangupFunc);

    S.Listen = ws2.socket(ws2.AF_INET, ws2.SOCK_STREAM, ws2.IPPROTO_TCP)
    if (S.Listen == ws2.INVALID_SOCKET) then
        ftrace("ERROR opening socket");
        return nil
    end

    -- /* So that we can re-bind to it without TIME_WAIT problems */
    local reuse_addr = ffi.new("char[1]")
    reuse_addr[0] = 1
    ws2.setsockopt(S.Listen, ws2.SOL_SOCKET, ws2.SO_REUSEADDR, reuse_addr, ffi.sizeof(reuse_addr))

    -- // set to non blocking
    setnonblocking(S.Listen)

    local serv_addr = ffi.new("struct sockaddr_in[1]")
    local addr = ffi.new("struct sockaddr[1]")
    serv_addr[0].sin_family         = ws2.AF_INET
    serv_addr[0].sin_addr.s_addr    = ws2.INADDR_ANY
    serv_addr[0].sin_port           = ws2.htons(S.Port)

    addr[0].sa_family               = ws2.AF_INET
    ffi.fill(addr[0].sa_data, ffi.sizeof("struct  in_addr"), 0)

    -- Some Debug Info
--    io.write("Socket: ", bit.tohex(S.Listen), "   Family: ", addr[0].sa_family, "   ")
--    for i=0,13 do io.write(addr[0].sa_data[i]) end; io.write("\n")
    --

    local ret = ws2.bind(S.Listen, addr, ffi.sizeof(addr))
    if (ret < 0) then
        ftrace("ERROR on binding:", ret);
        return nil
    end

    -- // set it to listen
    ret = ws2.listen(S.Listen, 5)
    if (ret < 0) then
        ftrace("listen failed %i\n", ret);
    end

    -- // initally no clients
    S.Client = nil

    ftrace("server setup done port: ", S.Port)
    return S
end

-- /**************************************************************************************************************/
--//
-- // destroy server
--//
function fServer_Destroy(S)

    S = toServer(S)
    if (S.Listen) then

        shutdown(S.Listen, 0)
        S.Listen = 0
    end

    C = S.Client
    while (C) do

        N = C.Next
        if (C.Socket) then
            shutdown(C.Socket, 0)
            C.Socket = 0
        end

        ffi.fill(C, ffi.size(fClient_t), 0)
        fFree(C)
        C = N
    end

    ffi.fill(S, ffi.size(fServer_t), 0)
    fFree(S)

    return 0
end

--/**************************************************************************************************************/
--//
--// connect to a server
--//
function fServer_Connect(hfunc, port, serverip, fifoname)

    local S = ffi.new("fServer_t")
    fAssert(S)

    S.Magic     = ws2.fSERVER_MAGIC
    S.Mode      = ws2.fServerMode_Connect
    S.Listen    = 0
    S.Client    = nil
    S.ClientSeq = 0

    S.FifoName = fifoname
    S.ServerIP = serverip
    S.Port = port

    -- // copy hangup function name
    S.HangupValid = (hfunc ~= nil)
    S.HangupFunc = hfunc
    -- //printf("hangup func [%s]\n", S->HangupFunc);

    local sock = ws2.socket(ws2.AF_INET, ws2.SOCK_STREAM, ws2.IPPROTO_TCP)
    if (sock < 0) then
        ftrace("ERROR opening socket")
        return nil
    end
    -- //ftrace("Router connect [%s:%i]\n", S->ServerIP, S->Port);

--    -- This is ok for OSX and Linux but seems to return crud on Win64
--    -- // get ip addr
--    local hp = ws2.gethostbyname(S.ServerIP)
--    if (hp == nil) then
--        ftrace("invalid host name: ", S.ServerIP)
--        return nil
--    end

    local result = ffi.new("PADDRINFOA[1]")
    local hints = ffi.new("ADDRINFOA[1]")
    ffi.fill(hints, ffi.sizeof("ADDRINFOA"), 0)
    hints[0].ai_family = ws2.AF_INET
    hints[0].ai_socktype = ws2.SOCK_STREAM
    hints[0].ai_protocol = ws2.IPPROTO_TCP

    local pstr = tostring(S.Port)
    local port = ffi.new("char["..string.len(pstr).."]")
    ffi.copy(port, pstr)
    local res = ws2.getaddrinfo(S.ServerIP, port, hints, result)
    if (res ~= 0) then
        ftrace("invalid host name: ", S.ServerIP)
        return nil
    end

    -- local hostip = hp.h_addr_list[0]
    local first_result = result[0]
    local hostip = first_result[0].ai_addr

    local serv_addr = ffi.new("sockaddr_in[1]")
    ffi.fill(serv_addr[0], ffi.sizeof(serv_addr), 0)

    serv_addr[0].sin_family = ws2.AF_INET
    serv_addr[0].sin_port = ws2.htons(S.Port)

    local ret = ws2.connect(sock, hostip, ffi.sizeof(hostip[0]))
    if (ret < 0) then
        ftrace("ERROR on connect: ", ret)
        return nil
    end

    -- // server with 1 client
    fServer_ClientConnect(S, sock)
    -- //ftrace("server connected:%i %08x FIFO[%s]\n", S->Port, S, S->FifoName);

    -- // return object
    return S
end


-- /**************************************************************************************************************/

--void fServer_Register(lua_State* L)
--    {
--        lua_register(L, "fServer_Create", fServer_Create);
--        lua_register(L, "fServer_Destroy", fServer_Destroy);
--        lua_register(L, "fServer_Connect", fServer_Connect);
--        lua_register(L, "fServer_Select", fServer_Select);
--        lua_register(L, "fServer_Send", fServer_ObjectTx);
--    }
