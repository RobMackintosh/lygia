#include "../../math/mmin.hlsl"

/*
contributors: Patricio Gonzalez Vivo
description: Convert CMYK to RGB
use: rgb2cmyk(<float3|float4> rgba)
license:
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Prosperity License - https://prosperitylicense.com/versions/3.0.0
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Patron License - https://lygia.xyz/license
*/

#ifndef FNC_RGB2CMYK
#define FNC_RGB2CMYK
float4 rgb2cmyk(float3 rgb) {
    float k = mmin(1.0 - rgb);
    float invK = 1.0 - k;
    float3 cmy = (1.0 - rgb - k) / invK;
    cmy *= step(0.0, invK);
    return saturate(float4(cmy, k));
}
#endif