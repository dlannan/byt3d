--
-- Created by David Lannan
-- User: grover
-- Date: 28/03/13
-- Time: 12:15 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

occulus_rift_shader_vert = [[
//
// Global variable definitions
//

attribute vec3 vPosition;
attribute vec2 vTexCoord;

varying vec4 	vColor;
varying vec2 	v_texCoord0;

uniform mat4 	viewProjMatrix;
uniform mat4 	modelMatrix;

uniform vec2    resolution;

const float w = 1.0;
const float h = 1.0;

const mat4 Texm = mat4(w, 0, 0, 0,  0, h, 0, 0,  0, 0, 0, 0,  0, 0, 0, 1);
const mat4 View = mat4(2, 0, 0, 0,  0, 2, 0, 0,  0, 0, 0, 0,  -1, -1, 0, 1);

//
// Function declarations
//

void xlat_main( in vec3 Position, in vec4 Color, in vec2 TexCoord, out vec4 oPosition, out vec4 oColor, out vec2 oTexCoord );

//
// Function definitions
//

void xlat_main( in vec3 Position, in vec4 Color, in vec2 TexCoord, out vec4 oPosition, out vec4 oColor, out vec2 oTexCoord ) {

    //oPosition = viewProjMatrix  * modelMatrix * vec4(Position, 1.0);
    oPosition = View * vec4(Position, 1.0);
    oTexCoord = vec2( ( Texm * vec4( TexCoord, 0.000000, 1.00000) ));
    oColor = vec4(1, 1, 1, 1);
}


//
// User varying
//
varying vec4 xlat_varying_SV_Position;

//
// Translator's entry point
//
void main() {
    vec4 xlat_temp_oPosition;
    vec4 xlat_temp_oColor;
    vec2 xlat_temp_oTexCoord;

    xlat_main( vPosition, vec4(vColor), vec2(vTexCoord), xlat_temp_oPosition, xlat_temp_oColor, xlat_temp_oTexCoord);

    gl_Position = xlat_temp_oPosition;
    xlat_varying_SV_Position = vec4( xlat_temp_oPosition);
    vColor = xlat_temp_oColor;
    v_texCoord0 = xlat_temp_oTexCoord;
}

]]


occulus_rift_shader_frag = [[

precision mediump float;

//
// Global variable definitions
//

const vec4 HmdWarpParam = vec4(1.0, 0.23, 0.23, 0.0);
const vec2 LensCenter = vec2(0.5, 0.5);
const vec2 Scale = vec2(0.5, 0.88885);
const vec2 ScaleIn = vec2(1.0, 1.125);
const vec2 ScreenCenter = vec2(0.5, 0.5);

uniform sampler2D 	s_tex0;
varying vec2 		v_texCoord0;
varying vec4 		vColor;
//
// Function declarations
//

vec4 xlat_main( in vec4 oPosition, in vec4 oColor, in vec2 oTexCoord );
vec2 HmdWarp( in vec2 in01 );

//
// Function definitions
//

vec4 xlat_main( in vec4 oPosition, in vec4 oColor, in vec2 oTexCoord ) {
    vec2 tc;

    tc = HmdWarp( oTexCoord);
    if ( any( bvec2( (clamp( tc, (ScreenCenter - vec2( 0.250000, 0.500000)), (ScreenCenter + vec2( 0.250000, 0.500000))) - tc) ) ) ){
        return vec4( 0, 0, 0, 0 );
    }

    return texture2D( s_tex0, tc );
}


vec2 HmdWarp( in vec2 in01 ) {
    vec2 theta;
    float rSq;
    vec2 theta1;

    theta = ((in01 - LensCenter) * ScaleIn);
    rSq = ((theta.x  * theta.x ) + (theta.y  * theta.y ));
    theta1 = (theta * (((HmdWarpParam.x  + (HmdWarpParam.y  * rSq)) + ((HmdWarpParam.z  * rSq) * rSq)) + (((HmdWarpParam.w  * rSq) * rSq) * rSq)));
    return (LensCenter + (Scale * theta1));
}


//
// User varying
//
varying vec4 xlat_varying_SV_Position;

//
// Translator's entry point
//
void main() {
    gl_FragColor = xlat_main( xlat_varying_SV_Position, vColor, v_texCoord0);
}

]]