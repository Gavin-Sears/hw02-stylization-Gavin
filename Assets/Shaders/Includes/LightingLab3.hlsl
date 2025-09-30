void ChooseColor_float(float3 Highlight, float3 Shadow, float Diffuse, float Threshold, out float3 OUT)
{
    if (Diffuse < Threshold)
    {
        OUT = Shadow;
    }
    else
    {
        OUT = Highlight;
    }
}

void ChooseColorThree_float(float3 Highlight, float3 Midtone, float3 Shadow, float Diffuse, float ThresholdA, float ThresholdB, out float3 OUT)
{
    if (Diffuse < ThresholdB)
    {
        OUT = Shadow;
    }
    else if (Diffuse < ThresholdA)
    {
        OUT = Midtone;
    }
    else
    {
        OUT = Highlight;
    }
}

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