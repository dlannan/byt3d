sun_shader_frag = [[
#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 resolution;
const vec2 mouse = vec2(200.0, 200.0);

/*
 * Metaballs 101.
 * Author: Someone trying to learn this stuff.
 */

void main( void ) {

	// Frag coord to corrected 0 to 1 coordinates with 0.5, 0.5 at center.
	float aspectRatio = resolution.x / resolution.y;
	vec2 position = 2.0 * ( ( gl_FragCoord.xy / resolution.xy ) - vec2( 0.5, 0.5 ) );
	position.x *= aspectRatio;
	
	// Center mouse.
	vec2 centeredMouse = 2.0 * ( mouse - vec2( 0.5, 0.5 ) );
	centeredMouse.x *= aspectRatio; 
	
	// Distance to mouse and center.
	float distanceToCenter = length( position );
	float distanceToMouse = distance( position, centeredMouse ); 
	
	// Fragments closer to one of the centers make larger contributions to the metaballs.
	// The contribution of each metaball is added.
	float centerContribution = ( 0.4 + 0.5 * sin( time ) ) / distanceToCenter;
	float mouseContribution = 1.0 / distanceToMouse;
	float totalContribution = centerContribution + mouseContribution;
	
	// Out!
	gl_FragColor = vec4( vec3( totalContribution / 5.0 ), 1.0 );

}

]]