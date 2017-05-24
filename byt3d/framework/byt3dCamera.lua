------------------------------------------------------------------------------------------------------------
--~ /*
--~  * Created by David Lannan
--~  * User: David Lannan
--~  * Date: 10/11/2012
--~  * Time: 7:04 PM
--~  * 
--~  */

------------------------------------------------------------------------------------------------------------

local ffi = require("ffi")
require("framework/byt3dNode")

------------------------------------------------------------------------------------------------------------
--~ 	/// <summary>
--~ 	/// Camera object derived from node (has location and orientation)
--~ 	/// The node provides view information for the camera pivot.
--~ 	/// </summary>
byt3dCamera =
{

--~		/// Node that the camera is attached to
    node 		= byt3dNode:New(),
    
    invView		= Matrix44:New(),
    mvp			= Matrix44:New(),
    
--~         /// <summary>
--~ 		/// The projection matrix this camera uses to generate a view
--~ 		/// This is set to the shader gl_ProjMatrix
--~ 		/// </summary>
    projection  = Matrix44:New(),

--~			/// Positioning of the viewport display output for this camera
	dispX		= 0,
	dispY		= 0,

--~ 		/// <summary>
--~ 		/// display Width TODO: Eventually have a display control
--~ 		/// </summary>
    dispWidth   = 640,
--~         /// <summary>
--~         /// Display Height
--~         /// </summary>
    dispHeight  = 480,

--~         /// <summary>
--~         /// vfov = Vertical field of view in degrees
--~         /// </summary>
    vfov        = 33.0,
--~         /// <summary>
--~         /// aspect ratio of the vfov anf hfov
--~         /// </summary>
    aspect      = 1.0,

--~         /// <summary>
--~         /// nearPlane of the view frustum
--~         /// </summary>
    nearPlane   = 1.0,
--~         /// <summary>
--~         /// farPLane of the view frustum
--~         /// </summary>
    farPlane    = 1000.0,


    zAway       = 0.0,
    mHeight     = 0.0,
    mWidth      = 0.0,

    -- Some sensible variables
    pitch       = 0.0,
    heading     = 0.0,
    eye         = { 0.0, 0.0, 0.0 },
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
function byt3dCamera:New()

	local newCam = deepcopy(byt3dCamera)

--~ 			// setup some sensible projection defaults.
	newCam.node 				= byt3dNode:New()
    newCam.projection      		= Matrix44:New()
    newCam.invView				= Matrix44:New()
    newCam.mvp 					= Matrix44:New()
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
function byt3dCamera:SetupView(px, py, width, height)
	
	self.dispX			= px
	self.dispY			= py
	self.dispWidth 		= width
	self.dispHeight 	= height
--~             // Set the viewport
end

------------------------------------------------------------------------------------------------------------
--~ 		/// <summary>
--~ 		/// Set the Camera settings for this camera.
--~ 		/// </summary>
--~ 		/// <param name="fov"></param>
--~ 		/// <param name="asp"></param>
--~ 		/// <param name="near"></param>
--~ 		/// <param name="far"></param>
function byt3dCamera:InitPerspective(fov, asp, near, far)

--~             // Camera setup
    self.vfov       = fov
    self.aspect     = asp
    self.nearPlane  = near
    self.farPlane   = far
    self.projection:Perspective(fov, asp, near, far)
end

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Orthographics view matrix for the camera
--~         /// </summary>
--~         /// <param name="width"></param>
--~         /// <param name="height"></param>
--~         /// <param name="near"></param>
--~         /// <param name="far"></param>
function byt3dCamera:InitOrtho(width, height, near, far)

    self.aspect = width / height
    self.nearPlane = near
    self.farPlane = far
    self.projection:Ortho(0, width, height, 0, near, far)
end

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Start rendering using this camera 
--~         /// WARNING: Sets viewport, and Clears buffers 
--~         /// TODO: Need to have flags for setting buffer clears
--~			///      This should only be used for seperate views. Need to fix some things.
--~         /// </summary>
--~         /// <param name="clear">Set this to false to disable gl clearing the buffers</param>
function byt3dCamera:BeginFrame(clear)

    if clear == nil then clear = true end
--~             // Clear the color buffer
    if (clear == true) then
        gl.glClear( bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT) )
