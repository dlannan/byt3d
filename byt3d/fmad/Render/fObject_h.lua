--
-- Created by David Lannan
-- User: grover
-- Date: 9/05/13
-- Time: 8:27 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

ffi.cdef[[

enum {
    fObject_Camera			= 1,
    fObject_LightDir		= 2,
    fObject_TriMesh			= 3,
    fObject_XForm			= 4,
    fObject_Material		= 5,
    fObject_Texture			= 6,
    fObject_Line			= 7,
    fObject_HeightMap		= 8,
    fObject_Icon			= 9,
    fObject_Skin			= 10,

    OBJECTLIST_MAX	        = 32*1024,
};

struct fRealize_t;
struct fObjectList_t;


]]

return ffi.C