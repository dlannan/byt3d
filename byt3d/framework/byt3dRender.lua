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
require("math/Matrix44")

require("shaders/shadow_vsm")
require("shaders/shadow_vsm_blur")
require("shaders/shadow_vsm_storedepth")
require("shaders/base_models")
require("shaders/post_bloom")

------------------------------------------------------------------------------------------------------------

local gl   = require( "ffi/OpenGLES2" )

------------------------------------------------------------------------------------------------------------
--~ 	/// <summary>
--~ 	/// Render Object looks after the running render states (these are related to current shader, current texture etc)
--~ 	/// The Render Object is more of a manager that can be assigned to a running level. 
--~		/// It is possible that post and pre render image effects may be done via this object
--~ 	///
--~ 	/// Render is a static class that can be used at anytime by any system. The main reason for this is to
--~     /// the interleaving of 'special render case' when needed. This usually occurs quite a bit.
--~ 	/// </summary>
------------------------------------------------------------------------------------------------------------

local byt3dRender =
{
    POOL_BUFFERS    = 6,

    PRERENDER       = 1,        -- For prerender passes add to this bucket
    OPAQUE          = 2,        -- Opaque rendering here (normal front to back render order)
    ALPHA           = 3,        -- Alpha rendering (back to front)
    ENV             = 4,        -- Post render passes
    EDITOR          = 5,
    EDITOR_ALPHA    = 6,

	currentShader	= nil,
	shaderChanged	= {},		-- When a shader changes all callbacks are notified.
	
	currentTexture	= nil,
	currentModel	= nil,
	currentMesh		= nil,
	
	currentCamera	= nil,
	cameraChanged	= {},		-- When a camera changes all callbacks are notified.
	
	-- The render pool is used to map shaders to list of mesh render requests
	-- Each pool entry is a list of MeshRender calls that shader a shader, and may/may not share textures
	renderPool		= {},

    currentNode		= nil,
    initialised     = false,

    --- Default internal shaders
    colourShader    = nil,
    phongShader     = nil,
    bloomShader     = nil
}

------------------------------------------------------------------------------------------------------------

byt3dRender.shadows =
{
    -- Shadow specific data - this is adjustable - will expose to render config
    RENDER_WIDTH    = 512.0,
    RENDER_HEIGHT   = 512.0,
    SHADOW_MAP_COEF = 0.5,
    BLUR_COEF       = 0.25,

    -- // Hold id of the framebuffer for light POV rendering
    fboId           = 0,
    -- // Z values will be rendered to this texture when using fboId framebuffer
    depthTextureId  = 0,
    colorTextureId  = 0,

    -- // Use to activate/disable shadowShader
    shadowShader    = 0,
    shadowMapTexMat         = 0,
    shadowMapUniform        = 0,
    shadowMapStepXUniform   = 0,
    shadowMapStepYUniform   = 0,

    -- // Used to store values during the first pass
    storeMomentsShader      = 0,

    -- // Bluring FBO
    blurFboId               = 0,
    -- // Z values will be rendered to this texture when using fboId framebuffer
    blurFboIdColorTextureId = 0,

    -- // Used to blur the depth values
    blurShader              = 0,
    -- // Used to pass blur horiz or vert
    scaleUniform            = 0,
    textureSourceUniform    = 0

}

------------------------------------------------------------------------------------------------------------

byt3dRender.lights = {

}

------------------------------------------------------------------------------------------------------------