--        gl.glClear(gl.GL_DEPTH_BUFFER_BIT)
    end

    gl.glViewport(self.dispX, self.dispY, self.dispWidth, self.dispHeight)
end

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Set the ProjMatrix for this current rendering setup
--~         /// </summary>
function byt3dCamera:ShaderViewProjectionMatrix()

	assert(self.projection)
	--self.invView:Copy(self.node.transform)
	--self.invView:Transpose()

	self.mvp = self.mvp:Mult44( self.node.transform, self.projection  )
	local tproj = ffi.new("float[16]", self.mvp.m )
	--print("Projection right:", tproj[0], tproj[1], tproj[2], tproj[3])
	--print("Projection up:", tproj[4], tproj[5], tproj[6], tproj[7])
	--print("Projection view:", tproj[8], tproj[9], tproj[10], tproj[11])
	--print("Projection pos:", tproj[12], tproj[13], tproj[14], tproj[15])

    -- Load the matrix in - only if we have a Shader running!!!
    byt3dRender.currentShader:SetProjectionMatrix(tproj)
end

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Center the camera on the model
--~         /// </summary>
--~         /// <param name="model">The target model to center the camera on.</param>
function byt3dCamera:CenterOnModel( model)

--~             /// Setup camera based on where model center is
    self.mHeight = model.boundMax[2] - model.boundCtr[2]
    self.mWidth = model.boundMax[1] - model.boundCtr[1]    
    local tWidth = model.boundMax[3] - model.boundCtr[3]    
    if (tWidth > self.mWidth) then self.mWidth = tWidth end

--        // To fit within 45 degrees work out z placement
    local tAngleHeight = math.tan( math.rad(self.vfov * 0.5) )
--        //if (Math.Abs(tAngleHeight) < 0.001) tAngleHeight = 0.001
    local tAngleWidth = math.tan( math.rad(self.vfov * 0.5 * self.aspect) )
--        //if (Math.Abs(tAngleWidth) < 0.001) tAngleWidth = 0.001

    local zForHeight = self.mHeight / tAngleHeight
    local zForWidth = self.mWidth / tAngleWidth
    self.zAway = -zForWidth
    if (zForHeight > zForWidth) then self.zAway = -zForHeight end

    local pos = { 0.0, self.mHeight, self.zAway * 1.5 }
    self:LookAt( pos, model.node.transform:pos() )
end

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Look at a specific point in the world
--~         /// </summary>
--~         /// <param name="model">The target position to center the camera on.</param>
function byt3dCamera:LookAt( eye, target )

    self.eye = { eye[1], eye[2], eye[3] }
    self.target = { target[1], target[2], target[3] }
    self.heading, self.pitch = self.node.transform:LookAt( eye, target )
end

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Update the Camera using eye and hp settings
--~         /// </summary>
------------------------------------------------------------------------------------------------------------

function byt3dCamera:UpdateFromEye()

    self.node.transform:Identity()
    self.node.transform:Translate( -self.eye[1], -self.eye[2], -self.eye[3] )
    self.node.transform:RotateHPR( self.heading, self.pitch, 0.0 )
end

------------------------------------------------------------------------------------------------------------
--~         /// <summary>
--~         /// Update the camera matrix
--~         /// </summary>
function byt3dCamera:SetForShader( shader )

	if(shader == nil) then return end
	byt3dRender:ChangeShader(shader)
	self:ShaderViewProjectionMatrix()
--	print("Setting Projection Matrix", byt3dRender.currentShader.info.prog, gl.glGetError())
end

------------------------------------------------------------------------------------------------------------
