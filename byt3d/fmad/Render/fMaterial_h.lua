--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 12:11 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--



local ffi  = require( "ffi" )

ffi.cdef[[

// material item
typedef struct fMaterial_t
{
    bool			TextureEnable;
    u32			TextureDiffuseObjectID;
    u32			TextureEnvObjectID;

    float			Roughness;
    float			Attenuation;
    float			Ambient;

    bool			Translucent;
    float			Opacity;

    float			DiffuseR;
    float			DiffuseG;
    float			DiffuseB;

} fMaterial_t;

]]


return ffi.C