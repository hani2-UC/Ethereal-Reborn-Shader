#version 120

varying vec4 vertexColor;

/* DRAWBUFFERS:04 */

void main() {
    // Keep this pass vanilla. The fantasy sky is generated later from depth,
    // so special geometry such as the End portal is not mistaken for the sky.
    gl_FragData[0] = vertexColor;
    gl_FragData[1] = vec4(0.5, 0.5, 1.0, 0.0);
}
