--
-- Created by David Lannan
-- User: grover
-- Date: 10/05/13
-- Time: 6:35 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

require("byt3d/fmad/Render/fTriMesh_h")

local gl   = require( "ffi/OpenGLES2" )

--//********************************************************************************************************************

TRIMESH_MAGIC	    = 0x1234beef

--//********************************************************************************************************************

function fTriMesh_BufferAllocVertex( M, VertexCount )

    if (M.VertexCount == VertexCount) then return end
--    // reallocate
    if (M.VertexList) then fFree(M.VertexList) end

    M.VertexList		= nil

--    // crc lists
    if (M.VertexChunkCRC) then	fFree(M.VertexChunkCRC) end

    M.VertexChunkCRC	= nil
    M.VertexCount	= VertexCount

    if (M.VertexList == nil) then

        M.VertexList = ffi.new("Vertex_t["..M.VertexCount.."]")
        M.VertexChunkCount = (1+M.VertexCount/fRealizeTriMeshVertexCount)
        M.VertexChunkCRC = ffi.new("u32["..M.VertexChunkCount.."]")
        ffi.fill(M.VertexChunkCRC, ffil.sizeof("u32")*M.VertexChunkCount, 0)
    end
end

--//********************************************************************************************************************

function fTriMesh_BufferAllocIndex( M, IndexCount)

    if (M.IndexCount == IndexCount) then return end

--    // reallocate
    if (M.IndexList) then fFree(M.IndexList) end
    M.IndexList		= nil

--    // crc lists
    if (M.IndexChunkCRC) then fFree(M.IndexChunkCRC) end
    M.IndexChunkCRC	= nil
    M.IndexCount	= IndexCount

--    //printf("mesh: %iV\n", M.VertexCount);

    if (M.IndexList == nil) then

        M.IndexList = ffi.new("Tri_t["..M.IndexCount.."]")
        M.IndexChunkCount = (1+M.IndexCount/fRealizeTriMeshIndexCount)
        M.IndexChunkCRC = ffi.new("u32["..M.IndexChunkCount.."]")
        ffi.fill(M.IndexChunkCRC, ffi.sizeof("u32")*M.IndexChunkCount, 0)
    end
end

--//********************************************************************************************************************

function fTriMesh_Packet( N, ObjectID, Data, Size, User)

    local H 	= ffi.cast("fRealizeHeader_t *", Data)
    local R		= fRealize_SceneIDFind(H.SceneID)
    if (R == nil) then return end

--    // find object
    local OL	= fRealize_ObjectList(Scene)
    fAssert(OL)

--    // get/make object
    local O		= fObject_Get(OL, fObject_TriMesh, H.NodeID, H.ObjectID)
    fAssert(O)

--    // allocaet tri mesh
    local MPtr = O.Object
    local M = nil
    if ( MPtr == nil ) then

        MPtr = ffi.new("TriMesh_t[1]")
        ffi.fill(MPtr , ffi.sizeof("fTriMesh_t"), 0)

        M = MPtr[0]
        M.Magic 	= TRIMESH_MAGIC
        M.FinishCRC	= 0xFFFFFFFF
        M.VertexCRC	= 0xffffffff
        M.IndexCRC	= 0xffffffff
        O.Object = MPtr
    end

    M = MPtr[0]
