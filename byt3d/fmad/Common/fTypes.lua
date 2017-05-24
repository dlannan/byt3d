--
-- Created by David Lannan
-- User: grover
-- Date: 4/05/13
-- Time: 4:12 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

------------------------------------------------------------------------------------------------------------

ffi.cdef[[

// common shared types
typedef unsigned long long	u64;
typedef signed long long	s64;

typedef uint32_t            u32;
typedef uint16_t            u16;

typedef int32_t		        s32;
typedef int16_t		        s16;

typedef unsigned char		u8;
typedef signed char		    s8;

typedef struct
{
    float x, y, z;
} fVector3;

typedef struct
{
    float x, y, z, w;
} fVector4;

typedef struct
{
    float m00, m01, m02, m03;
    float m10, m11, m12, m13;
    float m20, m21, m22, m23;
    float m30, m31, m32, m33;

} fMat44;

]]

return ffi.C

------------------------------------------------------------------------------------------------------------