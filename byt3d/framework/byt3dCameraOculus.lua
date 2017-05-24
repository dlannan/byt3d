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

require("shaders/oculus_rift")

------------------------------------------------------------------------------------------------------------

local FB_WIDTH      = 640
local FB_HEIGHT     = 720

------------------------------------------------------------------------------------------------------------
--~ 	/// <summary>
--~ 	/// Camera object derived from node (has location and orientation)
--~ 	/// The node provides view information for the camera pivot.
--~ 	/// </summary>
byt3dCameraOculus =
{
    frame       = { nil, nil },
    rtexture    = { 0, 0 },

    orig_camera = nil,
    --~     /// Left and Right camera position info
    eye_cam     =  {  },
    mesh        = nil,

    --~     /// Oculus shader
    shader      = nil,

    -- Some sensible variables
    pitch       = 0.0,
    heading     = 0.0,
    eye         = { 0.0, 0.0, 0.0, },
    speed       = 0.0,

    focus_distance  = 10.0,     -- 10 m focal distance is a fairly normal distance, it is usually much shorter
    eye_spacing     = 0.64      -- 64 cm is the Oculus default separation of the eyes
}

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Initialise a Camera with a position (Node) in the world.
--~         /// Cameras should be assigned to RenderLayers.
--~         /// </summary>
--~         /// <param name="prog"></param>
--~         /// <param name="projM"></param>
--~         /// <param name="viewM"></param>
function byt3dCameraOculus:New( )

    local newCam = deepcopy(byt3dCameraOculus)

    newCam.eye_cam[1] = byt3dCamera:New()
    newCam.eye_cam[2] = byt3dCamera:New()

    newCam.mesh   = byt3dMesh:New()

    newCam.shader = byt3dShader:NewProgram(occulus_rift_shader_vert, occulus_rift_shader_frag)
    --newCam.shader = byt3dShader:NewProgram(colour_shader_vert, colour_shader_frag)
    newCam.shader:UseDefaultDefinitions()

    ---~ // The texture we're going to render to
    newCam.rtexture[1] = byt3dTexture:NewTextureBuffer(FB_WIDTH, FB_HEIGHT, 1)
    newCam.frame[1] = newCam.rtexture[1].frameId
    newCam.rtexture[2] = byt3dTexture:NewTextureBuffer(FB_WIDTH, FB_HEIGHT, 1)
    newCam.frame[2] = newCam.rtexture[2].frameId

    newCam.mesh:SetTexture( newCam.rtexture[1] )
    newCam.mesh:SetShader(newCam.shader)

    gl.glClearColor(0.0, 0.0, 0.0, 0.0)
    --~ 			// setup some sensible projection defaults.
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
function byt3dCameraOculus:SetupView(px, py, width, height)

    -- TODO: Parse some values here and make sensible occulus camera ones

    self.dispX			= px
    self.dispY			= py
    self.dispWidth 		= width
    self.dispHeight 	= height
    --~             // Set the viewport
    gl.glViewport(self.dispX, self.dispY, self.dispWidth, self.dispHeight)
end

------------------------------------------------------------------------------------------------------------

function byt3dCameraOculus:Update(sourceCamera)

    self.orig_camera = sourceCamera
    self.eye_cam[1] = deepcopy(sourceCamera)
    self.eye_cam[2] = deepcopy(sourceCamera)
end

------------------------------------------------------------------------------------------------------------

function byt3dCameraOculus:GetCamera(eye_pos)

    return self.eye_cam[eye_pos]
end

------------------------------------------------------------------------------------------------------------

function byt3dCameraOculus:RenderOculus()

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0);
    gl.glDepthMask(0)
    gl.glDisable(gl.GL_DEPTH_TEST)
    gl.glDisable(gl.GL_BLEND)

    self.mesh.shader:Use()
    self.mesh:SetTexture( self.rtexture[1] )
    self.mesh:RenderTextureRect(0, 0, 0.5, 1)
    self.mesh:SetTexture( self.rtexture[2] )
    self.mesh:RenderTextureRect(0.5, 0, 0.5, 1)

    gl.glEnable(gl.GL_DEPTH_TEST)
    gl.glDepthMask(1)
end

------------------------------------------------------------------------------------------------------------

function byt3dCameraOculus:SetFrameBuffer(eye_pos)

    --~  // Render to our framebuffer
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, self.frame[eye_pos])
end

------------------------------------------------------------------------------------------------------------
