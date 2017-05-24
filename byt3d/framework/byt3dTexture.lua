------------------------------------------------------------------------------------------------------------
--/*
-- * Created by David Lannan
-- * User: David Lannan
-- * Date: 5/31/2012
-- * Time: 9:57 PM
-- *
-- */
------------------------------------------------------------------------------------------------------------
-- Texture has to be pool managed.. TODO!!!
------------------------------------------------------------------------------------------------------------

local ffi 	= require( "ffi" )

------------------------------------------------------------------------------------------------------------

local poolm = require("framework/byt3dPool")

------------------------------------------------------------------------------------------------------------
--	/// <summary>
--	/// Description of byt3dTexture.
--	/// </summary>
byt3dTexture =
{
	frameId 		= -1,
	textureId		= -1,
	textureName		= "",

	name			= ""
}

------------------------------------------------------------------------------------------------------------
-- TODO: Convert this into using a Pool mechanism. Pools will be effectively simple
--       caches that can be used by all sorts of objects (multi obj or singleton types)
TexExtension =
{
    texFrameBuffers = 1,
    texGenBuffers	= 1,		-- Counter for autogenerate textures
    texIdCache		= nil
}

------------------------------------------------------------------------------------------------------------

function byt3dTexture:New()

	local newTex = deepcopy(byt3dTexture)
	return newTex
end

------------------------------------------------------------------------------------------------------------

function byt3dTexture:Create()

end

------------------------------------------------------------------------------------------------------------

function byt3dTexture:Destroy()
	--print("Destroying Texture..", self.name, self.textureId)
	if self.textureId ~= nil then 
		local texId = ffi.new("int[1]")
		texId[0] = self.textureId
		gl.glDeleteTextures(1, texId ) 
	end
	
	--- Fix this
	if self.image ~= nil then
		self.cairo:DeleteImage(self)
	end
end


------------------------------------------------------------------------------------------------------------

function byt3dTexture:CheckPool()

	-- Add the texture into the texture pool
	local tpool = byt3dPool:GetPool(byt3dPool.TEXTURES_NAME)
	if TexExtension.texIdCache ~= tpool or tpool == nil then

		if tpool == nil then 
			tpool = poolm:New(byt3dPool.TEXTURES_NAME)
		end
		TexExtension.texIdCache = tpool
	end
end

------------------------------------------------------------------------------------------------------------

function byt3dTexture:GenTexName(tex)

	local tname = string.gsub( self.textureName, "[%p%/%\\]", "_")
	local tctx = tostring(gSdisp.eglInfo.ctx)
	local ctxname = string.gsub( tctx , "cdata%<void %*%>%:% ", "")
	local texid = string.format("%s_%s", tname, ctxname)
	return texid
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Special FrameBuffer related texture type.
--    /// If fb is set to anything other than 1, then the texture is created
--    /// only as a normal texture with the specific size settings.
--    /// </summary>
--    /// <param name="w">Width of textures</param>
--    /// <param name="h">Height of texture</param>
--    /// <param name="fb">fb == 1 is it a framebuffer texture or normal GL texture</param>
function byt3dTexture:NewTextureBuffer( w, h, fb )

	self:CheckPool()
	local newTex = deepcopy(byt3dTexture)
	if fb == nil then fb = 1 end

	if fb == 1 then
		newTex.name = "FrameBuffer"..TexExtension.texFrameBuffers
		TexExtension.texFrameBuffers = TexExtension.texFrameBuffers + 1

        local texId = ffi.new("int[1]")
        gl.glGenTextures(1, texId)
        gl.glBindTexture(gl.GL_TEXTURE_2D, texId[0])

        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGB, w, h, 0, gl.GL_RGB, gl.GL_UNSIGNED_BYTE, nil)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
        newTex.textureId = texId[0]

--        local depthId = ffi.new("int[1]")
--        gl.glGenTextures(1, depthId)
--        gl.glBindTexture(gl.GL_TEXTURE_2D, depthId[0])
--
--        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
--        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
--        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
--        gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
--        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_DEPTH_COMPONENT, w, h, 0, gl.GL_DEPTH_COMPONENT, gl.GL_UNSIGNED_SHORT, nil)
--        newTex.depthId = depthId[0]

        -- // create framebuffer
        local fId = ffi.new("int[1]")
        --~ // Attach each texture to the first color buffer of an FBO and clear it
        gl.glGenFramebuffers(1, fId);
        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fId[0])
        gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, newTex.textureId, 0)
--        gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_TEXTURE_2D, newTex.depthId, 0)
        newTex.frameId = fId[0]

        newTex.name = newTex.textureName
        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    else
		newTex.frameId = -1
		newTex.name = "AutoGenerated"..TexExtension.texGenBuffers
		TexExtension.texGenBuffers = TexExtension.texGenBuffers + 1

        newTex.textureId = TexExtension:MakeGLTexture(w, h)
        TexExtension.texIdCache:CreateResource(newTex)
    end

	return newTex
end

------------------------------------------------------------------------------------------------------------

