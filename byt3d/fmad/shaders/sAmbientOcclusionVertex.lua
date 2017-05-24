------------------------------------------------------------------------------------------------------------  
-- 
-- Autogenerated lua Vertex Shaders 
-- 
sAmbientOcclusionVertex_vert = [[  
// glslv output by Cg compiler
// cgc version 3.1.0013, build date Apr 18 2012
// command line args: -quiet -profile glslv -po version=330
// source file: sAmbientOcclusionVertex.vcg
//vendor NVIDIA Corporation
//version 3.1.0.13
//profile glslv
//program main
//var float3 position : $vin.POSITION : POSITION : 0 : 1
//var float4 color : $vin.COLOR : COLOR : 1 : 1
//var float2 tex : $vin.TEXCOORD0 : TEXCOORD0 : 2 : 1
//var float4 main.position : $vout.POSITION : HPOS : -1 : 1
//var float4 main.color : $vout.COLOR : COLOR : -1 : 1
//var float2 main.tex : $vout.TEXCOORD0 : TEXCOORD0 : -1 : 1


struct Output {
    vec4 _position2;
    vec4 _color1;
    vec2 _tex1;
};

varying vec4 COLOR;
varying vec4 TEXCOORD0;
varying vec4 cg_Vertex;
varying vec4 cg_FrontColor;
varying vec4 cg_TexCoord0;

 // main procedure, the original name was main
void main()
{

    Output _OUT;

    _OUT._position2 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
    cg_TexCoord0.xy = TEXCOORD0.xy;
    gl_Position = _OUT._position2;
    cg_FrontColor = COLOR;
    return;
} // main end
]] 
-- 
------------------------------------------------------------------------------------------------------------  