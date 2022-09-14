#include "../math/powFast.glsl"
#include "../math/saturate.glsl"
#include "../color/tonemap.glsl"

#include "shadow.glsl"
#include "material.glsl"
#include "fresnel.glsl"

#include "envMap.glsl"
#include "sphericalHarmonics.glsl"
#include "diffuse.glsl"
#include "specular.glsl"

/*
original_author: Patricio Gonzalez Vivo
description: simple PBR shading model
use: 
    - <vec4> pbrLittle(<Material> material) 
    - <vec4> pbrLittle(<vec4> baseColor, <vec3> normal, <float> roughness, <float> metallic [, <vec3> f0] ) 
options:
    - DIFFUSE_FNC: diffuseOrenNayar, diffuseBurley, diffuseLambert (default)
    - SPECULAR_FNC: specularGaussian, specularBeckmann, specularCookTorrance (default), specularPhongRoughness, specularBlinnPhongRoughnes (default on mobile)
    - LIGHT_POSITION: in GlslViewer is u_light
    - LIGHT_COLOR in GlslViewer is u_lightColor
    - CAMERA_POSITION: in GlslViewer is u_camera
*/

#ifndef CAMERA_POSITION
#if defined(GLSLVIEWER)
#define CAMERA_POSITION u_camera
#else
#define CAMERA_POSITION vec3(0.0, 0.0, -10.0);
#endif
#endif


#ifndef LIGHT_POSITION
#if defined(GLSLVIEWER)
#define LIGHT_POSITION  u_light
#else
#define LIGHT_POSITION  vec3(0.0, 10.0, -50.0)
#endif
#endif

#ifndef LIGHT_COLOR
#if defined(GLSLVIEWER)
#define LIGHT_COLOR     u_lightColor
#else
#define LIGHT_COLOR     vec3(0.5)
#endif
#endif

#ifndef FNC_PBR_LITTLE
#define FNC_PBR_LITTLE

vec4 pbrLittle(vec4 baseColor, vec3 position, vec3 normal, float roughness, float metallic, vec3 f0, float shadow ) {
    vec3 L = normalize(LIGHT_POSITION - position);
    vec3 N = normalize(normal);
    vec3 V = normalize(CAMERA_POSITION - position);

    float notMetal = 1. - metallic;
    float smooth = .95 - saturate(roughness);

    // DIFFUSE
    float diffuse = diffuse(L, N, V, roughness);
    float specular = specular(L, N, V, roughness);

    specular *= shadow;
    diffuse *= shadow;
    
    baseColor.rgb = baseColor.rgb * diffuse;
#ifdef SCENE_SH_ARRAY
    baseColor.rgb *= tonemapReinhard( sphericalHarmonics(N) );
#endif

    float NoV = dot(N, V); 

    // SPECULAR
    vec3 specIntensity =    vec3(1.0) *
                            (0.04 * notMetal + 2.0 * metallic) * 
                            saturate(-1.1 + NoV + metallic) * // Fresnel
                            (metallic + smooth * 4.0); // make smaller highlights brighter

    vec3 R = reflect(-V, N);
    vec3 ambientSpecular = tonemapReinhard( envMap(R, roughness, metallic) ) * specIntensity;
    ambientSpecular += fresnel(R, vec3(0.04), NoV) * metallic;

    baseColor.rgb = baseColor.rgb * notMetal + ( ambientSpecular 
                    + LIGHT_COLOR * 2.0 * specular
                    ) * (notMetal * smooth + baseColor.rgb * metallic);

    return baseColor;
}

vec4 pbrLittle(vec4 baseColor, vec3 position, vec3 normal, float roughness, float metallic, float shadow) {
    return pbrLittle(baseColor, position, normal, roughness, metallic, vec3(0.04), shadow);
}

vec4 pbrLittle(Material material) {
    return pbrLittle(material.baseColor, material.position, material.normal, material.roughness, material.metallic, material.ambientOcclusion * material.shadow) + vec4(material.emissive, 0.0);
}

#endif