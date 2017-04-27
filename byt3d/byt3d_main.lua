------------------------------------------------------------------------------------------------------------

ffi = require( "ffi" )
gl  = require( "ffi/OpenGLES2" )

------------------------------------------------------------------------------------------------------------
-- Version format: <release number>.<hg revision>.<special id>  -- TODO: Automate this id.. soon..
BYT3D_VERSION		= "0.71.001"

------------------------------------------------------------------------------------------------------------
-- Setup the root file path to use.

package.path 		= package.path..";byt3d\\?.lua;"

---- For debugging enable this - Now using a simple builtin debugger - very nice
--require("byt3d/scripts/utils/debugger.lua")

------------------------------------------------------------------------------------------------------------
-- Window width
--local WINwidth, WINheight = 1024, 576
local WINwidth, WINheight, WINFullscreen = 1280, 720, 0
--local WINwidth, WINheight, WINFullscreen = 1920, 1200, 1
local GUIwidth, GUIheight = 1024, 576

------------------------------------------------------------------------------------------------------------
-- Global because states need to use it themselves

sm = require("scripts/platform/statemanager")

------------------------------------------------------------------------------------------------------------
-- Require all the states we will use for the game

gSdisp 			= require("scripts/states/common/display")
local Smain 	= require("scripts/states/editor/editor_base")
local Sproject 	= require("scripts/panels/project_setup")
local Sstartup 	= require("scripts/states/editor/mainStartup")

------------------------------------------------------------------------------------------------------------

local ScfgPlatform 	= require("scripts/panels/config_platform")

------------------------------------------------------------------------------------------------------------

gDir            = require("scripts/utils/directory")

---- States
SassMgr			= require("scripts/states/editor/assetManager")
--local SsetupGame = require("scripts/states/setupGame")
--local SterrainGame = require("scripts/states/terrainGame")

------------------------------------------------------------------------------------------------------------
-- Register every state with the statemanager.

sm:Init()
sm:CreateState("Display", 		gSdisp) -- This technically doesnt need to go to the statemanager
sm:CreateState("MainMenu",		Smain)
sm:CreateState("ProjectSetup", 	Sproject)
sm:CreateState("MainStartup", 	Sstartup)
--sm:CreateState("SetupMenu",	SsetupGame)
--sm:CreateState("TerrainGame",	SterrainGame)

sm:CreateState("CfgPlatform", 	ScfgPlatform)

------------------------------------------------------------------------------------------------------------
-- Execute the statemanager loop
-- Exit only when all states have exited or expired.

-- Init folder system (uses Apache Portable Runtime)
gDir:Init()

-- Init display first
gSdisp:Init(WINwidth, WINheight, WINFullscreen)
gSdisp:Begin()

Sstartup:Init(GUIwidth, GUIheight)
-- There seems to be an odd problem here.. Screen and GUI are seemingly not synchronised
Smain:Init(WINwidth, WINheight)
ScfgPlatform:Init(GUIwidth, GUIheight)

sm:CreateState("AssetManager",	SassMgr)
SassMgr.width 	= GUIwidth
SassMgr.height 	= GUIheight

Sproject.width 	= GUIwidth
Sproject.height = GUIheight
--SsetupGame:Init(WINwidth, WINheight)
--SterrainGame:Init(WINwidth, WINheight)

sm:ChangeState("MainStartup")

------------------------------------------------------------------------------------------------------------
-- Enter state manager loop
while gSdisp:GetRunApp() and sm:Run() do

	local buttons 	= gSdisp:GetMouseButtons()
	local move 		= gSdisp:GetMouseMove()
	
	sm.keysdown		= gSdisp:GetKeyDown()
	
	gSdisp:PreRender()
	sm:Update(move.x, move.y, buttons)
	sm:Render()
	
	-- This does a buffer flip.
	gSdisp:Flip()
end

------------------------------------------------------------------------------------------------------------

gSdisp:Finish()

gDir:Finalize()

------------------------------------------------------------------------------------------------------------
