#version 120

uniform sampler2D texture;
uniform float alphaTestRef;

varying vec2 texCoord;
varying vec4 vertexColor;
varying vec3 viewNormal;

/* DRAWBUFFERS:04 */

void main() {
    vec4 color = texture2D(texture, texCoord) * vertexColor;
    if (color.a < alphaTestRef) discard;

    gl_FragData[0] = color;
    gl_FragData[1] = vec4(normalize(viewNormal) * 0.5 + 0.5, 0.0);
}
