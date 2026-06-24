//
//  LiquidBlob.metal
//  Glasskit — Foundry
//
//  A circular liquid-glass lens that refracts the content behind it.
//  Driven by four parameters (each 0...1, except waveAngle which is 0...2π):
//
//    baseDistortion — strength of the rolling liquid ripples
//    reflection     — brightness of the specular rim + glare hotspots
//    iridescence    — amount of rainbow chromatic fringing
//    waveAngle      — direction the ripples travel across the surface
//
//  This is a layerEffect shader: it samples the rasterized view texture
//  (`layer`) at offset positions, which is what lets the blob bend and
//  magnify whatever is drawn behind it. Requires iOS 17+.
//
//  Build/verify in layers — comment out later steps while you tune earlier
//  ones (mask → refraction → waves → chroma → specular → angle).
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>   // required for SwiftUI::Layer
using namespace metal;


// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------

// Rotate a 2D vector by an angle (radians). Used to steer the wave direction.
static float2 rotate2D(float2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return float2(v.x * c - v.y * s,
                  v.x * s + v.y * c);
}

// Cheap hash → pseudo-random value in 0...1 from a 2D input.
// Used to give the glare hotspots a little organic shimmer.
static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}


// ----------------------------------------------------------------------------
// Main shader
// ----------------------------------------------------------------------------
//
// Parameter order MUST match the Swift call site exactly:
//   .float2(size), .float(time),
//   .float(baseDistortion), .float(reflection),
//   .float(iridescence), .float(waveAngle)
//
[[ stitchable ]]
half4 liquidBlob(float2 position,
                 SwiftUI::Layer layer,
                 float2 size,
                 float time,
                 float baseDistortion,
                 float reflection,
                 float iridescence,
                 float waveAngle)
{
    // --- Normalized coordinates -------------------------------------------
    // p is a centered, aspect-corrected coord in -1...1 so the blob is round.
    float2 uv     = position / size;
    float2 p      = (uv - 0.5) * 2.0;
    p.x *= size.x / size.y;

    float radius = length(p);                       // 0 center, 1 edge


    // --- STEP 1 · Circular mask -------------------------------------------
    // Anti-aliased disc. Outside → clear, so the component is truly circular.
    float edge = 0.99;
    float mask = 1.0 - smoothstep(edge - 0.02, edge, radius);
    if (mask <= 0.0) {
        return half4(0.0);
    }


    // --- STEP 2 · Sphere normal + liquid ripples --------------------------
    // Build a fake 3D hemisphere normal from the disc, then perturb it with
    // scrolling sine waves so the surface looks like rolling liquid metal.
    float r2 = min(radius * radius, 1.0);
    float z  = sqrt(max(1e-4, 1.0 - r2));
    float3 N = normalize(float3(p, z));

    float2 rp = rotate2D(p, waveAngle);
    float  wave  = sin(rp.y * 9.0  + time * 1.6);
    wave        += sin(rp.y * 18.0 - time * 2.3) * 0.5;
    float  waveX = cos(rp.x * 8.0  - time * 1.3) * 0.5;

    // Ripples live in the interior and fade out at the rim.
    float interior = 1.0 - smoothstep(0.6, 1.0, radius);
    float2 ripple  = rotate2D(float2(waveX, wave), waveAngle)
                     * baseDistortion * 0.7 * interior;
    N = normalize(float3(N.xy + ripple, N.z));


    // --- STEP 3 · Refracted background (so a photo behind it shows) -------
    // Push the sample point inward near the rim (lens magnification) and along
    // the wave so the content behind the blob bends like real glass.
    float2 dir   = normalize(p + 1e-5);
    float  bend  = pow(radius, 2.0) * 0.35;
    float2 refractOffset = dir * bend * size.y * 0.5;
    float2 waveOffset    = rotate2D(float2(0.0, wave), waveAngle)
                           * baseDistortion * 26.0 * interior;
    float2 samplePos = position - refractOffset - waveOffset;

    // Chromatic split for iridescent edge fringing.
    float spread = iridescence * (0.6 + radius) * size.y * 0.012;
    half  rr = layer.sample(samplePos + dir * spread).r;
    half  gg = layer.sample(samplePos).g;
    half  bb = layer.sample(samplePos - dir * spread).b;
    half3 bg = half3(rr, gg, bb);


    // --- STEP 4 · Chrome environment reflection ---------------------------
    // Reflect the view vector off the (rippled) normal and read a procedural
    // "studio": a bright/grey world with soft horizontal softbox bands. This
    // is what makes the ball read as polished liquid metal / glass.
    float3 V   = float3(0.0, 0.0, 1.0);
    float3 Rfl = reflect(-V, N);

    float band = 0.5 + 0.5 * sin(Rfl.y * 5.0 + 1.2);
    band       = pow(band, 3.0);
    float vert = smoothstep(-0.5, 0.85, Rfl.y);
    float envL = mix(0.42, 1.0, vert) + band * 0.7;
    half3 env  = half3(half(clamp(envL, 0.0, 1.5)));

    // Fresnel: glancing angles (toward the rim) reflect more.
    float fres    = pow(1.0 - max(N.z, 0.0), 2.5);
    float reflAmt = clamp(reflection * (0.3 + 0.7 * fres), 0.0, 1.0);

    half3 col = mix(bg, env, half(reflAmt));


    // --- STEP 5 · Rim shading, fresnel line, specular hotspots -----------
    // (a) Silver rim darkening — the gradient that gives the sphere its form.
    float rimDark = smoothstep(0.55, 0.97, radius);
    col *= half(1.0 - rimDark * 0.5);

    // (b) Thin bright fresnel line right at the edge.
    float rimLine = smoothstep(0.92, 0.985, radius)
                    * (1.0 - smoothstep(0.99, 1.02, radius));
    col += half3(half(rimLine * (0.4 + reflection) * 1.2));

    // (c) Two glare hotspots that track the reflection vector.
    float shimmer = 0.9 + 0.1 * hash21(p * 8.0 + time);
    float3 L1 = normalize(float3(-0.45, 0.55, 0.7));
    float3 L2 = normalize(float3( 0.40, -0.45, 0.6));
    float  s1 = pow(max(dot(Rfl, L1), 0.0), 50.0);
    float  s2 = pow(max(dot(Rfl, L2), 0.0), 80.0);
    col += half3(half((s1 * 1.3 + s2 * 0.9) * reflection * shimmer));


    // --- STEP 6 · Iridescent fringe ---------------------------------------
    // Oil-slick rainbow that lives at the rim, strongest at glancing angles.
    half3 spectral = half3(0.5 + 0.5 * cos(6.2831 *
                     (radius * 3.0 + float3(0.0, 0.33, 0.67) + time * 0.08)));
    col = mix(col, col * 0.6h + spectral, half(iridescence) * half(fres));


    // --- STEP 7 · Composite -----------------------------------------------
    half4 color = half4(col, 1.0);
    color.a *= half(mask);
    return color;
}
