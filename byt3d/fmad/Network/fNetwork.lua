--
-- Created by David Lannan
-- User: grover
-- Date: 2/05/13
-- Time: 11:07 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

--#include <Network/ServerClient.h>
--#include <Network/UniCast.h>
--#include <Network/MultiCast.h>
--
--int luaopen_network(lua_State* L);

--/**************************************************************************************************************/
--//
--/* fmad llc 2008 */
--//
--// network/coms layer
--//
--/**************************************************************************************************************/
--
--#include <signal.h>
--#include <stdio.h>
--#include <stdlib.h>
--#include <string.h>
--
--#include <Common/fCommon.h>
--#include <System/fSystem.h>
--#include <Network/fNetwork.h>
--
--/**************************************************************************************************************/
--
--function luaopen_network()
----    {
--    fServer_Register()
--    fMultiCast_Register()
--    fUniCast_Register(L)
----return 0;
----}
--end