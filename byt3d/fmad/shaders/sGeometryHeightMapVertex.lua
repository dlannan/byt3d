------------------------------------------------------------------------------------------------------------  
-- 
-- Autogenerated lua Vertex Shaders 
-- 
sGeometryHeightMapVertex_vert = [[  
// glslv output by Cg compiler
// cgc version 3.1.0013, build date Apr 18 2012
// command line args: -quiet -profile glslv -po version=330
// source file: sGeometryHeightMapVertex.vcg
//vendor NVIDIA Corporation
//version 3.1.0.13
//profile glslv
//program main
//semantic main.modelViewProj
//semantic main.Local2View
//semantic main.Normal
//semantic main.DepthScale
//semantic main.DepthStep
//semantic main.N
//semantic main.U
//semantic main.V
//semantic main.heightMap : TEXUNIT15
//var float4x4 modelViewProj :  : _modelViewProj1[0], 4 : 3 : 1
//var float4x4 Local2View :  : _Local2View1[0], 4 : 4 : 1
//var float DepthScale :  : _DepthScale1 : 6 : 1
//var float2 DepthStep :  : _DepthStep1 : 7 : 1
//var float3 N :  : _N1 : 8 : 1
//var float3 U :  : _U1 : 9 : 1
//var float3 V :  : _V1 : 10 : 1
//var sampler2D heightMap : TEXUNIT15 : _heightMap1 15 : 11 : 1
//var float3 position : $vin.POSITION : POSITION : 0 : 1
//var float4 color : $vin.COLOR : COLOR : 1 : 1
//var float2 tex : $vin.TEXCOORD0 : TEXCOORD0 : 2 : 1
//var float4 main.position : $vout.POSITION : HPOS : -1 : 1
//var float4 main.color : $vout.COLOR : COLOR : -1 : 1
//var float2 main.tex : $vout.TEXCOORD0 : TEXCOORD0 : -1 : 1
//var float3 main.N : $vout.TEXCOORD1 : TEXCOORD1 : -1 : 1
//var float4 main.T : $vout.TEXCOORD2 : TEXCOORD2 : -1 : 1
//var float3 main.B : $vout.TEXCOORD3 : TEXCOORD3 : -1 : 1

struct Output {
    vec4 _position2;
    vec4 _color1;
    vec2 _tex1;
    vec3 _N2;
    vec4 _T;
    vec3 _B;
};

vec3 _TMP4;
vec3 _TMP3;
float _TMP7;
float _TMP6;
vec4 _TMP2;
vec4 _TMP1;
vec4 _TMP0;
uniform vec4 _modelViewProj1[4];
uniform vec4 _Local2View1[4];
uniform float _DepthScale1;
uniform vec2 _DepthStep1;
uniform vec3 _N1;
uniform vec3 _U1;
uniform vec3 _V1;
uniform sampler2D _heightMap1;
vec2 _c0022;
vec2 _c0024;
vec4 _r0026;
vec4 _v0026;
vec4 _r0044;
vec4 _v0044;
vec4 _r0054;
vec4 _v0054;
varying vec4 COLOR;
varying vec4 TEXCOORD0;
varying vec4 cg_Vertex;
varying vec4 cg_FrontColor;
varying vec4 cg_TexCoord1;
varying vec4 cg_TexCoord3;
varying vec4 cg_TexCoord0;
varying vec4 cg_TexCoord2;

 // main procedure, the original name was main
void main()
{

    Output _OUT;
    vec3 _p0;
    float _du;
    float _dv;
    vec3 _Nu;
    vec3 _Nv;
    vec3 _localNormal;

    _TMP0 = texture2D(_heightMap1, TEXCOORD0.xy);
    _c0022 = TEXCOORD0.xy + vec2(_DepthStep1.x, 0.00000000E+000);
    _TMP1 = texture2D(_heightMap1, _c0022);
    _c0024 = TEXCOORD0.xy + vec2(0.00000000E+000, _DepthStep1.y);
    _TMP2 = texture2D(_heightMap1, _c0024);
    _p0 = cg_Vertex.xyz + (_DepthScale1*_TMP0.x)*_N1;
    _v0026 = vec4(_p0.x, _p0.y, _p0.z, 1.00000000E+000);
    _r0026.x = dot(_modelViewProj1[0], _v0026);
    _r0026.y = dot(_modelViewProj1[1], _v0026);
    _r0026.z = dot(_modelViewProj1[2], _v0026);
    _r0026.w = dot(_modelViewProj1[3], _v0026);
    _du = _TMP1.x - _TMP0.x;
    _dv = _TMP2.x - _TMP0.x;
    _Nu = _DepthStep1.x*_U1 + _du*_N1;
    _Nv = _DepthStep1.y*_V1 + _dv*_N1;
    _TMP3 = _Nu.yzx*_Nv.zxy - _Nu.zxy*_Nv.yzx;
    _TMP6 = dot(_TMP3, _TMP3);
    _TMP7 = inversesqrt(_TMP6);
    _TMP4 = _TMP7*_TMP3;
    _localNormal = -_TMP4;
    _v0044 = vec4(_localNormal.x, _localNormal.y, _localNormal.z, 0.00000000E+000);
    _r0044.x = dot(_Local2View1[0], _v0044);
    _r0044.y = dot(_Local2View1[1], _v0044);
    _r0044.z = dot(_Local2View1[2], _v0044);
    _v0054 = vec4(_p0.x, _p0.y, _p0.z, 1.00000000E+000);
    _r0054.x = dot(_Local2View1[0], _v0054);
    _r0054.y = dot(_Local2View1[1], _v0054);
    _r0054.z = dot(_Local2View1[2], _v0054);
    _r0054.w = dot(_Local2View1[3], _v0054);
    cg_TexCoord2 = _r0054;
    cg_TexCoord0.xy = TEXCOORD0.xy;
    cg_TexCoord3.xyz = _OUT._B;
    cg_TexCoord1.xyz = _r0044.xyz;
    gl_Position = _r0026;
    cg_FrontColor = COLOR;
    return;
} // main end
]] 
-- 
------------------------------------------------------------------------------------------------------------  