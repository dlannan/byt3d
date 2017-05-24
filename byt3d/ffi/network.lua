--
-- Created by David Lannan
-- User: grover
-- Date: 4/05/13
-- Time: 10:25 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

local libs = ffi_winsock2_libs or {
    Windows = { x86 = "ws2_32.dll", x64 = "ws2_32.dll" },
}

local lib  = ffi_winsock2_libs or libs[ ffi.os ][ ffi.arch ]

local ws2   = ffi.load( lib )

ffi.cdef[[

///**************************************************************************************************************/
//
//void fServer_Register(lua_State* L);
//
///**************************************************************************************************************/

typedef uint32_t *  uint32_tPtr;

typedef uint32_t    u32;
typedef uint8_t     u8;

typedef char *      PCSTR;
typedef char *      charPtr;

//**************************************************************************************************************/
// *
// * The new type to be used in all
// * instances which refer to sockets.
// */

enum
{
    FD_SETSIZE              = 256
};

typedef uint32_t            SOCKET;

typedef struct fd_set {
    u32 fd_count;                   //* how many are SET? */
    SOCKET  fd_array[FD_SETSIZE];   //* an array of SOCKETs */
} fd_set;

//**************************************************************************************************************/

typedef struct in_addr {
    uint32_t s_addr;
} in_addr;

typedef struct sockaddr {
        uint16_t    sa_family;
        char        sa_data[14];
} sockaddr;

typedef struct sockaddr_in {
        int16_t             sin_family;
        uint16_t            sin_port;
        struct  in_addr     sin_addr;
        char                sin_zero[8];
} sockaddr_in;

typedef sockaddr * sockaddrPtr;

typedef struct  hostent {
        char    * h_name;               //* official name of host */
        charPtr * h_aliases;            //* alias list */
        uint16_t h_addrtype;            //* host address type */
        uint16_t h_length;              //* length of address */
        uint32_tPtr h_addr_list;      //* list of addresses */
} hostent;

typedef hostent * hostentPtr;

typedef struct ip_mreq {

    in_addr imr_multiaddr; /* multicast group to join */
    in_addr imr_interface; /* interface to join on */
} ip_mreq;

typedef struct timeval {
        uint32_t    tv_sec;         /* seconds */
        uint32_t    tv_usec;        /* and microseconds */
};

//**************************************************************************************************************/

enum
{
    IOCPARM_MASK            = 0x0000007f,      /* parameters must be < 128 bytes */
    IOC_VOID                = 0x20000000,      /* no parameters */
    IOC_OUT                 = 0x40000000,      /* copy out parameters */
    IOC_IN                  = 0x80000000,      /* copy in parameters */

    INADDR_ANY              = 0x00000000,
    IPPROTO_IP              = 0,

    IP_MULTICAST_IF         =   9, // IP multicast interface.
    IP_MULTICAST_TTL        =  10, // IP multicast TTL (hop limit).
    IP_MULTICAST_LOOP       =  11, // IP multicast loopback.
    IP_ADD_MEMBERSHIP       =  12, // Add an IP group membership.
    IP_DROP_MEMBERSHIP      =  13, // Drop an IP group membership.

    PACKET_MAGIC	        = 0x31337f00,
    fSERVER_MAGIC	        = 0xbeefbabe,
    MULTICAST_NODE_MAGIC	= 0xbeefbabe,
    UNICAST_NODE_MAGIC	    = 0xbeefbabe,

    // predefined multicast ids
    fMultiCastID_Discover   =	1,
    fMultiCastID_Alive		=   2,
    fMultiCastID_User		=   1,

    fServerMode_Listen	    = 1,
    fServerMode_Connect	    = 2,

    kPacketType_LUA         = 1,
    kPacketType_RAW         = 2,

    AF_INET                 = 2,
    AF_INET6                = 23,
    AF_NETBIOS              = 17,

    INVALID_SOCKET          = 0xffffffff,

    TCP_NODELAY             = 0x0001,

    SOCK_STREAM             = 1,
    SOCK_DGRAM              = 2,
    SOCK_RAW                = 3,
    SOCK_RDM                = 4,
    SOCK_SEQPACKET          = 5,

    IPPROTO_TCP             = 6,

    SO_DEBUG                = 0x0001,      // turn on debugging info recording
    SO_ACCEPTCONN           = 0x0002,      // socket has had listen()
    SO_REUSEADDR            = 0x0004,      // allow local address reuse
    SO_KEEPALIVE            = 0x0008,      // keep connections alive
    SO_DONTROUTE            = 0x0010,      // just use interface addresses
    SO_BROADCAST            = 0x0020,      // permit sending of broadcast msgs
    SO_USELOOPBACK          = 0x0040,      // bypass hardware when possible
    SO_LINGER               = 0x0080,      // linger on close if data present
    SO_OOBINLINE            = 0x0100,      // leave received OOB data in line

    SO_SNDBUF               = 0x1001,      // send buffer size
    SO_RCVBUF               = 0x1002,      // receive buffer size
    SO_SNDLOWAT             = 0x1003,      // send low-water mark
    SO_RCVLOWAT             = 0x1004,      // receive low-water mark
    SO_SNDTIMEO             = 0x1005,      // send timeout
    SO_RCVTIMEO             = 0x1006,      // receive timeout
    SO_ERROR                = 0x1007,      // get error status and clear
    SO_TYPE                 = 0x1008,      // get socket type
    SO_BSP_STATE            = 0x1009,      // get socket 5-tuple state

    SOL_SOCKET              = 0xffff,

    WSADESCRIPTION_LEN      = 256,
    WSASYS_STATUS_LEN       = 128,
};

//**************************************************************************************************************/

typedef struct WSAData {
  uint16_t      wVersion;
  uint16_t      wHighVersion;
  char          szDescription[WSADESCRIPTION_LEN+1];
  char          szSystemStatus[WSASYS_STATUS_LEN+1];
  uint16_t      iMaxSockets;
  uint16_t      iMaxUdpDg;
  char *        lpVendorInfo;
} WSADATA;

typedef WSADATA * LPWSADATA;

typedef struct addrinfo {
  int32_t           ai_flags;
  int32_t           ai_family;
  int32_t           ai_socktype;
  int32_t           ai_protocol;
  int32_t           ai_addrlen;
  char              *ai_canonname;
  struct sockaddr   *ai_addr;
  struct addrinfo   *ai_next;
} ADDRINFOA;

 typedef ADDRINFOA * PADDRINFOA;

//**************************************************************************************************************/

typedef struct PacketHeader_t
{
    u32 Length;
    u32 Magic;
    u32 Type;
    u32 Hash[32];
    u32 Seq;
    u32 pad[29];

} PacketHeader_t;

typedef PacketHeader_t * PacketHeader_tPtr;
typedef void * voidPtr;

//**************************************************************************************************************/

typedef struct fClient_t
{
    u32			Socket;
    u32			id;

    // receive
    u32			RxState;
    u32			RxPos;
    u32			RxLen;
    u32			RxMax;
    u8*			Rx;
    PacketHeader_t*		RxHeader;

    // when send is blocked, overflow to here
    u32			TxPos;
    u32			TxLen;
    u32			TxMax;
    u8*			Tx;
    PacketHeader_t*		TxHeader;

    struct fClient_t*	Next;
    struct fClient_t*	Prev;

} fClient_t;

//**************************************************************************************************************/

typedef struct
{
    u32			Mode;
    u32			Listen;		// listen socket (0 if nothing)
    u32			SockHigh;
    u32			Port;
    char			FifoName[128];	// name of fifo to push object into
    char			ServerIP[128];

    bool			HangupValid;
    char			HangupFunc[128];	// name of hangup function

    u32			ClientSeq;
    fClient_t*		Client;
    fd_set 			Sock;
    u32			Magic;

} fServer_t;

//**************************************************************************************************************/

struct fMultiCastNode_t;
typedef void PacketFunc_f(struct fMultiCastNode_t* N, u32 ObjectID, void* Data, u32 Size, void* User);
typedef PacketFunc_f * PacketFunc_fPtr;

struct fUniCastNode_t;
typedef void 		UniFunc_f(struct fUniCastNode_t* N, struct fUniCastClient_t* C, void* Data, u32 Size, void* User);
typedef UniFunc_f * UniFunc_fPtr;

//**************************************************************************************************************/

typedef struct fMutliHeader_t
{
    u32	PayloadTotal;
    u32	PayloadSize;
    u32	PayloadOffset;
    u32	ObjectID;
    u32	SeqID;

} fMultiHeader_t;

typedef fMultiHeader_t * fMultiHeader_tPtr;

typedef struct fMultiCastNode_t
{
    struct sockaddr_in addr;

    u32		    Socket;
    fd_set 		Sock;
    u32		    SockHigh;

    char		McGroup[32];
    u32		    Port;
    u32		    SeqNumber;

    // packet handlers

    u32		DispatchMax;
    PacketFunc_fPtr*	Dispatch;
    voidPtr*		    DispatchUser;

    // this nodes object id

    u32		ObjectID;
    u32		DiscoverID;
    bool		DiscoverFound;

    // tmp buffer

    u32		BufferSize;
    char*		BufferTx;
    char*		BufferRx;

    u32		Magic;

} fMultiCastNode_t;

//**************************************************************************************************************/

typedef struct fUniHeader_t
{
	u32	PayloadTotal;
	u32	PayloadSize;
	u32	PayloadOffset;
	u32	MessageID;
	u32	SeqID;

} fUniHeader_t;

typedef fUniHeader_t * fUniHeader_tPtr;

//**************************************************************************************************************/

typedef struct fUniCastClient_t
{
	u32				ClientID;
	struct sockaddr_in 		addr;

	struct fUniCastClient_t*	Next;
	struct fUniCastClient_t*	Prev;

} fUniCastClient_t;

//**************************************************************************************************************/

typedef struct fUniCastNode_t
{
	struct sockaddr_in addr;

	u32		Socket;
	fd_set 		Sock;
	u32		SockHigh;

	u32		Port;
	u32		SeqNumber;

	// packet handlers

	u32		DispatchMax;
	UniFunc_f**	Dispatch;
	void**		DispatchUser;

	// tmp buffer

	u32		BufferSize;
	char*		BufferTx;
	char*		BufferRx;

	// client list
	u32		ClientSeq;
	fUniCastClient_t*	Client;

	u32		Magic;

} fUniCastNode_t;

//**************************************************************************************************************/

int setsockopt( SOCKET s, int level, int optname, const char* optval, int optlen );
int ioctlsocket( SOCKET s, long cmd, uint32_t * argp );

SOCKET socket( int af, int type, int protocol );

uint16_t htons( uint16_t hostshort );
int bind( SOCKET s, struct sockaddr* name, int namelen );
int listen( SOCKET s, int backlog );
hostentPtr gethostbyname( const char *name );
int connect( SOCKET s,const struct sockaddr * name, int namelen );
int sendto( SOCKET s, const char * buf, int len, int flags, const struct sockaddr * to,int tolen );
int select( int nfds, fd_set * readfds, fd_set * writefds, fd_set * exceptfds, const struct timeval * timeout );
int recvfrom( SOCKET s, char * buf,int len, int flags, struct sockaddr * from, int * fromlen );

char* inet_ntoa( struct in_addr in );
uint32_t htonl( uint32_t hostlong );
uint32_t inet_addr( const char * cp );

int getaddrinfo( PCSTR pNodeName, PCSTR pServiceName, const ADDRINFOA *pHints, PADDRINFOA *ppResult );
int __WSAFDIsSet( SOCKET fd, fd_set *set);
int WSAStartup( uint16_t wVersionRequested, LPWSADATA lpWSAData );

//**************************************************************************************************************/
]]

