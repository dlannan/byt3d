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

	newLevel.cameras["Default"]		= byt3dCamera:New()
	newLevel.cameras["Default"]:InitPerspective(45, 1.7777, 0.5, 1000.0)
	newLevel.cameras["Default"]:SetupView(0, 0, 640, 480)
	newLevel.currentCamera 			= "Default"

	newLevel.cameras["FreeCamera"]	= byt3dCamera:New()
	newLevel.cameras["FreeCamera"]:InitPerspective(45, 1.7777, 0.5, 1000.0)
	newLevel.cameras["FreeCamera"]:SetupView(0, 0, 640, 480)
	
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

function byt3dLevel:Load( filepath )

end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:Unload()

end

------------------------------------------------------------------------------------------------------------

function byt3dLevel:ChangeCamera(name)
					
	local newcam = self.cameras[name] 
	if newcam ~= nil then 
		self.currentCamera = name
		local cam = self.cameras[name]
		byt3dRender:ChangeCamera(cam)		
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

function byt3dLevel:Render()

	byt3dRender:Clear()

	-- Setup camera.. 
	local cam = self.cameras[self.currentCamera]
	-- // Set the camera projection matrix and view matrix
	byt3dRender:ChangeCamera(cam)

	-- Before rendering.. do the sky!.. if there is one
	if self.sky then 
		local campos = cam.invView:pos()
		--print("Cam:",campos[1], campos[2], campos[3])
		self.sky.node.transform:Position(campos[1], campos[2], campos[3])
		self.sky:Render(cam) 
	end
	
	-- Render nodes for time being...
	for k,v in pairs(self.nodes) do
		-- passing the current camera in allow camera mod on the fly
		v:Render(cam)
	end
	
	byt3dRender:Render()	
end

------------------------------------------------------------------------------------------------------------