function byt3dTexture:NewDepthTextures( w, h )

    self:CheckPool()
    local newTex = deepcopy(byt3dTexture)

    newTex.name = "FrameBuffer"..TexExtension.texFrameBuffers
    TexExtension.texFrameBuffers = TexExtension.texFrameBuffers + 1

    local shadowMapWidth    = w
    local shadowMapHeight   = h
    local FBOstatus         = 0

    -- // create a framebuffer object
    local fboId = ffi.new("int[1]")
    gl.glGenFramebuffers(1, fboId)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fboId[0]);

    local renderId = ffi.new("int[1]")
    gl.glGenRenderbuffers(1, renderId)

    local depthId = ffi.new("int[1]")
    gl.glGenTextures(1, depthId)

    gl.glBindTexture(gl.GL_TEXTURE_2D, depthId[0])
    gl.glTexImage2D( gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, w, h, 0, gl.GL_RGBA, gl.GL_FLOAT, nil)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    -- //glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE)

    -- // Remove artefact on the edges of the shadowmap
    gl.glTexParameterf( gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE )
    gl.glTexParameterf( gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE )

    gl.glBindRenderbuffer(gl.GL_RENDERBUFFER, renderId[0])
    gl.glRenderbufferStorage(gl.GL_RENDERBUFFER, gl.GL_DEPTH_COMPONENT16, w, h)

    -- // attach the texture to FBO depth attachment point
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0,gl.GL_TEXTURE_2D, depthId[0], 0)
    gl.glFramebufferRenderbuffer(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_RENDERBUFFER, renderId[0])

    --local buf = ffi.new("int["..(w * h).."]")
    --gl.glGenerateMipmap(gl.GL_TEXTURE_2D)
    -- // No color output in the bound framebuffer, only depth.
    -- gl.glColorMask(gl.GL_FALSE, gl.GL_FALSE, gl.GL_FALSE, gl.GL_FALSE)

    -- // check FBO status
    local FBOstatus = gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER)
    if(FBOstatus ~= gl.GL_FRAMEBUFFER_COMPLETE) then
        io.write("GL_FRAMEBUFFER_COMPLETE failed for shadowmap FBO, CANNOT use FBO\n")
    end

    -- // switch back to window-system-provided framebuffer
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    newTex.textureId    = depthId[0]
    newTex.fboId        = fboId[0]

    -- print("OpenGLES Error:", gl.glGetError())

    return newTex
end

------------------------------------------------------------------------------------------------------------

function byt3dTexture:NewColourTextures( w, h )

    self:CheckPool()
    local newTex = deepcopy(byt3dTexture)

    newTex.name = "FrameBuffer"..TexExtension.texFrameBuffers
    TexExtension.texFrameBuffers = TexExtension.texFrameBuffers + 1

    local shadowMapWidth    = w
    local shadowMapHeight   = h
    local FBOstatus         = 0

    -- // create a framebuffer object
    local fboId = ffi.new("int[1]")
    gl.glGenFramebuffers(1, fboId)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fboId[0]);

    local colorId = ffi.new("int[1]")
    gl.glGenTextures(1, colorId)

    gl.glBindTexture(gl.GL_TEXTURE_2D, colorId[0])
    gl.glTexImage2D( gl.GL_TEXTURE_2D, 0, gl.GL_RGB, w, h, 0, gl.GL_RGB, gl.GL_FLOAT, nil)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    -- //glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE)

    -- // Remove artefact on the edges of the shadowmap
    gl.glTexParameterf( gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE )
    gl.glTexParameterf( gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE )

    -- // attach the texture to FBO depth attachment point
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0,gl.GL_TEXTURE_2D, colorId[0], 0)

    -- // check FBO status
    local FBOstatus = gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER)
    if(FBOstatus ~= gl.GL_FRAMEBUFFER_COMPLETE) then
        io.write("GL_FRAMEBUFFER_COMPLETE failed for shadowmap FBO, CANNOT use FBO\n")
    end

    -- // switch back to window-system-provided framebuffer
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    newTex.textureId    = colorId[0]
    newTex.fboId        = fboId[0]
    -- print("OpenGLES Error:", gl.glGetError())

    return newTex
end

------------------------------------------------------------------------------------------------------------

function byt3dTexture:NewFilePath( filePath )
	self.textureName = filePath
	self:LoadTexture(null)
end

------------------------------------------------------------------------------------------------------------

function byt3dTexture:FromCairoImage( c_ui, name, filePath )

	-- Assumes the by3dTexture new has been previously called
	-- store the cairo_image for later use if needed
    if type(filePath) == "string" then
        self.cairo_image = c_ui:LoadImage(name, filePath)
        self.textureName = filePath
    else
        self.cairo_image = filePath
        self.textureName = name
    end
	self.cairo_image.data = c_ui:GetImageData(self.cairo_image)
	self.cairo = c_ui

	self:LoadTexture(self.cairo_image)
end

------------------------------------------------------------------------------------------------------------

