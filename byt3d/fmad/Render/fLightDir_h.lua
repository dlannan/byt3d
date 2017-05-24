--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 12:13 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--


local ffi  = require( "ffi" )

ffi.cdef[[

typedef struct fLightDir_t
{
    u32		Magic;

    float		ColorDiffuseR;
    float		ColorDiffuseG;
    float		ColorDiffuseB;

    float		ColorSpecularR;
    float		ColorSpecularG;
    float		ColorSpecularB;

    float		PositionX;
    float		PositionY;
    float		PositionZ;

    float		DirectionX;
    float		DirectionY;
    float		DirectionZ;

    float		Intensity;

    float		Falloff0;
    float		Falloff1;
    float		Falloff2;

    float 		ShadowMapBias;
    bool 		ShadowEnable;

    fMat44		View;
    fMat44		iView;

    fMat44		Projection;
    fMat44		iProjection;

} fLightDir_t;

//********************************************************************************************************************

]]


return ffi.C