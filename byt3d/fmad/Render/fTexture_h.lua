--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 12:23 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

ffi.cdef[[

typedef struct fTexture_t
{

    u32		Width;
    u32		Height;
    u32		Bpp;
    u32		Format;
    u32		Layout;

    u32		TextureID;

    u8*		Compress;
    u32*		CompressCRC;

    u32*		Data;

    bool		Online;

} fTexture_t;

]]



return ffi.C