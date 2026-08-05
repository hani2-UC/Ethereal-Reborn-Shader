#version 120

varying vec4 vertexColor;

/* DRAWBUFFERS:04 */

void main() {
    gl_FragData[0] = vertexColor;
    gl_FragData[1] = vec4(0.5, 0.5, 1.0, 0.0);
}
