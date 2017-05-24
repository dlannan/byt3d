--
-- Created by David Lannan
-- User: grover
-- Date: 6/05/13
-- Time: 9:40 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--
-- //********************************************************************************************************************

local gl   = require( "ffi/OpenGLES2" )

-- //********************************************************************************************************************

s_AOVector  = ffi.new("float[128*3]")

-- //********************************************************************************************************************
-- // geometry pass
-- //   <param> Frame-t * </param>
function Render_GeometryBegin( FPtr )

    local F         = FPtr[0]
    local D         = fFrame_Device(F)

    local Width	    = fFrame_Width(F)
    local Height	= fFrame_Height(F)

    -- // urgh..
    local ClearR	= fFrame_ClearColorR(F)
    local ClearG	= fFrame_ClearColorG(F)
    local ClearB	= fFrame_ClearColorB(F)

    -- gl.BeginQuery(gl.GL_TIME_ELAPSED, D->PerfQuery[PerfGeometry]);

    -- // render into g b uffer
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.GBufFbID)

    -- // enable all 4 outputs
    -- local buffers[] = ffi.new("u32[?]", { gl.GL_COLOR_ATTACHMENT0, gl.GL_COLOR_ATTACHMENT0, gl.GL_COLOR_ATTACHMENT0, gl.GL_COLOR_ATTACHMENT0 } )
    -- gl..gl.DrawBuffers(4, buffers)

    gl.glViewport(0, 0, Width, Height)
    gl.glScissor(0, 0, Width, Height)

    -- // clear it
    gl.glClearColor(ClearR, ClearG, ClearB, 1.0)
    gl.glClearDepthf(1.0)
    gl.glClear( bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT) )

    gl.glEnable(gl.GL_DEPTH_TEST)
    gl.glDepthFunc(gl.GL_LESS)

--    gl.glMatrixMode(gl.GL_PROJECTION)
--    gl.glLoadIdentity()
--
--    gl.MatrixMode(gl.GL_MODELVIEW);
--    gl.LoadIdentity()

    -- //gl.Flush();
    return 0
end

function Render_GeometryEnd()

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)
    --gl.EndQuery(gl.GL_TIME_ELAPSED)

    return 0
end

-- //********************************************************************************************************************
-- // shadow map gen pass

function Render_ShadowBegin(LightName, F)

    F = toFrame(L, -2)
    local D = fFrame_Device(F)

    -- //dtrace("render shadows [%s]\n", LightName);
    -- gl.BeginQuery(gl.GL_TIME_ELAPSED, D.PerfQuery[PerfShadow0 + fFrame_ShadowID(F) ]);

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.ShadowFbID)

    -- u32 buffers[] = { gl.GL_COLOR_ATTACHMENT0 };
    -- gl.glDrawBuffers(1, buffers);

    gl.glViewport(0, 0, 512, 512)
    gl.glScissor( 0, 0, 512, 512)

    gl.glClearColor(0.0, 0.0, 0.0, 0.0)
    gl.glClearDepthf(1.0)
    gl.glClear( bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT) )

    gl.glEnable(gl.GL_DEPTH_TEST)
    gl.glDepthFunc(gl.GL_LESS)
    gl.glDepthMask(gl.GL_TRUE)

--    /*
--    // show shadows
--    gl.glClearColor(0.0, 0.0, 0.0, 1.0);
--    gl.glClearDepth(0.0);
--    gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
--    gl.glDepthFunc(gl.GL_ALWAYS);
--    */
    return 0
end

-- //********************************************************************************************************************

function Render_ShadowEnd(F)

    F = toFrame(F)
    local D = fFrame_Device(F)

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)
    gl.glDepthFunc(gl.GL_LESS)

    -- gl.glEndQuery(gl.GL_TIME_ELAPSED)

    fFrame_ShadowNext(F)
    return 0
end

-- //********************************************************************************************************************
-- // render lighting
-- // hopefully the GL statck caches RT things

