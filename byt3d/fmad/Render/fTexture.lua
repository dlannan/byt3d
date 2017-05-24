--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 12:24 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

require("byt3d/fmad/Render/fTexture_h")

-- //********************************************************************************************************************

s_Scratch = nil

-- //********************************************************************************************************************

function fTexture_Packet( N, ObjectID, Data, Size, User)

    local RT = ffi.cast("fRealizeTexture_t*", Data)
    local R	= fRealize_SceneIDFind(RT.Header.SceneID)
    if (R == nil) then return end

    -- // find object
    local OL	= fRealize_ObjectList(R)
    fAssert(OL)

    -- // get/make object
    local O		= fObject_Get(OL, fObject_Texture, RT.Header.NodeID, RT.Header.ObjectID)
    fAssert(O)

    -- // new camera object
    local TPtr = O.Object
    if (TPtr == nil) then

        TPtr = ffi.new("fTexture_t[1]")
        ffi.fill(TPtr, ffi.sizeof("fTexture_t"), 0)
        O.Object = TPtr
    end

    local T = TPtr[0]
    -- // send current ack of packet
    -- // note: world will continue to send pkts if the inital ack is dropped
    if(RT.Header.CmdID == fRealizeCmdID_Update) then

        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack.NetID	= fMultiCast_ObjectID(N)
        Ack.NodeID	= RT.Header.NodeID
        Ack.ObjectID	= RT.Header.ObjectID
        Ack.PartPos	= RT.Header.PartPos
        Ack.PartTotal	= RT.Header.PartTotal
        Ack.CRC32	= O.CRC32

        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, AckPtr, ffi.sizeof(Ack))

        -- // crc matches then dont waste cycles processing it
        if (O.CRC32 == RT.Header.CRC32) then

            return
        end
        -- // dimentions

        T.Width	    	= RT.Width
        T.Height		= RT.Height
        T.Bpp			= RT.Bpp
        T.Format		= RT.Format
        T.Layout		= RT.Layout
        T.Online 		= false

        -- // data size
        if (T.Data == nil) then

            fAssert(T.Width < 4096)
            fAssert(T.Height < 4096)
            fAssert(T.Bpp < 128)

            T.Data		= fMalloc(T.Width*T.Height*T.Bpp/8)
        end

        -- // compress buffer
        if (T.Compress == nil) then

            T.Compress = ffi.new("u8["..RT.CompressSize.."]")
            T.CompressCRC	= ffi.new("u32["..RT.CompressCount.."]")
            ffi.fill(T.CompressCRC, ffi.sizeof("u32")*RT.CompressCount, 0)
        end

        -- // already processed ?
        if (T.CompressCRC[RT.CompressPos] == 0) then

            -- // update CRC
            T.CompressCRC[RT.CompressPos] = RT.CompressCRC

            -- // copy packet info
            ffi.copy(T.Compress + RT.Offset, RT.Data, RT.Len)

            -- // update crc
            O.CRC32 = 0
            for i=0, RT.CompressCount-1 do

                O.CRC32 = O.CRC32 + T.CompressCRC[i]
            end
        end
    elseif(RT.Header.CmdID == fRealizeCmdID_Collect) then

