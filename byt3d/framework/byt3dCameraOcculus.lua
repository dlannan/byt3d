--
-- Created by David Lannan
-- User: grover
-- Date: 24/03/13
-- Time: 7:36 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

------------------------------------------------------------------------------------------------------------

local ffi = require("ffi")
require("framework/byt3dNode")

------------------------------------------------------------------------------------------------------------
--~ 	/// <summary>
--~ 	/// Camera object derived from node (has location and orientation)
--~ 	/// The node provides view information for the camera pivot.
--~ 	/// </summary>
byt3dCameraOcculus =
{
    --~		/// Node that the camera is attached to
    node 		= byt3dNode:New(),

    --~     /// Left Camera for left eye in occulus rift
    eye_left    = byt3dCamera:New(),

    --~     /// Right Camera for right eye in occulus rift
    eye_right   = byt3dCamera:New(),

    -- Some sensible variables
    pitch       = 0.0,
    heading     = 0.0,
    eye         = { 0.0, 0.0, 0.0, },
    speed       = 0.0
}

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Initialise a Camera with a position (Node) in the world.
--~         /// Cameras should be assigned to RenderLayers.
--~         /// </summary>
--~         /// <param name="prog"></param>
--~         /// <param name="projM"></param>
--~         /// <param name="viewM"></param>
function byt3dCameraOcculus:New()

    local newCam = deepcopy(byt3dCameraOcculus)

    --~ 			// setup some sensible projection defaults.
    newCam.node 				= byt3dNode:New()
    return newCam
end

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Setup the view information (resolution) for the camera
--~         /// View resolutions should not change often, so this should not be called every frame.
--~         /// </summary>
--~         /// <param name="px"></param>
--~         /// <param name="py"></param>
--~         /// <param name="width"></param>
--~         /// <param name="height"></param>
function byt3dCameraOcculus:SetupView(px, py, width, height)

    -- TODO: Parse some values here and make sensible occulus camera ones

    self.dispX			= px
    self.dispY			= py
    self.dispWidth 		= width
    self.dispHeight 	= height
    --~             // Set the viewport
    gl.glViewport(self.dispX, self.dispY, self.dispWidth, self.dispHeight)
end

------------------------------------------------------------------------------------------------------------
--~ 		/// <summary>
--~ 		/// Set the Camera settings for this camera.
--~ 		/// </summary>
--~ 		/// <param name="fov"></param>
--~ 		/// <param name="asp"></param>
--~ 		/// <param name="near"></param>
--~ 		/// <param name="far"></param>
function byt3dCameraOcculus:InitPerspective(fov, asp, near, far)

    -- TODO: Parse some values here and make sensible occulus camera ones

    --~             // Camera setup
    self.vfov       = fov
    self.aspect     = asp
    self.nearPlane  = near
    self.farPlane   = far
    self.projection:Perspective(fov, asp, near, far)
end

------------------------------------------------------------------------------------------------------------