function Render_LightBegin( F )

    F = toFrame(F)
    local D = fFrame_Device(F)

    local fWidth  = fFrame_Width(F)
    local fHeight = fFrame_Height(F)

    -- // perf
    -- gl.glBeginQuery(gl.GL_TIME_ELAPSED, D->PerfQuery[PerfLight + fFrame_LightID(F) ]);

    -- // create material texture
    local MaterialTex = fFrame_MaterialArray(F)

    gl.glBindTexture(gl.GL_TEXTURE_2D, D.MaterialTexID)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, fFrame_MaterialMax(F), 1, 0, gl.GL_RGBA, gl.GL_FLOAT, MaterialTex)
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)

    --// render into g buffer
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.LBufFbID)

    -- // enable all 4 outputs
    -- u32 buffers[] = { gl.GL_COLOR_ATTACHMENT0, gl.GL_COLOR_ATTACHMENT0 }
    -- gl.glDrawBuffers(2, buffers)

    gl.glViewport(0, 0, fWidth, fHeight)
    gl.glScissor( 0, 0, fWidth, fHeight)

    gl.glDisable(gl.GL_DEPTH_TEST)
    gl.glDisable(gl.GL_SCISSOR_TEST)

    gl.glMatrixMode(gl.GL_PROJECTION)
    gl.glLoadIdentity()

    gl.glMatrixMode(gl.GL_MODELVIEW)
    gl.glLoadIdentity()

    return 0
end

-- //********************************************************************************************************************

function Render_LightEnd(F)

    F = toFrame(F)
    local D = fFrame_Device(F)

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)
    -- gl.glEndQuery(gl.GL_TIME_ELAPSED);

    fFrame_LightNext(F)
    return 0
end

-- //********************************************************************************************************************
-- // render bloom

function Render_Bloom(F)

    F = toFrame(F)
    local D = fFrame_Device(F)

    local  fWidth = fFrame_Width(F)
    local fHeight = fFrame_Height(F)

    local DtoF_Width  = fWidth/ D.RtWidth
    local DtoF_Height = fHeight/ D.RtHeight

    -- gl.glBeginQuery(gl.GL_TIME_ELAPSED, D->PerfQuery[PerfBloom]);

    -- // bloom
    for b=0, 3 do

        local Width	    = fWidth / (1+b)
        local Height	= fHeight / (1+b)

        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.BloomFbID[b])

        fAssert(D.ShaderBloomV ~= nil)
        fAssert(D.ShaderBloomHorizF ~= nil)

        BloomRadiusX = 3.0 / Width
        BloomRadiusY = 3.0 / Height

        gl.glViewport(0, 0, Width, Height);
        gl.glScissor(0, 0, Width, Height);
        gl.glDisable(gl.GL_DEPTH_TEST);

--    // boom horiz
--    CGparameter	BlurRadius = cgGetNamedParameter(D->ShaderBloomHorizF, "BlurRadius");
--    CHECK_CG(cgSetParameter1f(BlurRadius, BloomRadiusX));

--    // only bloom the spec component
--    CGparameter	SamplerFrame = cgGetNamedParameter(D->ShaderBloomHorizF, "samplerFrame");
--    cgGLSetTextureParameter(SamplerFrame, (b == 0) ? D->LBufTexID[1] : D->BloomTexID[b-1][1]);
--    //cgGLSetTextureParameter(SamplerFrame, D->LBufTexID[1]);

--    CHECK_CG(cgGLBindProgram(D->ShaderBloomV));
--    CHECK_CG(cgGLBindProgram(D->ShaderBloomHorizF));
--
--    CHECK_CG(cgUpdateProgramParameters(D->ShaderBloomV));
--    CHECK_CG(cgUpdateProgramParameters(D->ShaderBloomHorizF));

    -- // enable horz output
    -- u32 buffers[] = {gl.GL_COLOR_ATTACHMENT0};
    -- gl.glDrawBuffers(1, buffers);

        gl.glColor3f(1.0, 1.0, 1.0)
        gl.glBegin(gl.GL_TRIANGLE_STRIP)
        gl.glTexCoord2f(0.0*DtoF_Width, 0.0*DtoF_Height); gl.glVertex3f(-1.0, -1.0, 0.0)
        gl.glTexCoord2f(1.0*DtoF_Width, 0.0*DtoF_Height); gl.glVertex3f( 1.0, -1.0, 0.0)
        gl.glTexCoord2f(0.0*DtoF_Width, 1.0*DtoF_Height); gl.glVertex3f(-1.0,  1.0, 0.0)
        gl.glTexCoord2f(1.0*DtoF_Width, 1.0*DtoF_Height); gl.glVertex3f( 1.0,  1.0, 0.0)
        gl.glEnd()


--        -- // bloom vertical
--        CGparameter	BlurRadius = cgGetNamedParameter(D->ShaderBloomVertF, "BlurRadius");
--        CHECK_CG(cgSetParameter1f(BlurRadius, BloomRadiusY));
--
--        CGparameter	SamplerFrame = cgGetNamedParameter(D->ShaderBloomVertF, "samplerFrame");
--        cgGLSetTextureParameter(SamplerFrame, D->BloomTexID[b][0]);
--
--        CHECK_CG(cgGLBindProgram(D->ShaderBloomV));
--        CHECK_CG(cgGLBindProgram(D->ShaderBloomVertF));
--
--        CHECK_CG(cgUpdateProgramParameters(D->ShaderBloomV));
--        CHECK_CG(cgUpdateProgramParameters(D->ShaderBloomVertF));

