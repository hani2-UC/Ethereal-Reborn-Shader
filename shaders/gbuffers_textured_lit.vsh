#version 120

uniform mat4 gbufferModelViewInverse;

varying vec2 texCoord;
varying vec2 lightCoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
varying vec3 playerPosition;

void main() {
    vec4 viewPosition = gl_ModelViewMatrix * gl_Vertex;

    gl_Position = gl_ProjectionMatrix * viewPosition;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    playerPosition = (gbufferModelViewInverse * vec4(viewPosition.xyz, 1.0)).xyz;
}
