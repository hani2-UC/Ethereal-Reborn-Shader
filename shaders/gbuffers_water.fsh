#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float alphaTestRef;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;

varying vec2 texCoord;
varying vec2 lightCoord;
varying vec4 vertexColor;
varying vec3 viewPosition;
varying vec3 worldPosition;
varying vec3 worldNormal;
varying float blockId;

#define WATER_WAVES
#define WATER_WAVE_AMOUNT 0.13 // [0.00 0.05 0.08 0.13 0.18 0.24]

/* DRAWBUFFERS:04 */

void main() {
    vec4 sourceTexture = texture2D(texture, texCoord) * vertexColor;
    if (sourceTexture.a < alphaTestRef) discard;

    vec3 lightColor = texture2D(lightmap, lightCoord).rgb;
    float exactWater = float(abs(blockId - 10001.0) < 0.5);
    float waterMask = exactWater;

    vec3 normalWorld = normalize(worldNormal);
#ifdef WATER_WAVES
    float topSurface = clamp(normalWorld.y, 0.0, 1.0);
    float slopeX = cos(worldPosition.x * 0.72 + frameTimeCounter * 1.05) * 0.40;
    slopeX += cos((worldPosition.x + worldPosition.z) * 1.37 + frameTimeCounter * 0.57) * 0.19;
    slopeX += cos(worldPosition.x * 2.43 - worldPosition.z * 1.18 - frameTimeCounter * 1.74) * 0.08;
    float slopeZ = cos(worldPosition.z * 0.91 - frameTimeCounter * 0.82) * 0.28;
    slopeZ += cos((worldPosition.x + worldPosition.z) * 1.37 + frameTimeCounter * 0.57) * 0.19;
    slopeZ += cos(worldPosition.z * 2.17 + worldPosition.x * 1.31 + frameTimeCounter * 1.48) * 0.08;
    normalWorld = normalize(normalWorld + vec3(-slopeX, 0.0, -slopeZ)
        * WATER_WAVE_AMOUNT * topSurface * waterMask);
#endif

    vec3 normalView = normalize(mat3(gbufferModelView) * normalWorld);
    vec3 nonWaterColor = sourceTexture.rgb * (lightColor * 0.72 + vec3(0.17, 0.23, 0.32));
    float broadRipple = 0.5 + 0.5 * sin(worldPosition.x * 0.44 + worldPosition.z * 0.58 + frameTimeCounter * 0.38);
    float fineRipple = 0.5 + 0.5 * sin(worldPosition.x * 1.71 - worldPosition.z * 1.29 - frameTimeCounter * 0.83);
    vec3 clearWater = mix(vec3(0.010, 0.16, 0.23), vec3(0.018, 0.34, 0.43), lightColor.b);
    clearWater = mix(clearWater, vec3(0.025, 0.42, 0.48), broadRipple * 0.18 + fineRipple * 0.07);

    vec4 base;
    base.rgb = mix(nonWaterColor, clearWater, waterMask);
    base.a = mix(sourceTexture.a, 0.74, waterMask);

    gl_FragData[0] = base;
    gl_FragData[1] = vec4(normalView * 0.5 + 0.5, waterMask);
}
