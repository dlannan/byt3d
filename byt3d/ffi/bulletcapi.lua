--
-- Created by David Lannan - copyright 2013
-- Developed for the Byt3D project. byt3d.codeplex.com
-- User: dlannan
-- Date: 21/04/13
-- Time: 8:28 PM
--
local ffi = require( "ffi" )

local libs = ffi_bullet_libs or {
    Windows = { x86 = "bin/Windows/x86/BulletCAPI.dll", x64 = "bin/Windows/x64/BulletCAPI.dll" },
    OSX     = { x86 = "/usr/lib/bulletCAPI.dylib", x64 = "/usr/lib/bulletCAPI.dylib" },
    Linux   = { x86 = "bulletCAPI", x64 = "bulletCAPI", arm = "bulletCAPI" },
}

local lib   = ffi_bullet_libs or libs[ ffi.os ][ ffi.arch ]
local bullet= ffi.load( lib )

ffi.cdef [[
// Bullet Continuous Collision Detection and Physics Library
// Copyright (c) 2003-2006 Erwin Coumans  http://continuousphysics.com/Bullet/
//
// This software is provided 'as-is', without any express or implied warranty.
// In no event will the authors be held liable for any damages arising from the use of this software.
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it freely,
// subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//
//
// Draft high-level generic physics C-API. For low-level access, use the physics SDK native API's.
// Work in progress, functionality will be added on demand.
//
// If possible, use the richer Bullet C++ API, by including "btBulletDynamicsCommon.h"
//

typedef float	plReal;

typedef plReal	plVector3[3];
typedef plReal	plQuaternion[4];

//**	Particular physics SDK (C-API) */
typedef struct plPhysicsSdkHandle__ { int unused; } *plPhysicsSdkHandle;

//** 	Dynamics world, belonging to some physics SDK (C-API)*/
typedef struct plDynamicsWorldHandle__ { int unused; } *plDynamicsWorldHandle;

//** Rigid Body that can be part of a Dynamics World (C-API)*/
typedef struct plRigidBodyHandle__ { int unused; } *plRigidBodyHandle;

//** 	Collision Shape/Geometry, property of a Rigid Body (C-API)*/
typedef struct plCollisionShapeHandle__ { int unused; } *plCollisionShapeHandle;

//** Constraint for Rigid Bodies (C-API)*/
typedef struct plConstraintHandle__ { int unused; } *plConstraintHandle;

//** Triangle Mesh interface (C-API)*/
typedef struct plMeshInterfaceHandle__ { int unused; } *plMeshInterfaceHandle;

//** Broadphase Scene/Proxy Handles (C-API)*/
typedef struct plCollisionBroadphaseHandle__ { int unused; } *plCollisionBroadphaseHandle;
typedef struct plBroadphaseProxyHandle__ { int unused; } *plBroadphaseProxyHandle;
typedef struct plCollisionWorldHandle__ { int unused; } *plCollisionWorldHandle;

//**
//Create and Delete a Physics SDK
//*/

//this could be also another sdk, like ODE, PhysX etc.
plPhysicsSdkHandle	plNewBulletSdk(void);
void		plDeletePhysicsSdk(plPhysicsSdkHandle	physicsSdk);

///** Collision World, not strictly necessary, you can also just create a Dynamics World with Rigid Bodies which
///   internally manages the Collision World with Collision Objects */

typedef void(*btBroadphaseCallback)(void* clientData, void* object1,void* object2);

plCollisionBroadphaseHandle	plCreateSapBroadphase(btBroadphaseCallback beginCallback,btBroadphaseCallback endCallback);
void	plDestroyBroadphase(plCollisionBroadphaseHandle bp);
plBroadphaseProxyHandle plCreateProxy(plCollisionBroadphaseHandle bp, void* clientData, plReal minX,plReal minY,plReal minZ, plReal maxX,plReal maxY, plReal maxZ);
void plDestroyProxy(plCollisionBroadphaseHandle bp, plBroadphaseProxyHandle proxyHandle);
void plSetBoundingBox(plBroadphaseProxyHandle proxyHandle, plReal minX,plReal minY,plReal minZ, plReal maxX,plReal maxY, plReal maxZ);

///* todo: add pair cache support with queries like add/remove/find pair */
plCollisionWorldHandle plCreateCollisionWorld(plPhysicsSdkHandle physicsSdk);

///* todo: add/remove objects */


///* Dynamics World */

plDynamicsWorldHandle plCreateDynamicsWorld(plPhysicsSdkHandle physicsSdk);

void plDeleteDynamicsWorld(plDynamicsWorldHandle world);

void plStepSimulation(plDynamicsWorldHandle,	plReal	timeStep, int subSteps);

void plAddRigidBody(plDynamicsWorldHandle world, plRigidBodyHandle object);

void plRemoveRigidBody(plDynamicsWorldHandle world, plRigidBodyHandle object);


///* Rigid Body  */

plRigidBodyHandle plCreateRigidBody(	void* user_data,  float mass, plCollisionShapeHandle cshape );
void plDeleteRigidBody(plRigidBodyHandle body);


///* Collision Shape definition */

plCollisionShapeHandle plNewSphereShape(plReal radius);
plCollisionShapeHandle plNewBoxShape(plReal x, plReal y, plReal z);
plCollisionShapeHandle plNewCapsuleShape(plReal radius, plReal height);
plCollisionShapeHandle plNewConeShape(plReal radius, plReal height);
plCollisionShapeHandle plNewCylinderShape(plReal radius, plReal height);
plCollisionShapeHandle plNewCompoundShape(void);
void	plAddChildShape(plCollisionShapeHandle compoundShape,plCollisionShapeHandle childShape, plVector3 childPos,plQuaternion childOrn);

void plDeleteShape(plCollisionShapeHandle shape);

///* Convex Meshes */
plCollisionShapeHandle plNewConvexHullShape(void);
void		plAddVertex(plCollisionShapeHandle convexHull, plReal x,plReal y,plReal z);
///* Concave static triangle meshes */
plMeshInterfaceHandle		   plNewMeshInterface(void);
void		plAddTriangle(plMeshInterfaceHandle meshHandle, plVector3 v0,plVector3 v1,plVector3 v2);
plCollisionShapeHandle plNewStaticTriangleMeshShape(plMeshInterfaceHandle);

void plSetScaling(plCollisionShapeHandle shape, plVector3 scaling);

///* SOLID has Response Callback/Table/Management */
///* PhysX has Triggers, User Callbacks and filtering */
///* ODE has the typedef void dNearCallback (void *data, dGeomID o1, dGeomID o2); */

///*	typedef void plUpdatedPositionCallback(void* userData, plRigidBodyHandle	rbHandle, plVector3 pos); */
///*	typedef void plUpdatedOrientationCallback(void* userData, plRigidBodyHandle	rbHandle, plQuaternion orientation); */

///* get world transform */
void	plGetOpenGLMatrix(plRigidBodyHandle object, plReal* matrix);
void	plGetPosition(plRigidBodyHandle object,plVector3 position);
void plGetOrientation(plRigidBodyHandle object,plQuaternion orientation);

///* set world transform (position/orientation) */
void plSetPosition(plRigidBodyHandle object, const plVector3 position);
void plSetOrientation(plRigidBodyHandle object, const plQuaternion orientation);
void plSetEuler(plReal yaw,plReal pitch,plReal roll, plQuaternion orient);
void plSetOpenGLMatrix(plRigidBodyHandle object, plReal* matrix);

void plSetLinearVelocity(plRigidBodyHandle object, const plVector3 velocity);
void plSetAngularVelocity(plRigidBodyHandle object, const plVector3 velocity);
void plSetRestitution(plRigidBodyHandle object, const plReal rest);

void plSetLinearFactor(plRigidBodyHandle object, const plVector3 factor);
void plSetAngularFactor(plRigidBodyHandle object, const plVector3 factor);


typedef struct plRayCastResult {
    plRigidBodyHandle		m_body;
    plCollisionShapeHandle	m_shape;
    plVector3				m_positionWorld;
    plVector3				m_normalWorld;
} plRayCastResult;

int plRayCast(plDynamicsWorldHandle world, const plVector3 rayStart,  const plVector3 rayEnd, plRayCastResult *result);

void plGetMass(plRigidBodyHandle object, plReal *mass);
void plApplyImpulse(plRigidBodyHandle object, const plVector3 impulse, const plVector3 relativePos);

void plGetLinearVelocity(plRigidBodyHandle object, plVector3 velocity);
void plGetSpeed(plRigidBodyHandle object, plReal *speed);
void plSetActivationState(plRigidBodyHandle object, int flag);
int plGetActivationState(plRigidBodyHandle object);

void plSetCollisionFlags(plRigidBodyHandle object, int flags);
int plGetCollisionFlags(plRigidBodyHandle object);

void plSetSleepingThresholds(plRigidBodyHandle object, plReal linear, plReal angular);
void plSetFriction(plRigidBodyHandle object, plReal friction);

// needed for source/blender/blenkernel/intern/collision.c
double plNearestPoints(float p1[3], float p2[3], float p3[3], float q1[3], float q2[3], float q3[3], float *pa, float *pb, float normal[3]);

]]

return bullet