--
----    // send ack
----    // header is use to key if entire object is dirty or not. so send the current crc state
----    // not the final state
--    if(H.CmdID == fRealizeCmdID_TriMeshHeader) then
--        local Ack = ffi.new("fRealizeObjectAct_t")
--        Ack[0].NetID   	    = fMultiCast_ObjectID(N)
--        Ack[0].NodeID	    = H.NodeID
--        Ack[0].ObjectID	    = H.ObjectID
--        Ack[0].CRC32	    = M.IndexCRC + M.VertexCRC + M.MaterialID
--        Ack[0].PartPos	    = H.PartPos
--        Ack[0].PartTotal	= H.PartTotal
--        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, Ack, sizeof(Ack[0]))
--
--    elseif((H.CmdID == fRealizeCmdID_TriMeshVertex) or
--            (H.CmdID == fRealizeCmdID_TriMeshIndex) or
--            (H.CmdID == fRealizeCmdID_Collect) )
--            then
--
----        // send part crc back
--        local Ack = ffi.new("fRealizeObjectAct_t")
--        Ack[0].NetID	= fMultiCast_ObjectID(N)
--        Ack[0].NodeID	= H.NodeID
--        Ack[0].ObjectID	= H.ObjectID
--        Ack[0].CRC32	= H.CRC32
--        Ack[0].PartPos	= H.PartPos
--        Ack[0].PartTotal	= H.PartTotal
--        fMultiCast_Send(N, fRealizeMultiCast_ObjectAck, Ack, sizeof(Ack[0]))
--    end
--
----    /*
----    // crc matches then dont waste cycles processing it
----    if ((H.CmdID != fRealizeCmdID_TriMeshHeader) && (O.CRC32 == M.FinishCRC))
----        {
----    return;
----    }
----    else if (M.Online)
----        {
----            ftrace("tri mesh changed [%04i:%04i] %08x . %08x online:%i\n", H.NodeID, H.ObjectID, O.CRC32, H.CRC32, M.Online);
----            //M.Online = false;
----    }
----    */
--
--    if (M.Online) then
--
--        return
--    end

--    // process it
    if(H.CmdID == fRealizeCmdID_TriMeshHeader) then
        local RT = ffi.cast("fRealizeTriMesh_t*", Data)
--        // set object proporties
        M.FinishCRC	    = RT.Header.CRC32
        M.MaterialID	= RT.MaterialID

    elseif(H.CmdID == fRealizeCmdID_TriMeshVertex) then
        local RV = ffi.cast("fRealizeTriMeshVertex_t*", Data)
        M.VertexReceive = M.VertexReceive + RV.VertexCount

--        // alloc buffers (if needed)
        fTriMesh_BufferAllocVertex(M, RV.VertexTotal)

--        // crc match, then its already been processed
        if (M.VertexChunkCRC[RV.Sequence] == RV.Header.CRC32) then
            M.VertexDud = M.VertexDud + RV.VertexCount

        else

            for i=0, RV.VertexCount-1 do

                M.VertexList[RV.VertexOffset+i].Px = RV.List[i].Px
                M.VertexList[RV.VertexOffset+i].Py = RV.List[i].Py
                M.VertexList[RV.VertexOffset+i].Pz = RV.List[i].Pz

                M.VertexList[RV.VertexOffset+i].rgba = RV.List[i].rgba
                M.VertexList[RV.VertexOffset+i].u = RV.List[i].u
                M.VertexList[RV.VertexOffset+i].v = RV.List[i].v
                M.VertexList[RV.VertexOffset+i].pad = 0

                M.VertexList[RV.VertexOffset+i].Nx = RV.List[i].Nx
                M.VertexList[RV.VertexOffset+i].Ny = RV.List[i].Ny
                M.VertexList[RV.VertexOffset+i].Nz = RV.List[i].Nz

                M.VertexList[RV.VertexOffset+i].Tx = RV.List[i].Tx
                M.VertexList[RV.VertexOffset+i].Ty = RV.List[i].Ty
                M.VertexList[RV.VertexOffset+i].Tz = RV.List[i].Tz

                M.VertexList[RV.VertexOffset+i].Bx = RV.List[i].Bx
                M.VertexList[RV.VertexOffset+i].By = RV.List[i].By
                M.VertexList[RV.VertexOffset+i].Bz = RV.List[i].Bz
            end

    --        // be carefull here, when changing the local vs realizer structure
    --        // as the world generates the CRC based on realizer structure
            M.VertexChunkCRC[RV.Sequence] = RV.Header.CRC32
            M.VertexCRC	= 0
            for i=0, M.VertexChunkCount-1 do

                M.VertexCRC = M.VertexCRC + M.VertexChunkCRC[i];
            end
        end

    elseif(H.CmdID == fRealizeCmdID_TriMeshIndex) then

        local RI = ffi.cast("fRealizeTriMeshIndex_t*",Data)
        M.IndexReceive = M.IndexReceive + RI.IndexCount

--        // alloc buffers (if needed)
        fTriMesh_BufferAllocIndex(M, RI.IndexTotal)

