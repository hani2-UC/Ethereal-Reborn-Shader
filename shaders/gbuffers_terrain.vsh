#version 120

attribute vec4 mc_Entity;

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

varying vec2 texCoord;
varying vec2 lightCoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
varying vec3 playerPosition;

#define WAVING_FOLIAGE
#define WAVE_AMOUNT 0.12 // [0.00 0.05 0.08 0.12 0.16 0.22]

void main() {
    vec4 localPosition = gl_Vertex;
    vec4 originalView = gl_ModelViewMatrix * localPosition;
    vec3 originalPlayer = (gbufferModelViewInverse * vec4(originalView.xyz, 1.0)).xyz;
    vec3 worldPosition = originalPlayer + cameraPosition;

#ifdef WAVING_FOLIAGE
    float plant = float(abs(mc_Entity.x - 10002.0) < 0.5);
    float leaves = float(abs(mc_Entity.x - 10003.0) < 0.5);
    float breeze = sin(worldPosition.x * 0.71 + worldPosition.z * 0.93 + frameTimeCounter * 1.25);
    breeze += sin(worldPosition.x * 1.73 - worldPosition.z * 1.21 - frameTimeCounter * 0.74) * 0.45;
    localPosition.x += breeze * WAVE_AMOUNT * (plant + leaves * 0.42);
    localPosition.z += breeze * WAVE_AMOUNT * 0.38 * (plant + leaves * 0.35);
#endif

    vec4 viewPosition = gl_ModelViewMatrix * localPosition;
    gl_Position = gl_ProjectionMatrix * viewPosition;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    playerPosition = (gbufferModelViewInverse * vec4(viewPosition.xyz, 1.0)).xyz;
}
