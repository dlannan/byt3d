------------------------------------------------------------------------------------------------------------
--/*
-- * Created by David Lannan
-- * User: David Lannan
-- * Date: 5/31/2012
-- * Time: 9:56 PM
-- * 
-- */
------------------------------------------------------------------------------------------------------------

-- TODO: Geometry Shaders - for instancing and so forth. Need to fit in here nicely.
--       Whole thing needs a bit of a tidy-up.

local gl   = require( "ffi/OpenGLES2" )

------------------------------------------------------------------------------------------------------------
--	/// <summary>
--	/// Description of byt3dShader.
--	/// </summary>

byt3dShader =
{
	-- // Handle to a program object
	info			= nil,		-- ShaderInfo in here
	
	vertexArray		= -1,
	normalArray		= -1,
    colorArray		= -1, 
	texCoordArray	= { },
	
	modelMatrix		= -1,
	samplerTex		= { },
	
	loc_res			= -1,
	loc_time		= -1,
	
	-- // These are camera related, but they are per shader set
	viewProjMatrix	= -1,

    vertCode		= "",
    fragCode		= "",

    -- Special user defined uniforms - name <-> uniformid mapping.
    uniforms        = {}
}

------------------------------------------------------------------------------------------------------------

function byt3dShader:New()

	local newShader = deepcopy(byt3dShader)
    -- // Up to 8 texture samples per shader
    newShader.samplerTex 	= {}
    -- //Two UV layers maximum
    newShader.texCoordArray = {}
    return newShader
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:NewProgram( vert, frag )

	local newShader 		= deepcopy(byt3dShader)
    newShader.vertCode 		= vert
    newShader.fragCode 		= frag

    -- // Up to 8 texture samples per shader
    newShader.samplerTex 	= {}
    -- //Two UV layers maximum
    newShader.texCoordArray = {}

    if newShader:LoadShaders() < 0 then 
    	print("Error: Unable to execute LoadShaders()")
    end
    
    newShader:UseDefaultDefinitions()
    
    return newShader
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:Delete()

	if self.info == nil then return end
	self:DeleteShader(self.info)
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:DeleteShader( shader )

	gl.glDetachShader(self.shader.prog, self.shader.vs)
	gl.glDetachShader(self.shader.prog, self.shader.fs)
	
	gl.glDeleteProgram(self.shader.prog)
end
    
------------------------------------------------------------------------------------------------------------

function byt3dShader:ValidateShader( shader )

	local int = ffi.new( "GLint[1]", 0 )
	gl.glGetShaderiv( shader, gl.GL_COMPILE_STATUS, int )
	if int[0] == gl.GL_TRUE then
		return
	else
		print( "Shader Compliler: Unable to compile shader.")

		gl.glGetShaderiv( shader, gl.GL_INFO_LOG_LENGTH, int )
		if int[0] <= 0 then
			return
		end
		
		local buffer = ffi.new( "char[?]", int[0]+1 )
		gl.glGetShaderInfoLog( shader, int[0], int, buffer )
		print( "Shader Compiler Error:"..ffi.string(buffer) )
		assert(true, "Exiting due to shader errors.")
	end
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:LoadAShader( src, t )

	local shader = gl.glCreateShader( t )
	if shader == 0 then
		print( "Unable to Create Shader Object: glGetError: " .. tonumber( gl.glGetError()) )
		return nil
	end
	
	local tsrc = ffi.new( "char["..(string.len(src)+1).."]", src )
	local srcs = ffi.new( "const char*[1]", tsrc )

	gl.glShaderSource( shader, 1, srcs, nil )
	gl.glCompileShader ( shader )
	
	self:ValidateShader( shader )
	return shader
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:LoadShaders()

    --// Check both shaders are valid!
    if (string.len(self.vertCode) > 0) and (string.len(self.fragCode) > 0) then
        -- // Store the program object            
		local vs = self:LoadAShader( self.vertCode, gl.GL_VERTEX_SHADER )
		local fs = self:LoadAShader( self.fragCode, gl.GL_FRAGMENT_SHADER )
		local prog = gl.glCreateProgram()
		
		gl.glAttachShader( prog, vs )
		gl.glAttachShader( prog, fs )
		
		gl.glLinkProgram( prog )
		gl.glUseProgram( prog )
        self.info = { vs=vs, fs=fs, prog=prog }
    else
        return -1
    end 
    return 0
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:UseDefaultDefinitions()

    self.vertexArray 		= gl.glGetAttribLocation( self.info.prog, "vPosition")
--    self.normalArray 		= gl.glGetAttribLocation(self.info.prog, "vNormal")
    --self.colorArray 		= gl.glGetAttribLocation( self.info.prog, "vColor")
    self.texCoordArray[0]  	= gl.glGetAttribLocation( self.info.prog, "vTexCoord")
    
    -- Diffuse and extra texture
	self.samplerTex[0]     	= gl.glGetAttribLocation( self.info.prog, "s_tex0" )
--    self.samplerTex[1] 	= gl.glGetUniformLocation(self.info.prog, "s_tex1") -- ***** NOTE: TO BE DONE
    
    -- Camera elements
    self.modelMatrix 		= gl.glGetUniformLocation( self.info.prog, "modelMatrix")
    self.viewProjMatrix		= gl.glGetUniformLocation( self.info.prog, "viewProjMatrix")

	self.loc_res      		= gl.glGetUniformLocation( self.info.prog, "resolution" )
	self.loc_time     		= gl.glGetUniformLocation( self.info.prog, "time" )
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:DestroyShader()

    gl.glDetachShader(self.info.prog, self.info.vs)
    gl.glDetachShader(self.info.prog, self.info.fs)
    gl.glDeleteProgram(self.info.prog)
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:SetTime( tm )

	if tm == nil then tm = os.clock() end
	gl.glUniform1f(self.loc_time, tm )
end
    
------------------------------------------------------------------------------------------------------------
    
function byt3dShader:SetResolution( w, h )

	gl.glUniform2f(self.loc_res, w, h )
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:SetProjectionMatrix( tproj )

    gl.glUniformMatrix4fv(self.viewProjMatrix, 1, gl.GL_FALSE, tproj)
end

------------------------------------------------------------------------------------------------------------

function byt3dShader:Use()

    -- // Use the program object
    gl.glUseProgram(self.info.prog)   
--	print("Setting Shader:", self.info.prog, gl.glGetError())

	-- print("Sampler: ", self.samplerTex[0], self.texCoordArray[0], self.vertexArray, self.name)
	self:SetTime()
	self:SetResolution(1024, 1024)
end

------------------------------------------------------------------------------------------------------------