--        // crc match, then its already been processed
        if (M.IndexChunkCRC[RI.Sequence] == RI.Header.CRC32) then

            M.IndexDud = M.IndexDud + RI.IndexCount
        else

            for i=0, RI.IndexCount-1 do

                M.IndexList[RI.IndexOffset+i].p0 = RI.List[i].p0
                M.IndexList[RI.IndexOffset+i].p1 = RI.List[i].p1
                M.IndexList[RI.IndexOffset+i].p2 = RI.List[i].p2
            end

--            // be carefull here, when changing the local vs realizer structure
--            // as the world generates the CRC based on realizer structure
            M.IndexChunkCRC[RI.Sequence] = RI.Header.CRC32
            M.IndexCRC	= 0
            for i=0, M.IndexChunkCount-1 do

                M.IndexCRC = M.IndexCRC + M.IndexChunkCRC[i]
            end
        end

    elseif(H.CmdID == fRealizeCmdID_Collect) then

        ftrace("----------------- collect -----------------\n")
        M.FinishCRC = 0
    end

--    //printf("tri mesh %08x %08x : %08x %08x\n", H.NodeID, H.ObjectID, M.FinishCRC, M.IndexCRC+M.VertexCRC+M.MaterialID);
--    // finished ?
    if ((M.FinishCRC == (M.IndexCRC+M.VertexCRC+M.MaterialID))) then

--        // set mesh crc
        O.CRC32 = M.FinishCRC

--        // generate vbos
        if (not M.Online) then

            local sm = os.clock()

--            // index vbo is dirty
            if (M.IndexVBOCRC ~= M.IndexCRC) then

                M.IndexVBOCRC = M.IndexCRC
                if (M.IndexVBO) then

--                    //gl.glFinish();
                    gl.glDeleteBuffers(1, M.IndexVBO)
                    M.IndexVBO = 0
                end

                local tid = ffi.new("u32[1]")
                gl.glGenBuffers(1, tid)
                M.IndexVBO = tid[0]

                fAssert(M.IndexVBO)
                fAssert(M.IndexList)

                gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, M.IndexVBO)
                gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, M.IndexCount* ffi.sizeof("Tri_t"), M.IndexList, gl.GL_STATIC_READ)
                gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, 0)
            end

--            // vertexc vbo is dirty
            if (M.VertexVBOCRC ~= M.VertexCRC) then

                M.VertexVBOCRC = M.VertexCRC
                if (M.VertexVBO) then

--                    //gl.glFinish();
                    gl.glDeleteBuffers(1, M.VertexVBO)
                    M.VertexVBO = 0
                end

--                // generate GL resources
                local temp = ffi.new("u32[1]")
                gl.glGenBuffers(1, temp)
                M.VertexVBO = temp[0]

                fAssert(M.VertexVBO)
                fAssert(M.VertexList)

                gl.glBindBuffer(gl.GL_ARRAY_BUFFER, M.VertexVBO)
                gl.glBufferData(gl.GL_ARRAY_BUFFER, M.VertexCount*ffi.sizeof("Vertex_t"), M.VertexList, gl.GL_STATIC_READ)
                gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)
                gl.glFinish();
            end

--            // stats of the mesh
            M.Online =	(M.IndexVBOCRC == M.IndexCRC) and (M.VertexVBOCRC == M.VertexCRC)
            if (M.Online == true) then

                local em = os.clock()
                ftrace("gen mesh[%04i:%04i] %fms Index:%i Vertex:%i VertexOverSend:%0.4f IndexOverSend:%0.4f\n",
                    H.NodeID, H.ObjectID,
                    (em-sm)*1e3,
                    M.IndexCount, M.VertexCount,
                    M.VertexReceive/M.VertexCount,
                    M.IndexReceive/M.IndexCount
                )
--                //ftrace("gen mesh [%04i:%04i] %08x %08x\n", H.NodeID, H.ObjectID, H.CRC32, O.CRC32);
            end
        end
    end
end

--//********************************************************************************************************************
--// actually render the bastard

function lTriMesh_Render( TBL )

--    //gl.glFinish();
    local sDraw = os.clock()

    local FPtr  = toFrame(TBL.Frame)
    local F     = FPtr[0]
    local D     = fFrame_Device(F)
    local OLPtr = TBL.ObjectList
    local OL    = OLPtr[0]

    local Mode  = TBL.Mode
    local SliceRender = false