--    // enable vert output
--    u32 buffers[] = {gl.GL_COLOR_ATTACHMENT1};
--    gl.glDrawBuffers(1, buffers);

        gl.glColor3f(1.0, 1.0, 1.0)
        gl.glBegin(gl.GL_TRIANGLE_STRIP)
        gl.glTexCoord2f(0.0*DtoF_Width, 0.0*DtoF_Height); gl.glVertex3f(-1.0, -1.0, 0.0)
        gl.glTexCoord2f(1.0*DtoF_Width, 0.0*DtoF_Height); gl.glVertex3f( 1.0, -1.0, 0.0)
        gl.glTexCoord2f(0.0*DtoF_Width, 1.0*DtoF_Height); gl.glVertex3f(-1.0,  1.0, 0.0)
        gl.glTexCoord2f(1.0*DtoF_Width, 1.0*DtoF_Height); gl.glVertex3f( 1.0,  1.0, 0.0)
        gl.glEnd()

    end

--    gl.glEndQuery(gl.GL_TIME_ELAPSED);

    return 0
end

-- //********************************************************************************************************************
-- // resolve buffers & aa

function Render_Resolve(FPtr)

    F = FPtr[0]
    local D = fFrame_Device(F)

    local fWidth = fFrame_Width(F)
    local fHeight = fFrame_Height(F)

    local DtoF_Width  = fWidth / D.RtWidth
    local DtoF_Height = fHeight / D.RtHeight

    -- gl.glBeginQuery(gl.GL_TIME_ELAPSED, D->PerfQuery[PerfRessolve])

    -- // resolve
    -- //gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fFrame_OutputFbID(F))
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D.OutputFbID)

--    local	GBuffer3 = getShaderParameter(D.ShaderResolveF, "samplerGBuffer3")
--
--    local	ToneMap = getShaderParameter(D.ShaderResolveF, "samplerToneMap")
--
--    local	LBuffer0 = getShaderParameter(D.ShaderResolveF, "samplerLBuffer0")
--    local	LBuffer1 = getShaderParameter(D.ShaderResolveF, "samplerLBuffer1")
--
--    local	BloomScale = getShaderParameter(D.ShaderResolveF, "BloomScale")
--    local	BloomMap0 = getShaderParameter(D.ShaderResolveF, "samplerBloom0")
--    local	BloomMap1 = getShaderParameter(D.ShaderResolveF, "samplerBloom1")
--    local	BloomMap2 = getShaderParameter(D.ShaderResolveF, "samplerBloom2")
--    local	BloomMap3 = getShaderParameter(D.ShaderResolveF, "samplerBloom3")
--
--    local	PostMap = getShaderParameter(D.ShaderResolveF, "samplerPost")
--
--    local	ShadowMap = getShaderParameter(D.ShaderResolveF, "samplerShadow")
--    local	AmbientMap = getShaderParameter(D.ShaderResolveF, "samplerAmbient")
--    local	CollisionMap = getShaderParameter(D.ShaderResolveF, "samplerCollision")
--
--    setTextureParameter(GBuffer3, D.GBufTexID)
--
--    setTextureParameter(LBuffer0, D.LBufTexID[0])
--    setTextureParameter(LBuffer1, D.LBufTexID[1])
--    setTextureParameter(BloomMap0, D.BloomTexID[0][1])
--    setTextureParameter(BloomMap1, D.BloomTexID[1][1])
--    setTextureParameter(BloomMap2, D.BloomTexID[2][1])
--    setTextureParameter(BloomMap3, D.BloomTexID[3][1])
--
--    setTextureParameter(PostMap, D.PBufTexID[0])
--
--    setTextureParameter(ToneMap, D.ToneMapTexID)
--    setTextureParameter(ShadowMap, D.ShadowColorTexID)
--    setTextureParameter(CollisionMap, D.CBufTexID[0])
--    setTextureParameter(CollisionMap, D.ParticleTexID)
--    setTextureParameter(AmbientMap, D.AmbientOcclusionTexID[0])
--
--    fShader_SetParam2f(D.ShaderResolveF, "texelScale", 1.0/D.RtWidth, 1.0/D.RtHeight)
--    glSetParameter1f(BloomScale, 0.3)
--
--    fAssert(D.ShaderResolveV ~= NULL)
--    fAssert(D.ShaderResolveF ~= NULL)
--
    gl.glUseProgram(D.ShaderSimpleV)
    gl.glUseProgram(D.ShaderSimpleF)
