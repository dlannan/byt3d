--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 12:19 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

ffi.cdef[[

//********************************************************************************************************************
typedef struct fLine_t
{
    u32		Magic;
    bool		Online;

    float		ColorR;
    float		ColorG;
    float		ColorB;
    bool		DepthTest;

    u32		VertexCount;

    u32		FinalCRC;
    u32		PacketCount;
    u32* 		PacketCRC;

    float*		VertexList;

    // vbos
    u32		VertexVBO;

} fLine_t;


]]


return ffi.C