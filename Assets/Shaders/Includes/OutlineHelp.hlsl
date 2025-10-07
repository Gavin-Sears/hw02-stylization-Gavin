#ifndef SOBELOUTLINES_INCLUDED
#define SOBELOUTLINES_INCLUDED

SAMPLER(sampler_point_clamp);

void GetDepth_float(float2 uv, out float Depth)
{
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


void GetNormal_float(float2 uv, out float3 Normal)
{
    Normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv).rgb;
}

// These are points to sample relative to the starting point
static float2 sobelSamplePoints[9] =
{
    float2(-1, 1), float2(0, 1), float2(1, 1),
    float2(-1, 0), float2(0, 0), float2(1, 0),
    float2(-1, -1), float2(0, -1), float2(1, -1)
};

// Weights for the x component
static float sobelXMatrix[9] =
{
    1.0, 0.0, -1.0,
    2.0, 0.0, -2.0,
    1.0, 0.0, -1.0
};

// Weight for the y component
static float sobelYMatrix[9] =
{
    1.0, 2.0, 1.0,
    0.0, 0.0, 0.0,
    -1.0, -2.0, -1.0
};

void DepthSobel_float(float2 uv, float thickness, out float Out)
{
    float2 sobel = 0.0;
    
    [unroll]
    for (int i = 0; i < 9; ++i)
    {   
        float depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv + sobelSamplePoints[i] * thickness);
        sobel += depth * float2(sobelXMatrix[i], sobelYMatrix[i]);
    }

    Out = length(sobel);
}

void ColorSobel_float(float2 uv, float thickness, out float Out)
{
    float2 sobelR = 0;
    float2 sobelG = 0;
    float2 sobelB = 0;
    
    [unroll]
    for (int i = 0; i < 9; ++i)
    {
        float3 rgb = SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, uv + sobelSamplePoints[i] * thickness).rgb;
        
        float2 kernel = float2(sobelXMatrix[i], sobelYMatrix[i]);
        
        sobelR += rgb.r * kernel;
        sobelG += rgb.g * kernel;
        sobelB += rgb.b * kernel;
    }

    Out = max(length(sobelR), max(length(sobelG), length(sobelB)));
}

void NormSobel_float(float2 uv, float thickness, out float Out)
{
    float2 sobelR = 0;
    float2 sobelG = 0;
    float2 sobelB = 0;
    
    [unroll]
    for (int i = 0; i < 9; ++i)
    {
        float3 rgb = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv + sobelSamplePoints[i] * thickness).rgb;
        float2 kernel = float2(sobelXMatrix[i], sobelYMatrix[i]);
        
        sobelR += rgb.r * kernel;
        sobelG += rgb.g * kernel;
        sobelB += rgb.b * kernel;
    }

    Out = max(length(sobelR), max(length(sobelG), length(sobelB)));
}

#endif