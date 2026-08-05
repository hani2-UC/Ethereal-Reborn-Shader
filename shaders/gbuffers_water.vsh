#version 120

attribute vec4 mc_Entity;

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

varying vec2 texCoord;
varying vec2 lightCoord;
varying vec4 vertexColor;
varying vec3 viewPosition;
varying vec3 worldPosition;
varying vec3 worldNormal;
varying float blockId;

#define WATER_WAVES
#define WATER_HEIGHT_AMOUNT 0.07 // [0.00 0.025 0.04 0.07 0.11 0.15]

void main() {
    vec4 localPosition = gl_Vertex;
    vec4 originalView = gl_ModelViewMatrix * localPosition;
    vec3 originalPlayer = (gbufferModelViewInverse * vec4(originalView.xyz, 1.0)).xyz;
    vec3 originalWorld = originalPlayer + cameraPosition;
    float exactWater = float(abs(mc_Entity.x - 10001.0) < 0.5);

#ifdef WATER_WAVES
    float topSurface = step(0.55, gl_Normal.y);
    float wave = sin(originalWorld.x * 0.72 + frameTimeCounter * 1.05) * 0.50;
    wave += sin(originalWorld.z * 0.91 - frameTimeCounter * 0.82) * 0.30;
    wave += sin((originalWorld.x + originalWorld.z) * 1.37 + frameTimeCounter * 0.57) * 0.20;
    // Range is [-WATER_HEIGHT_AMOUNT, 0]. The crest never rises above
    // Minecraft's original water plane.
    localPosition.y += (wave - 1.0) * 0.5 * WATER_HEIGHT_AMOUNT * exactWater * topSurface;
#endif

    vec4 currentView = gl_ModelViewMatrix * localPosition;
    vec3 currentPlayer = (gbufferModelViewInverse * vec4(currentView.xyz, 1.0)).xyz;
    vec3 normalView = normalize(gl_NormalMatrix * gl_Normal);

    gl_Position = gl_ProjectionMatrix * currentView;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    viewPosition = currentView.xyz;
    worldPosition = currentPlayer + cameraPosition;
    worldNormal = normalize(mat3(gbufferModelViewInverse) * normalView);
    blockId = mc_Entity.x;
}
