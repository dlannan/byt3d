------------------------------------------------------------------------------------------------------------

colour_shader = [[
	attribute vec3 vPosition;
	attribute vec2 vTexCoord; 
	
	uniform float 	time;
	uniform vec2 	resolution;
	
	varying vec4 	vColor;
	varying vec2 	v_texCoord0;
	
	void main() {
	    vColor = vec4(1.0, 1.0, 1.0, 1.0); 
	    gl_Position =  vec4(vPosition.xyz, 1.0);
	    v_texCoord0 = vTexCoord;
	}
]]

------------------------------------------------------------------------------------------------------------
-- WARNING: Do not change this shader. It is built for the use of Cairo, and thus needs
--			to swap B and R to correct the output. This is the best place to do this because
--			it is minimal performance impact.
gui_shader = [[
	precision mediump float;
	uniform sampler2D 	s_tex0;
	varying vec2 		v_texCoord0;
	varying vec4 		vColor;
	void main() 
	{
		vec4 texel = texture2D(s_tex0, v_texCoord0);
		gl_FragColor = vec4(texel.b, texel.g, texel.r, texel.a) * vColor;
	}
]]

------------------------------------------------------------------------------------------------------------
