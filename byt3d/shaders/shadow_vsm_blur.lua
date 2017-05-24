--
-- Created by David Lannan
-- User: grover
-- Date: 26/04/13
-- Time: 1:24 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

------------------------------------------------------------------------------------------------------------

shadow_vsm_blur_vert = [[

	attribute vec3 vPosition;
	attribute vec2 vTexCoord;

	uniform float 	time;
	uniform vec2 	resolution;

	varying vec4 	vColor;
	varying vec2 	v_texCoord0;

void main()
{
    gl_Position =  vec4(vPosition.xyz, 1.0);
    v_texCoord0 = vTexCoord;
}
]]

------------------------------------------------------------------------------------------------------------

shadow_vsm_blur_frag = [[

/////////////////////////////////////////////////
// 7x1 gaussian blur fragment shader
/////////////////////////////////////////////////

precision mediump float;
uniform sampler2D 	s_tex0;
varying vec2 		v_texCoord0;
varying vec4 		vColor;
uniform vec2        u_Scale;

// Portability prevented us from using a const array of vec2
// Mac shader compiler don't support it.
/*
const vec2 gaussFilter[7] =
{
	-3.0,	0.015625,
	-2.0,	0.09375,
	-1.0,	0.234375,
	0.0,	0.3125,
	1.0,	0.234375,
	2.0,	0.09375,
	3.0,	0.015625
};
*/

void main()
{
	vec4 color = vec4(0.0);
	//for( int i = 0; i < 9; i++ )
	//{
	//	color += texture2D( s_tex0, v_texCoord0.st + vec2( gaussFilter[i].x*u_Scale.x, gaussFilter[i].x*u_Scale.y ) )*gaussFilter[i].y;
	//}
	color += texture2D( s_tex0, v_texCoord0.st + vec2( -3.0*u_Scale.x, -3.0*u_Scale.y ) ) * 0.015625;
	color += texture2D( s_tex0, v_texCoord0.st + vec2( -2.0*u_Scale.x, -2.0*u_Scale.y ) ) * 0.09375;
	color += texture2D( s_tex0, v_texCoord0.st + vec2( -1.0*u_Scale.x, -1.0*u_Scale.y ) ) * 0.234375;
	color += texture2D( s_tex0, v_texCoord0.st + vec2( 0.0 , 0.0) ) * 0.3125;
	color += texture2D( s_tex0, v_texCoord0.st + vec2( 1.0*u_Scale.x,  1.0*u_Scale.y ) ) * 0.234375;
	color += texture2D( s_tex0, v_texCoord0.st + vec2( 2.0*u_Scale.x,  2.0*u_Scale.y ) ) * 0.09375;
	color += texture2D( s_tex0, v_texCoord0.st + vec2( 3.0*u_Scale.x, -3.0*u_Scale.y ) ) * 0.015625;

	gl_FragColor = color;
}

]]

------------------------------------------------------------------------------------------------------------

