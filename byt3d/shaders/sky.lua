
------------------------------------------------------------------------------------------------------------

sky_shader_vert = [[
	attribute vec3 	vPosition;  
	attribute vec2	vTexCoord;
	uniform vec2 	resolution;
	uniform float 	time;	
	uniform mat4 	viewProjMatrix; 
	uniform mat4 	modelMatrix;	
	varying vec3 	v_texCoord0;
	void main()
	{
		gl_Position = (viewProjMatrix * modelMatrix) * vec4(vPosition, 1.0);
	    v_texCoord0 = vPosition;
	}
]]

------------------------------------------------------------------------------------------------------------

sky_shader_frag = [[

#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 	resolution;
varying vec3		v_texCoord0;
	
mat2 m = mat2( 0.90,  0.110, -0.70,  1.00 );

float hash( float n )
{
    return fract(sin(n)*758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    //f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + p.z*800.0;
    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x), mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
		    mix(mix( hash(n+800.0), hash(n+801.0),f.x), mix( hash(n+857.0), hash(n+858.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f = 0.0;
    f += 0.50000*noise( p ); p = p*2.02;
    f += 0.25000*noise( p ); p = p*2.03;
    f += 0.12500*noise( p ); p = p*2.01;
    f += 0.06250*noise( p ); p = p*2.04;
    f += 0.03125*noise( p );
    return f/0.984375;
}

float cloud(vec3 p)
{
	float a =0.0;
	a+=fbm(p*3.0)*2.2-0.9;
	if (a<0.0) a=0.0;
	//a=a*a;
	return a;
}

vec3 f2(vec3 c)
{
	c+=hash(time+gl_FragCoord.x*0.1+gl_FragCoord.y*9.9)*0.01;
	
	
	c*=0.7-length(gl_FragCoord.xy / resolution.xy -0.5)*0.3;
	float w=length(c);
	c=mix(c*vec3(1.0,1.2,1.6),vec3(w,w,w)*vec3(1.4,1.2,1.0),w*1.1-0.2);
	return c;
}

void main( void ) {

	float gnd = max(v_texCoord0.y, 0.0);
	vec2 position = gl_FragCoord.xy / resolution.xy ;
	position.y = gnd * 0.006 + 0.4;
	
	vec2 coord = vec2((position.x-0.5)/position.y, 1.0/(position.y));
	
	coord += fbm(vec3(coord*18.0,time*0.001))*0.07;
	coord += time*0.01;
	
	float q = cloud(vec3(coord*1.0,time*0.0222));
	float qx= cloud(vec3(coord+vec2(0.156,0.0),time*0.0222));
	float qy= cloud(vec3(coord+vec2(0.0,0.156),time*0.0222));
	q+=qx+qy; q*=0.33333;
	qx=q-qx;
	qy=q-qy;
	
	float s =(-qx-qy+0.1); if (s<-0.05) s=-0.05;
	vec3 d=s*vec3(0.9,0.8,0.6);
	//d=max(vec3(0.0),d);
	//d+=0.1;
	d*=0.2;
	d=mix(vec3(1.0,1.0,1.0)*0.1+d*2.0,vec3(1.0,1.0,1.0)*0.8,1.0-pow(q,0.02)*1.1);
	d*=8.0;
	
	vec3 col = mix(vec3(0.2, 0.3, 0.4) / (position.y * 0.5+0.7),d,q);
	gnd = min(gnd, 1.0);
	gl_FragColor = vec4( f2(col) * gnd, 1.0 );
}

]]