function byt3dRender:Init()

    if self.initialised  == true then return end

    self.renderPool = {}
    for k=1,self.POOL_BUFFERS do self.renderPool[k] = {} end

    gl.glDisable(gl.GL_BLEND)
    gl.glEnable(gl.GL_DEPTH_TEST)
    gl.glDepthMask(gl.GL_TRUE)

    -- Setup internal shaders - useful for various render methods
    self.colourShader = byt3dShader:NewProgram(colour_shader_vert, colour_shader_frag)
    self:ChangeShader(self.colourShader)

    self.bloomShader = byt3dShader:NewProgram(colour_shader, post_bloom_shader_frag)
    self.bloomtex = byt3dTexture:NewColourTextures(Gcairo.WIDTH, Gcairo.HEIGHT)

    -- Internally used render function by default is without shadows
    byt3dRender.RenderInternal  = byt3dRender.RenderShadows
    local SH = self.shadows

    -- Add a light to the rendering - this should probably go in the Level?
    --  TODO: Move to level code (I think)
    self.lights["sun"] = byt3dCamera:New()
    self.lights["sun"]:InitPerspective(50, 1, 1, 40.0)
    self.lights["sun"]:SetupView(0, 0, self.shadows.RENDER_WIDTH * self.shadows.SHADOW_MAP_COEF, self.shadows.RENDER_HEIGHT * self.shadows.SHADOW_MAP_COEF)
    self.lights["sun"]:LookAt( { 13, 10, 13 }, { 0.0, 0.0, 0.0 } )

    -- Prepare some shadow shaders and textures
    SH.storeMomentsShader = byt3dShader:NewProgram(shadow_vsm_storedepth_vert, shadow_vsm_storedepth_frag)
    SH.shadowShader = byt3dShader:NewProgram(shadow_vsm_vert, shadow_vsm_frag)
    SH.blurShader = byt3dShader:NewProgram(shadow_vsm_blur_vert, shadow_vsm_blur_frag)

    local shadowMapWidth = byt3dRender.shadows.RENDER_WIDTH * byt3dRender.shadows.SHADOW_MAP_COEF
    local shadowMapHeight = byt3dRender.shadows.RENDER_HEIGHT * byt3dRender.shadows.SHADOW_MAP_COEF
    SH.tex = byt3dTexture:NewDepthTextures(shadowMapWidth, shadowMapHeight)
    self.initialised     = true

    SH.blurtex = byt3dTexture:NewColourTextures(shadowMapWidth, shadowMapHeight)

    -- Get the uniform handles for the parameters that will be modifiable
    SH.shadowMapUniform = gl.glGetUniformLocation(SH.shadowShader.info.prog,"ShadowMap")
    SH.shadowMapTexMat = gl.glGetUniformLocation(SH.shadowShader.info.prog,"u_TextureMatrix")
--    SH.shadowMapStepXUniform = gl.glGetUniformLocation(SH.shadowShader.info.prog,"xPixelOffset")
--    SH.shadowMapStepYUniform = gl.glGetUniformLocation(SH.shadowShader.info.prog,"yPixelOffset")

    -- Get the uniform handles for the parameters that will be modifiable
    SH.scaleUniform = gl.glGetUniformLocation(SH.blurShader.info.prog,"u_Scale")

    -- Allocate a texture id for the surface to render to.
    SH.mesh = byt3dMesh:New()
    SH.mesh:SetShader(Gcairo.uiShader)
end

------------------------------------------------------------------------------------------------------------

function byt3dRender:RenderMesh( mesh )

    local p = mesh.priority
	assert(self.renderPool[p], "Invalid pool id: "..tostring(p) )

	local tbl = self.renderPool[p]
	table.insert(tbl, mesh)
	self.renderPool[p] = tbl
end

------------------------------------------------------------------------------------------------------------
-- Clear the render pool at the begining of a render frame

function byt3dRender:Clear(ok)

    self.renderPool = { }
    for k=1,self.POOL_BUFFERS do self.renderPool[k] = {} end

    if ok then
        gl.glClear( bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT) )
    end
end

------------------------------------------------------------------------------------------------------------
-- Render all render pool elements (can consist of anything)

function byt3dRender:Render()

    self:RenderInternal()
end


------------------------------------------------------------------------------------------------------------
-- Internal normal no shadows render

function byt3dRender:RenderNoShadows()

    gl.glEnable(gl.GL_CULL_FACE)
    gl.glCullFace(gl.GL_BACK)

    local ptbl = self.renderPool
	for s,p in ipairs(ptbl) do

        if s == self.OPAQUE then
            gl.glDisable( gl.GL_BLEND )
            gl.glEnable(gl.GL_DEPTH_TEST)
        elseif s == self.ALPHA then
            gl.glEnable( gl.GL_BLEND )
            gl.glBlendFunc( gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA )
            gl.glEnable(gl.GL_DEPTH_TEST)
        end

        for i, m in pairs(p) do
			-- When using a new shader, set the camera view info for it!
			self.currentCamera:SetForShader(m.shader)

            -- Iterate the list of ibuffers and render them
            local ibuffers = m.ibuffers
            if ibuffers then
                for k,v in pairs(ibuffers) do
                    self:RenderBuffer(m, v)
                end
            end
   		end
	end
end

