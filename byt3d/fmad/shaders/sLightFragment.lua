------------------------------------------------------------------------------------------------------------  
-- 
-- Autogenerated lua Fragment Shaders 
-- 
sLightFragment_frag = [[  
// glslf output by Cg compiler
// cgc version 3.1.0013, build date Apr 18 2012
// command line args: -quiet -profile glslf -po version=330
// source file: sLightFragment.fcg
//vendor NVIDIA Corporation
//version 3.1.0.13
//profile glslf
//program main
//semantic main.LightColorDiffuse
//semantic main.LightColorSpecular
//semantic main.LightPos
//semantic main.LightDir
//semantic main.ShadowEnable
//semantic main.ShadowXForm
//semantic main.ShadowBias
//semantic main.ShadowDelta
//semantic main.LightIntensity
//semantic main.Falloff
//semantic main.samplerGBuffer0
//semantic main.samplerGBuffer1
//semantic main.samplerGBuffer2
//semantic main.samplerGBuffer3
//semantic main.samplerMaterial
//semantic main.samplerShadowMap
//var float3 LightColorDiffuse :  : _LightColorDiffuse1 : 5 : 1
//var float3 LightColorSpecular :  : _LightColorSpecular1 : 6 : 1
//var float3 LightPos :  : _LightPos1 : 7 : 1
//var bool ShadowEnable :  : _ShadowEnable1 : 9 : 1
//var float4x4 ShadowXForm :  : _ShadowXForm1[0], 4 : 10 : 1
//var float ShadowBias :  : _ShadowBias1 : 11 : 1
//var float2 ShadowDelta :  : _ShadowDelta1 : 12 : 1
//var float LightIntensity :  : _LightIntensity1 : 13 : 1
//var float3 Falloff :  : _Falloff1 : 14 : 1
//var sampler2D samplerGBuffer0 :  : _samplerGBuffer01 : 15 : 1
//var sampler2D samplerGBuffer1 :  : _samplerGBuffer11 : 16 : 1
//var sampler2D samplerGBuffer2 :  : _samplerGBuffer21 : 17 : 1
//var sampler2D samplerGBuffer3 :  : _samplerGBuffer31 : 18 : 1
//var sampler2D samplerMaterial :  : _samplerMaterial1 : 19 : 1
//var sampler2D samplerShadowMap :  : _samplerShadowMap1 : 20 : 1
//var float2 tex : $vin.TEXCOORD0 : TEXCOORD0 : 0 : 1
//var float4 iColor : $vin.COLOR :  : 1 : 0
//var float4 Pos : $vin.WPOS :  : 2 : 0
//var float4 oDiffuse : $vout.COLOR0 : COLOR0 : 3 : 1
//var float4 oSpec : $vout.COLOR1 : COLOR1 : 4 : 1


precision mediump float;

vec4 _oDiffuse1;
vec4 _oSpec1;
float _TMP8;
float _TMP7;
float _TMP6;
float _TMP4;
float _TMP5;
float _TMP3;
float _TMP2;
float _TMP1;
float _TMP11;
float _TMP10;
float _TMP0;
float _TMP9;
uniform vec3 _LightColorDiffuse1;
uniform vec3 _LightColorSpecular1;
uniform vec3 _LightPos1;
uniform bool _ShadowEnable1;
uniform vec4 _ShadowXForm1[4];
uniform float _ShadowBias1;
uniform vec2 _ShadowDelta1;
uniform float _LightIntensity1;
uniform vec3 _Falloff1;
uniform sampler2D _samplerGBuffer01;    // Only one interleaved with three data sets
uniform sampler2D _samplerMaterial1;
uniform sampler2D _samplerShadowMap1;
vec4 _r0041;
vec4 _v0041;
vec3 _coord0051;
vec3 _coord0053;
vec3 _coord0055;
vec3 _coord0057;
vec3 _coord0059;
vec3 _coord0061;
vec3 _coord0063;
vec3 _coord0065;
vec3 _coord0067;
vec2 _c0069;
float _b0077;
vec3 _v0093;
float _x0113;
float _TMP114;
float _x0115;
float _b0121;
float _b0125;
varying vec4 cg_TexCoord0;

 // main procedure, the original name was main
void main()
{

    vec4 _GBuf0;
    vec4 _GBuf1;
    vec4 _GBuf2;
    vec4 _GBuf3;
    vec3 _Albedo;
    vec3 _Normal;
    vec3 _Position;
    vec3 _Env;
    vec3 _ShadowProj;
    float _Shadow;
    vec3 _ShadowTap01;
    vec3 _ShadowTapH01;
    vec3 _ShadowTapH11;
    vec3 _ShadowTapH21;
    vec3 _ShadowTapH31;
    vec3 _ShadowTapV01;
    vec3 _ShadowTapV11;
    vec3 _ShadowTapV21;
    vec3 _ShadowTapV31;
    float _Shadow01;
    float _ShadowH01;
    float _ShadowH11;
    float _ShadowH21;
    float _ShadowH31;
    float _ShadowV01;
    float _ShadowV11;
    float _ShadowV21;
    float _ShadowV31;
    vec4 _Material;
    vec3 _SpecularColor;
    vec3 _lightDir;
    vec3 _ViewDir;
    vec3 _LightToPos;
    float _Distance2;
    float _Distance;
    float _FalloffScale;
    vec3 _viewDir;
    vec3 _vHalf;
    float _NormalDotHalf;
    float _ViewDotHalf;
    float _NormalDotView;
    float _NormalDotLight;
    float _G1;
    float _G2;
    float _G;
    float _F;
    float _R_2;
    float _NDotH_2;
    float _A;
    float _R;
    float _Denom;
    float _SpecScale;
    vec3 _TMP28;
    vec3 _TMP29;

    _GBuf0 = texture2D(_samplerGBuffer01, cg_TexCoord0.xy);
    _GBuf1 = texture2D(_samplerGBuffer01, cg_TexCoord0.xy + vec2(1.0, 0.0));
    _GBuf2 = texture2D(_samplerGBuffer01, cg_TexCoord0.xy + vec2(2.0, 0.0));
    //_GBuf3 = texture2D(_samplerGBuffer31, cg_TexCoord0.xy);
    _Albedo = vec3(_GBuf0.x, _GBuf0.y, _GBuf0.z);
    _Normal = vec3(_GBuf1.x, _GBuf1.y, _GBuf1.z);
    _Position = vec3(_GBuf2.x, _GBuf2.y, _GBuf2.z);
    // _Env = vec3(_GBuf3.x, _GBuf3.y, _GBuf3.z);
    _v0041 = vec4(_Position.x, _Position.y, _Position.z, 1.00000000E+000);
    _r0041.x = dot(_ShadowXForm1[0], _v0041);
    _r0041.y = dot(_ShadowXForm1[1], _v0041);
    _r0041.z = dot(_ShadowXForm1[2], _v0041);
    _r0041.w = dot(_ShadowXForm1[3], _v0041);
    _ShadowProj = _r0041.xyz/_r0041.w;
    _ShadowProj.z = _ShadowProj.z + _ShadowBias1;
    _Shadow = 1.00000000E+000;
    if (_ShadowEnable1) { // if begin
        _ShadowTap01 = vec3(_ShadowProj.x, _ShadowProj.y, _ShadowProj.z);
        _ShadowTapH01 = vec3(_ShadowProj.x - 2.00000000E+000*_ShadowDelta1.x, _ShadowProj.y, _ShadowProj.z);
        _ShadowTapH11 = vec3(_ShadowProj.x - _ShadowDelta1.x, _ShadowProj.y, _ShadowProj.z);
        _ShadowTapH21 = vec3(_ShadowProj.x + _ShadowDelta1.x, _ShadowProj.y, _ShadowProj.z);
        _ShadowTapH31 = vec3(_ShadowProj.x + 2.00000000E+000*_ShadowDelta1.x, _ShadowProj.y, _ShadowProj.z);
        _ShadowTapV01 = vec3(_ShadowProj.x, _ShadowProj.y - 2.00000000E+000*_ShadowDelta1.y, _ShadowProj.z);
        _ShadowTapV11 = vec3(_ShadowProj.x, _ShadowProj.y - _ShadowDelta1.y, _ShadowProj.z);
        _ShadowTapV21 = vec3(_ShadowProj.x, _ShadowProj.y + _ShadowDelta1.y, _ShadowProj.z);
        _ShadowTapV31 = vec3(_ShadowProj.x, _ShadowProj.y + 2.00000000E+000*_ShadowDelta1.y, _ShadowProj.z);
        _coord0051.xy = _ShadowTap01.xy;
        _coord0051.z = _ShadowTap01.z;
        _Shadow01 = texture2D(_samplerShadowMap1, _coord0051.xy).x;
        _coord0053.xy = _ShadowTapH01.xy;
        _coord0053.z = _ShadowTapH01.z;
        _ShadowH01 = texture2D(_samplerShadowMap1, _coord0053.xy).x;
        _coord0055.xy = _ShadowTapH11.xy;
        _coord0055.z = _ShadowTapH11.z;
        _ShadowH11 = texture2D(_samplerShadowMap1, _coord0055.xy).x;
        _coord0057.xy = _ShadowTapH21.xy;
        _coord0057.z = _ShadowTapH21.z;
        _ShadowH21 = texture2D(_samplerShadowMap1, _coord0057.xy).x;
        _coord0059.xy = _ShadowTapH31.xy;
        _coord0059.z = _ShadowTapH31.z;
        _ShadowH31 = texture2D(_samplerShadowMap1, _coord0059.xy).x;
        _coord0061.xy = _ShadowTapV01.xy;
        _coord0061.z = _ShadowTapV01.z;
        _ShadowV01 = texture2D(_samplerShadowMap1, _coord0061.xy).x;
        _coord0063.xy = _ShadowTapV11.xy;
        _coord0063.z = _ShadowTapV11.z;
        _ShadowV11 = texture2D(_samplerShadowMap1, _coord0063.xy).x;
        _coord0065.xy = _ShadowTapV21.xy;
        _coord0065.z = _ShadowTapV21.z;
        _ShadowV21 = texture2D(_samplerShadowMap1, _coord0065.xy).x;
        _coord0067.xy = _ShadowTapV31.xy;
        _coord0067.z = _ShadowTapV31.z;
        _ShadowV31 = texture2D(_samplerShadowMap1, _coord0067.xy).x;
        _Shadow = 1.11111112E-001*(_Shadow01 + _ShadowH01 + _ShadowH11 + _ShadowH21 + _ShadowH31 + _ShadowV01 + _ShadowV11 + _ShadowV21 + _ShadowV31);
    } // end if
    _c0069 = vec2(_GBuf1.w*2.44140625E-004, 0.00000000E+000);
    _Material = texture2D(_samplerMaterial1, _c0069);
    if (_Material.z == 1.00000000E+000) { // if begin
        _oDiffuse1 = vec4(_Albedo.x, _Albedo.y, _Albedo.z, 1.00000000E+000);
        _oSpec1 = vec4( 0.00000000E+000, 0.00000000E+000, 0.00000000E+000, 0.00000000E+000);
        float rem = mod(gl_FragCoord.x, 3.0);
        if(rem < 1.0) {
            gl_FragColor = _oDiffuse1;
        }
        else {
            gl_FragColor = vec4( 0.00000000E+000, 0.00000000E+000, 0.00000000E+000, 0.00000000E+000);
        }
        return;
    } // end if
    _SpecularColor = _LightColorSpecular1; //*_Env;
    _lightDir = _LightPos1 - _Position;
    _ViewDir = -_Position;
    _LightToPos = _LightPos1 - _Position;
    _Distance2 = dot(_LightToPos, _LightToPos);
    _TMP9 = inversesqrt(_Distance2);
    _Distance = 1.00000000E+000/_TMP9;
    _b0077 = _Falloff1.x + _Falloff1.y*_Distance + _Falloff1.z*_Distance2;
    _TMP0 = max(1.00000000E+000, _b0077);
    _FalloffScale = _LightIntensity1/_TMP0;
    _FalloffScale = min(1.00000000E+000, _FalloffScale);
    _TMP10 = dot(_ViewDir, _ViewDir);
    _TMP11 = inversesqrt(_TMP10);
    _viewDir = _TMP11*_ViewDir;
    _TMP10 = dot(_lightDir, _lightDir);
    _TMP11 = inversesqrt(_TMP10);
    _lightDir = _TMP11*_lightDir;
    _v0093 = _lightDir + _viewDir;
    _TMP10 = dot(_v0093, _v0093);
    _TMP11 = inversesqrt(_TMP10);
    _vHalf = _TMP11*_v0093;
    _NormalDotHalf = dot(_Normal, _vHalf);
    _ViewDotHalf = dot(_vHalf, _viewDir);
    _NormalDotView = dot(_Normal, _viewDir);
    _NormalDotLight = dot(_Normal, _lightDir);
    _G1 = (2.00000000E+000*_NormalDotHalf*_NormalDotView)/_ViewDotHalf;
    _G2 = (2.00000000E+000*_NormalDotHalf*_NormalDotLight)/_ViewDotHalf;
    _TMP1 = min(_G1, _G2);
    _TMP2 = max(0.00000000E+000, _TMP1);
    _G = min(1.00000000E+000, _TMP2);
    _x0113 = 1.00000000E+000 - _NormalDotView;
    _TMP3 = pow(_x0113, 5.00000000E+000);
    _F = _Material.y*(1.00000000E+000 - _TMP3);
    _R_2 = _Material.x*_Material.x;
    _NDotH_2 = _NormalDotHalf*_NormalDotHalf;
    _A = 1.00000000E+000/(4.00000000E+000*_R_2*_NDotH_2*_NDotH_2);
    _x0115 = -(1.00000000E+000 - _NDotH_2)/(_R_2*_NDotH_2);
    _TMP114 = pow(2.71828198E+000, _x0115);
    _R = _A*_TMP114;
    _Denom = _NormalDotLight*_NormalDotView;
    _TMP5 = abs(_Denom);
    if (_TMP5 <= 9.99999975E-005) { // if begin
        _TMP4 = 0.00000000E+000;
    } else {
        _TMP4 = 1.00000000E+000/_Denom;
    } // end if
    _b0121 = _G*_F*_R*_TMP4;
    _SpecScale = min(1.00000000E+000, _b0121);
    if (_NormalDotLight < 9.99999997E-007) { // if begin
        _TMP6 = 0.00000000E+000;
    } else {
        _TMP6 = _SpecScale;
    } // end if
    if (_NormalDotLight < 0.00000000E+000) { // if begin
        _TMP7 = _Material.z;
    } else {
        _TMP7 = max(_Material.z, _NormalDotLight);
    } // end if
    _TMP29 = (_Albedo*_LightColorDiffuse1)*_TMP7;
    _oDiffuse1 = _FalloffScale*vec4(_TMP29.x, _TMP29.y, _TMP29.z, 1.00000000E+000);
    _TMP28 = _SpecularColor*vec3(_TMP6, _TMP6, _TMP6);
    _oSpec1 = _FalloffScale*vec4(_TMP28.x, _TMP28.y, _TMP28.z, 1.00000000E+000);
    _b0125 = 4.00000006E-001 + _Shadow;
    _TMP8 = min(1.00000000E+000, _b0125);
    _oDiffuse1 = _oDiffuse1*_TMP8;
    _oSpec1 = _oSpec1*_Shadow;

    float rem = mod(gl_FragCoord.x, 3.0);
    if(rem < 1.0) {
        gl_FragColor = _oDiffuse1;
    }
    else {
        gl_FragColor = _oSpec1;
    }
} // main end
]] 
-- 
------------------------------------------------------------------------------------------------------------  