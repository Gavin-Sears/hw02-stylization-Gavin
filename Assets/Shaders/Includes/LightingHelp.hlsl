float GetBias(float t, float b)
{
    return (t / ((((1.0 / b) - 2.0) * (1.0 - t)) + 1.0));
}

float GetGain(float t, float g)
{
    if (t < 0.5)
    {
        return GetBias(t * 2.0, g) / 2.0;
    }
    else
    {
        return GetBias(t * 2.0 - 1.0, 1.0 - g) / 2.0 + 0.5;
    }
}

void ChooseColorThreeSmooth_float(float3 Highlight, float3 Midtone, float3 Shadow, float Diffuse, float ThresholdA, float GainA, float ThresholdB, float GainB, out float3 OUT)
{
    // start with midtone for blending
    OUT = Midtone;
    
    if (Diffuse < ThresholdB)
    {
        // blend shadow with midtone based on gain
        
        // diffuse = time, so we remap diffuse under threshold to range 0 to 1
        float remap = Diffuse / ThresholdB;
        float factor = GetGain(remap, GainB); // "B" is border between shadow and midtone
        
        // blend between highlight and current color. OUT is currently midtone blended with shadow
        OUT = lerp(Shadow, OUT, factor);
    }
    
    if (Diffuse > ThresholdA)
    {
        // blend higlight with midtone based on gain
        
        // diffuse = time, so we remap diffuse over threshold to range 0 to 1
        float remap = (Diffuse - ThresholdA) * (1.0 / (1.0 - ThresholdA));
        float factor = GetGain(remap, GainA); // "A" is border between highlight and midtone
        
        // blend between highlight and current color. OUT is currently midtone blended with shadow
        OUT = lerp(OUT, Highlight, factor);
    }
}

void GetMainLight_float(float3 WorldPos, out float3 Color, out float3 Direction, out float DistanceAtten, out float ShadowAtten)
{
#ifdef SHADERGRAPH_PREVIEW
    Direction = normalize(float3(0.5, 0.5, 0));
    Color = 1;
    DistanceAtten = 1;
    ShadowAtten = 1;
#else
#if SHADOWS_SCREEN
        float4 clipPos = TransformWorldToClip(WorldPos);
        float4 shadowCoord = ComputeScreenPos(clipPos);
#else
    float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
#endif

    Light mainLight = GetMainLight(shadowCoord);
    Direction = mainLight.direction;
    Color = mainLight.color;
    DistanceAtten = mainLight.distanceAttenuation;
    ShadowAtten = mainLight.shadowAttenuation;
#endif
}

void ComputeAdditionalLighting_float(float3 WorldPosition, float3 WorldNormal,
    float4 Thresholds, float4 Gains, float3 RampedDiffuseValues,
    out float3 Color, out float Diffuse)
{
    Color = float3(0, 0, 0);
    Diffuse = 0;
#ifndef SHADERGRAPH_PREVIEW
    int pixelLightCount = GetAdditionalLightsCount();
    
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPosition);
        float4 tmp = unity_LightIndices[i / 4];
        uint light_i = tmp[i % 4];

        half shadowAtten = light.shadowAttenuation * AdditionalLightRealtimeShadow(light_i, WorldPosition, light.direction);
        half NdotL = saturate(dot(WorldNormal, light.direction));
        half distanceAtten = light.distanceAttenuation;
        
        half thisDiffuse = distanceAtten * shadowAtten * NdotL;
        half rampedDiffuse = RampedDiffuseValues.y;
        
        if (thisDiffuse < Thresholds.x)
        {
            float remap = thisDiffuse / Thresholds.x;
            float factor = GetGain(remap, Gains.x);
        
            rampedDiffuse = lerp(RampedDiffuseValues.x, rampedDiffuse, factor);
        }
    
        if (thisDiffuse > Thresholds.y)
        {
            float remap = (thisDiffuse - Thresholds.y) * (1.0 / (1.0 - Thresholds.y));
            float factor = GetGain(remap, Gains.y);
        
            rampedDiffuse = lerp(rampedDiffuse, RampedDiffuseValues.z, factor);
        }

        if (shadowAtten * NdotL < Thresholds.z)
        {
            if (shadowAtten * NdotL <= 0.0)
            {
                rampedDiffuse = 0.0;
            }
            else
            {
                float remap = (shadowAtten * NdotL) / Thresholds.z;
                float factor = GetGain(remap, Gains.z);
                
                rampedDiffuse = lerp(0.0, rampedDiffuse, factor);
            }
        }
        if (light.distanceAttenuation <= Thresholds.w)
        {
            if (light.distanceAttenuation <= 0.0)
            {
                rampedDiffuse = 0.0;
            }
            else
            {
                float remap = light.distanceAttenuation / Thresholds.w;
                float factor = GetGain(remap, Gains.w);
                rampedDiffuse = lerp(0.0, rampedDiffuse, factor);
            }
        }
        
        Color += max(rampedDiffuse, 0) * light.color.rgb;
        Diffuse += rampedDiffuse;
    }
#endif
}

void ChooseColor_float(float3 Highlight, float3 Midtone, float3 Shadow, float Diffuse, float2 Thresholds, out float3 OUT)
{
    if (Diffuse < Thresholds.x)
    {
        OUT = Shadow;
    }
    else if (Diffuse < Thresholds.y)
    {
        OUT = Midtone;
    }
    else
    {
        OUT = Highlight;
    }
}