-- /**************************************************************************************************************/
-- Special Script - this provides all the FD_ macros that sockets need in POSIX world
--/*
--* Select uses arrays of SOCKETs.  These macros manipulate such
--* arrays.  FD_SETSIZE may be defined by the user before including
--* this file, but the default here should be >= 64.
--*
--* CAVEAT IMPLEMENTOR and USER: THESE MACROS AND TYPES MUST BE
--* INCLUDED IN WINSOCK2.H EXACTLY AS SHOWN HERE.
--*/

function FD_CLR(fd, set)

    for __i = 0, set.fd_count - 1 do

        if (set.fd_array[__i] == fd) then

            while (__i < set.fd_count-1 ) do

                set.fd_array[__i] = set.fd_array[__i+1]
                __i = __i + 1
            end
            set.fd_count = set.fd_count -1
            break
        end
    end
end

-- /**************************************************************************************************************/

function FD_SET(fd, set)

    local __i
    for __i = 0, set.fd_count -1 do
        if (set.fd_array[__i] == fd) then
            break
        end
    end
    if (__i == set.fd_count) then
        if (set.fd_count < FD_SETSIZE) then
            set.fd_array[__i] = (fd)
            set.fd_count = set.fd_count + 1
        end
    end
end

-- /**************************************************************************************************************/

