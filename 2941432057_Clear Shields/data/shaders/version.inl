#ifdef HIGH
#ifdef VERTEX_SHADER
layout(location = 0) in vec3 vPosition;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vTex;
layout(location = 3) in vec4 vColor;
layout(location = 4) in uint vIndex;
layout(location = 5) in uint vInstancedIndex;
layout(location = 6) in float vSize;
layout(location = 7) in vec3 vTangent;
layout(location = 8) in vec3 vBitangent;
layout(location = 9) in vec4 vUtil0;
layout(location = 10) in vec4 vUtil1;
layout(location = 11) in vec4 vUtil2;
layout(location = 12) in vec4 vUtil3;
layout(location = 13) in vec2 vTexWorld;
layout(location = 14) in vec3 vLight;
#endif // VERTEX_SHADER

#ifdef FRAGMENT_SHADER
layout(location = 0) out vec4 outFragColor;

#if defined(DEFERRED)
layout(location = 1) out vec4 outNormalColor;
layout(location = 2) out vec4 outPositionColor;
#endif // DEFERRED
#endif // FRAGMENT_SHADER
#else

out vec4 outFragColor;

#ifdef VERTEX_SHADER
in vec3 vPosition;
in vec3 vNormal;
in vec2 vTex;
in vec4 vColor;
in float vIndex;
in float vInstancedIndex;
in float vSize;
in vec3 vTangent;
in vec3 vBitangent;
in vec4 vUtil0;
in vec4 vUtil1;
in vec4 vUtil2;
in vec4 vUtil3;
in vec2 vTexWorld;
in vec3 vLight;
#endif // VERTEX_SHADER

#endif // HIGH

#define NORMAL_MAPPING

float aberration = 0.06;
