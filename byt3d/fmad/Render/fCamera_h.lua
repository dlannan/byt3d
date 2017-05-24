--
-- Created by David Lannan
-- User: grover
-- Date: 10/05/13
-- Time: 6:13 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

ffi.cdef[[

struct fObject_t;

//********************************************************************************************************************
typedef struct fCamera_t
{
    fMat44			Local2World;
    fMat44			iLocal2World;

    fMat44			View;
    fMat44			iView;

    fMat44			Projection;
    fMat44			iProjection;

} fCamera_t;

]]

return ffi.C