--    // get default shaders
    local ShaderVertexDefault   = nil
    local ShaderGeometryDefault = nil
    local ShaderFragmentDefault = nil

    if (Mode == "GEOMETRY") then
--        // geom buffer
        ShaderVertexDefault	    = D.ShaderGeomV
        ShaderFragmentDefault	= D.ShaderGeomF
    elseif (Mode == "SHADOWMAP") then
--        // shadow map
        ShaderVertexDefault	    = D.ShaderShadowV
        ShaderFragmentDefault	= D.ShaderShadowF
    elseif (Mode == "COLLISION")then
--        // colllision map
        ShaderVertexDefault	    = D.ShaderCollisionV
        ShaderFragmentDefault	= D.ShaderCollisionF
    elseif (Mode == "VOXEL") then
--        // colllision map
        ShaderVertexDefault	= D.ShaderVoxelV
        ShaderGeometryDefault	= D.ShaderVoxelG
        ShaderFragmentDefault	= D.ShaderVoxelF
        SliceRender = true
    else
        ftrace("TriMesh: unknown render mode [%s]\n", Mode)
        fAssert(false)
    end

--    // calc camera info
    local World2ViewProj, View2World, iView2World
    if (Mode == "GEOMETRY") then

        local OC = fObjectList_CameraGet(OLPtr)
        if (OC == nil) then

            ftrace("no camera object\n");
            return 0
        end

        local C = (ffi.cast("fCamera_t *", OC.Object))
        fAssert(C)

--        // full world.camera xform
        local tempM     = fMat44_Mul(C.View, C.iLocal2World)
        World2ViewProj	= fMat44_Mul(C.Projection, tempM)
        View2World	    = fMat44_Mul(C.Local2World, C.iView)
        iView2World	    = fMat44_Mul(C.View, C.iLocal2World)

--        // apply apsect ratio
        local AspectRatio   = fFrame_Aspect(F)
        local Aspect		= fMat44_Scale(1.0, AspectRatio, 1.0)
        World2ViewProj		= fMat44_Mul(Aspect, World2ViewProj)

    elseif (Mode == "SHADOWMAP") then

        local OS = toObject(TBL.Light)
        if (OS == nil) then

            ftrace("no shadow object\n")
            return 0
        end

        local OSt = OS.Object
        fAssert(OSt)

        local L = OSt.Object
        fAssert(L)

        World2ViewProj	= fMat44_Mul(L.Projection, fMat44_Mul(L.View, OS.iLocal2World))
        View2World	    = fMat44_Mul(OS.Local2World, L.iView)
        iView2World	    = fMat44_Mul(L.iView, OS.iLocal2World)

    else

        fAssert(0)
    end

--    // eye position in world space
    local EyeWx = View2World.m03
    local EyeWy = View2World.m13
    local EyeWz = View2World.m23

--    //printf("render mode [%s]\n", Mode);
--    // input formats always the same
    gl.glEnableVertexAttribArray(0)
    gl.glEnableVertexAttribArray(1)
    gl.glEnableVertexAttribArray(8)
    gl.glEnableVertexAttribArray(9)
    gl.glEnableVertexAttribArray(10)
    gl.glEnableVertexAttribArray(11)

--    // get material list
    local OList	        = fObjectList_TriMeshList(OL)
    local OLFrameNo		= fObjectList_FrameNo(OL)

    local ocount = 0
    local OXPtr = OList[ocount]
    local OX = OXPtr[0]

    while (OXPtr ~= nil) do

        OX = OXPtr[0]
--        // xform
        ftrace("Object: %d  %d\n", OX.Type, OX.ObjectID)
        fAssert(OX)

--        // reference mesh object
        local OM = ffi.cast("fObject_t *",OX.Object)
--        fAssert(OM)

--        // update refrence no                                                      scene.RenderList
--        OM.FrameCount = OLFrameNo

--        // actuall mesh object
        local MPtr = ffi.cast("fTriMesh_t *", OM.Object)
        fAssert(MPtr)

        local M = MPtr[0]
        if (M.Magic ~= TRIMESH_MAGIC) then

            ftrace("magic invalid! %08x \n", M.Magic)
        end
        fAssert(M.Magic == TRIMESH_MAGIC)

