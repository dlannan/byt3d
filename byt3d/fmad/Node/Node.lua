--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 1:57 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

--/**************************************************************************************************************/
---- //
--/* fmad llc 2008 */
---- //
---- // base network node, can be configured in a router type or kernel type based on the configuration file
---- //
--/**************************************************************************************************************/

require "fmad/Common/fCommon_h"
require "fmad/System/fSystem_h"
require "fmad/Network/fNetwork_h"
require "fmad/Node/Module_h"
require "fmad/Node/Execute_h"

--#include <stdint.h>
--#include <Tools/x264/x264.h>
--#include <Tools/libjpeg/jpeglib.h>

---- //**************************************************************************************************************/

local	s_ProcessName = nil
local	s_ProcessNameMax = 0
local	s_ProcessPID = 0

local 	g_WatchdogKey
local 	g_WatchdogSemaphore = 0
local	g_WatchdogDeadStart = 0
local	g_WatchdogTimeout = 1*60	-- // 3 minutes

-- //**************************************************************************************************************/

-- // lua scripts
fLua_ExternByteCode(lCommon)
fLua_ExternByteCode(lSystem)
fLua_ExternByteCode(lNode)
fLua_ExternByteCode(lRouter)
fLua_ExternByteCode(lKernel)
fLua_ExternByteCode(lDispatch)
fLua_ExternByteCode(lModule)

-- // note execution order is list order
m_LuaInclude = ffi.new("LuaInclude_t[?]",
{
    { "lCommon.lua", 	"Common/lCommon.lua",	fLua_ByteCode(lCommon)	},
    { "lSystem.lua", 	"System/lSystem.lua",	fLua_ByteCode(lSystem)	},
    { "lNode.lua",		"Node/lNode.lua",	    fLua_ByteCode(lNode)	},
} )

m_LuaRequire = ffi.new("LuaInclude_t[?]",
{
    { "lRouter.lua",	"Node/lRouter.lua",	    fLua_ByteCode(lRouter)	},
    { "lKernel.lua",	"Node/lKernel.lua",	    fLua_ByteCode(lKernel)	},
    { "lDispatch.lua",	"Node/lDispatch.lua",	fLua_ByteCode(lDispatch)},
    { "lModule.lua",	"Node/lModule.lua",	    fLua_ByteCode(lModule)	},
} )

-- //**************************************************************************************************************/

function lua_fRequire(L)

    local Name = lua_tostring(L)

    -- // check list
    for i=0, ffi.sizeof(m_LuaRequire)/ffi.sizeof("LuaInclude_t") do

        local R = m_LuaRequire[i]
        if (Name == R.Name) then

            luainc_load(L, 1, R, false)
            return 1
        end
    end
    ftrace("unable to load module [%s]\n", Name)
    return 0
end

function some_shit(void)

--    -- // make sure libx264 gets linked
--    x264_param_t	p
--    x264_t*	 E = x264_encoder_open(&p)
--
--    -- // make sure libjpeg gets linked
--    struct jpeg_compress_struct 	cinfo
--    struct jpeg_error_mgr		jerr
--
--    cinfo.err = jpeg_std_error(&jerr)
--    jpeg_create_compress(&cinfo)
--    jpeg_set_defaults(&cinfo)
--    jpeg_start_compress(&cinfo, TRUE)
--    jpeg_finish_compress(&cinfo)
--    jpeg_destroy_compress(&cinfo)
--
--
--    -- // ode dynamics link in
--
--    dInitODE()
--
--    fMat44_Decompose(nil, nil, nil, nil)
--
--    SSL_CTX_use_certificate_chain_file()
--
--    db_create()
--
--    -- // zlib
--    compress(0, 0, 0, 0)
    ftrace("X264 Not setup yet - Fix this.")
end

-- //**************************************************************************************************************/

function lWatchdogNode( L)

    -- // no child ?
    if (s_ProcessPID == 0) then

        return true
    end
    local value = semctl(g_WatchdogSemaphore, 0, GETVAL)