function FD_ZERO(set)
    set.fd_count=0
end

-- /**************************************************************************************************************/

function FD_ISSET(fd, set)
    ws2.__WSAFDIsSet((SOCKET)(fd), set)
end

-- /**************************************************************************************************************/

function _IO(x,y)
    return bit.bor(ws2.IOC_VOID, bit.bor(bit.lshift(x,8),y))
end

function _IOR(x,y,t)
    return bit.bor(ws2.IOC_OUT, bit.bor( bit.lshift(bit.band(ffi.sizeof(t), ws2.IOCPARM_MASK), 16), bit.bor(bit.lshift(x, 8), y) ) )
end

function _IOW(x,y,t)
    return bit.bor(ws2.IOC_IN, bit.bor( bit.lshift(bit.band(ffi.sizeof(t), ws2.IOCPARM_MASK), 16), bit.bor(bit.lshift(x, 8), y) ) )
end

FIONREAD    = _IOR(string.byte('f'), 127, "uint64_t")
FIONBIO     = _IOW(string.byte('f'), 126, "uint64_t")
FIOASYNC    = _IOW(string.byte('f'), 125, "uint64_t")

-- /**************************************************************************************************************/
--// Initialize Winsock

function WS2Init()

    local wsaDataPtr = ffi.new("WSADATA[1]")
    local iResult = ws2.WSAStartup( 0x0202, wsaDataPtr);
    if (iResult < 0) then
        tracef("Error at WSAStartup()")
    end
end

-- /**************************************************************************************************************/

return ws2

-- /**************************************************************************************************************/
