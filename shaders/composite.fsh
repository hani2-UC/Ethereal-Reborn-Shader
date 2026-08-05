#version 120

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texCoord;

#define WATER_REFLECTIONS
#define SSR_STEPS 48 // [16 24 32 48 64]
#define REFLECTION_STRENGTH 0.78 // [0.35 0.50 0.62 0.78 0.92 1.10]
#define FANTASY_SKY
#define AURORA
#define AURORA_STRENGTH 0.82 // [0.00 0.35 0.55 0.82 1.10 1.40]
#define NEBULA_STRENGTH 0.58 // [0.00 0.20 0.35 0.58 0.82 1.10]
#define SSAO
#define SSAO_STRENGTH 0.65 // [0.00 0.25 0.45 0.65 0.85 1.00]

/* const int colortex4Format = RGBA16F; */
/* DRAWBUFFERS:0 */

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    local = local * local * (3.0 - 2.0 * local);
    float a = hash21(cell);
    float b = hash21(cell + vec2(1.0, 0.0));
    float c = hash21(cell + vec2(0.0, 1.0));
    float d = hash21(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.55;
    for (int i = 0; i < 4; ++i) {
        value += valueNoise(p) * amplitude;
        p = mat2(1.60, 1.20, -1.20, 1.60) * p + 3.17;
        amplitude *= 0.48;
    }
    return value;
}

vec3 reconstructViewPosition(vec2 uv, float depth) {
    vec4 clip = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * clip;
    return view.xyz / view.w;
}

vec2 projectToScreen(vec3 viewPosition) {
    vec4 clip = gbufferProjection * vec4(viewPosition, 1.0);
    return clip.xy / clip.w * 0.5 + 0.5;
}

vec3 fantasyAtmosphere(vec3 viewDirection) {
    vec3 worldDirection = normalize(mat3(gbufferModelViewInverse) * viewDirection);
    float skyLuminance = dot(skyColor, vec3(0.299, 0.587, 0.114));
    float daylight = clamp(skyLuminance * 3.4, 0.0, 1.0);
    float night = 1.0 - daylight;
    float upward = clamp(worldDirection.y * 0.5 + 0.5, 0.0, 1.0);
    float horizon = pow(1.0 - abs(worldDirection.y), 3.0);

    vec3 dayZenith = max(skyColor * 1.28, vec3(0.10, 0.25, 0.48));
    vec3 dayHorizon = max(fogColor * 1.15, vec3(0.32, 0.45, 0.62));
    vec3 nightZenith = vec3(0.008, 0.012, 0.055);
    vec3 nightHorizon = vec3(0.055, 0.025, 0.115);
    vec3 daySky = mix(dayHorizon, dayZenith, pow(upward, 0.62));
    vec3 nightSky = mix(nightHorizon, nightZenith, pow(upward, 0.54));
    vec3 atmosphere = mix(nightSky, daySky, daylight);
    atmosphere += mix(vec3(0.12, 0.035, 0.18), vec3(0.34, 0.18, 0.08), daylight) * horizon * 0.42;

    vec2 celestial = worldDirection.xz / (abs(worldDirection.y) + 0.34);
    float clouds = fbm(celestial * 1.35 + vec2(frameTimeCounter * 0.002, 0.0));
    float nebula = smoothstep(0.48, 0.86, clouds);
    vec3 nebulaColor = mix(vec3(0.08, 0.42, 0.68), vec3(0.52, 0.10, 0.72), valueNoise(celestial * 2.7));
    atmosphere += nebulaColor * nebula * night * NEBULA_STRENGTH * (0.45 + upward * 0.55);

    vec2 starCell = floor(celestial * 310.0);
    float starRandom = hash21(starCell);
    float star = smoothstep(0.9925, 1.0, starRandom);
    float twinkle = 0.72 + 0.28 * sin(frameTimeCounter * (1.2 + starRandom) + starRandom * 31.0);
    atmosphere += mix(vec3(0.55, 0.78, 1.00), vec3(1.00, 0.72, 0.92), hash21(starCell + 9.3))
        * star * twinkle * night * smoothstep(-0.08, 0.18, worldDirection.y) * 1.8;

#ifdef AURORA
    float bandCenter = 0.20
        + sin(worldDirection.x * 5.2 + frameTimeCounter * 0.032) * 0.09
        + sin(worldDirection.z * 8.4 - frameTimeCounter * 0.021) * 0.045;
    float ribbon = exp(-abs(worldDirection.y - bandCenter) * 18.0);
    ribbon *= 0.62 + 0.38 * sin(worldDirection.x * 25.0 + worldDirection.z * 13.0 + frameTimeCounter * 0.12);
    ribbon = max(ribbon, 0.0);
    float auroraMask = smoothstep(-0.04, 0.10, worldDirection.y)
        * (1.0 - smoothstep(0.64, 0.92, worldDirection.y));
    vec3 auroraColor = mix(vec3(0.04, 1.00, 0.66), vec3(0.56, 0.16, 1.00),
        0.5 + 0.5 * sin(worldDirection.x * 9.0 - worldDirection.z * 6.0));
    atmosphere += auroraColor * ribbon * auroraMask * night * AURORA_STRENGTH * (1.0 - rainStrength);
#endif

    vec3 sunDirection = normalize(sunPosition);
    vec3 moonDirection = normalize(moonPosition);
    float sunDisc = smoothstep(0.99945, 0.99982, dot(viewDirection, sunDirection));
    float sunGlow = pow(max(dot(viewDirection, sunDirection), 0.0), 64.0);
    float moonDisc = smoothstep(0.99935, 0.99978, dot(viewDirection, moonDirection));
    atmosphere += vec3(1.00, 0.70, 0.38) * (sunDisc * 4.0 + sunGlow * 0.48) * daylight;
    atmosphere += vec3(0.58, 0.72, 1.00) * moonDisc * 2.6 * night;
    return atmosphere;
}