--
--    useProgramParameters(D.ShaderResolveV)
--    useProgramParameters(D.ShaderResolveF)

    gl.glViewport(0, 0, fWidth, fHeight)
    gl.glScissor(0, 0, fWidth, fHeight)
    gl.glDisable(gl.GL_DEPTH_TEST)

--    gl.glColor(1.0, 1.0, 1.0, 1.0)
--    gl.glBegin(gl.GL_TRIANGLE_STRIP)
--
--    gl.glTexCoord2f(0.0*DtoF_Width, 0.0*DtoF_Height); gl.glVertex3f(-1.0, -1.0, 0.0)
--    gl.glTexCoord2f(1.0*DtoF_Width, 0.0*DtoF_Height); gl.glVertex3f( 1.0, -1.0, 0.0)
--    gl.glTexCoord2f(0.0*DtoF_Width, 1.0*DtoF_Height); gl.glVertex3f(-1.0,  1.0, 0.0)
--    gl.glTexCoord2f(1.0*DtoF_Width, 1.0*DtoF_Height); gl.glVertex3f( 1.0,  1.0, 0.0)
--    gl.glEnd();

    local x = -1.0
    local y = -1.0
    local w = 2.0
    local h = 2.0
    local z = -0.1

    local vertexArray = gl.glGetAttribLocation(D.ShaderSimpleV, "vPosition")
    local texArray = gl.glGetAttribLocation(D.ShaderSimpleV, "v_texCoord0")

    local verts = ffi.new("float[12]", { x, y, z, x + w, y, z, x + w, y + h, z, x, y + h, z } )
    gl.glVertexAttribPointer(vertexArray, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, verts)

    local texCoords = ffi.new("float[8]", { 0.0, 0.0, 1.0*DtoF_Width, 0.0, 1.0*DtoF_Width, 1.0*DtoF_Width, 0.0, 1.0*DtoF_Width } )
    -- // Load the vertex data
    gl.glVertexAttribPointer(texArray, 2, gl.GL_FLOAT, gl.GL_FALSE, 0, texCoords)

    gl.glEnableVertexAttribArray(vertexArray)
    gl.glEnableVertexAttribArray(texArray)
--
--    gl.glActiveTexture( gl.GL_TEXTURE0 )
--    gl.glBindTexture( gl.GL_TEXTURE_2D, mesh.tex0.textureId )
--    -- // Set the sampler texture unit to 0
--    gl.glUniform1i(lshader.samplerTex[0], 0)

    local indexs = ffi.new("unsigned short[6]", { 0, 2, 1, 0, 3, 2 } )
    --gl.glDrawArrays( gl.GL_TRIANGLES, 0, 3 )
    gl.glDrawElements(gl.GL_TRIANGLES, 6, gl.GL_UNSIGNED_SHORT, indexs)
    -- gl.glEndQuery(gl.GL_TIME_ELAPSED);
    return 0
end

-- //********************************************************************************************************************
-- // aa

function Render_AA(F)

    F = toFrame(F)
    D = fFrame_Device(F)

    local fWidth = fFrame_Width(F)
    local fHeight = fFrame_Height(F)

    local DtoF_Width  = fWidth / D.RtWidth
    local DtoF_Height = fHeight / D.RtHeight

    -- gl.glBeginQuery(gl.GL_TIME_ELAPSED, D->PerfQuery[PerfAA]);

    -- // resolve
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fFrame_OutputFbID(F))

    local	ToneMap = getShaderParameter(D.ShaderAAF, "samplerOutput")

    local	GBuffer0 = getShaderParameter(D.ShaderLightF, "samplerGBuffer0")
    local	GBuffer1 = getShaderParameter(D.ShaderLightF, "samplerGBuffer1")
    local	GBuffer2 = getShaderParameter(D.ShaderLightF, "samplerGBuffer2")
    local	GBuffer3 = getShaderParameter(D.ShaderLightF, "samplerGBuffer3")

    local	LBuffer0 = getShaderParameter(D.ShaderAAF, "samplerLBuffer0")
    local	LBuffer1 = getShaderParameter(D.ShaderAAF, "samplerLBuffer1")

    local	OBuffer = getShaderParameter(D.ShaderAAF, "samplerOutBuffer")

    setTextureParameter(LBuffer0, D.LBufTexID[0])
    setTextureParameter(LBuffer1, D.LBufTexID[1])

    setTextureParameter(GBuffer0, D.GBufTexID)

    cgGLSetTextureParameter(OBuffer, D.OutputTexID)

    fShader_SetParam1f(D.ShaderAAF, "CenterScale", 8.0) --	// this is the scale factor ramp thing
    fShader_SetParam1f(D.ShaderAAF, "EdgeScale", 1.2)   --	// edge scale
    fShader_SetParam1f(D.ShaderAAF, "EdgeCutoff", 0.3)  --	// edge min threshold (before blur kicks in)
    fShader_SetParam1f(D.ShaderAAF, "CenterScale", 8.0) --	// this is the scale factor ramp thing
    fShader_SetParam2f(D.ShaderAAF, "texelScale", 1.0/D.RtWidth, 1.0/D.RtHeight)

    fAssert(D.ShaderAAV ~= nil)
    fAssert(D.ShaderAAF ~= nil)

