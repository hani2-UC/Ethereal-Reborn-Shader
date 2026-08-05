#version 120

uniform sampler2D colortex0;

varying vec2 texCoord;

/* const int colortex5Format = RGBA16F; */
/* DRAWBUFFERS:5 */

void main() {
    // Preserve the opaque scene before water and glass are drawn. Composite
    // uses this clean image for water refraction and SSR hit colors.
    gl_FragData[0] = texture2D(colortex0, texCoord);
}