------------------------------------------------------------------------------------------------------------
-- Internal render that uses currently set shader to render a pool of objects
--   TODO: This needs frustum culling for cameras and so on.

function byt3dRender:RenderCurrentShader(ignore_type, check_mesh_property, value)

    local ptbl = self.renderPool
    for s,p in ipairs(ptbl) do

        if ignore_type == nil then
            if s == self.OPAQUE then
                gl.glDisable( gl.GL_BLEND )
                gl.glEnable(gl.GL_DEPTH_TEST)
            elseif s == self.ALPHA then
                gl.glEnable( gl.GL_BLEND )
                gl.glBlendFunc( gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA )
                gl.glEnable(gl.GL_DEPTH_TEST)
            end
        end

        for i, m in pairs(p) do

            if m[check_mesh_property] == value or check_mesh_property == nil then
                -- Iterate the list of ibuffers and render them
                local ibuffers = m.ibuffers
                if ibuffers then
                    for k,v in pairs(ibuffers) do
                        self:RenderBuffer(m, v)
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------

function byt3dRender:blurShadowMap()

    gl.glDisable( gl.GL_CULL_FACE )
    gl.glDisable( gl.GL_DEPTH_TEST )
    gl.glDisable( gl.GL_BLEND )
    local SH = self.shadows

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, SH.blurtex.fboId)
    self:ChangeShader(SH.blurShader)
    -- // Bluring the shadow map  horinzontaly
    local blurWidth = SH.RENDER_WIDTH * SH.SHADOW_MAP_COEF
    local blurHeight = SH.RENDER_HEIGHT * SH.SHADOW_MAP_COEF
    --gl.glViewport(0,0,  blurWidth, blurHeight)

    --	// Bluring horinzontal
    gl.glUniform2f(SH.scaleUniform, 1.0 / (SH.RENDER_WIDTH * SH.SHADOW_MAP_COEF), 0.0)
    SH.mesh.tex0 = {}
    SH.mesh.tex0.textureId = SH.tex.textureId
    -- //Drawing quad
    self:RenderTexRect( SH.mesh, -1, -1, 2, 2, -0.5 )

    -- // Bluring vertically
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, SH.tex.fboId)
    --gl.glViewport(0,0, SH.RENDER_WIDTH * SH.SHADOW_MAP_COEF ,SH.RENDER_HEIGHT * SH.SHADOW_MAP_COEF)
    gl.glUniform2f(SH.scaleUniform,0.0, 1.0/ ( SH.RENDER_HEIGHT * SH.SHADOW_MAP_COEF ) )
    SH.mesh.tex0 = {}
    SH.mesh.tex0.textureId = SH.blurtex.textureId
    self:RenderTexRect( SH.mesh, -1, -1, 2, 2, -0.5 )

    gl.glEnable(gl.GL_DEPTH_TEST)
    gl.glEnable(gl.GL_CULL_FACE)
end

------------------------------------------------------------------------------------------------------------
-- Internal  shadows render - does two passes with specific shadows rendering setup

function byt3dRender:RenderShadows()

    local ptbl = self.renderPool
    local shadow = self.shadows

    -- // Enable depth test
    gl.glDisable( gl.GL_BLEND )
    gl.glDepthMask(gl.GL_TRUE)
    gl.glEnable(gl.GL_DEPTH_TEST)
    -- // Accept fragment if it closer to the camera than the former one
    gl.glDepthFunc(gl.GL_LEQUAL)

    -- // Cull triangles which normal is not towards the camera
    gl.glEnable(gl.GL_CULL_FACE)
    gl.glCullFace(gl.GL_BACK)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, shadow.tex.fboId)

    gl.glClearColor(0.0, 0.0, 0.4, 1.0)
    local mainlight = self.lights["sun"]
    mainlight:BeginFrame(true)

    -- // Use our shader
    self:ChangeShader(shadow.storeMomentsShader)

    local cproj = mainlight.mvp:Mult44( mainlight.node.transform, mainlight.projection  )
    local tproj = ffi.new("float[16]", cproj.m )
    shadow.storeMomentsShader:SetProjectionMatrix(tproj)

