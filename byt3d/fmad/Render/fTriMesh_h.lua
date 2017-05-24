--
-- Created by David Lannan
-- User: grover
-- Date: 10/05/13
-- Time: 6:33 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi  = require( "ffi" )

ffi.cdef[[

//********************************************************************************************************************

typedef struct Tri_t
{
    u32	p0, p1, p2;
} Tri_t;

// once size fits all.. cough
typedef struct Vertex_t
{
    float	Px, Py, Pz;
    u32	rgba;

    float   u, v;
    u32	pad;

    float  	Nx, Ny, Nz;
    float  	Tx, Ty, Tz;
    float  	Bx, By, Bz;

} Vertex_t;

//********************************************************************************************************************

typedef struct fTriMesh_t
{
    u32		Magic;
    u32		MaterialID;

    u32		VertexCount;
    u32		IndexCount;

    u32		VertexCRC;
    u32		IndexCRC;
    u32		FinishCRC;

    u32		IndexChunkCount;
    u32		VertexChunkCount;

    u32*    IndexChunkCRC;
    u32*	VertexChunkCRC;

    u32		VertexDud;
    u32		VertexReceive;

    u32		IndexDud;
    u32		IndexReceive;

    Tri_t*	    IndexList;
    Vertex_t*	VertexList;

    // vbos
    u32		VertexVBO;
    u32		IndexVBO;

    u32		VertexVBOCRC;
    u32		IndexVBOCRC;

    bool		Online;

} fTriMesh_t;

]]


return ffi.C