--    CHECK_CG(cgGLBindProgram(D.ShaderAAV))
--    CHECK_CG(cgGLBindProgram(D.ShaderAAF))
--
--    CHECK_CG(cgUpdateProgramParameters(D.ShaderAAV))
--    CHECK_CG(cgUpdateProgramParameters(D.ShaderAAF))

    gl.glViewport(0, 0, fWidth, fHeight)
    gl.glScissor(0, 0, fWidth, fHeight)
    gl.glDisable(gl.GL_DEPTH_TEST)

    gl.glColor3f(1.0, 1.0, 1.0)
    gl.glBegin(gl.GL_TRIANGLE_STRIP)

    gl.glTexCoord2f(0.0*DtoF_Width, 0.0*DtoF_Height); gl.glVertex3f(-1.0, -1.0, 0.0)
    gl.glTexCoord2f(1.0*DtoF_Width, 0.0*DtoF_Height); gl.glVertex3f( 1.0, -1.0, 0.0)
    gl.glTexCoord2f(0.0*DtoF_Width, 1.0*DtoF_Height); gl.glVertex3f(-1.0,  1.0, 0.0)
    gl.glTexCoord2f(1.0*DtoF_Width, 1.0*DtoF_Height); gl.glVertex3f( 1.0,  1.0, 0.0)
    gl.glEnd();

    -- gl.glEndQuery(gl.GL_TIME_ELAPSED);
    return 0;
end

-- //********************************************************************************************************************
-- // ambient occlusion hacks

