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

------------------------------------------------------------------------------------------------------------
--~ 	/// <summary>
--~ 	/// Render Object looks after the running render states (these are related to current shader, current texture etc)
--~ 	/// The Render Object is more of a manager that can be assigned to a running level. 
--~		/// It is possible that post and pre render image effects may be done via this object
--~ 	/// </summary>
------------------------------------------------------------------------------------------------------------

local byt3dRender =
{
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
	
	currentNode		= nil
}

------------------------------------------------------------------------------------------------------------

function byt3dRender:New()

	local newRender = deepcopy(byt3dRender)
	
	newRender.renderPool = {}
	return newRender
end

------------------------------------------------------------------------------------------------------------

function byt3dRender:RenderMesh( mesh )
	 
	if(self.renderPool[mesh.priority] == nil) then
		self.renderPool[mesh.priority] = { }
	end
		
	local tbl = self.renderPool[mesh.priority]	
	table.insert(tbl , mesh)
	self.renderPool[mesh.priority] = tbl
end

------------------------------------------------------------------------------------------------------------
-- Clear the render pool at the begining of a render frame

function byt3dRender:Clear()
	self.renderPool = {}
end

------------------------------------------------------------------------------------------------------------
-- Render all render pool elements (can consist of anything)

function byt3dRender:Render()
	
	-- Enable depth testing initially
	gl.glEnable(gl.GL_DEPTH_TEST)
	--gl.glDepthFunc(gl.GL_LESS)
	
	for s,p in pairs(self.renderPool) do
		
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

function byt3dRender:RenderTexRect( mesh, x, y, w, h )

    local verts = ffi.new("float[12]", { x, y, -0.1, x + w, y, -0.1, x + w, y + h, -0.1, x, y + h, -0.1 } )
    --local verts = ffi.new("float[12]", { 0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0 } )
    -- // Load the vertex data
    gl.glVertexAttribPointer(mesh.shader.vertexArray, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, verts)
    -- // Load the color data
--    local colors = ffi.new("float[16]", { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 } )
--    gl.glEnableVertexAttribArray(self.shader.colorArray)
--    gl.glVertexAttribPointer(self.shader.colorArray, 4, gl.GL_FLOAT, gl.GL_FALSE, 16, colors)

    local texCoords = ffi.new("float[8]", { 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0 } )
    -- // Load the vertex data
    gl.glVertexAttribPointer(mesh.shader.texCoordArray, 2, gl.GL_FLOAT, gl.GL_FALSE, 0, texCoords)

    gl.glEnableVertexAttribArray(mesh.shader.vertexArray)
    gl.glEnableVertexAttribArray(mesh.shader.texCoordArray)

	if self.tex0 ~= nil then
	    gl.glActiveTexture( gl.GL_TEXTURE0 )
	    -- // Set the sampler texture unit to 0
	    gl.glBindTexture( gl.GL_TEXTURE_2D, self.tex0.textureId )
	    gl.glUniform1i(mesh.shader.samplerTex, 0)
	end
	
    local indexs = ffi.new("unsigned short[6]", { 0, 2, 1, 2, 0, 3 } )
    --gl.glDrawArrays( gl.GL_TRIANGLES, 0, 3 )
    gl.glDrawElements(gl.GL_TRIANGLES, 6, gl.GL_UNSIGNED_SHORT, indexs)

    gl.glDisableVertexAttribArray(mesh.shader.vertexArray)
    gl.glDisableVertexAttribArray(mesh.shader.texCoordArray)
end

------------------------------------------------------------------------------------------------------------

function byt3dRender:ChangeShader( newshader )

	if newshader == nil then return end

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
	if newcamera == self.currentCamera then return end

	-- Notify registered callbacks there has been a shader change
	for k,v in pairs(self.cameraChanged) do
		v(newshader, newcamera)
	end
	
	self.currentCamera = newcamera
end


------------------------------------------------------------------------------------------------------------

function byt3dRender:RenderBuffer(mesh, buffer)

    gl.glUniformMatrix4fv( mesh.shader.modelMatrix, 1, gl.GL_FALSE, mesh.modelMatrix );
    --	print("Setting ModelMatrix :", shader.modelMatrix, gl.glGetError())

    -- TODO: This needs moving, so that alpha meshes are sorted with other alpha
    --       meshes to get correctly ordered rendering.
    if (mesh.alpha ) then
        gl.glEnable( gl.GL_BLEND )
        gl.glBlendFunc( gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA )
    else
        gl.glDisable( gl.GL_BLEND )
    end

    if( mesh.tex0 ~= nil ) then

        gl.glActiveTexture( gl.GL_TEXTURE0 )
        gl.glBindTexture( gl.GL_TEXTURE_2D, mesh.tex0.textureId )
        -- // Set the sampler texture unit to 0
        gl.glUniform1i(mesh.shader.samplerTex[0], 0)
    end

    -- // Load the vertex data
    gl.glVertexAttribPointer(mesh.shader.vertexArray, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, buffer.vertBuffer )
    gl.glEnableVertexAttribArray(mesh.shader.vertexArray)
    --	print("Setting Vertices:", shader.texCoordArray[0], gl.glGetError())

    --if (self.normalBuffer) then
    -- // Load the normal data
    --gl.glVertexAttribPointer(self.shader.normalArray, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, self.normalBuffer)
    --gl.glEnableVertexAttribArray(self.shader.normalArray)
    --end

    --if (self.colorBuffer) then
    --    -- // Load the color data
    --    gl.glVertexAttribPointer(self.shader.colorArray, 4, gl.GL_FLOAT, gl.GL_FALSE, 0, self.colorBuffer)
    -- 	  gl.glDisableVertexAttribArray(self.shader.colorArray)
    --end

    if( buffer.texCoordBuffer ~= nil ) then
        -- // Load the vertex data
        gl.glVertexAttribPointer(mesh.shader.texCoordArray[0], 2, gl.GL_FLOAT, gl.GL_FALSE, 0, buffer.texCoordBuffer )
        gl.glEnableVertexAttribArray(mesh.shader.texCoordArray[0])
        --print("Setting TexCoords:", mesh.shader.texCoordArray[0], gl.glGetError())
    end

    local isize = ffi.sizeof(buffer.indexBuffer) / 2.0
    gl.glDrawElements( gl.GL_TRIANGLES, isize, gl.GL_UNSIGNED_SHORT, buffer.indexBuffer )
    --gl.glDrawElements( gl.GL_LINE_STRIP, isize, gl.GL_UNSIGNED_SHORT, mesh.indexBuffer )
    --	print("Drawing Triangles:", isize, gl.glGetError())
end

------------------------------------------------------------------------------------------------------------

return byt3dRender

------------------------------------------------------------------------------------------------------------