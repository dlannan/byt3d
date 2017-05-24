--
-- Created by David Lannan
-- User: grover
-- Date: 9/05/13
-- Time: 7:45 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

require("byt3d/fmad/Render/fTranslucent_h")

-- //********************************************************************************************************************
-- // alpha tris system

function Translucent_Render(OL, F)

    F	    = toFrame(F)
    local D	= fFrame_Device(F)
    OL      = toObjectList(OL)

    local fWidth	= fFrame_Width(F)
    local fHeight	= fFrame_Height(F)

--    // get camera
    OC = fObjectList_CameraGet(OL)
    if(OC == nil) then

        ftrace("no camera object\n")
        return 0
    end

    local C = OC.Object
    fAssert(C)
--    // urgh.. more nastyness... sort each tri based on centroid
    for T=0, s_TriCount-1 do

        local MaxDepth = -10e9
        local Index = -1
        for i=0, s_TriCount-1 do

            if (s_Centroid[i] > MaxDepth) then

                MaxDepth = s_Centroid[i]
                Index = i
            end
        end

--        // add index
        s_IndexSort[T*3+0] = Index*3 + 0
        s_IndexSort[T*3+1] = Index*3 + 1
        s_IndexSort[T*3+2] = Index*3 + 2

--        // nullify centroid
        s_Centroid[Index] = -10e9;
    end

--    // copy vbo data
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, D.TranslucentVBO)
    gl.glBufferData(gl.GL_ARRAY_BUFFER, s_TriCount*sizeof(Vertex_t)*3, s_Vertex, gl.GL_STATIC_READ)

--    // copy index data
    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, D.TranslucentIBO)
    gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, s_TriCount*3*ffi.sizeof("u32"), s_IndexSort, gl.GL_STATIC_READ)

--    // render direclty into L buffer
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.LBufFbID)

--    // enable all 2 outputs
--    u32 buffers[] = { gl.GL_COLOR_ATTACHMENT0, gl.GL_COLOR_ATTACHMENT1};
--    gl.glDrawBuffers(2, buffers);

    gl.glViewport(0, 0, fWidth, fHeight)
    gl.glScissor( 0, 0, fWidth, fHeight)

    gl.glEnable(gl.GL_DEPTH_TEST)
    gl.glDepthMask(gl.GL_FALSE)
    gl.glDisable(gl.GL_SCISSOR_TEST)

    gl.glMatrixMode(gl.GL_PROJECTION)
    gl.glLoadIdentity()

    gl.glMatrixMode(gl.GL_MODELVIEW)
    gl.glLoadIdentity()

--    // sahder
    local ShaderVertex	= D.ShaderTranslucentV
    local ShaderFragment= D.ShaderTranslucentF

--    // light info
--    // light space -> view space

    local World2View = fMat44_Mul(C.View, C.iLocal2World)

--    // view -> world
    local View2World = fMat44_Mul(C.Local2World, C.iView)

    local LightList = fObjectList_LightList(OL)
    local LightCount = 0
    while (LightList[0] ~= nil) do

        local OX		= LightList[0]
        fAssert(OX)

        local O		= OX.Object
        fAssert(O)

        local I		= O.Object
        fAssert(I)

        local Light2View = fMat44_Mul(World2View, OX.Local2World)

--        // light in view space (position in light space, not light view space)
        local PLx = I.PositionX
        local PLy = I.PositionY
        local PLz = I.PositionZ

        local PVx = PLx*Light2View.m00 + PLy*Light2View.m01 + PLz*Light2View.m02 + Light2View.m03
        local PVy = PLx*Light2View.m10 + PLy*Light2View.m11 + PLz*Light2View.m12 + Light2View.m13
        local Vz = PLx*Light2View.m20 + PLy*Light2View.m21 + PLz*Light2View.m22 + Light2View.m23

--        //printf("trans %f %f %f : %f %f %f\n", PVx, PVy, PVz,  OX->Local2World.m03,  OX->Local2World.m13,  OX->Local2World.m23);
--        // direction into view space

        local DVx = Light2View.m00*I.DirectionX + Light2View.m01*I.DirectionY + Light2View.m02*I.DirectionZ
        local DVy = Light2View.m10*I.DirectionX + Light2View.m11*I.DirectionY + Light2View.m12*I.DirectionZ
        local DVz = Light2View.m20*I.DirectionX + Light2View.m21*I.DirectionY + Light2View.m22*I.DirectionZ

--        // update texture
        local Info = s_LightTexture[LightCount]

        Info.ColorDiffuseR	= I.ColorDiffuseR
        Info.ColorDiffuseG	= I.ColorDiffuseG
        Info.ColorDiffuseB	= I.ColorDiffuseB

        Info.ColorSpecularR	= I.ColorSpecularR
        Info.ColorSpecularG	= I.ColorSpecularG
        Info.ColorSpecularB	= I.ColorSpecularB

        Info.PositionX		= PVx
        Info.PositionY		= PVy
        Info.PositionZ		= PVz

        Info.DirectionX	= DVx
        Info.DirectionY	= DVy
        Info.DirectionZ	= DVz

        Info.Falloff0		= I.Falloff0
        Info.Falloff1		= I.Falloff1
        Info.Falloff2		= I.Falloff2

        Info.Intensity		= I.Intensity

        LightCount=LightCount+1
        LightList=LightList+1
    end

