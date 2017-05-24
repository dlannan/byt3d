--
-- Created by David Lannan
-- User: grover
-- Date: 12/05/13
-- Time: 5:46 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

-- //********************************************************************************************************************

local gl   = require( "ffi/OpenGLES2" )

-- //********************************************************************************************************************

function fShader_SetXForm( Shader, Name, M )

    local param  	= gl.glGetUniformLocation( Shader, Name )
    ftrace("SetXform %d %d %s\n", param, Shader, Name)

    if(param > -1) then

        local buf = ffi.new("float[16]", M.m00, M.m01, M.m02, M.m03, M.m10, M.m11, M.m12, M.m13, M.m20, M.m21, M.m22, M.m23, M.m30, M.m31, M.m32, M.m33)
        CHECK_CG( gl.glUniformMatrix4fv(param, 1, gl.GL_FALSE, buf) )
    end
end

-- //********************************************************************************************************************

function fShader_SetParam1i( Shader, Name, value )

    local param  	= gl.glGetUniformLocation( Shader, Name )
    if(param > -1) then

        CHECK_CG( gl.glUniform1i(param, value))
    end
end

-- //********************************************************************************************************************

function fShader_SetParam3f( Shader, Name, f0, f1, f2 )

    local param  	= gl.glGetUniformLocation( Shader, Name )
    if(param > -1) then

        CHECK_CG( gl.glUniform3f(param, f0, f1, f2))
    end
end

-- //********************************************************************************************************************

function fShader_SetParam2f( Shader, Name, f0, f1 )

    local param  = gl.glGetUniformLocation( Shader, Name )
    if(param > -1) then

        CHECK_CG( gl.glUniform2f(param, f0, f1))
    end
end

-- //********************************************************************************************************************

function fShader_SetParam1f( Shader, Name, f0)

    local	param = gl.glGetUniformLocation(Shader, Name)
    if(param > -1) then

        CHECK_CG(gl.glUniform1f(param, f0))
    end
end

-- //********************************************************************************************************************

function fShader_SetParamArray1f( Shader, Name, Count, array)

    local	param = gl.glGetUniformLocation(Shader, Name)
    if(param > -1) then

        gl.glUniform1fv(param, Count, array)
    end
end

-- //********************************************************************************************************************

function fShader_SetParamArray1i( Shader, Name, Count, array)

    local	param = gl.glGetUniformLocation(Shader, Name)
    if(param > -1) then

        gl.glUniform1iv(param, Count, array)
    end
end

-- //********************************************************************************************************************

function fShader_SetTexture( Shader, Name, OL, ObjectID, DefaultID )

    local	param = gl.glGetAttribLocation(Shader, Name)
    if(param > -1) then

        local TexID = DefaultID

        -- // search for texture
        local TO = fObject_Find(OL, 0, ObjectID)
        if (TO)  then

            if (TO.Object) then

                local Tex = ffi.cast("fTexture_t* ", TO.Object)
                if (Tex.Online) then

                    TexID		= Tex.TextureID;
                    TO.FrameCount	= fObjectList_FrameNo(OL)
                -- //ftrace("FOUDN %s %08x\n", Name, ObjectID);
                end
            end
        -- //ftrace(" failed to find %s %08x\n", Name, ObjectID);
        end
        -- // bind it
        gl.glActiveTexture( gl.GL_TEXTURE0 )
        gl.glBindTexture( gl.GL_TEXTURE_2D, TexID )
    end
end

-- //********************************************************************************************************************

function fShader_SetSampler( Shader, Name, TexID )

    local	param = gl.glGetAttribLocation(Shader, Name)
    if(param > -1) then

        gl.glUniform1i(param, TexID)
    end
end

-- //********************************************************************************************************************