--function Render_AmbientOcclusion(F)
--
--    struct fFrame_t * F = toFrame(L, -1);
--    fDevice_t* D = fFrame_Device(F);
--
--    u32 fWidth	= fFrame_Width(F);
--    u32 fHeight	= fFrame_Height(F);
--    float Apsect	= fFrame_Aspect(F);
--
--    gl.glBeginQuery(gl.GL_TIME_ELAPSED, D->PerfQuery[PerfAmbientOcclusion]);
--
--    float DtoF_Width  = (float)fWidth/ (float)D->RtWidth;
--    float DtoF_Height = (float)fHeight/(float)D->RtHeight;
--
--    // camera projection matrix
--    fMat44 Projection = fFrame_ProjectionGet(F);
--
--    // apply apsect ratio
--    float AspectRatio	= fFrame_Aspect(F);
--    fMat44 Aspect		= fMat44_Scale(1.0, AspectRatio, 1.0);
--    Projection		= fMat44_Mul(Aspect, Projection);
--
--    // calculate gaussian coefficents
--
--    float	BlurSigma = 5.0;
--    float	BlurWeight[7];
--    double	g = 1.0 / sqrtf(2.0*3.1415*BlurSigma);
--    double  sum = 0;
--    for (int i=-3; i <= 3; i++)
--    {
--    BlurWeight[3+i] = g * exp(-( i*i) / (2.0*BlurSigma*BlurSigma) );
--    sum += BlurWeight[3+i];
--    }
--
--    // normalize
--    for (int i=-3; i <= 3; i++)
--    {
--    BlurWeight[3+i] /= sum;
--    }
--
--    // sample AO
--
--    {
--    CGprogram	ShaderVertex = D->ShaderAmbientOcclusionV;
--    CGprogram	ShaderFragment = D->ShaderAmbientOcclusionF;
--
--    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D->AmbientOcclusionFbID[0]);
--
--    fShader_SetSampler(ShaderFragment, "samplerGBuffer0", D.GBufTexID);
--
--    fShader_SetParam1f(ShaderFragment, "OcclusionRadius", 5.0);	// magic for now
--    fShader_SetParam1f(ShaderFragment, "OcclusionDScale", 2000);	// magic for now
--    fShader_SetParam2f(ShaderFragment, "texelScale", DtoF_Width, DtoF_Height);
--    fShader_SetParamArray1f(ShaderFragment, "Noise", 32*3, s_AOVector);
--
--    fShader_SetXForm(ShaderFragment, "Projection", &Projection);
--
--    CHECK_CG(cgGLBindProgram(ShaderFragment));
--    CHECK_CG(cgGLBindProgram(ShaderVertex));
--
--    CHECK_CG(cgUpdateProgramParameters(ShaderFragment));
--    CHECK_CG(cgUpdateProgramParameters(ShaderVertex));
--
--    gl.glViewport(0, 0, fWidth, fHeight);
--    gl.glScissor(0, 0, fWidth, fHeight);
--    gl.glDisable(gl.GL_DEPTH_TEST);
--
--    gl.glColor3f(1.0f, 1.0f, 1.0f);
--    gl.glBegin(gl.GL_TRIANGLE_STRIP);
--
--    gl.glTexCoord2f(0.0f*DtoF_Width, 0.0f*DtoF_Height); gl.glVertex3f(-1.0f, -1.0f, 0.0f);
--    gl.glTexCoord2f(1.0f*DtoF_Width, 0.0f*DtoF_Height); gl.glVertex3f( 1.0f, -1.0f, 0.0f);
--    gl.glTexCoord2f(0.0f*DtoF_Width, 1.0f*DtoF_Height); gl.glVertex3f(-1.0f,  1.0f, 0.0f);
--    gl.glTexCoord2f(1.0f*DtoF_Width, 1.0f*DtoF_Height); gl.glVertex3f( 1.0f,  1.0f, 0.0f);
--    gl.glEnd();
--    }
--
--    // ### horizontal AO geom blur
--
--    {
--    CGprogram	ShaderVertex	= D->ShaderAmbientOcclusionV;
--    CGprogram	ShaderFragment	= D->ShaderAmbientOcclusionBlurHF;
--
--    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D->AmbientOcclusionFbID[1]);
--
--    fShader_SetSampler(ShaderFragment, "samplerGBuffer0",	D.GBufTexID);
--    fShader_SetSampler(ShaderFragment, "samplerAO",		D.AmbientOcclusionTexID[0]);
--    fShader_SetParam1f(ShaderFragment, "BlurRadius", 1.0 / (float)fWidth);
--    fShader_SetParam1f(ShaderFragment, "ImageScale", 1.0 / (float)fWidth);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_m3", BlurWeight[0]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_m2", BlurWeight[1]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_m1", BlurWeight[2]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_0",  BlurWeight[3]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_p1", BlurWeight[4]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_p2", BlurWeight[5]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_p3", BlurWeight[6]);
--
--    CHECK_CG(cgGLBindProgram(ShaderFragment));
--    CHECK_CG(cgGLBindProgram(ShaderVertex));
--
--    CHECK_CG(cgUpdateProgramParameters(ShaderFragment));
--    CHECK_CG(cgUpdateProgramParameters(ShaderVertex));
--
--    gl.glViewport(0, 0, fWidth, fHeight);
--    gl.glScissor(0, 0, fWidth, fHeight);
--    gl.glDisable(gl.GL_DEPTH_TEST);
--
--    gl.glColor3f(1.0f, 1.0f, 1.0f);
--    gl.glBegin(gl.GL_TRIANGLE_STRIP);
--
--    gl.glTexCoord2f(0.0f*DtoF_Width, 0.0f*DtoF_Height); gl.glVertex3f(-1.0f, -1.0f, 0.0f);
--    gl.glTexCoord2f(1.0f*DtoF_Width, 0.0f*DtoF_Height); gl.glVertex3f( 1.0f, -1.0f, 0.0f);
--    gl.glTexCoord2f(0.0f*DtoF_Width, 1.0f*DtoF_Height); gl.glVertex3f(-1.0f,  1.0f, 0.0f);
--    gl.glTexCoord2f(1.0f*DtoF_Width, 1.0f*DtoF_Height); gl.glVertex3f( 1.0f,  1.0f, 0.0f);
--    gl.glEnd();
--    }
--
--    // ### vertical AO geom blur
--
--    {
--    CGprogram	ShaderVertex	= D->ShaderAmbientOcclusionV;
--    CGprogram	ShaderFragment	= D->ShaderAmbientOcclusionBlurVF;
--
--    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D->AmbientOcclusionFbID[0]);
--
--    fShader_SetSampler(ShaderFragment, "samplerGBuffer0",	D.GBufTexID);
--    fShader_SetSampler(ShaderFragment, "samplerAO", D->AmbientOcclusionTexID[1]);
--    fShader_SetParam1f(ShaderFragment, "OcclusionAmbient", 0.2);	// magic for now
--    fShader_SetParam1f(ShaderFragment, "BlurRadius", 1.0 / (float)fHeight);
--    fShader_SetParam1f(ShaderFragment, "ImageScale", 1.0 / (float)D->RtWidth);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_m3", BlurWeight[0]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_m2", BlurWeight[1]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_m1", BlurWeight[2]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_0",  BlurWeight[3]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_p1", BlurWeight[4]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_p2", BlurWeight[5]);
--    fShader_SetParam1f(ShaderFragment, "BlurWeight_p3", BlurWeight[6]);
--
--    CHECK_CG(cgGLBindProgram(ShaderFragment));
--    CHECK_CG(cgGLBindProgram(ShaderVertex));
--
--    CHECK_CG(cgUpdateProgramParameters(ShaderFragment));
--    CHECK_CG(cgUpdateProgramParameters(ShaderVertex));
--
--    gl.glViewport(0, 0, fWidth, fHeight);
--    gl.glScissor(0, 0, fWidth, fHeight);
--    gl.glDisable(gl.GL_DEPTH_TEST);
--
--    gl.glColor3f(1.0f, 1.0f, 1.0f);
--    gl.glBegin(gl.GL_TRIANGLE_STRIP);
--
--    gl.glTexCoord2f(0.0f*DtoF_Width, 0.0f*DtoF_Height); gl.glVertex3f(-1.0f, -1.0f, 0.0f);
--    gl.glTexCoord2f(1.0f*DtoF_Width, 0.0f*DtoF_Height); gl.glVertex3f( 1.0f, -1.0f, 0.0f);
--    gl.glTexCoord2f(0.0f*DtoF_Width, 1.0f*DtoF_Height); gl.glVertex3f(-1.0f,  1.0f, 0.0f);
--    gl.glTexCoord2f(1.0f*DtoF_Width, 1.0f*DtoF_Height); gl.glVertex3f( 1.0f,  1.0f, 0.0f);
--    gl.glEnd();
--    }
--
--    // apply to LBuffer
--    {
--
--    CGprogram	ShaderVertex	= D->ShaderAmbientOcclusionV;
--    CGprogram	ShaderFragment	= D->ShaderAmbientOcclusionResolveF;
--
--    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, D->LBufFbID);
--
--    CGparameter	LBuffer0	= cgGetNamedParameter(ShaderFragment, "samplerLBuffer0");
--    CGparameter	LBuffer1	= cgGetNamedParameter(ShaderFragment, "samplerLBuffer1");
--    CGparameter	AmbientMap	= cgGetNamedParameter(ShaderFragment, "samplerAmbient");
--
--    cgGLSetTextureParameter(LBuffer0, D->LBufTexID[0]);
--    cgGLSetTextureParameter(LBuffer1, D->LBufTexID[1]);
--    cgGLSetTextureParameter(AmbientMap, D->AmbientOcclusionTexID[0]);
--
--    fAssert(D->ShaderResolveV != NULL);
--    fAssert(D->ShaderResolveF != NULL);
--
--    CHECK_CG(cgGLBindProgram(ShaderVertex));
--    CHECK_CG(cgGLBindProgram(ShaderFragment));
--
--    CHECK_CG(cgUpdateProgramParameters(ShaderVertex));
--    CHECK_CG(cgUpdateProgramParameters(ShaderFragment));
--
--    gl.glViewport(0, 0, fWidth, fHeight);
--    gl.glScissor(0, 0, fWidth, fHeight);
--    gl.glDisable(gl.GL_DEPTH_TEST);
--
--    gl.glColor3f(1.0f, 1.0f, 1.0f);
--    gl.glBegin(gl.GL_TRIANGLE_STRIP);
--    gl.glTexCoord2f(0.0f*DtoF_Width, 0.0f*DtoF_Height); gl.glVertex3f(-1.0f, -1.0f, 0.0f);
--    gl.glTexCoord2f(1.0f*DtoF_Width, 0.0f*DtoF_Height); gl.glVertex3f( 1.0f, -1.0f, 0.0f);
--    gl.glTexCoord2f(0.0f*DtoF_Width, 1.0f*DtoF_Height); gl.glVertex3f(-1.0f,  1.0f, 0.0f);
--    gl.glTexCoord2f(1.0f*DtoF_Width, 1.0f*DtoF_Height); gl.glVertex3f( 1.0f,  1.0f, 0.0f);
--    gl.glEnd();
--    }
--
--    gl.glEndQuery(gl.GL_TIME_ELAPSED);
--    return 0;
-- end

