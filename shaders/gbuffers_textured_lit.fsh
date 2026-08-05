#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;
uniform float alphaTestRef;
uniform float rainStrength;
uniform vec3 skyColor;
uniform vec3 shadowLightPosition;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

varying vec2 texCoord;
varying vec2 lightCoord;
varying vec4 vertexColor;
varying vec3 viewNormal;
varying vec3 playerPosition;

#define SHADOWS
#define SHADOW_STRENGTH 0.88 // [0.50 0.65 0.75 0.88 0.95 1.00]

const int shadowMapResolution = 2048;
const float shadowDistance = 160.0;
const float shadowIntervalSize = 2.0;
const bool shadowHardwareFiltering = false;

/* DRAWBUFFERS:04 */

float getShadow(vec3 playerPos, float normalLight) {
#ifdef SHADOWS
    vec4 shadowPosition = shadowProjection * shadowModelView * vec4(playerPos, 1.0);
    shadowPosition.xyz /= shadowPosition.w;
    float distortion = length(shadowPosition.xy) * 0.85 + 0.15;
    shadowPosition.xy /= distortion;
    shadowPosition = shadowPosition * 0.5 + 0.5;

    if (shadowPosition.x < 0.0 || shadowPosition.x > 1.0 ||
        shadowPosition.y < 0.0 || shadowPosition.y > 1.0 ||
        shadowPosition.z < 0.0 || shadowPosition.z > 1.0) return 1.0;

    float bias = mix(0.00065, 0.0024, 1.0 - normalLight);
    vec2 texel = vec2(1.0 / float(shadowMapResolution));
    float visibility = 0.0;
    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            float mapDepth = texture2D(shadowtex0, shadowPosition.xy + vec2(x, y) * texel).r;
            visibility += step(shadowPosition.z - bias, mapDepth);
        }
    }
    return mix(1.0 - SHADOW_STRENGTH, 1.0, visibility / 9.0);
#else
    return 1.0;
#endif
}

void main() {
    vec4 base = texture2D(texture, texCoord) * vertexColor;
    if (base.a < alphaTestRef) discard;

    vec3 normal = normalize(viewNormal);
    vec3 lightDirection = normalize(shadowLightPosition);
    float normalLight = max(dot(normal, lightDirection), 0.0);
    float shadow = getShadow(playerPosition, normalLight);
    vec3 vanillaLight = texture2D(lightmap, lightCoord).rgb;
    float skyLuminance = dot(skyColor, vec3(0.299, 0.587, 0.114));
    float night = clamp((0.26 - skyLuminance) * 4.0, 0.0, 1.0);
    vec3 directColor = mix(vec3(1.00, 0.87, 0.67), vec3(0.48, 0.62, 1.00), night);
    vec3 ambientTint = mix(vec3(0.18, 0.22, 0.30), vec3(0.28, 0.34, 0.46), night);
    vec3 lighting = vanillaLight * 0.64 + ambientTint * 0.21;
    lighting += directColor * normalLight * shadow * (0.55 - rainStrength * 0.22);

    base.rgb *= lighting;
    gl_FragData[0] = base;
    gl_FragData[1] = vec4(normal * 0.5 + 0.5, 0.0);
}
