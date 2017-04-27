--
-- Created by IntelliJ IDEA.
-- User: grover
-- Date: 3/03/13
-- Time: 2:19 PM
-- To change this template use File | Settings | File Templates.
--

------------------------------------------------------------------------------------------------------------

terrain_shader_vert = [[
	attribute vec3 	vPosition;
	attribute vec2	vTexCoord;
	uniform vec2 	resolution;
	uniform float 	time;
	uniform mat4 	viewProjMatrix;
	uniform mat4 	modelMatrix;
	varying vec2 	v_texCoord0;
	void main()
	{
		gl_Position = (viewProjMatrix * modelMatrix) * vec4(vPosition, 1.0);
	    v_texCoord0 = vPosition.xz * 0.001 + 0.5;
	}
]]

------------------------------------------------------------------------------------------------------------

terrain_shader_frag = [[
	precision highp float;
	uniform sampler2D 	s_tex0;
	varying vec2 		v_texCoord0;
	void main()
	{
		vec4 texel = texture2D(s_tex0, v_texCoord0);
		gl_FragColor = vec4(texel.b, texel.g, texel.r, texel.a);
	}
]]

------------------------------------------------------------------------------------------------------------