-- //********************************************************************************************************************
-- // particle system

function Render_ParticleBegin(F)

    F = toFrame(F)
    local D = fFrame_Device(F)

    local fWidth	= fFrame_Width(F)
    local fHeight	= fFrame_Height(F)

    -- gl.glBeginQuery(gl.GL_TIME_ELAPSED, D->PerfQuery[PerfParticle]);

    gl.glglBindFramebuffer(gl.GL_FRAMEBUFFER, D.PBufFbID)

    -- u32 buffers[] = {gl.GL_COLOR_ATTACHMENT0};
    -- gl.glDrawBuffers(1, buffers);

    gl.glglViewport(0, 0, fWidth, fHeight)
    gl.glglScissor(0, 0, fWidth, fHeight)

    gl.glglClearColor(0, 0, 1, 0)
    gl.glglClear(gl.GL_COLOR_BUFFER_BIT)

    -- // depth test, but no write
    gl.glglDepthMask(gl.GL_FALSE)
    gl.glglEnable(gl.GL_DEPTH_TEST)
    gl.glglDepthFunc(gl.GL_LESS)

    -- // point sprite
    gl.glglEnable(gl.GL_POINT_SPRITE)
    gl.glglTexEnvi(gl.GL_POINT_SPRITE, gl.GL_COORD_REPLACE, gl.GL_TRUE)

    -- // blend particles
    gl.glglEnable(gl.GL_BLEND)
    gl.glglBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE)

    return 0
