#version 120

attribute vec4 mc_Entity;

uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

varying vec2 texCoord;
varying vec4 vertexColor;

#define WAVING_FOLIAGE
#define WAVE_AMOUNT 0.12 // [0.00 0.05 0.08 0.12 0.16 0.22]

void main() {
    vec4 localPosition = gl_Vertex;
    vec4 originalShadowView = gl_ModelViewMatrix * localPosition;
    vec3 playerPosition = (shadowModelViewInverse * vec4(originalShadowView.xyz, 1.0)).xyz;
    vec3 worldPosition = playerPosition + cameraPosition;

#ifdef WAVING_FOLIAGE
    float plant = float(abs(mc_Entity.x - 10002.0) < 0.5);
    float leaves = float(abs(mc_Entity.x - 10003.0) < 0.5);
    float breeze = sin(worldPosition.x * 0.71 + worldPosition.z * 0.93 + frameTimeCounter * 1.25);
    breeze += sin(worldPosition.x * 1.73 - worldPosition.z * 1.21 - frameTimeCounter * 0.74) * 0.45;
    localPosition.x += breeze * WAVE_AMOUNT * (plant + leaves * 0.42);
    localPosition.z += breeze * WAVE_AMOUNT * 0.38 * (plant + leaves * 0.35);
#endif

    gl_Position = gl_ModelViewProjectionMatrix * localPosition;
    float distortion = length(gl_Position.xy) * 0.85 + 0.15;
    gl_Position.xy /= distortion;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexColor = gl_Color;
}