function byt3dTexture:NewColorImage( color )

	self:CheckPool()
	self.textureName = string.format("BuildColorTex_%03d_%03d_%03d_%03d", color[1], color[2], color[3], color[4])
    self.name = self.textureName

	-- print("Texture Name: "..self.textureName)
	local tex = TexExtension.texIdCache:GetResource(self.name)
	if(tex ~= nil) then
		self.textureId = tex.textureId
	else
		self.textureId = TexExtension:BuildColorTexture( color[1], color[2], color[3], color[4] )
		TexExtension.texIdCache:CreateResource(self)
	end
end

------------------------------------------------------------------------------------------------------------

function byt3dTexture:LoadTexture(tex)

	self:CheckPool()	
	local texid = self:GenTexName(tex)
	
	-- Is it a cairo image or an object with data already set?
	if tex.data ~= nil then
		-- Copy into the structure for later deletion
		for k,v in pairs(tex) do self[k] = v end 
	end
	
	self.textureName = texid
	self.name = texid

	local temp = TexExtension.texIdCache:GetResource(texid)

	if (temp ~= nil) then
		self.textureId 		= temp.textureId
	else
		self.textureId = TexExtension:GenerateTexture( texid, tex )
		self.name = texid
		TexExtension.texIdCache:CreateResource(self)
	end
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Enable rendering to target a frame buffer object
--    /// Use the ClearFrameBuffer() when rendering is complete (after swap)
--    /// </summary>
function byt3dTexture:EnableFrameBuffer()
	
	if(frameId > 0) then
		gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, frameId)
	end
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Disable any further rendering to a frame buffer object - back to display
--    /// </summary>
function byt3dTexture:ClearFrameBuffer()

	gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)
end

------------------------------------------------------------------------------------------------------------

function TexExtension:GenerateId(name)

	local texId = ffi.new("int[1]")
	gl.glGenTextures(1, texId)
	return texId[0]
end

------------------------------------------------------------------------------------------------------------

function TexExtension:GenerateTexData( barray )

	local bcount = table.getn(barray)
	local texData = ffi.new( "uint8_t[?]", bcount * 4 )
	icount = 1
	for i=1, bcount do

		texData[icount] = barray[i].R; icount = icount + 1
		texData[icount] = barray[i].G; icount = icount + 1
		texData[icount] = barray[i].B; icount = icount + 1
		texData[icount] = barray[i].A; icount = icount + 1
	end
	return texData
end

------------------------------------------------------------------------------------------------------------
--	/// <summary>
--	/// Generate the texture for GL usage
--	/// </summary>
--	/// <param name="textureName"></param>
--	/// <param name="tex"></param>
--	/// <returns></returns>
function TexExtension:GenerateTexture( textureName, tex )

	local texData	= nil
	local Width		= 0
	local Height	= 0

	if(tex ~= nil) then

		texData = tex.data
		Width = tex.width
		Height = tex.height
	else
		-- TODO:  Insert favourite Image Loader - SDL? or Cairo?
	end

	local texId = ffi.new("int[1]")
	gl.glGenTextures(1, texId)
	gl.glBindTexture(gl.GL_TEXTURE_2D, texId[0])
	--gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
	--gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
	gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, Width, Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, texData )
	gl.glGenerateMipmap(gl.GL_TEXTURE_2D);

	return texId[0]
end

------------------------------------------------------------------------------------------------------------

function TexExtension:SetFilter( linear, texid )

	gl.glBindTexture(gl.GL_TEXTURE_2D, texid)

	if linear then
		gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
		gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
	end
end

------------------------------------------------------------------------------------------------------------

function TexExtension:BuildColorTexture( r, g, b, a)

	local Width = 64;
	local Height = 64;
	local data = ffi.new( "unsigned char["..(Width*Height*4).."]" )
	local index = 0
	for i = 1, Width * Height do

		data[index] 	= b
		data[index+1] 	= g
		data[index+2] 	= r
		data[index+3] 	= a
		index = index + 4
	end

	-- //if(a != 255.0f) hasalpha = 1;
	local texId = ffi.new("int[1]")
	gl.glGenTextures(1, texId)
	gl.glBindTexture(gl.GL_TEXTURE_2D, texId[0])
	gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
	gl.glTexParameterf(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
	gl.glGenerateMipmap(gl.GL_TEXTURE_2D);
	gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, Width, Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, data )

	-- print("Making Texture:", r , g, b,  a, texId[0], textureName )
	return texId[0]
end

------------------------------------------------------------------------------------------------------------

function TexExtension:MakeGLTexture( w, h )

	local data 		= ffi.new( "int[?]", w * h)
	local Width 	= w
	local Height 	= h

	local texId = ffi.new("int[1]")
	gl.glGenTextures(1, texId)
	gl.glBindTexture(gl.GL_TEXTURE_2D, texId[0])
	gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, Width, Height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, texData )
	gl.glGenerateMipmap( gl.GL_TEXTURE_2D )

	return texId[0]
end

------------------------------------------------------------------------------------------------------------