--        printf("collect texture\n")

        local AckPtr = ffi.new("fRealizeObjectAct_t[1]")
        local Ack = AckPtr[0]
        Ack.NetID	= fMultiCast_ObjectID(N)
        Ack.NodeID	= RT.Header.NodeID
        Ack.ObjectID	= RT.Header.ObjectID
        Ack.PartPos	= RT.Header.PartPos
        Ack.PartTotal	= RT.Header.PartTotal
        Ack.CRC32	= RT.Header.CRC32

        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, AckPtr, ffi.sizeof(Ack))
        -- // undefined packet
    end

    -- // all done !
    if (O.CRC32 == RT.Header.CRC32) then
            -- // de-compress it
        printf("texture decomp: %i %i %i : %08x %08x\n", T.Width, T.Height, T.Bpp, O.CRC32, RT.Header.CRC32)

        local RawSize = qlz_decompress( ffi.cast("const char *", T.Compress), T.Data, s_Scratch)
        fAssert(RawSize == (T.Width*T.Height*T.Bpp/8))

        -- // free compress buffer
        fFree(T.Compress)
        T.Compress = nil
        if (T.TextureID ~= 0) then

            gl.glDeleteTextures(1, T.TextureID)
            T.TextureID = 0
        end

        -- // make gl.gl texture
        gl.glGenTextures(1, ffi.cast("GLuint*",T.TextureID))

        local BindID = 0
        if(T.Layout == fRealizeTextureLayout_2D) then
            BindID  = gl.GL_TEXTURE_2D
        elseif(T.Layout == fRealizeTextureLayout_CUBE) then
            BindID 	= gl.GL_TEXTURE_CUBE_MAP
        else
            fAssert(false)
        end
    end
    gl.glBindTexture(BindID, T.TextureID)

    -- // realize format to GL format
    local InternalFormat	= 0
    local Format		= 0
    local Bytes		= 0
    local Stride		= 0
    if(T.Format == fRealizeTextureFormat_RGBA8) then
        InternalFormat	= gl.GL_RGBA8
        Format		= gl.GL_BGRA
        Bytes		= gl.GL_UNSIGNED_BYTE
        Stride		= T.Width*4
    end

    if(T.Format == fRealizeTextureFormat_U16) then
        InternalFormat	= gl.GL_LUMINANCE16
        Format		= gl.GL_LUMINANCE
        Bytes		= gl.GL_UNSIGNED_SHORT
        Stride		= T.Width*2
    end
    gl.glTexParameterf(BindID, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameterf(BindID, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)

--    /*
--    -- // flip the texture vertically... man ogl.gl does suck
--    char* iData = fMalloc(T.Height*Stride)
--    for (int i=0 i < T.Height i++)
--        {
--            memcpy(iData + i*Stride, (char *)T.Data + (T.Height-1-i)*Stride, Stride)
--    }
--    fFree(T.Data)
--    T.Data = (u32 *)iData
--    */

    if(T.Layout == fRealizeTextureLayout_2D) then

        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, InternalFormat, T.Width, T.Height, 0, Format, Bytes, T.Data)

    elseif(T.Layout == fRealizeTextureLayout_CUBE) then

        local CubeWidth	    = T.Width/6
        local CubeHeight	= T.Height

        ftrace("decode cube map! %08x\n", O.ObjectID)
        local Map = ffi.new("u8["..(CubeWidth * CubeHeight * 4).."]")

        local Facemap =
        {
            gl.GL_TEXTURE_CUBE_MAP_POSITIVE_X,
            gl.GL_TEXTURE_CUBE_MAP_NEGATIVE_X,

            gl.GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
            gl.GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,

            gl.GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
            gl.GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
        }

        for f=1, 6 do

            local r = 0
            local g = 0
            local b = 0
            local a = 0
            if(f == 1) then	r = 0xff; g = 0x00; b = 0x00; end
            if(f == 2) then r = 0x7f; g = 0x00; b = 0x00; end
            if(f == 3) then r = 0x00; g = 0xff; b = 0x00; end
            if(f == 4) then r = 0x00; g = 0x7f; b = 0x00; end
            if(f == 5) then r = 0x00; g = 0x00; b = 0xff; end
            if(f == 6) then r = 0x00; g = 0x00; b = 0x7f; end

            for j=0, CubeHeight-1 do

                -- // fucking invert somewhere..
                local Dst = Map + (CubeHeight -j -1)*CubeWidth*4
                local Src = ffi.cast("char *", T.Data) + (j*T.Width + (f-1)*CubeWidth)*4
                ffi.copy(Dst, Src, CubeWidth*4)
--                    /*
--                    -- //memset(Dst, f*0x10, CubeWidth*4)
--                    for (int i=0 i < CubeWidth i++)
--                    {
--                        Dst[i*4+0] = r
--                        Dst[i*4+1] = g
--                        Dst[i*4+2] = b
--                        Dst[i*4+3] = a
--                    }
--                    */
            end
            gl.glTexImage2D(Facemap[f], 0, InternalFormat, CubeWidth, CubeHeight, 0, Format, Bytes, Map)
        end

        fFree(Map)
    end

    gl.glTexParameteri(BindID, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameteri(BindID, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)

    -- // magical mips
    gl.glTexParameteri(BindID, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR_MIPMAP_LINEAR)
    gl.glGenerateMipmapEXT(BindID)

    gl.glBindTexture(BindID, 0)

    T.Online = true
end

-- //********************************************************************************************************************
function fTexture_Destroy( O)

    local T = ffi.cast("fTexture_t*", O.Object)
    if (T == nil) then return end

    -- // release gl.gl resources
    if (T.TextureID ~= 0) then

        gl.glDeleteTextures(1, T.TextureID)
        T.TextureID = 0
    end

    if (T.Compress) then

        fFree(T.Compress)
        T.Compress = nil
    end

    if (T.CompressCRC) then

        fFree(T.CompressCRC)
        T.CompressCRC = nil
    end

    if (T.Data) then

        fFree(T.Data)
        T.Data = nil
    end

    ffi.fill(T, ffi.sizeof("fTexture_t"), 0)
    fFree(T)

    O.Object = nil
end

-- //********************************************************************************************************************
--int	fTexture_Register(lua_State* L)
--{
--s_Scratch = fMalloc(QLZ_SCRATCH_COMPRESS)
--memset(s_Scratch, 0, QLZ_SCRATCH_COMPRESS)
--
--return 0
--}
