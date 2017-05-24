--
-- Created by David Lannan
-- User: grover
-- Date: 26/04/13
-- Time: 1:26 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

------------------------------------------------------------------------------------------------------------

shadow_simple_vert = [[

attribute vec3 	vPosition;
attribute vec2	vTexCoord;

uniform mat4 	viewProjMatrix;
uniform mat4 	modelMatrix;
uniform mat4    u_TextureMatrix;

// Used for shadow lookup
varying vec4    ShadowCoord;
varying vec2    v_texCoord0;

void main()
{
    ShadowCoord = u_TextureMatrix * vec4(vPosition, 1.0);
    gl_Position = viewProjMatrix  * modelMatrix * vec4(vPosition, 1.0);
    v_texCoord0 = vTexCoord;
}

]]

------------------------------------------------------------------------------------------------------------

shadow_simple_frag = [[

precision highp float;
uniform sampler2D 	s_tex0;
uniform sampler2D   ShadowMap;

varying vec4    ShadowCoord;
varying vec2    v_texCoord0;

void main()
{
	vec4 shadowCoordinateWdivide = ShadowCoord / ShadowCoord.w ;

	// Used to lower moiré pattern and self-shadowing
	shadowCoordinateWdivide.z += 0.0005;

	float distanceFromLight = texture2D(ShadowMap,shadowCoordinateWdivide.st).z;

 	float shadow = 1.0;
 	if (ShadowCoord.w > 0.0)
 		shadow = distanceFromLight < shadowCoordinateWdivide.z ? 0.5 : 1.0 ;

  	vec4 texel = texture2D(s_tex0, v_texCoord0);
  	gl_FragColor =	vec4(1.0, 0.0, 0.0, 1.0); //texel;
}

]]

------------------------------------------------------------------------------------------------------------
