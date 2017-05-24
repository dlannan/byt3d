--
-- Created by David Lannan
-- User: grover
-- Date: 26/04/13
-- Time: 1:21 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

------------------------------------------------------------------------------------------------------------

shadow_vsm_storedepth_vert = [[
attribute vec3 	vPosition;

uniform mat4 	viewProjMatrix;
uniform mat4 	modelMatrix;

varying vec4    v_position;

void main()
{
    v_position =  viewProjMatrix  * modelMatrix * vec4(vPosition, 1.0);
    gl_Position = v_position;
}

]]

------------------------------------------------------------------------------------------------------------

shadow_vsm_storedepth_frag = [[
#extension GL_OES_standard_derivatives : enable

precision highp float;

varying vec4    v_position;

void main()
{
    float depth = v_position.z / v_position.w ;
    //Don't forget to move away from unit cube ([-1,1]) to [0,1] coordinate system
    depth = depth * 0.5 + 0.5;

    float moment1 = depth;
    float moment2 = depth * depth;

    // Adjusting moments (this is sort of bias per pixel) using derivative
    float dx = dFdx(depth);
    float dy = dFdy(depth);
    moment2 += 0.25*(dx*dx+dy*dy) ;

    gl_FragColor = vec4( moment1, moment2, 0.0, 0.0 );
}

]]

------------------------------------------------------------------------------------------------------------
