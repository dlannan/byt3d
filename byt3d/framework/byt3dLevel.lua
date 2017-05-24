------------------------------------------------------------------------------------------------------------
--~ /*
--~  * Created by David Lannan
--~  * User: David Lannan
--~  * Date: 5/22/2012
--~  * Time: 7:04 PM
--~  * 
--~  */
------------------------------------------------------------------------------------------------------------

require("framework/byt3dNode")
require("framework/byt3dCamera")
require("framework/byt3dCameraOculus")

require("framework/byt3dLayer")
local poolm = require("framework/byt3dPool")

require("math/Matrix44")

------------------------------------------------------------------------------------------------------------
--~ 	/// <summary>
--~ 	/// Camera object derived from node (has location and orientation)
--~ 	/// The node provides view information for the camera pivot.
--~ 	/// </summary>
byt3dLevel =
{
	name		= "",
	filepath	= "",

    rframe      = nil,
    rtexture    = nil,

	currentCamera = "Default",
	cameras		= {},	-- cameras used in the level, Default one always created.
	nodes		= {},	-- Can be an array of root node hierarchies
	
	layers		= {},	-- list of layers to be used - these are like grouped node references
	pools		= {} 	-- pools are resources that are cache to improve performance (textures, meshes etc)	
}

------------------------------------------------------------------------------------------------------------
function byt3dLevel:New( name, filepath )

	local newLevel 		= deepcopy(byt3dLevel)
	newLevel.name		= name
	newLevel.filepath	= filepath

    newLevel.oculus_cam = byt3dCameraOculus:New()

	newLevel.cameras["Default"]		= byt3dCamera:New()
	newLevel.cameras["Default"]:InitPerspective(45, 1.7777, 0.5, 1000.0)
	newLevel.cameras["Default"]:SetupView(0, 0, 1280, 720)
	newLevel.currentCamera 			= "Default"

	newLevel.cameras["FreeCamera"]	= byt3dCamera:New()
	newLevel.cameras["FreeCamera"]:InitPerspective(45, 1.7777, 0.5, 1000.0)
	newLevel.cameras["FreeCamera"]:SetupView(0, 0, 1280, 720)
	
	newLevel.nodes["root"]			= byt3dNode:New()
	
	newLevel.layers["main"]			= byt3dLayer:New()
    newLevel.pools["materials"]		= byt3dPool:New(byt3dPool.MATERIALS_NAME)
    newLevel.pools["textures"]		= byt3dPool:New(byt3dPool.TEXTURES_NAME)
	newLevel.pools["shaders"]		= byt3dPool:New(byt3dPool.SHADERS_NAME)

    byt3dRender:ChangeCamera(newLevel.cameras["Default"])

--SaveXml("Level-Default.xml", newLevel, "byt3dLevel")
--local lvl = LoadXml("Level-Default.xml")
--DumpXml(lvl)

	return newLevel 
end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:BuildFBO( width, height )

    ---~ // The texture we're going to render to
    self.rtexture    = byt3dTexture:NewTextureBuffer(width, height, 1)
    self.rframe      = self.rtexture.frameId
end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:Load( filepath )

end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:Unload()

end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:ChangeCamera(name, copy_cam)
					
	local newcam = self.cameras[name] 
	if newcam ~= nil then
        local oldcam = self.cameras[self.currentCamera]
        if(copy_cam == 1) then
            newcam.node.transform.m = deepcopy(oldcam.node.transform.m)
            newcam.pitch = oldcam.pitch; newcam.heading = oldcam.heading
            newcam.eye = deepcopy(oldcam.eye)
            -- print("Eye: ", newcam.eye[1], newcam.eye[2], newcam.eye[3], newcam.pitch, newcam.heading)
        end

		self.currentCamera = name
        newcam:BeginFrame()
		byt3dRender:ChangeCamera(newcam)
	end
end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:Update(mx, my, buttons)

	-- Render nodes for time being...
	for k,v in pairs(self.nodes) do
		-- passing the current camera in allow camera mod on the fly
		v:Update(mx, my, buttons)
	end
end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:RenderLevel(ocam)

	byt3dRender:Clear(1)

    -- Setup camera..
	local cam = self.cameras[self.currentCamera]
    -- Override the camera if the function has been passed one
    if ocam then cam = ocam end
	-- // Set the camera projection matrix and view matrix
	byt3dRender:ChangeCamera(cam)

	-- Render nodes for time being...
	for k,v in pairs(self.nodes) do
		-- passing the current camera in allow camera mod on the fly
		v:Render(cam)
	end
	
	byt3dRender:Render()	
end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:Render(clr)

    -- Setup camera..
    local cam = self.cameras[self.currentCamera]
    -- TODO: Probably should deal with this better
    if cam == nil then return end

    -- save original camera use
    local saved = self.currentCamera

    self:RenderLevel(cam)

    -- Restore original camera
    self.currentCamera = saved
end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:RenderOculus()

    -- Setup camera..
    local cam = self.cameras[self.currentCamera]
    -- TODO: Probably should deal with this better
    if cam == nil then return end

    -- save original camera use
    local saved = self.currentCamera
    self.oculus_cam:Update(cam)

    self.oculus_cam:SetFrameBuffer(1)
    local cam1 = self.oculus_cam:GetCamera(1)
    self:RenderLevel(cam1)

    -- Change framebuffer target... and render other eye
    self.oculus_cam:SetFrameBuffer(2)
    local cam2 = self.oculus_cam:GetCamera(2)
    self:RenderLevel(cam2)

    -- Render to the full screen using the Oculus shader .. this should be setup when FB is setup
    self.oculus_cam:RenderOculus()

    -- Restore original camera
    self.currentCamera = saved
end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:RenderTexture()

    assert(self.rframe, "No Framebuffer Object Created!")
    -- Setup camera..
    local cam = self.cameras[self.currentCamera]
    -- TODO: Probably should deal with this better
    if cam == nil then return end

    -- save original camera use
    local saved = self.currentCamera

    --~  // Render to our framebuffer
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, self.rframe)

    self:RenderLevel()
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    -- Restore original camera
    self.currentCamera = saved
end

------------------------------------------------------------------------------------------------------------