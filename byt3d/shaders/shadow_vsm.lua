--
-- Created by David Lannan
-- User: grover
-- Date: 26/04/13
-- Time: 1:26 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

------------------------------------------------------------------------------------------------------------

shadow_vsm_vert = [[

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
    ShadowCoord = u_TextureMatrix * modelMatrix * vec4(vPosition, 1.0);
    gl_Position = viewProjMatrix  * modelMatrix * vec4(vPosition, 1.0);
    v_texCoord0 = vTexCoord;
}
]]

------------------------------------------------------------------------------------------------------------

shadow_vsm_frag = [[

precision highp float;
uniform sampler2D   ShadowMap;
uniform sampler2D 	s_tex0;

varying vec4    ShadowCoord;
varying vec2    v_texCoord0;

vec4 ShadowCoordPostW;

float chebyshevUpperBound( float distance)
{
	vec2 moments = texture2D(ShadowMap, ShadowCoordPostW.xy).rg;
	// Surface is fully lit. as the current fragment is before the light occluder
	if (distance - 0.002 <= moments.x)
		return 1.0;

	// The fragment is either in shadow or penumbra. We now use chebyshev's upperBound to check
	// How likely this pixel is to be lit (p_max)
	float variance = moments.y - (moments.x * moments.x);
	variance = max(variance, 0.002);

	float d = distance - moments.x;
	float p_max = variance / (variance + d*d);

	p_max = clamp(p_max, 0.0, 1.0);
	if (p_max < 0.1)
	    return 1.0;
	return (1.0-p_max);
}

void main()
{
	ShadowCoordPostW = ShadowCoord / ShadowCoord.w;
	//ShadowCoordPostW = ShadowCoordPostW * 0.5 + 0.5; This is done via a bias matrix in main.c

	float shadow = chebyshevUpperBound(ShadowCoordPostW.z);
    vec4 texel = texture2D(s_tex0, v_texCoord0);

    //float depth = gl_FragCoord.w / gl_FragCoord.z;

	gl_FragColor = vec4(shadow, shadow, shadow, 1.0) * vec4(texel.b, texel.g, texel.r, texel.a);
}
]]

------------------------------------------------------------------------------------------------------------