--        // mesh is fully loaded ?
--        if (M.Online == false) then

--        //ftrace("%08x mesh not online %08x : %i\n", M, OM.ObjectID, M.IndexCount);
--            continue
--        end

--        // calc xforms
        local L2V = fMat44_Mul(iView2World, OX.Local2World)
        local L2W = OX.Local2World
        local W2L = OX.iLocal2World
        local L2P = fMat44_Mul(World2ViewProj, OX.Local2World)
--        //ftrace("render mesh %f% f %f : %08x : %i\n", L2V.m03, L2V.m13, L2V.m23, OM.ObjectID, M.IndexCount);

--        // shaders are all standard
        local ShaderVertex      = ShaderVertexDefault
        local ShaderFragment    = ShaderFragmentDefault
        local ShaderGeometry    = ShaderGeometryDefault

        fAssert(ShaderVertex ~= nil)
        fAssert(ShaderFragment ~= nil)

--        // updates the xforms
        fShader_SetXForm(ShaderVertex, "_modelViewProj1",	L2P)
        fShader_SetXForm(ShaderVertex, "Local2World",	OX.Local2World)
        fShader_SetXForm(ShaderVertex, "iLocal2World",	OX.iLocal2World)
        fShader_SetXForm(ShaderVertex, "Local2View",	L2V)

--        // eye position in world space
        fShader_SetParam3f(ShaderVertex, "eyeWorld", EyeWx, EyeWy, EyeWz)

        ----        // find material
        local matid = M.MaterialID
        local MtlPtr = fMaterial_Find(OL, matid)

        local MPtr = ffi.cast("fMaterial_t *", MtlPtr.Object)
        local Mtl = MPtr[0]

