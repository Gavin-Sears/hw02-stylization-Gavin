#ifndef KUWAHARA
#define KUWAHARA

SAMPLER(sampler_point_clamp);

void GeneralizedKuwahara_float(float2 uv, out float4 Out)
{
    int k;
    float4 m[8];
    float3 s[8];
    int radius = _KernelSize / 2;
    
    if (_DepthAware)
    {
        float depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
        radius = round(lerp(_MinKernelSize / 2.0, _KernelSize / 2.0, smoothstep(0.0, 1.0, depth)));
    }
    
    for (k = 0; k < _N; ++k)
    {
        m[k] = 0.0;
        s[k] = 0.0;
    }
    
    float piN = 2.0 * 3.1459 / float(_N);
    
    float2x2 X = float2x2(
        float2(cos(piN), sin(piN)),
        float2(-sin(piN), cos(piN))
    );
    
    for (int x = -radius; x <= radius; ++x)
    {
        for (int y = -radius; y <= radius; ++ y)
        {
            float2 v = 0.5 * float2(x, y) / float(radius);
            float3 c = SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, uv + float2(x, y)).rgb;
            for (k = 0; k < _N; ++k)
            {
                float w = 1.0;
                
                m[k] += float4(c * w, w);
                s[k] += c * c * w;
                
                v = mul(X, v);
            }
        }
    }
    
    Out = 0.0;
    for (k = 0; k < _N; ++k)
    {
        m[k].rgb /= m[k].w;
        s[k] = abs(s[k] / m[k].w - m[k].rgb * m[k].rgb);
        
        float sigma2 = s[k].r + s[k].g + s[k].b;
        float w = 1.0 / (1.0 + pow(abs(1000.0 * sigma2), 0.5 * _Q));
        
        Out += float4(m[k].rgb * w, w);
    }
    
    Out /= Out.w;
}


#endif