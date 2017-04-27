--
-- Created by David Lannan
-- Date: 5/03/13
-- Time: 7:25 PM
-- Developed for the byt3d engine
--

------------------------------------------------------------------------------------------------------------
-- State - Editor Base
--
-- Decription: Display GUI Elements
-- 				Interaction with Slideouts
--				Interaction with Exploder
--              Main System for rendering the Editor elements and panels.

------------------------------------------------------------------------------------------------------------

require("scripts/utils/xml-reader")
require("scripts/utils/assimp")

------------------------------------------------------------------------------------------------------------
-- Some states call other states!!
-- This is our BG state, and belongs with the MainMenu state

--local Slogin 	= require("scripts/states/login")

byt3dRender = require("framework/byt3dRender")
Gpool		= require("framework/byt3dPool")

------------------------------------------------------------------------------------------------------------
-- byt3d Framework includes

require("framework/byt3dModel")
require("framework/byt3dLevel")
require("framework/byt3dShader")
require("framework/byt3dTexture")

------------------------------------------------------------------------------------------------------------
-- Shaders

require("shaders/base_models")
require("shaders/base_terrain")
require("shaders/sky")
require("shaders/grid")

------------------------------------------------------------------------------------------------------------
---- Panels
local cmdPanel 	        = require("scripts/panels/command_console")
local Pedit_main 	    = require("scripts/panels/editor_main")
local Pedit_assetMgr    = require("scripts/panels/editor_assetlist")

local edit_camera       = require("scripts/states/editor/editor_cameras")
------------------------------------------------------------------------------------------------------------

local SEditor	= NewState()

------------------------------------------------------------------------------------------------------------

gLevels				= { }
gLevels["Default"]	= {

    level 	= nil
}

------------------------------------------------------------------------------------------------------------

SEditor.newObject	= nil
SEditor.editLevel	= "Default"

------------------------------------------------------------------------------------------------------------

function SEditor:Init(wwidth, wheight)

    self.width 		= wwidth
    self.height 	= wheight
    Gcairo.newObject	= nil
    initComplete    = true
end

------------------------------------------------------------------------------------------------------------

function SEditor:CheckFlags(mxi, myi, buttons)

    if Pedit_main.flags == nil then return end
    local tryrequest = 0

    if Pedit_main.flags["assets"] == "RequestOpen" then
        Pedit_main.flags["assets"] = nil
        tryrequest = 1
    end
    if Pedit_main.flags["assets"] == "RequestClose" then
        Pedit_main.flags["assets"] = nil
        tryrequest = 2
    end

    if Pedit_assetMgr.started == ASSET_LIST_INACTIVE then
        Pedit_main.flags["assets_last"] = "RequestClose"
    end

    if Pedit_assetMgr.started == ASSET_LIST_ACTIVE then
        Pedit_main.flags["assets_last"] = "RequestOpen"
    end

    if Pedit_assetMgr.started == ASSET_LIST_SLIDEOUT then
        tryrequest = 1
    end

    if Pedit_assetMgr.started == ASSET_LIST_SLIDEIN then
        tryrequest = 2
    end

    if tryrequest == 1 then Pedit_assetMgr:Begin() end
    if tryrequest == 2 then Pedit_assetMgr:Close() end
    if Pedit_assetMgr.started > ASSET_LIST_INACTIVE then
        Pedit_assetMgr:Update(mxi, myi, buttons)
    end

    if Pedit_main.flags["close"] == true then
        print("Quitting...")
        sm:ExitState()
    end
end

------------------------------------------------------------------------------------------------------------

function SEditor:SetupEditor()

    local level = gLevels[self.editLevel].level
    local newmodel = byt3dModel:New()
    local newshader = byt3dShader:NewProgram(grid_shader_vert, grid_shader_frag)
    local newtex = byt3dTexture:New()

    newtex:FromCairoImage(Gcairo, "grid1", "byt3d/data/images/editor/grid_001.png")
    newmodel:GeneratePlane(160, 160, 10)
    newmodel:SetAlpha(1)
    newmodel:SetPriority(999)
    newmodel:SetShader(newshader)

    newmodel:SetSamplerTex(newtex, "s_tex0")
    newmodel.node.transform:Position(0.0, 0.0, 0.0)
    newmodel.node.transform:RotationHPR(0.0, 90.0, 0.0)
    level.nodes["root"]:AddChild(newmodel, "editor_grid")
end

------------------------------------------------------------------------------------------------------------

function SEditor:Begin()
    -- Assert that we have valid width and heights (simple protection)
    assert(initComplete == true, "Init function not called.")
    self.time_start = os.time()

    local lvl = byt3dLevel:New("Default", "data/levels/default.lvl" )
    gLevels[self.editLevel].level = lvl

    local level = gLevels[self.editLevel].level
    level.cameras["Default"]:SetupView(0.0, 0.0, self.width, self.height)
    level.cameras["Default"]:LookAt( { 13, 12, 13 }, { 0.0, 0.0, 0.0 } )

    level.cameras["FreeCamera"]:SetupView(0.0, 0.0, self.width, self.height)

    -- Add handlers here
    level.cameras["FreeCamera"].handler = edit_camera.CameraFreeController

    level.icons = {}
    level.icons.select = Gcairo:LoadImage("icon1", "byt3d/data/icons/generic_64.png", 1)
    level.icons.camera = Gcairo:LoadImage("icon1", "byt3d/data/icons/generic_obj_camera_64.png")

    self:SetupEditor()
    Pedit_main:Begin()
end

------------------------------------------------------------------------------------------------------------

function SEditor:Update(mxi, myi, buttons)
    local tcolor = { r=1.0, b=1.0, g=1.0, a=1.0 }
    Gcairo:Begin()

    local saved = Gcairo.style.button_color
    Gcairo.style.button_color = { r=0.2, g=0.0, b=0.7, a=1.0 }

    Gcairo:RenderBox(5, 0, 240, 27, 0)
    Gcairo:RenderText("byt3d", 20, 20, 20, tcolor )
    Gcairo.style.button_color = saved

    local level = gLevels[self.editLevel].level
    Pedit_main:Update(mxi, myi, buttons)

    -- Cameras with handlers need eye, heading and pitch updates
    if byt3dRender.currentCamera.handler then
        edit_camera:CameraUpdate()
        byt3dRender.currentCamera.handler(edit_camera, mxi, myi, buttons)
    end

    edit_camera:CameraList(level)
    -- Check flags
    self:CheckFlags(mxi, myi, buttons)
    Gcairo:Update(mxi, myi, buttons)
end

------------------------------------------------------------------------------------------------------------

function SEditor:Render()

    local level = gLevels[self.editLevel].level
    level:Render(false)
    Gcairo:Render()

end

------------------------------------------------------------------------------------------------------------

function SEditor:Finish()

    -- Before leaving capture a thumbnail for the project if set
    if gCurrProjectInfo.byt3dProject.projectInfo.genThumbnail == 1 then
        local thumbnail = "byt3d/data/projects/thumbnails/"..projectName..".png"
        Gcairo:ScreenShot(1, 1, thumbnail )
        gCurrProjectInfo.byt3dProject.projectInfo.thumbnail = thumbnail
        SaveXml(gProjectFile..".xml", gCurrProjectInfo.byt3dProject, "byt3dProject")
    end

    Pedit_main:Finish()

    local tpool = byt3dPool:GetPool(byt3dPool.TEXTURES_NAME)
    tpool:DestroyAllFromTime(self.time_start)
end

------------------------------------------------------------------------------------------------------------

return SEditor

------------------------------------------------------------------------------------------------------------