float ambientOcclusion(vec2 uv, float centerDepth) {
#ifdef SSAO
    vec2 pixel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    float centerDistance = -reconstructViewPosition(uv, centerDepth).z;
    float radius = mix(2.0, 7.0, clamp(centerDistance / 80.0, 0.0, 1.0));
    float occlusion = 0.0;
    vec2 offset;

    offset = vec2( 1.0, 0.0) * pixel * radius;
    float sampleDistance = -reconstructViewPosition(uv + offset, texture2D(depthtex0, uv + offset).r).z;
    occlusion += smoothstep(0.06, 1.4, centerDistance - sampleDistance) * (1.0 - smoothstep(1.5, 8.0, centerDistance - sampleDistance));
    offset = vec2(-1.0, 0.0) * pixel * radius;
    sampleDistance = -reconstructViewPosition(uv + offset, texture2D(depthtex0, uv + offset).r).z;
    occlusion += smoothstep(0.06, 1.4, centerDistance - sampleDistance) * (1.0 - smoothstep(1.5, 8.0, centerDistance - sampleDistance));
    offset = vec2(0.0,  1.0) * pixel * radius;
    sampleDistance = -reconstructViewPosition(uv + offset, texture2D(depthtex0, uv + offset).r).z;
    occlusion += smoothstep(0.06, 1.4, centerDistance - sampleDistance) * (1.0 - smoothstep(1.5, 8.0, centerDistance - sampleDistance));
    offset = vec2(0.0, -1.0) * pixel * radius;
    sampleDistance = -reconstructViewPosition(uv + offset, texture2D(depthtex0, uv + offset).r).z;
    occlusion += smoothstep(0.06, 1.4, centerDistance - sampleDistance) * (1.0 - smoothstep(1.5, 8.0, centerDistance - sampleDistance));
    offset = vec2( 0.707,  0.707) * pixel * radius;
    sampleDistance = -reconstructViewPosition(uv + offset, texture2D(depthtex0, uv + offset).r).z;
    occlusion += smoothstep(0.06, 1.4, centerDistance - sampleDistance) * (1.0 - smoothstep(1.5, 8.0, centerDistance - sampleDistance));
    offset = vec2(-0.707,  0.707) * pixel * radius;
    sampleDistance = -reconstructViewPosition(uv + offset, texture2D(depthtex0, uv + offset).r).z;
    occlusion += smoothstep(0.06, 1.4, centerDistance - sampleDistance) * (1.0 - smoothstep(1.5, 8.0, centerDistance - sampleDistance));
    offset = vec2( 0.707, -0.707) * pixel * radius;
    sampleDistance = -reconstructViewPosition(uv + offset, texture2D(depthtex0, uv + offset).r).z;
    occlusion += smoothstep(0.06, 1.4, centerDistance - sampleDistance) * (1.0 - smoothstep(1.5, 8.0, centerDistance - sampleDistance));
    offset = vec2(-0.707, -0.707) * pixel * radius;
    sampleDistance = -reconstructViewPosition(uv + offset, texture2D(depthtex0, uv + offset).r).z;
    occlusion += smoothstep(0.06, 1.4, centerDistance - sampleDistance) * (1.0 - smoothstep(1.5, 8.0, centerDistance - sampleDistance));
    return clamp(1.0 - occlusion / 8.0 * SSAO_STRENGTH, 0.25, 1.0);
#else
    return 1.0;
#endif
}

