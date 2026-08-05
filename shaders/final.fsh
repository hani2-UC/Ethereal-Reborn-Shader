#version 120

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texCoord;

#define BLOOM
#define BLOOM_STRENGTH 0.65 // [0.00 0.25 0.40 0.65 0.90 1.15]
#define COLOR_GRADE
#define EXPOSURE 0.92 // [0.80 0.88 0.92 0.98 1.00 1.08]
#define SATURATION 1.18 // [0.90 1.00 1.10 1.18 1.25 1.35]
#define VIGNETTE 0.14 // [0.00 0.06 0.10 0.14 0.18 0.24]

vec3 bloomSource(vec2 uv) {
    vec3 color = texture2D(colortex0, clamp(uv, 0.001, 0.999)).rgb;
    float peak = max(color.r, max(color.g, color.b));
    float threshold = smoothstep(0.86, 1.42, peak);
    float chroma = peak - min(color.r, min(color.g, color.b));
    return color * threshold * (0.70 + chroma * 0.65);
}

vec3 gatherBloom(vec2 uv) {
    vec2 pixel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 bloom = bloomSource(uv) * 0.10;

    vec2 r1 = pixel * 2.5;
    bloom += bloomSource(uv + vec2( r1.x, 0.0)) * 0.085;
    bloom += bloomSource(uv + vec2(-r1.x, 0.0)) * 0.085;
    bloom += bloomSource(uv + vec2(0.0,  r1.y)) * 0.085;
    bloom += bloomSource(uv + vec2(0.0, -r1.y)) * 0.085;
    bloom += bloomSource(uv + vec2( r1.x,  r1.y)) * 0.060;
    bloom += bloomSource(uv + vec2(-r1.x,  r1.y)) * 0.060;
    bloom += bloomSource(uv + vec2( r1.x, -r1.y)) * 0.060;
    bloom += bloomSource(uv + vec2(-r1.x, -r1.y)) * 0.060;

    vec2 r2 = pixel * 7.0;
    bloom += bloomSource(uv + vec2( r2.x, 0.0)) * 0.050;
    bloom += bloomSource(uv + vec2(-r2.x, 0.0)) * 0.050;
    bloom += bloomSource(uv + vec2(0.0,  r2.y)) * 0.050;
    bloom += bloomSource(uv + vec2(0.0, -r2.y)) * 0.050;
    bloom += bloomSource(uv + vec2( r2.x,  r2.y)) * 0.035;
    bloom += bloomSource(uv + vec2(-r2.x,  r2.y)) * 0.035;
    bloom += bloomSource(uv + vec2( r2.x, -r2.y)) * 0.035;
    bloom += bloomSource(uv + vec2(-r2.x, -r2.y)) * 0.035;

    vec2 r3 = pixel * 15.0;
    bloom += bloomSource(uv + vec2( r3.x, 0.0)) * 0.032;
    bloom += bloomSource(uv + vec2(-r3.x, 0.0)) * 0.032;
    bloom += bloomSource(uv + vec2(0.0,  r3.y)) * 0.032;
    bloom += bloomSource(uv + vec2(0.0, -r3.y)) * 0.032;
    return bloom;
}

vec3 acesToneMap(vec3 color) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

void main() {
    vec3 color = texture2D(colortex0, texCoord).rgb;

#ifdef BLOOM
    color += gatherBloom(texCoord) * BLOOM_STRENGTH;
#endif

#ifdef COLOR_GRADE
    color *= EXPOSURE;
    color = acesToneMap(color);
    color = pow(color, vec3(1.075));
    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(luminance), color, SATURATION);
    color = (color - 0.5) * 1.075 + 0.5;
    color *= vec3(1.005, 0.975, 1.025);
    color += vec3(0.006, 0.002, 0.010) * (1.0 - luminance);

    vec2 centered = texCoord * 2.0 - 1.0;
    float vignette = 1.0 - dot(centered, centered) * VIGNETTE;
    color *= clamp(vignette, 0.58, 1.0);
#endif

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
