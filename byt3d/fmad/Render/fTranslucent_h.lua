--
-- Created by David Lannan
-- User: grover
-- Date: 9/05/13
-- Time: 7:44 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

ffi.cdef[[

//********************************************************************************************************************
typedef struct
{
    float	Px, Py, Pz, Pw;
    float	Nx, Ny, Nz;
    float	Vx, Vy, Vz;
    u32	rgba;

    float	Roughness;
    float	Attenuation;
    float	Ambient;
    float	Opacity;

} Vertex_t;

typedef struct
{
    float ColorDiffuseR;
    float ColorDiffuseG;
    float ColorDiffuseB;
    float Intensity;

    float ColorSpecularR;
    float ColorSpecularG;
    float ColorSpecularB;
    float pad1;

    float PositionX;
    float PositionY;
    float PositionZ;
    float pad2;

    float DirectionX;
    float DirectionY;
    float DirectionZ;
    float pad3;

    float Falloff0;
    float Falloff1;
    float Falloff2;
    float pad4;

} LightInfo_t;

]]

return ffi.C