--        if (Mtl.Translucent == true) and (ShaderVertexDefault == D.ShaderGeomV) then
----            // only add for geom pass
----            // view space
--            local P0=ffi.new("float[4]")
--            local P1=ffi.new("float[4]")
--            local P2=ffi.new("float[4]")
--
--            local N0=ffi.new("float[3]")
--            local N1=ffi.new("float[3]")
--            local N2=ffi.new("float[3]")
--
--            local V0=ffi.new("float[3]")
--            local V1=ffi.new("float[3]")
--            local V2=ffi.new("float[3]")
--
--            local RGBA=ffi.new("u32[3]")
--
--            local I		= M.IndexList
--            local V	    = M.VertexList
--            Translucent_Material(F, Mtl)
--
----            // (painfully..) add each transparent tri to transparency list
--            for i=0, M.IndexCount-1 do
--
--                local i0 = I.p0
--                local i1 = I.p1
--                local i2 = I.p2
--                I=I+1
--
----                // xform into proj space
--                P0[0] = L2P.m00*V[i0].Px + L2P.m01*V[i0].Py + L2P.m02*V[i0].Pz + L2P.m03
--                P0[1] = L2P.m10*V[i0].Px + L2P.m11*V[i0].Py + L2P.m12*V[i0].Pz + L2P.m13
--                P0[2] = L2P.m20*V[i0].Px + L2P.m21*V[i0].Py + L2P.m22*V[i0].Pz + L2P.m23
--                P0[3] = L2P.m30*V[i0].Px + L2P.m31*V[i0].Py + L2P.m32*V[i0].Pz + L2P.m33
--
--                P1[0] = L2P.m00*V[i1].Px + L2P.m01*V[i1].Py + L2P.m02*V[i1].Pz + L2P.m03
--                P1[1] = L2P.m10*V[i1].Px + L2P.m11*V[i1].Py + L2P.m12*V[i1].Pz + L2P.m13
--                P1[2] = L2P.m20*V[i1].Px + L2P.m21*V[i1].Py + L2P.m22*V[i1].Pz + L2P.m23
--                P1[3] = L2P.m30*V[i1].Px + L2P.m31*V[i1].Py + L2P.m32*V[i1].Pz + L2P.m33
--
--                P2[0] = L2P.m00*V[i2].Px + L2P.m01*V[i2].Py + L2P.m02*V[i2].Pz + L2P.m03
--                P2[1] = L2P.m10*V[i2].Px + L2P.m11*V[i2].Py + L2P.m12*V[i2].Pz + L2P.m13
--                P2[2] = L2P.m20*V[i2].Px + L2P.m21*V[i2].Py + L2P.m22*V[i2].Pz + L2P.m23
--                P2[3] = L2P.m30*V[i2].Px + L2P.m31*V[i2].Py + L2P.m32*V[i2].Pz + L2P.m33
--
----                // xform into view space
--                V0[0] = L2V.m00*V[i0].Px + L2V.m01*V[i0].Py + L2V.m02*V[i0].Pz + L2V.m03
--                V0[1] = L2V.m10*V[i0].Px + L2V.m11*V[i0].Py + L2V.m12*V[i0].Pz + L2V.m13
--                V0[2] = L2V.m20*V[i0].Px + L2V.m21*V[i0].Py + L2V.m22*V[i0].Pz + L2V.m23
--
--                V1[0] = L2V.m00*V[i1].Px + L2V.m01*V[i1].Py + L2V.m02*V[i1].Pz + L2V.m03
--                V1[1] = L2V.m10*V[i1].Px + L2V.m11*V[i1].Py + L2V.m12*V[i1].Pz + L2V.m13
--                V1[2] = L2V.m20*V[i1].Px + L2V.m21*V[i1].Py + L2V.m22*V[i1].Pz + L2V.m23
--
--                V2[0] = L2V.m00*V[i2].Px + L2V.m01*V[i2].Py + L2V.m02*V[i2].Pz + L2V.m03
--                V2[1] = L2V.m10*V[i2].Px + L2V.m11*V[i2].Py + L2V.m12*V[i2].Pz + L2V.m13
--                V2[2] = L2V.m20*V[i2].Px + L2V.m21*V[i2].Py + L2V.m22*V[i2].Pz + L2V.m23
--
----                // normal into view space
--                N0[0] = L2V.m00*V[i0].Nx + L2V.m01*V[i0].Ny + L2V.m02*V[i0].Nz
--                N0[1] = L2V.m10*V[i0].Nx + L2V.m11*V[i0].Ny + L2V.m12*V[i0].Nz
--                N0[2] = L2V.m20*V[i0].Nx + L2V.m21*V[i0].Ny + L2V.m22*V[i0].Nz
--
--                N1[0] = L2V.m00*V[i1].Nx + L2V.m01*V[i1].Ny + L2V.m02*V[i1].Nz
--                N1[1] = L2V.m10*V[i1].Nx + L2V.m11*V[i1].Ny + L2V.m12*V[i1].Nz
--                N1[2] = L2V.m20*V[i1].Nx + L2V.m21*V[i1].Ny + L2V.m22*V[i1].Nz
--
--                N2[0] = L2V.m00*V[i2].Nx + L2V.m01*V[i2].Ny + L2V.m02*V[i2].Nz
--                N2[1] = L2V.m10*V[i2].Nx + L2V.m11*V[i2].Ny + L2V.m12*V[i2].Nz
--                N2[2] = L2V.m20*V[i2].Nx + L2V.m21*V[i2].Ny + L2V.m22*V[i2].Nz
--
--                Translucent_Triangle(F, P0, P1, P2, V0, V1, V2, N0, N1, N2, RGBA)
--            end
--            -- continue;
--        end

--        // tmap Enabled
        local temp = 0
        -- if (Mtl.TextureEnable == true) then temp = 1 end
        fShader_SetParam1i(ShaderFragment, "_enableTexture1", temp)

        --        //printf("material tex: %08x, %i : %f %f %f\n", Mtl, Mtl.TextureEnable, Mtl.DiffuseR, Mtl.DiffuseG, Mtl.DiffuseB);
--        // diffuse color
        fShader_SetParam3f(ShaderFragment, "_diffuseColor1", Mtl.DiffuseR, Mtl.DiffuseG, Mtl.DiffuseB)

--        // texture
--        // variable it is to be mapped to
        fShader_SetTexture(ShaderFragment, "_MapDiffuseColor1",	OL, Mtl.TextureDiffuseObjectID, D.DefaultTextureID)
--        fShader_SetTexture(ShaderFragment, "MapEnv",		    OL, Mtl.TextureEnvObjectID, D.EnvTexID)

