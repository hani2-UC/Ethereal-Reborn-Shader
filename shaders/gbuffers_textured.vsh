#version 120

varying vec2 texCoord;
varying vec4 vertexColor;
varying vec3 viewNormal;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexColor = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
}
