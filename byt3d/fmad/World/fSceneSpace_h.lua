--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:45 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--


local ffi  = require( "ffi" )

ffi.cdef[[
typedef struct fSceneSpaceQuery_t
{
    float			        Px;
    float			        Py;
    float			        Pz;
    float			        Distance2;
    float			        Radius;

    struct fSceneObject_t*	Object;

} fSceneSpaceQuery_t;

void fSceneSpace_Insert
(
    struct fSceneSpace_t*	A,
    const char*		        Path,
    fMat44*			        L2W,
    fMat44*			        iL2W,
    struct fSceneHost_t*	Host,
    struct fSceneNode_t*	Node,
    fSceneObject_t*		    Object,
    u32			            SpaceID
);

//********************************************************************************************************************
// spacial object

typedef struct fSpaceObject_t
{
    // host
    struct fSceneHost_t*	Host;
    // parent node
    struct fSceneNode_t*	Node;

    char			        Path[1024];
    fMat44			        Local2World;
    fMat44			        iLocal2World;

    float			        SphereX;
    float			        SphereY;
    float			        SphereZ;
    float			        SphereRadius;
    float			        SphereRadius2;

    u32			            SpaceID;

    // to the object
    struct fSceneObject_t*	Object;

    // next in the space list
    struct fSpaceObject_t*	Next;

} fSpaceObject_t;

typedef struct fSceneSpace_t
{
    fSpaceObject_t*		SpaceHead;
    u32			        SpaceRef;

    // packetized list
    u32			        RSceneMax;
    u32			        RSceneCount;
    fRealizeScene_t*	RScene;

} fSceneSpace_t;


]]

return ffi.C