liquid_blue_shader_frag = [[

#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float scale = 2.3;

vec3 getColour(vec2 p)
{
	// background color
	vec3 color = vec3(0.5,1.5,3.2);
	
	for(float i = 0.0; i < 5.0; ++i) {
		
		p.x += cos((time / 10.0) + p.y);
		p.y += sin((time / 10.0) + p.x);
		
		p.x *= scale + (i / 10.0);
		p.y *= scale + (i / 10.0);
		
		float fTemp = abs(((p.x * 0.5) / (p.y * 1.0)) / 150.0);
		float r = fTemp * (sin(p.x * 0.5) * 100.0) - 0.02;
		float g = fTemp * (cos(p.y * 0.5) * 100.0) + 0.02;
		float b = fTemp * (cos(-p.x * 0.5) * 100.0) - 0.02;
		
		color += vec3(r,g,b);
	}
	return color;
}

void main(void) {
	vec2 uPos = ( gl_FragCoord.xy / resolution.xy );//normalize wrt y axis
	uPos.x += (time+10.) / 12.0;
	uPos.y -= (time+10.) / 10.0;

	vec3 lum=vec3(0.299,0.587,0.114);

	vec3 l=normalize(vec3(-0.5,-0.5,1.0));
	vec2 s=vec2(0.0,0.001);

	vec3 c1=getColour(uPos);
	vec3 c2=getColour(uPos+s.xy);
	vec3 c3=getColour(uPos+s.yx);

	float s1=dot(c1,lum);
	float s2=dot(c2,lum);
	float s3=dot(c3,lum);
	
	vec3 n=normalize(vec3(s1,s2,s3));

	float fSpec=dot(l,n)*30.0;
	vec3 c=(c1/5.0)+fSpec;

	gl_FragColor=vec4(c,1.0);
}

]]