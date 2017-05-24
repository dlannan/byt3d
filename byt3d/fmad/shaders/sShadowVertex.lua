------------------------------------------------------------------------------------------------------------  
-- 
-- Autogenerated lua Vertex Shaders 
-- 
sShadowVertex_vert = [[  
// glslv output by Cg compiler
// cgc version 3.1.0013, build date Apr 18 2012
// command line args: -quiet -profile glslv -po version=330
// source file: sShadowVertex.vcg
//vendor NVIDIA Corporation
//version 3.1.0.13
//profile glslv
//program main
//semantic main.modelViewProj
//semantic main.Local2View
//var float4x4 modelViewProj :  : _modelViewProj1[0], 4 : 6 : 1
//var float3 position : $vin.POSITION : POSITION : 0 : 1
//var float4 color : $vin.COLOR :  : 1 : 0
//var float2 tex : $vin.TEXCOORD0 :  : 2 : 0
//var float3 N : $vin.TEXCOORD1 :  : 3 : 0
//var float3 T : $vin.TEXCOORD2 :  : 4 : 0
//var float3 B : $vin.TEXCOORD3 :  : 5 : 0
//var float4 main.position : $vout.POSITION : HPOS : -1 : 1

struct Output {
    vec4 _position2;
};

uniform vec4 _modelViewProj1[4];
vec4 _r0004;
vec4 _v0004;
varying vec4 cg_Vertex;

 // main procedure, the original name was main
void main()
{


    _v0004 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
    _r0004.x = dot(_modelViewProj1[0], _v0004);
    _r0004.y = dot(_modelViewProj1[1], _v0004);
    _r0004.z = dot(_modelViewProj1[2], _v0004);
    _r0004.w = dot(_modelViewProj1[3], _v0004);
    gl_Position = _r0004;
    return;
} // main end
]] 
-- 
------------------------------------------------------------------------------------------------------------  