end

function Render_ParticleEnd()

    gl.glglDisable(gl.GL_BLEND)
    gl.glglDepthMask(gl.GL_TRUE)

    -- gl.glglEndQuery(gl.GL_TIME_ELAPSED);

    return 0
end

--//********************************************************************************************************************
--void fRender_Register(lua_State* L)
--{
--lua_table_register(L, -1, "Render_GeometryBegin",	Render_GeometryBegin);
--lua_table_register(L, -1, "Render_GeometryEnd",		Render_GeometryEnd);
--
--lua_table_register(L, -1, "Render_ShadowBegin",		Render_ShadowBegin);
--lua_table_register(L, -1, "Render_ShadowEnd",		Render_ShadowEnd);
--
--lua_table_register(L, -1, "Render_LightBegin",		Render_LightBegin);
--lua_table_register(L, -1, "Render_LightEnd",		Render_LightEnd);
--
--lua_table_register(L, -1, "Render_Bloom",		Render_Bloom);
--lua_table_register(L, -1, "Render_Resolve",		Render_Resolve);
--lua_table_register(L, -1, "Render_AA",			Render_AA);
--lua_table_register(L, -1, "Render_AmbientOcclusion",	Render_AmbientOcclusion);
--
--lua_table_register(L, -1, "Render_ParticleBegin",	Render_ParticleBegin);
--lua_table_register(L, -1, "Render_ParticleEnd",		Render_ParticleEnd);

function Noise()

    -- // uniform grid for the moment
    local c = 0
    for i=0, 2 do

        for j=0, 2 do

            for k=0, 2 do

                -- // any sample thats only on depth will be largely noise
                if ((i ~= 1) or (j ~= 1)) then

--                /*
--                float x = -1.0 + (float)rand() /(float)(RAND_MAX/2);
--                float y = -1.0 + (float)rand() /(float)(RAND_MAX/2);
--                float z = -1.0 + (float)rand() /(float)(RAND_MAX/2);
--                */

                    local x = -1.0 + i*(1.0/2.0)*2.0
                    local y = -1.0 + j*(1.0/2.0)*2.0
                    local z = -1.0 + k*(1.0/2.0)*2.0

                    local l = 1.0 -- //(float)rand() /(float)(RAND_MAX);

                    local ood = 1.0 / (x*x + y*y + z*z)
                    s_AOVector[c*3+0] = z  -- //*ood*l
                    s_AOVector[c*3+1] = y  -- //*ood*l
                    s_AOVector[c*3+2] = x  -- //*ood*l

                    --ftrace("%03i: %f %f %f : %i %i %i\n", c, x, y, z, i, j, k)
                    c = c + 1
                end
            end
        end
    end
end

