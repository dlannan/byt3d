------------------------------------------------------------------------------------------------------------

ffi     = require( "ffi" )
gl      = require( "ffi/OpenGLES2" )

------------------------------------------------------------------------------------------------------------
-- Version format: <release number>.<hg revision>.<special id>  -- TODO: Automate this id.. soon..

-- Build version from current check in tag.
--os.execute("hg id --debug -i -n > hg_version_id.txt")
local tagfile = io.open("hg_version_id.txt", "r")
assert(tagfile, "No Revision Tag!!")
local tagdata = tagfile:read("*a")
local id, tagrevision = string.match(tagdata, "(%w)%+? (%d+)%+?")
io.close(tagfile)

local release       = "0"
local subversion    = "001"

------------------------------------------------------------------------------------------------------------

BYT3D_VERSION		= release.."."..tagrevision.."."..subversion

------------------------------------------------------------------------------------------------------------
-- Setup the root file path to use.

if ffi.os == "OSX" then
    package.path 		= package.path..";byt3d/?.lua"
    package.cpath       = package.cpath..";./bin/OSX/?.dylib"
    print(package.path)

    lfs   = require("lfs")
end

------------------------------------------------------------------------------------------------------------
-- Windows direct access - mainly for keys ( TODO: will reduce this later on )
if ffi.os == "Windows" then
    package.path 		= package.path..";byt3d\\?.lua"
--
--    kernel32 	= ffi.load( "kernel32.dll" )
--    user32 	    = ffi.load( "user32.dll" )
--    comdlg32    = ffi.load( "Comdlg32.dll" )
--    gdi32       = ffi.load( "gdi32.dll" )
--
--    require("ffi/win32")

    lfs   = require("lfs")
end

------------------------------------------------------------------------------------------------------------
---- For debugging enable this - builtin LuaDebugger based on the excellent clidebugger
-- http://files.luaforge.net/releases/clidebugger/clidebugger/Updated/debugger.lua
-- TODO: Integrate debugger into Cairo so that a nice debugging panel can be used.

require("byt3d/scripts/utils/debugger")

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
local Sabout 	= require("scripts/states/editor/editor_about")

------------------------------------------------------------------------------------------------------------

local ScfgPlatform 	    = require("scripts/panels/config_platform")
gDebugPanel 	        = require("scripts/panels/editor_debug")

------------------------------------------------------------------------------------------------------------

gCache          = require("scripts/states/editor/editor_cache")
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
sm:CreateState("AboutPage", 	Sabout)
--sm:CreateState("SetupMenu",	SsetupGame)
--sm:CreateState("TerrainGame",	SterrainGame)

sm:CreateState("CfgPlatform", 	ScfgPlatform)

------------------------------------------------------------------------------------------------------------
-- Execute the statemanager loop
-- Exit only when all states have exited or expired.

-- Init folder system
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

-- Cache first!
--gCache:Begin()
gCache:Begin()
byt3dRender:Init()

sm:ChangeState("MainStartup")

------------------------------------------------------------------------------------------------------------
-- Enter state manager loop
while gSdisp:GetRunApp() and sm:Run() do

	local buttons 	= gSdisp:GetMouseButtons()
	local move 		= gSdisp:GetMouseMove()

	sm.keysdown		= gSdisp:GetKeyDown()

    for k, v in pairs(sm.keysdown) do
        if v.scancode == sdl.SDL_SCANCODE_F12 then
            -- Init display first - make a nice debug window (this is platform dependant)
            pause("Enable Debugger")
        end
    end

	gSdisp:PreRender()
    --gCache:Update(move.x, move.y, buttons)
    gCache:Update(move.x, move.y, buttons)

    sm:Update(move.x, move.y, buttons)

    --gCache:Render()
    gCache:Render()
	sm:Render()

	-- This does a buffer flip.
	gSdisp:Flip()
end

------------------------------------------------------------------------------------------------------------

--gCache:Finish()
gCache:Finish()

gSdisp:Finish()
gDir:Finalize()

------------------------------------------------------------------------------------------------------------
