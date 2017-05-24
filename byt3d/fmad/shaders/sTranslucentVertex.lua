------------------------------------------------------------------------------------------------------------  
-- 
-- Autogenerated lua Vertex Shaders 
-- 
sTranslucentVertex_vert = [[  
// glslv output by Cg compiler
// cgc version 3.1.0013, build date Apr 18 2012
// command line args: -quiet -profile glslv -po version=330
// source file: sTranslucentVertex.vcg
//vendor NVIDIA Corporation
//version 3.1.0.13
//profile glslv
//program main
//semantic main.Proj
//var float4 position : $vin.POSITION : POSITION : 0 : 1
//var float4 color : $vin.COLOR : COLOR : 1 : 1
//var float3 N : $vin.TEXCOORD0 : TEXCOORD0 : 2 : 1
//var float4 M : $vin.TEXCOORD1 : TEXCOORD1 : 3 : 1
//var float3 V : $vin.TEXCOORD2 : TEXCOORD2 : 4 : 1
//var float4 main.position : $vout.POSITION : HPOS : -1 : 1
//var float4 main.color : $vout.COLOR : COLOR : -1 : 1
//var float3 main.N : $vout.TEXCOORD0 : TEXCOORD0 : -1 : 1
//var float4 main.M : $vout.TEXCOORD1 : TEXCOORD1 : -1 : 1
//var float3 main.V : $vout.TEXCOORD2 : TEXCOORD2 : -1 : 1

struct Output {
    vec4 _position2;
    vec4 _color1;
    vec3 _N1;
    vec4 _M1;
    vec3 _V1;
};

varying vec4 COLOR;
varying vec4 TEXCOORD0;
varying vec4 TEXCOORD1;
varying vec4 TEXCOORD2;
varying vec4 cg_Vertex;
varying vec4 cg_FrontColor;
varying vec4 cg_TexCoord1;
varying vec4 cg_TexCoord0;
varying vec4 cg_TexCoord2;

 // main procedure, the original name was main
void main()
{


    cg_TexCoord2.xyz = TEXCOORD2.xyz;
    cg_TexCoord0.xyz = TEXCOORD0.xyz;
    cg_TexCoord1 = TEXCOORD1;
    gl_Position = cg_Vertex;
    cg_FrontColor = COLOR;
    return;
} // main end
]] 
-- 
------------------------------------------------------------------------------------------------------------  