--    print("Projection right:", tproj[0], tproj[1], tproj[2], tproj[3])
--    print("Projection up:", tproj[4], tproj[5], tproj[6], tproj[7])
--    print("Projection view:", tproj[8], tproj[9], tproj[10], tproj[11])
--    print("Projection pos:", tproj[12], tproj[13], tproj[14], tproj[15])
--    print("************* Light pos/target: ", mainlight.eye[1], mainlight.eye[2], mainlight.eye[3])

    self:RenderCurrentShader(1, "shadows_cast", 1)

    self:blurShadowMap()
    --gl.glGenerateMipmap(gl.GL_TEXTURE_2D)

    -- // Now rendering from the camera POV, using the FBO to generate shadows
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    gl.glEnable(gl.GL_CULL_FACE)
    gl.glCullFace(gl.GL_BACK)
    self.currentCamera:BeginFrame(true)

    self:ChangeShader(shadow.shadowShader)
    self.currentCamera:SetForShader(self.currentShader)

    -- Set Texture Matrix for light
    local light_bias = Matrix44:New()
    light_bias.m = { 0.5, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.5, 0.5, 0.5, 1.0 }
    light_bias = light_bias:Mult44( cproj, light_bias  )
    local bproj = ffi.new("float[16]", light_bias.m )
    gl.glUniformMatrix4fv(shadow.shadowMapTexMat, 1, gl.GL_FALSE, bproj)

    gl.glActiveTexture(gl.GL_TEXTURE7)
    gl.glBindTexture(gl.GL_TEXTURE_2D, shadow.blurtex.textureId)
    gl.glUniform1i(shadow.shadowMapUniform, 7)

    --gl.glUniform1f(shadow.shadowMapStepXUniform,1.0/ (shadow.RENDER_WIDTH * shadow.SHADOW_MAP_COEF))
    --gl.glUniform1f(shadow.shadowMapStepYUniform,1.0/ (shadow.RENDER_HEIGHT * shadow.SHADOW_MAP_COEF))

    -- Render everything in shadow shader
    self:RenderCurrentShader(nil, "shadows_recv", 1)

    self:ChangeShader(self.colourShader)
    self.currentCamera:SetForShader(self.currentShader)
    self:RenderCurrentShader(nil, "shadows_recv", nil)

--    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)
--
--    gl.glDisable(gl.GL_CULL_FACE)
--    gl.glDisable ( gl.GL_DEPTH_TEST )
--    self:ChangeShader(self.bloomShader)
--    shadow.mesh.tex0 = {}
--    shadow.mesh.tex0.textureId = self.bloomtex.textureId
--    self:RenderTexRect( shadow.mesh, -1, -1, 2, 2 )

    gl.glDisable(gl.GL_CULL_FACE)
    gl.glDisable ( gl.GL_DEPTH_TEST )
    self:ChangeShader(Gcairo.uiShader)
    shadow.mesh.tex0 = {}
    shadow.mesh.tex0.textureId = shadow.blurtex.textureId
    self:RenderTexRect( shadow.mesh, -1, 0.0, 0.6, 0.8 )

end


------------------------------------------------------------------------------------------------------------

function byt3dRender:RenderTexRect( mesh, x, y, w, h, depth )

    -- Shader overrides...
    local lshader = self.currentShader
    -- Uee mesh shader if current isnt set!!
    if lshader == nil then lshader = mesh.shader end

    local z = depth
    -- Set the z value to a default if it is not passed in
    if z == nil then z = -0.1 end
    -- // Load the vertex data
    --       meshes to get correctly ordered rendering.
    if (mesh.alpha ) then
        gl.glEnable( gl.GL_BLEND )
        gl.glBlendFunc( gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA )
    else
        gl.glDisable( gl.GL_BLEND )
    end

    local verts = ffi.new("float[12]", { x, y, z, x + w, y, z, x + w, y + h, z, x, y + h, z } )
    gl.glVertexAttribPointer(lshader.vertexArray, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, verts)

    local texCoords = ffi.new("float[8]", { 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0 } )
    -- // Load the vertex data
    gl.glVertexAttribPointer(lshader.texCoordArray[0], 2, gl.GL_FLOAT, gl.GL_FALSE, 0, texCoords)

    gl.glEnableVertexAttribArray(lshader.vertexArray)
    gl.glEnableVertexAttribArray(lshader.texCoordArray[0])

    if( mesh.tex0 ~= nil ) then

        gl.glActiveTexture( gl.GL_TEXTURE0 )
        gl.glBindTexture( gl.GL_TEXTURE_2D, mesh.tex0.textureId )
        -- // Set the sampler texture unit to 0
        gl.glUniform1i(lshader.samplerTex[0], 0)
    end
	
    local indexs = ffi.new("unsigned short[6]", { 0, 2, 1, 0, 3, 2 } )
    --gl.glDrawArrays( gl.GL_TRIANGLES, 0, 3 )
    gl.glDrawElements(gl.GL_TRIANGLES, 6, gl.GL_UNSIGNED_SHORT, indexs)

    --gl.glDisableVertexAttribArray(lshader.vertexArray)
    --gl.glDisableVertexAttribArray(lshader.texCoordArray[0])