vec3 traceReflection(vec3 origin, vec3 direction, out float hitAmount) {
    vec3 rayPosition = origin + direction * 0.18;
    vec3 hitColor = vec3(0.0);
    hitAmount = 0.0;

    for (int i = 0; i < SSR_STEPS; ++i) {
        float progress = (float(i) + 1.0) / float(SSR_STEPS);
        rayPosition += direction * mix(0.16, 2.35, progress * progress);
        vec2 sampleUv = projectToScreen(rayPosition);
        if (sampleUv.x <= 0.002 || sampleUv.x >= 0.998 || sampleUv.y <= 0.002 || sampleUv.y >= 0.998) break;

        float sceneDepth = texture2D(depthtex1, sampleUv).r;
        if (sceneDepth < 0.99998) {
            vec3 scenePosition = reconstructViewPosition(sampleUv, sceneDepth);
            float difference = (-rayPosition.z) - (-scenePosition.z);
            float thickness = 0.28 + (-rayPosition.z) * 0.018;
            if (difference > 0.0 && difference < thickness) {
                hitColor = texture2D(colortex5, sampleUv).rgb;
                float edgeFade = smoothstep(0.0, 0.08, sampleUv.x)
                    * smoothstep(0.0, 0.08, sampleUv.y)
                    * smoothstep(0.0, 0.08, 1.0 - sampleUv.x)
                    * smoothstep(0.0, 0.08, 1.0 - sampleUv.y);
                hitAmount = edgeFade * (1.0 - progress * 0.48);
                break;
            }
        }
    }
    return hitColor;
}

void main() {
    vec4 sceneSample = texture2D(colortex0, texCoord);
    vec4 material = texture2D(colortex4, texCoord);
    float depth = texture2D(depthtex0, texCoord).r;
    vec3 viewPosition = reconstructViewPosition(texCoord, depth);
    vec3 viewDirection = normalize(viewPosition);
    vec3 color = sceneSample.rgb;

#ifdef FANTASY_SKY
    if (depth >= 0.99998) {
        vec3 generatedSky = fantasyAtmosphere(viewDirection);
        float chroma = max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b));
        float originalLuminance = dot(color, vec3(0.299, 0.587, 0.114));
        float preserveSpecial = smoothstep(0.16, 0.38, chroma) * smoothstep(0.035, 0.18, originalLuminance);
        color = mix(generatedSky, color, preserveSpecial);
    } else