--    /*
--    static int b = 0
--    if (b++ > 60)
--        {
--            static int n = 0
--    printf("node %i %i\n", n++, value)
--    b = 0
--    }
--    */

    if (value == 0) then

        local t = os.clock()
        if (g_WatchdogDeadStart == 0) then g_WatchdogDeadStart = t end
        local dt = t - g_WatchdogDeadStart

        -- // gets childs state as well
        local state = waitpid(s_ProcessPID, nil, WNOHANG)

        -- // timeed out or zombine then kill it
        if ( (dt > g_WatchdogTimeout) or (state ~= 0)) then

            ftrace("module is dead! restart %i %f\n", s_ProcessPID, dt)
            kill(s_ProcessPID, SIGKILL)

            ftrace("waiting\n")
            waitpid(s_ProcessPID, nil, 0)
            s_ProcessPID = 0

            semctl(g_WatchdogSemaphore, 0, SETVAL, 0)
            g_WatchdogDeadStart = 0
            return 0
        end
    else
        -- // heartbeat was good so reset
        g_WatchdogDeadStart = 0
    end

    -- // reset to zero
    semctl(g_WatchdogSemaphore, 0, SETVAL, 0)

    return true
end

-- //**************************************************************************************************************/
-- // increment value to signifiy its still alive

function lWatchdogKernel( L)

    local value = semctl(g_WatchdogSemaphore, 0, GETVAL)
    value = value + 1
    -- //printf("kernel: %i\n", value)

    local ret = semctl(g_WatchdogSemaphore, 0, SETVAL, value)
    if (ret  < 0) then

        -- //ftrace("watchdog kernel failed to update semaphore%i\n", ret)
        return 0
    end
    return 0
end

-- //**************************************************************************************************************/
-- // create the semaphore using the common key
function fWatchdogCreate(void)

    g_WatchdogSemaphore = semget(g_WatchdogKey, 1, bit.bor(0666, IPC_CREAT))
    if (g_WatchdogSemaphore < 0) then

        ftrace("failed to create watchdog semaphore\n")
        return
    end
end

-- //**************************************************************************************************************/

function main( argc, argv)

    if (argc < 2) then

        printf("no configuration script found!\n")
        return -1
    end
    System_SigSegV()
    printf("Node %s\n", __DATE__)

    -- // run as daemon ?
    if ((argc > 2) and (argv[2] == "-d")) then

        ftrace("run as daemon\n")
        fDaemon()
    end

--    lua_State* luavm = lua_open()
--    luaL_openlibs(luavm)
--    luaopen_base(luavm)
--    luaopen_pluto(luavm)

    -- // pass command line args
    luavm = {}
    for i=0, argc-1 do

        luavm[i] = tostring(argv[i+1])
    end

    _G.argv = luavm
    luavm.fBase     = getenv("FMAD_ROOT")
    luavm.fRequire  = lua_fRequire

    -- // config file parseing
    dofile(luavm, argv[1])
    local msg = lua_tostring(luavm, -1)
    if (msg) then

        ftrace("config file: %s\n", msg)
        lua_pop(luavm, 1)
    else

        -- // get top level GID and replace process name with it
        local cfg = luavm.Config
        if (cfg == nil) then

            ftrace("no config path!\n")
        end
        local GID = luavm.gid
        fAssert(GID)

        -- // generate key (unique for the node) but NOT process(s)
        g_WatchdogKey = fCommon_CRC32( GID, string.length(GID))

        -- // create watchdog semaphore
        fWatchdogCreate()

        -- // set to 0
        ftrace("watchdog %08x\n", g_WatchdogSemaphore)

        local ret = semctl(g_WatchdogSemaphore, 0, SETVAL, 1)
        if (ret < 0) then

            ftrace("failed to reset watchdog semaphore %i\n", ret)
            return 0
        end

        -- // overwrite procecss name with GID
        s_ProcessName = argv[0]
        s_ProcessNameMax = string.length(s_ProcessName)
        ffi.copy(s_ProcessName, GID, s_ProcessNameMax)

        -- // open fmad libs
--        luaopen_common(luavm)
--        luaopen_system(luavm)
--        luaopen_network(luavm)
--        luaopen_module(luavm)

        -- // watchdog check
--        lua_register(luavm, "Watchdog", lWatchdogNode)

        -- // run the scripts
        luainc_load(luavm, sizeof(m_LuaInclude)/sizeof(LuaInclude_t), m_LuaInclude, true)
    end
    luavm = nil
    ftrace("Node Shutdown\n")

    return 0
end