end

------------------------------------------------------------------------------------------------------------

function byt3dRender:ChangeShader( newshader )

	if newshader == nil then return end

    -- Do setup for shader if callback exist
    --if newshader.PreRender then newshader:PreRender() end

    -- Setup shader ready for use
    newshader:Use()

    -- is it new? if the same, bail
    if(newshader == self.currentShader) then return end

	-- Notify registered callbacks there has been a shader change
	for k,v in pairs(self.shaderChanged) do
		v(newshader, self.currentShader)
	end

	self.currentShader = newshader
end

------------------------------------------------------------------------------------------------------------

function byt3dRender:ChangeCamera( newcamera )

	if newcamera == nil then return end

	-- Forces shader setting
	newcamera:SetForShader(self.currentShader)
	
	-- is it new? if the same, bail
	--if newcamera == self.currentCamera then return end

	-- Notify registered callbacks there has been a camera change
	for k,v in pairs(self.cameraChanged) do
		v(newshader, newcamera)
	end
	
	self.currentCamera = newcamera
end

------------------------------------------------------------------------------------------------------------

function byt3dRender:RenderBuffer(mesh, buffer)

    -- Stop texture rendering if needed
    local ltex = mesh.tex0

    -- Shader overrides...
    local lshader = self.currentShader

    -- Sets the model matrix for this mesh buffer
    gl.glUniformMatrix4fv( lshader.modelMatrix, 1, gl.GL_FALSE, mesh.modelMatrix );
    --	print("Setting ModelMatrix :", shader.modelMatrix, gl.glGetError())

    if( ltex ~= nil ) then
        gl.glActiveTexture( gl.GL_TEXTURE0 )
        gl.glBindTexture( gl.GL_TEXTURE_2D, ltex.textureId )
        -- // Set the sampler texture unit to 0
        gl.glUniform1i(lshader.samplerTex[0], 0)
    end

    -- // Load the vertex data
    gl.glVertexAttribPointer( lshader.vertexArray, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, buffer.vertBuffer )
    gl.glEnableVertexAttribArray( lshader.vertexArray)
    --	print("Setting Vertices:", shader.texCoordArray[0], gl.glGetError())

    if (buffer.normalBuffer ~= nil) then
        -- // Load the normal data
        gl.glVertexAttribPointer( lshader.normalArray, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, buffer.normalBuffer)
        gl.glEnableVertexAttribArray( lshader.normalArray)
    end

    if (buffer.colorBuffer ~= nil) then
    --    -- // Load the color data
        gl.glVertexAttribPointer( lshader.colorArray, 4, gl.GL_FLOAT, gl.GL_FALSE, 0, buffer.colorBuffer)
    	gl.glDisableVertexAttribArray( lshader.colorArray)
    end

    if( buffer.texCoordBuffer ~= nil) then
        -- // Load the vertex data
        gl.glVertexAttribPointer( lshader.texCoordArray[0], 2, gl.GL_FLOAT, gl.GL_FALSE, 0, buffer.texCoordBuffer )
        gl.glEnableVertexAttribArray( lshader.texCoordArray[0])
        --print("Setting TexCoords:", mesh.shader.texCoordArray[0], gl.glGetError())
    end

    local isize = ffi.sizeof(buffer.indexBuffer) / 2.0
    gl.glDrawElements( gl.GL_TRIANGLES, isize, gl.GL_UNSIGNED_SHORT, buffer.indexBuffer )
    --gl.glDrawElements( gl.GL_LINE_STRIP, isize, gl.GL_UNSIGNED_SHORT, mesh.indexBuffer )
    -- print("Drawing Triangles:", isize, gl.glGetError())
end


------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------

return byt3dRender

------------------------------------------------------------------------------------------------------------