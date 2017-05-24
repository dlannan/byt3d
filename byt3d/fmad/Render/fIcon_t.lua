--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 7:30 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--


local ffi  = require( "ffi" )

ffi.cdef[[

//********************************************************************************************************************

typedef struct fIcon_t
{
    u32		Magic;

    u32		MaterialID;
    u32		DiffuseID;

    float		Ox;
    float		Oy;
    float		Oz;

    float		Tx;
    float		Ty;
    float		Tz;

    float		MinX;
    float		MinY;
    float		MinZ;

    float		MaxX;
    float		MaxY;
    float		MaxZ;

    char		Name[128];
    char		Desc[512];

    bool		Online;

} fIcon_t;

]]

return ffi.C