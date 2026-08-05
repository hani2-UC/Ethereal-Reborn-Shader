#version 120

uniform sampler2D texture;
uniform float alphaTestRef;

varying vec2 texCoord;
varying vec4 vertexColor;

/* DRAWBUFFERS:0 */

void main() {
    vec4 color = texture2D(texture, texCoord) * vertexColor;
    if (color.a < max(alphaTestRef, 0.10)) discard;
    gl_FragData[0] = vec4(1.0);
}
