------------------------------------------------------------------------------------------------------------  
-- 
-- Autogenerated lua Vertex Shaders 
-- 
sGeometrySkinVertex_vert = [[  
// glslv output by Cg compiler
// cgc version 3.1.0013, build date Apr 18 2012
// command line args: -quiet -profile glslv -po version=330
// source file: sGeometrySkinVertex.vcg
//vendor NVIDIA Corporation
//version 3.1.0.13
//profile glslv
//program main
//semantic main.modelViewProj
//semantic main.Local2View
//semantic main.Bone
//var float4x4 modelViewProj :  : _modelViewProj1[0], 4 : 10 : 1
//var float4x4 Local2View :  : _Local2View1[0], 4 : 11 : 1
//var float3x4 Bone[0] :  : _Bone1[0], 3 : 12 : 1
//var float3x4 Bone[1] :  : _Bone1[3], 3 : 12 : 1
//var float3x4 Bone[2] :  : _Bone1[6], 3 : 12 : 1
//var float3x4 Bone[3] :  : _Bone1[9], 3 : 12 : 1
//var float3x4 Bone[4] :  : _Bone1[12], 3 : 12 : 1
//var float3x4 Bone[5] :  : _Bone1[15], 3 : 12 : 1
//var float3x4 Bone[6] :  : _Bone1[18], 3 : 12 : 1
//var float3x4 Bone[7] :  : _Bone1[21], 3 : 12 : 1
//var float3x4 Bone[8] :  : _Bone1[24], 3 : 12 : 1
//var float3x4 Bone[9] :  : _Bone1[27], 3 : 12 : 1
//var float3x4 Bone[10] :  : _Bone1[30], 3 : 12 : 1
//var float3x4 Bone[11] :  : _Bone1[33], 3 : 12 : 1
//var float3x4 Bone[12] :  : _Bone1[36], 3 : 12 : 1
//var float3x4 Bone[13] :  : _Bone1[39], 3 : 12 : 1
//var float3x4 Bone[14] :  : _Bone1[42], 3 : 12 : 1
//var float3x4 Bone[15] :  : _Bone1[45], 3 : 12 : 1
//var float3x4 Bone[16] :  : _Bone1[48], 3 : 12 : 1
//var float3x4 Bone[17] :  : _Bone1[51], 3 : 12 : 1
//var float3x4 Bone[18] :  : _Bone1[54], 3 : 12 : 1
//var float3x4 Bone[19] :  : _Bone1[57], 3 : 12 : 1
//var float3x4 Bone[20] :  : _Bone1[60], 3 : 12 : 1
//var float3x4 Bone[21] :  : _Bone1[63], 3 : 12 : 1
//var float3x4 Bone[22] :  : _Bone1[66], 3 : 12 : 1
//var float3x4 Bone[23] :  : _Bone1[69], 3 : 12 : 1
//var float3x4 Bone[24] :  : _Bone1[72], 3 : 12 : 1
//var float3x4 Bone[25] :  : _Bone1[75], 3 : 12 : 1
//var float3x4 Bone[26] :  : _Bone1[78], 3 : 12 : 1
//var float3x4 Bone[27] :  : _Bone1[81], 3 : 12 : 1
//var float3x4 Bone[28] :  : _Bone1[84], 3 : 12 : 1
//var float3x4 Bone[29] :  : _Bone1[87], 3 : 12 : 1
//var float3x4 Bone[30] :  : _Bone1[90], 3 : 12 : 1
//var float3x4 Bone[31] :  : _Bone1[93], 3 : 12 : 1
//var float3x4 Bone[32] :  : _Bone1[96], 3 : 12 : 1
//var float3x4 Bone[33] :  : _Bone1[99], 3 : 12 : 1
//var float3x4 Bone[34] :  : _Bone1[102], 3 : 12 : 1
//var float3x4 Bone[35] :  : _Bone1[105], 3 : 12 : 1
//var float3x4 Bone[36] :  : _Bone1[108], 3 : 12 : 1
//var float3x4 Bone[37] :  : _Bone1[111], 3 : 12 : 1
//var float3x4 Bone[38] :  : _Bone1[114], 3 : 12 : 1
//var float3x4 Bone[39] :  : _Bone1[117], 3 : 12 : 1
//var float3x4 Bone[40] :  : _Bone1[120], 3 : 12 : 1
//var float3x4 Bone[41] :  : _Bone1[123], 3 : 12 : 1
//var float3x4 Bone[42] :  : _Bone1[126], 3 : 12 : 1
//var float3x4 Bone[43] :  : _Bone1[129], 3 : 12 : 1
//var float3x4 Bone[44] :  : _Bone1[132], 3 : 12 : 1
//var float3x4 Bone[45] :  : _Bone1[135], 3 : 12 : 1
//var float3x4 Bone[46] :  : _Bone1[138], 3 : 12 : 1
//var float3x4 Bone[47] :  : _Bone1[141], 3 : 12 : 1
//var float3x4 Bone[48] :  : _Bone1[144], 3 : 12 : 1
//var float3x4 Bone[49] :  : _Bone1[147], 3 : 12 : 1
//var float3x4 Bone[50] :  : _Bone1[150], 3 : 12 : 1
//var float3x4 Bone[51] :  : _Bone1[153], 3 : 12 : 1
//var float3x4 Bone[52] :  : _Bone1[156], 3 : 12 : 1
//var float3x4 Bone[53] :  : _Bone1[159], 3 : 12 : 1
//var float3x4 Bone[54] :  : _Bone1[162], 3 : 12 : 1
//var float3x4 Bone[55] :  : _Bone1[165], 3 : 12 : 1
//var float3x4 Bone[56] :  : _Bone1[168], 3 : 12 : 1
//var float3x4 Bone[57] :  : _Bone1[171], 3 : 12 : 1
//var float3x4 Bone[58] :  : _Bone1[174], 3 : 12 : 1
//var float3x4 Bone[59] :  : _Bone1[177], 3 : 12 : 1
//var float3x4 Bone[60] :  : _Bone1[180], 3 : 12 : 1
//var float3x4 Bone[61] :  : _Bone1[183], 3 : 12 : 1
//var float3x4 Bone[62] :  : _Bone1[186], 3 : 12 : 1
//var float3x4 Bone[63] :  : _Bone1[189], 3 : 12 : 1
//var float3x4 Bone[64] :  : _Bone1[192], 3 : 12 : 1
//var float3x4 Bone[65] :  : _Bone1[195], 3 : 12 : 1
//var float3x4 Bone[66] :  : _Bone1[198], 3 : 12 : 1
//var float3x4 Bone[67] :  : _Bone1[201], 3 : 12 : 1
//var float3x4 Bone[68] :  : _Bone1[204], 3 : 12 : 1
//var float3x4 Bone[69] :  : _Bone1[207], 3 : 12 : 1
//var float3x4 Bone[70] :  : _Bone1[210], 3 : 12 : 1
//var float3x4 Bone[71] :  : _Bone1[213], 3 : 12 : 1
//var float3x4 Bone[72] :  : _Bone1[216], 3 : 12 : 1
//var float3x4 Bone[73] :  : _Bone1[219], 3 : 12 : 1
//var float3x4 Bone[74] :  : _Bone1[222], 3 : 12 : 1
//var float3x4 Bone[75] :  : _Bone1[225], 3 : 12 : 1
//var float3x4 Bone[76] :  : _Bone1[228], 3 : 12 : 1
//var float3x4 Bone[77] :  : _Bone1[231], 3 : 12 : 1
//var float3x4 Bone[78] :  : _Bone1[234], 3 : 12 : 1
//var float3x4 Bone[79] :  : _Bone1[237], 3 : 12 : 1
//var float3x4 Bone[80] :  : _Bone1[240], 3 : 12 : 1
//var float3x4 Bone[81] :  : _Bone1[243], 3 : 12 : 1
//var float3x4 Bone[82] :  : _Bone1[246], 3 : 12 : 1
//var float3x4 Bone[83] :  : _Bone1[249], 3 : 12 : 1
//var float3x4 Bone[84] :  : _Bone1[252], 3 : 12 : 1
//var float3x4 Bone[85] :  : _Bone1[255], 3 : 12 : 1
//var float3x4 Bone[86] :  : _Bone1[258], 3 : 12 : 1
//var float3x4 Bone[87] :  : _Bone1[261], 3 : 12 : 1
//var float3x4 Bone[88] :  : _Bone1[264], 3 : 12 : 1
//var float3x4 Bone[89] :  : _Bone1[267], 3 : 12 : 1
//var float3x4 Bone[90] :  : _Bone1[270], 3 : 12 : 1
//var float3x4 Bone[91] :  : _Bone1[273], 3 : 12 : 1
//var float3x4 Bone[92] :  : _Bone1[276], 3 : 12 : 1
//var float3x4 Bone[93] :  : _Bone1[279], 3 : 12 : 1
//var float3x4 Bone[94] :  : _Bone1[282], 3 : 12 : 1
//var float3x4 Bone[95] :  : _Bone1[285], 3 : 12 : 1
//var float3x4 Bone[96] :  : _Bone1[288], 3 : 12 : 1
//var float3x4 Bone[97] :  : _Bone1[291], 3 : 12 : 1
//var float3x4 Bone[98] :  : _Bone1[294], 3 : 12 : 1
//var float3x4 Bone[99] :  : _Bone1[297], 3 : 12 : 1
//var float3x4 Bone[100] :  : _Bone1[300], 3 : 12 : 1
//var float3x4 Bone[101] :  : _Bone1[303], 3 : 12 : 1
//var float3x4 Bone[102] :  : _Bone1[306], 3 : 12 : 1
//var float3x4 Bone[103] :  : _Bone1[309], 3 : 12 : 1
//var float3x4 Bone[104] :  : _Bone1[312], 3 : 12 : 1
//var float3x4 Bone[105] :  : _Bone1[315], 3 : 12 : 1
//var float3x4 Bone[106] :  : _Bone1[318], 3 : 12 : 1
//var float3x4 Bone[107] :  : _Bone1[321], 3 : 12 : 1
//var float3x4 Bone[108] :  : _Bone1[324], 3 : 12 : 1
//var float3x4 Bone[109] :  : _Bone1[327], 3 : 12 : 1
//var float3x4 Bone[110] :  : _Bone1[330], 3 : 12 : 1
//var float3x4 Bone[111] :  : _Bone1[333], 3 : 12 : 1
//var float3x4 Bone[112] :  : _Bone1[336], 3 : 12 : 1
//var float3x4 Bone[113] :  : _Bone1[339], 3 : 12 : 1
//var float3x4 Bone[114] :  : _Bone1[342], 3 : 12 : 1
//var float3x4 Bone[115] :  : _Bone1[345], 3 : 12 : 1
//var float3x4 Bone[116] :  : _Bone1[348], 3 : 12 : 1
//var float3x4 Bone[117] :  : _Bone1[351], 3 : 12 : 1
//var float3x4 Bone[118] :  : _Bone1[354], 3 : 12 : 1
//var float3x4 Bone[119] :  : _Bone1[357], 3 : 12 : 1
//var float3x4 Bone[120] :  : _Bone1[360], 3 : 12 : 1
//var float3x4 Bone[121] :  : _Bone1[363], 3 : 12 : 1
//var float3x4 Bone[122] :  : _Bone1[366], 3 : 12 : 1
//var float3x4 Bone[123] :  : _Bone1[369], 3 : 12 : 1
//var float3x4 Bone[124] :  : _Bone1[372], 3 : 12 : 1
//var float3x4 Bone[125] :  : _Bone1[375], 3 : 12 : 1
//var float3x4 Bone[126] :  : _Bone1[378], 3 : 12 : 1
//var float3x4 Bone[127] :  : _Bone1[381], 3 : 12 : 1
//var float3 position : $vin.POSITION : POSITION : 0 : 1
//var float4 color : $vin.COLOR : COLOR : 1 : 1
//var float2 tex : $vin.TEXCOORD0 : TEXCOORD0 : 2 : 1
//var float3 N : $vin.TEXCOORD1 : TEXCOORD1 : 3 : 1
//var float3 T : $vin.TEXCOORD2 :  : 4 : 0
//var float3 B : $vin.TEXCOORD3 : TEXCOORD3 : 5 : 1
//var float4 WeightA : $vin.TEXCOORD4 : TEXCOORD4 : 6 : 1
//var float4 WeightB : $vin.TEXCOORD5 : TEXCOORD5 : 7 : 1
//var float4 BoneA : $vin.TEXCOORD6 : TEXCOORD6 : 8 : 1
//var float4 BoneB : $vin.TEXCOORD7 : TEXCOORD7 : 9 : 1
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
    vec3 _N1;
    vec4 _T1;
    vec3 _B1;
};

uniform vec4 _modelViewProj1[4];
uniform vec4 _Local2View1[4];
uniform vec4 _Bone1[384];
vec3 _r0039;
vec4 _M0039[3];
vec4 _v0039;
vec3 _r0047;
vec4 _M0047[3];
vec4 _v0047;
vec3 _r0055;
vec4 _M0055[3];
vec4 _v0055;
vec3 _r0063;
vec4 _M0063[3];
vec4 _v0063;
vec3 _r0071;
vec4 _M0071[3];
vec4 _v0071;
vec3 _r0079;
vec4 _M0079[3];
vec4 _v0079;
vec3 _r0087;
vec4 _M0087[3];
vec4 _v0087;
vec3 _r0095;
vec4 _M0095[3];
vec4 _v0095;
vec3 _r0103;
vec4 _M0103[3];
vec4 _v0103;
vec3 _r0111;
vec4 _M0111[3];
vec4 _v0111;
vec3 _r0119;
vec4 _M0119[3];
vec4 _v0119;
vec3 _r0127;
vec4 _M0127[3];
vec4 _v0127;
vec3 _r0135;
vec4 _M0135[3];
vec4 _v0135;
vec3 _r0143;
vec4 _M0143[3];
vec4 _v0143;
vec3 _r0151;
vec4 _M0151[3];
vec4 _v0151;
vec3 _r0159;
vec4 _M0159[3];
vec4 _v0159;
vec4 _r0167;
vec4 _v0167;
vec4 _r0177;
vec4 _v0177;
vec4 _r0187;
vec4 _v0187;
varying vec4 COLOR;
varying vec4 TEXCOORD0;
varying vec4 TEXCOORD1;
varying vec4 TEXCOORD3;
varying vec4 TEXCOORD4;
varying vec4 TEXCOORD5;
varying vec4 TEXCOORD6;
varying vec4 TEXCOORD7;
varying vec4 cg_Vertex;
varying vec4 cg_FrontColor;
varying vec4 cg_TexCoord1;
varying vec4 cg_TexCoord3;
varying vec4 cg_TexCoord0;
varying vec4 cg_TexCoord2;

 // main procedure, the original name was main
void main()
{

    vec3 _Pos;
    vec3 _Normal;

    _Pos = vec3( 0.00000000E+000, 0.00000000E+000, 0.00000000E+000);
    if (TEXCOORD4.x > 0.00000000E+000) { // if begin
        _M0039[0] = _Bone1[(3*int(TEXCOORD6.x) + 0)];
        _M0039[1] = _Bone1[(3*int(TEXCOORD6.x) + 1)];
        _M0039[2] = _Bone1[(3*int(TEXCOORD6.x) + 2)];
        _v0039 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
        _r0039.x = dot(_M0039[0], _v0039);
        _r0039.y = dot(_M0039[1], _v0039);
        _r0039.z = dot(_M0039[2], _v0039);
        _Pos = _r0039*TEXCOORD4.x;
    } // end if
    if (TEXCOORD4.y > 0.00000000E+000) { // if begin
        _M0047[0] = _Bone1[(3*int(TEXCOORD6.y) + 0)];
        _M0047[1] = _Bone1[(3*int(TEXCOORD6.y) + 1)];
        _M0047[2] = _Bone1[(3*int(TEXCOORD6.y) + 2)];
        _v0047 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
        _r0047.x = dot(_M0047[0], _v0047);
        _r0047.y = dot(_M0047[1], _v0047);
        _r0047.z = dot(_M0047[2], _v0047);
        _Pos = _Pos + _r0047*TEXCOORD4.y;
    } // end if
    if (TEXCOORD4.z > 0.00000000E+000) { // if begin
        _M0055[0] = _Bone1[(3*int(TEXCOORD6.z) + 0)];
        _M0055[1] = _Bone1[(3*int(TEXCOORD6.z) + 1)];
        _M0055[2] = _Bone1[(3*int(TEXCOORD6.z) + 2)];
        _v0055 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
        _r0055.x = dot(_M0055[0], _v0055);
        _r0055.y = dot(_M0055[1], _v0055);
        _r0055.z = dot(_M0055[2], _v0055);
        _Pos = _Pos + _r0055*TEXCOORD4.z;
    } // end if
    if (TEXCOORD4.w > 0.00000000E+000) { // if begin
        _M0063[0] = _Bone1[(3*int(TEXCOORD6.w) + 0)];
        _M0063[1] = _Bone1[(3*int(TEXCOORD6.w) + 1)];
        _M0063[2] = _Bone1[(3*int(TEXCOORD6.w) + 2)];
        _v0063 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
        _r0063.x = dot(_M0063[0], _v0063);
        _r0063.y = dot(_M0063[1], _v0063);
        _r0063.z = dot(_M0063[2], _v0063);
        _Pos = _Pos + _r0063*TEXCOORD4.w;
    } // end if
    if (TEXCOORD5.x > 0.00000000E+000) { // if begin
        _M0071[0] = _Bone1[(3*int(TEXCOORD7.x) + 0)];
        _M0071[1] = _Bone1[(3*int(TEXCOORD7.x) + 1)];
        _M0071[2] = _Bone1[(3*int(TEXCOORD7.x) + 2)];
        _v0071 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
        _r0071.x = dot(_M0071[0], _v0071);
        _r0071.y = dot(_M0071[1], _v0071);
        _r0071.z = dot(_M0071[2], _v0071);
        _Pos = _Pos + _r0071*TEXCOORD5.x;
    } // end if
    if (TEXCOORD5.y > 0.00000000E+000) { // if begin
        _M0079[0] = _Bone1[(3*int(TEXCOORD7.y) + 0)];
        _M0079[1] = _Bone1[(3*int(TEXCOORD7.y) + 1)];
        _M0079[2] = _Bone1[(3*int(TEXCOORD7.y) + 2)];
        _v0079 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
        _r0079.x = dot(_M0079[0], _v0079);
        _r0079.y = dot(_M0079[1], _v0079);
        _r0079.z = dot(_M0079[2], _v0079);
        _Pos = _Pos + _r0079*TEXCOORD5.y;
    } // end if
    if (TEXCOORD5.z > 0.00000000E+000) { // if begin
        _M0087[0] = _Bone1[(3*int(TEXCOORD7.z) + 0)];
        _M0087[1] = _Bone1[(3*int(TEXCOORD7.z) + 1)];
        _M0087[2] = _Bone1[(3*int(TEXCOORD7.z) + 2)];
        _v0087 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
        _r0087.x = dot(_M0087[0], _v0087);
        _r0087.y = dot(_M0087[1], _v0087);
        _r0087.z = dot(_M0087[2], _v0087);
        _Pos = _Pos + _r0087*TEXCOORD5.z;
    } // end if
    if (TEXCOORD5.w > 0.00000000E+000) { // if begin
        _M0095[0] = _Bone1[(3*int(TEXCOORD7.w) + 0)];
        _M0095[1] = _Bone1[(3*int(TEXCOORD7.w) + 1)];
        _M0095[2] = _Bone1[(3*int(TEXCOORD7.w) + 2)];
        _v0095 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
        _r0095.x = dot(_M0095[0], _v0095);
        _r0095.y = dot(_M0095[1], _v0095);
        _r0095.z = dot(_M0095[2], _v0095);
        _Pos = _Pos + _r0095*TEXCOORD5.w;
    } // end if
    _Normal = vec3( 0.00000000E+000, 0.00000000E+000, 0.00000000E+000);
    if (TEXCOORD4.x > 0.00000000E+000) { // if begin
        _M0103[0] = _Bone1[(3*int(TEXCOORD6.x) + 0)];
        _M0103[1] = _Bone1[(3*int(TEXCOORD6.x) + 1)];
        _M0103[2] = _Bone1[(3*int(TEXCOORD6.x) + 2)];
        _v0103 = vec4(TEXCOORD1.x, TEXCOORD1.y, TEXCOORD1.z, 0.00000000E+000);
        _r0103.x = dot(_M0103[0], _v0103);
        _r0103.y = dot(_M0103[1], _v0103);
        _r0103.z = dot(_M0103[2], _v0103);
        _Normal = _r0103*TEXCOORD4.x;
    } // end if
    if (TEXCOORD4.y > 0.00000000E+000) { // if begin
        _M0111[0] = _Bone1[(3*int(TEXCOORD6.y) + 0)];
        _M0111[1] = _Bone1[(3*int(TEXCOORD6.y) + 1)];
        _M0111[2] = _Bone1[(3*int(TEXCOORD6.y) + 2)];
        _v0111 = vec4(TEXCOORD1.x, TEXCOORD1.y, TEXCOORD1.z, 0.00000000E+000);
        _r0111.x = dot(_M0111[0], _v0111);
        _r0111.y = dot(_M0111[1], _v0111);
        _r0111.z = dot(_M0111[2], _v0111);
        _Normal = _Normal + _r0111*TEXCOORD4.y;
    } // end if
    if (TEXCOORD4.z > 0.00000000E+000) { // if begin
        _M0119[0] = _Bone1[(3*int(TEXCOORD6.z) + 0)];
        _M0119[1] = _Bone1[(3*int(TEXCOORD6.z) + 1)];
        _M0119[2] = _Bone1[(3*int(TEXCOORD6.z) + 2)];
        _v0119 = vec4(TEXCOORD1.x, TEXCOORD1.y, TEXCOORD1.z, 0.00000000E+000);
        _r0119.x = dot(_M0119[0], _v0119);
        _r0119.y = dot(_M0119[1], _v0119);
        _r0119.z = dot(_M0119[2], _v0119);
        _Normal = _Normal + _r0119*TEXCOORD4.z;
    } // end if
    if (TEXCOORD4.w > 0.00000000E+000) { // if begin
        _M0127[0] = _Bone1[(3*int(TEXCOORD6.w) + 0)];
        _M0127[1] = _Bone1[(3*int(TEXCOORD6.w) + 1)];
        _M0127[2] = _Bone1[(3*int(TEXCOORD6.w) + 2)];
        _v0127 = vec4(TEXCOORD1.x, TEXCOORD1.y, TEXCOORD1.z, 0.00000000E+000);
        _r0127.x = dot(_M0127[0], _v0127);
        _r0127.y = dot(_M0127[1], _v0127);
        _r0127.z = dot(_M0127[2], _v0127);
        _Normal = _Normal + _r0127*TEXCOORD4.w;
    } // end if
    if (TEXCOORD5.x > 0.00000000E+000) { // if begin
        _M0135[0] = _Bone1[(3*int(TEXCOORD7.x) + 0)];
        _M0135[1] = _Bone1[(3*int(TEXCOORD7.x) + 1)];
        _M0135[2] = _Bone1[(3*int(TEXCOORD7.x) + 2)];
        _v0135 = vec4(TEXCOORD1.x, TEXCOORD1.y, TEXCOORD1.z, 0.00000000E+000);
        _r0135.x = dot(_M0135[0], _v0135);
        _r0135.y = dot(_M0135[1], _v0135);
        _r0135.z = dot(_M0135[2], _v0135);
        _Normal = _Normal + _r0135*TEXCOORD5.x;
    } // end if
    if (TEXCOORD5.y > 0.00000000E+000) { // if begin
        _M0143[0] = _Bone1[(3*int(TEXCOORD7.y) + 0)];
        _M0143[1] = _Bone1[(3*int(TEXCOORD7.y) + 1)];
        _M0143[2] = _Bone1[(3*int(TEXCOORD7.y) + 2)];
        _v0143 = vec4(TEXCOORD1.x, TEXCOORD1.y, TEXCOORD1.z, 0.00000000E+000);
        _r0143.x = dot(_M0143[0], _v0143);
        _r0143.y = dot(_M0143[1], _v0143);
        _r0143.z = dot(_M0143[2], _v0143);
        _Normal = _Normal + _r0143*TEXCOORD5.y;
    } // end if
    if (TEXCOORD5.z > 0.00000000E+000) { // if begin
        _M0151[0] = _Bone1[(3*int(TEXCOORD7.z) + 0)];
        _M0151[1] = _Bone1[(3*int(TEXCOORD7.z) + 1)];
        _M0151[2] = _Bone1[(3*int(TEXCOORD7.z) + 2)];
        _v0151 = vec4(TEXCOORD1.x, TEXCOORD1.y, TEXCOORD1.z, 0.00000000E+000);
        _r0151.x = dot(_M0151[0], _v0151);
        _r0151.y = dot(_M0151[1], _v0151);
        _r0151.z = dot(_M0151[2], _v0151);
        _Normal = _Normal + _r0151*TEXCOORD5.z;
    } // end if
    if (TEXCOORD5.w > 0.00000000E+000) { // if begin
        _M0159[0] = _Bone1[(3*int(TEXCOORD7.w) + 0)];
        _M0159[1] = _Bone1[(3*int(TEXCOORD7.w) + 1)];
        _M0159[2] = _Bone1[(3*int(TEXCOORD7.w) + 2)];
        _v0159 = vec4(TEXCOORD1.x, TEXCOORD1.y, TEXCOORD1.z, 0.00000000E+000);
        _r0159.x = dot(_M0159[0], _v0159);
        _r0159.y = dot(_M0159[1], _v0159);
        _r0159.z = dot(_M0159[2], _v0159);
        _Normal = _Normal + _r0159*TEXCOORD5.w;
    } // end if
    _v0167 = vec4(_Pos.x, _Pos.y, _Pos.z, 1.00000000E+000);
    _r0167.x = dot(_modelViewProj1[0], _v0167);
    _r0167.y = dot(_modelViewProj1[1], _v0167);
    _r0167.z = dot(_modelViewProj1[2], _v0167);
    _r0167.w = dot(_modelViewProj1[3], _v0167);
    _v0177 = vec4(_Normal.x, _Normal.y, _Normal.z, 0.00000000E+000);
    _r0177.x = dot(_Local2View1[0], _v0177);
    _r0177.y = dot(_Local2View1[1], _v0177);
    _r0177.z = dot(_Local2View1[2], _v0177);
    _v0187 = vec4(cg_Vertex.x, cg_Vertex.y, cg_Vertex.z, 1.00000000E+000);
    _r0187.x = dot(_Local2View1[0], _v0187);
    _r0187.y = dot(_Local2View1[1], _v0187);
    _r0187.z = dot(_Local2View1[2], _v0187);
    _r0187.w = dot(_Local2View1[3], _v0187);
    cg_TexCoord2 = _r0187;
    cg_TexCoord0.xy = TEXCOORD0.xy;
    cg_TexCoord3.xyz = TEXCOORD3.xyz;
    cg_TexCoord1.xyz = _r0177.xyz;
    gl_Position = _r0167;
    cg_FrontColor = COLOR;
    return;
} // main end
]] 
-- 
------------------------------------------------------------------------------------------------------------  