--        // add material
        local MaterialID = fFrame_MaterialAdd(F, Mtl.Roughness, Mtl.Attenuation, Mtl.Ambient, 0)

        fShader_SetParam1i(ShaderFragment, "_MaterialID1", MaterialID)

--        // update to device
        gl.glUseProgram(ShaderVertex)
--        if (ShaderGeometry) then CHECK_CG(gl.glUseProgram(ShaderGeometry)) end
        gl.glUseProgram(ShaderFragment)
--        // set it
--        CHECK_CG(cgUpdateProgramParameters(ShaderVertex));
--        if (ShaderGeometry) CHECK_CG(cgUpdateProgramParameters(ShaderGeometry));
--        CHECK_CG(cgUpdateProgramParameters(ShaderFragment));

--        // queue the mesh
        fAssert(M.VertexVBO ~= nil)
        fAssert(M.IndexVBO ~= nil)

        gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, M.IndexVBO)
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, M.VertexVBO)

        gl.glVertexAttribPointer(0, 3,	gl.GL_FLOAT, 		false, ffi.sizeof("Vertex_t"), ffi.cast("void*", ffi.offsetof("Vertex_t", "Px")))
        gl.glVertexAttribPointer(1, 4,	gl.GL_UNSIGNED_BYTE,false, ffi.sizeof("Vertex_t"), ffi.cast("void*", ffi.offsetof("Vertex_t", "rgba")))
        gl.glVertexAttribPointer(8, 2,	gl.GL_FLOAT, 		false, ffi.sizeof("Vertex_t"), ffi.cast("void*", ffi.offsetof("Vertex_t", "u")) )
        gl.glVertexAttribPointer(9, 3,	gl.GL_FLOAT, 		false, ffi.sizeof("Vertex_t"), ffi.cast("void*", ffi.offsetof("Vertex_t", "Nx")))
        gl.glVertexAttribPointer(10, 3,	gl.GL_FLOAT, 		false, ffi.sizeof("Vertex_t"), ffi.cast("void*", ffi.offsetof("Vertex_t", "Tx")))
        gl.glVertexAttribPointer(11, 3,	gl.GL_FLOAT, 		false, ffi.sizeof("Vertex_t"), ffi.cast("void*", ffi.offsetof("Vertex_t", "Bx")))

        gl.glDrawElements(gl.GL_TRIANGLES, M.IndexCount*3, gl.GL_UNSIGNED_INT, nil)

        D.VertexAcc	= D.VertexAcc + M.VertexCount
        D.TriAcc	= D.TriAcc + M.IndexCount

        ocount = ocount + 1
        OXPtr = OList[ocount]
    end

    gl.glDisableVertexAttribArray(0)
    gl.glDisableVertexAttribArray(1)
    gl.glDisableVertexAttribArray(8)
    gl.glDisableVertexAttribArray(9)
    gl.glDisableVertexAttribArray(10)
    gl.glDisableVertexAttribArray(11)

--    // make sure to disable any stray arrays
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)
    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, 0)

    return 0
end

--//********************************************************************************************************************

function fTriMesh_Destroy( O )

    local M = O.Object
    if (M == nil) then return end

    if (M.IndexChunkCRC ~= nil) then

        fFree(M.IndexChunkCRC)
        M.IndexChunkCRC = nil
    end

    if (M.VertexChunkCRC) then

        fFree(M.VertexChunkCRC)
        M.VertexChunkCRC = nil
    end

    if (M.IndexList) then

        fFree(M.IndexList)
        M.IndexList = nil
    end

    if (M.VertexList) then

        fFree(M.VertexList)
        M.VertexList = nil
    end

    if (M.VertexVBO) then

        gl.glDeleteBuffers(1, M.VertexVBO)
        M.VertexVBO = 0
    end

    if (M.IndexVBO) then

        gl.glDeleteBuffers(1, M.IndexVBO)
        M.IndexVBO = 0
    end

    ffi.fill(M, ffi.sizeof("fTriMesh_t"), 0)
    fFree(M)
end

--//********************************************************************************************************************

--function fTriMesh_Register(L)
--{
--lua_table_register(L, -1, "TriMesh_Render",		lTriMesh_Render);
--return 0;
--}