#endif
    {
        float ao = ambientOcclusion(texCoord, depth);
        color *= ao;
        float distanceToCamera = length(viewPosition);
        float atmosphericFog = clamp(1.0 - exp(-distanceToCamera * (0.0022 + rainStrength * 0.0035)), 0.0, 0.54);
        vec3 fantasyFog = mix(fogColor, vec3(0.075, 0.095, 0.19), 0.32);
        color = mix(color, fantasyFog, atmosphericFog);
    }

#ifdef WATER_REFLECTIONS
    if (material.a > 0.45 && depth < 0.99998) {
        vec3 normal = normalize(material.rgb * 2.0 - 1.0);
        vec3 reflectionDirection = normalize(reflect(viewDirection, normal));
        float hitAmount = 0.0;
        vec3 screenReflection = traceReflection(viewPosition + normal * 0.08, reflectionDirection, hitAmount);
        vec3 skyReflection = fantasyAtmosphere(reflectionDirection);
        vec3 reflection = mix(skyReflection, screenReflection, hitAmount);

        vec3 viewToCamera = normalize(-viewPosition);
        float facing = clamp(dot(normal, viewToCamera), 0.0, 1.0);
        float fresnel = pow(1.0 - facing, 5.0);

        float opaqueDepth = texture2D(depthtex1, texCoord).r;
        vec3 opaquePosition = reconstructViewPosition(texCoord, opaqueDepth);
        float waterThickness = clamp(length(opaquePosition) - length(viewPosition), 0.0, 42.0);
        float deepWater = 1.0 - exp(-waterThickness * 0.095);

        float refractionStrength = mix(0.011, 0.003, facing) * (1.0 - deepWater * 0.45);
        vec2 refractionUv = clamp(texCoord + normal.xy * refractionStrength, vec2(0.002), vec2(0.998));
        vec3 refractedScene = texture2D(colortex5, refractionUv).rgb;
        vec3 transmittance = exp(-vec3(0.19, 0.070, 0.030) * waterThickness);
        vec3 deepColor = vec3(0.006, 0.070, 0.135);
        vec3 waterBody = refractedScene * transmittance + deepColor * (1.0 - transmittance);
        waterBody = mix(waterBody, mix(vec3(0.018, 0.27, 0.34), deepColor, deepWater), 0.12 + deepWater * 0.26);

        vec3 playerPosition = (gbufferModelViewInverse * vec4(viewPosition, 1.0)).xyz;
        vec3 worldPosition = playerPosition + cameraPosition;
        float causticA = sin(worldPosition.x * 1.72 + sin(worldPosition.z * 1.31 + frameTimeCounter * 0.76) * 1.25);
        float causticB = sin(worldPosition.z * 2.03 - sin(worldPosition.x * 1.17 - frameTimeCounter * 0.61) * 1.18);
        float caustics = pow(max(1.0 - abs(causticA + causticB) * 0.64, 0.0), 5.0);
        float shallowMask = exp(-waterThickness * 0.30) * (1.0 - deepWater);
        waterBody += vec3(0.10, 0.72, 0.76) * caustics * shallowMask * 0.34;
        color = waterBody;

        float reflectionAmount = REFLECTION_STRENGTH * mix(0.22, 0.92, fresnel);
        color = mix(color, reflection, clamp(reflectionAmount, 0.0, 0.96));
        float glint = pow(max(dot(reflectionDirection, normalize(shadowLightPosition)), 0.0), 96.0);
        color += mix(vec3(1.00, 0.70, 0.35), vec3(0.50, 0.70, 1.00),
            clamp((0.24 - dot(skyColor, vec3(0.333))) * 4.0, 0.0, 1.0)) * glint * 1.45;
    }
#endif

    gl_FragData[0] = vec4(color, sceneSample.a);
}