--    CGparameter	pLightCount	= cgGetNamedParameter(ShaderFragment, "LightCount")
--    CHECK_CG(cgSetParameter1f(pLightCount, LightCount))

--    // update light info
    gl.glBindTexture(gl.GL_TEXTURE_2D, D.LightTexID)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA32F_ARB, 4096, 1, 0, gl.GL_RGBA, gl.GL_FLOAT, s_LightTexture)
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)

--    CGparameter	pLightInfo = cgGetNamedParameter(ShaderFragment, "samplerLightInfo");
--    cgGLSetTextureParameter(pLightInfo, D->LightTexID);

--    // update to device
--    CHECK_CG(cgGLBindProgram(ShaderVertex));
--    CHECK_CG(cgGLBindProgram(ShaderFragment));

--    // set it
--    CHECK_CG(cgUpdateProgramParameters(ShaderVertex));
--    CHECK_CG(cgUpdateProgramParameters(ShaderFragment));

--    // blending
--    gl.glEnable(gl.GL_BLEND);
--    gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA);

--    // queue the mesh
    gl.glEnableVertexAttribArray(0)
    gl.glEnableVertexAttribArray(1)
    gl.glEnableVertexAttribArray(8)
    gl.glEnableVertexAttribArray(9)
    gl.glEnableVertexAttribArray(10)
--    //gl.glEnableVertexAttribArray(11)

    gl.glVertexAttribPointer(0, 4,	gl.GL_FLOAT, 		false, ffi.sizeof("Vertex_t"), offsetof(Vertex_t, Px))
    gl.glVertexAttribPointer(1, 4,	gl.GL_UNSIGNED_BYTE, 	false, ffi.sizeof("Vertex_t"), offsetof(Vertex_t, rgba))
    gl.glVertexAttribPointer(8, 3,	gl.GL_FLOAT, 		false, ffi.sizeof("Vertex_t"), offsetof(Vertex_t, Nx))
    gl.glVertexAttribPointer(9, 4,	gl.GL_FLOAT, 		false, ffi.sizeof("Vertex_t"), offsetof(Vertex_t, Roughness))
    gl.glVertexAttribPointer(10, 3,	gl.GL_FLOAT, 		false, ffi.sizeof("Vertex_t"), offsetof(Vertex_t, Vx))

    gl.glDrawElements(gl.GL_TRIANGLES, s_TriCount*3, gl.GL_UNSIGNED_INT, 0)

    gl.glDisableVertexAttribArray(0)
    gl.glDisableVertexAttribArray(1)
    gl.glDisableVertexAttribArray(8)
    gl.glDisableVertexAttribArray(9)
    gl.glDisableVertexAttribArray(10)
--    //gl.glDisableVertexAttribArray(11);

--    // make sure to disable any stray arrays
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)
    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, 0)

    gl.glDepthMask(gl.GL_TRUE)
    gl.glDisable(gl.GL_BLEND)

--    //dtrace("%i\n", s_TriCount);
    s_TriCount = 0

    return 0
end

-- //********************************************************************************************************************
function Translucent_Material(Frame, M)

    s_Material = M
end

--//********************************************************************************************************************
--// this is just nasty ass shit.... but im a lazy cunt at the moment. only a few hundered alpha polys.. so hmm

function Translucent_Triangle(Frame, P0, P1, P2, V0, V1, V2, N0, N1, N2, RGBA )

    local V	= s_Vertex[s_TriCount*3]

    local R		=  s_Material.Roughness
    local A		=  s_Material.Attenuation
    local K		=  s_Material.Ambient
    local O		=  s_Material.Opacity

    V.Px		= P0[0]		-- // proj space position
    V.Py		= P0[1]
    V.Pz		= P0[2]
    V.Pw		= P0[3]
    V.Vx		= V0[0]		-- // view space position
    V.Vy		= V0[1]
    V.Vz		= V0[2]
    V.Nx		= N0[0]		-- // view space normal
    V.Ny		= N0[1]
    V.Nz		= N0[2]
    V.Roughness	= R
    V.Attenuation	= A
    V.Ambient	= K
    V.Opacity	= O
    V = V+1

    V.Px		= P1[0]
    V.Py		= P1[1]
    V.Pz		= P1[2]
    V.Pw		= P1[3]
    V.Vx		= V1[0]		-- // view space position
    V.Vy		= V1[1]
    V.Vz		= V1[2]
    V.Nx		= N1[0]
    V.Ny		= N1[1]
    V.Nz		= N1[2]
    V.Roughness	= R
    V.Attenuation	= A
    V.Ambient	= K
    V.Opacity	= O
    V = V + 1

    V.Px		= P2[0]
    V.Py		= P2[1]
    V.Pz		= P2[2]
    V.Pw		= P2[3]
    V.Vx		= V2[0]		-- // view space position
    V.Vy		= V2[1]
    V.Vz		= V2[2]
    V.Nx		= N2[0]
    V.Ny		= N2[1]
    V.Nz		= N2[2]

    V.Roughness	= R
    V.Attenuation	= A
    V.Ambient	= K
    V.Opacity	= O
    V=V+1

    s_Centroid[s_TriCount] = (P0[2] + P1[2] + P2[2]) * (1.0 / 3)

    s_TriCount=s_TriCount+1
    return 0
end

-- //********************************************************************************************************************
--void fTranslucent_Register(lua_State* L)
--{
--    lua_table_register(L, -1, "Render_Translucent",	Translucent_Render);
--}
