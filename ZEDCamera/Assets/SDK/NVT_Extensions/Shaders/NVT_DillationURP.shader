Shader "NVT/Dillation URP"
{
    Properties
    {
        [NoScaleOffset] _BaseMap("Main Texture", 2D) = "black" {}
        _Type("Type: 0 = □; 1 = ◊; 2 = ○", Int) = 0
        _Size("Kernel Size", Int) = 5
        _Separation("Separation",Range(1.0, 10.0)) = 2.0
        _MinThreshold("Min Threshold",Range(0.0, 1.0)) = 0.0
        _MaxThreshold("Max Threshold",Range(0.0, 1.0)) = 0.5
    }

    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        // The Blit.hlsl file provides the vertex shader (Vert),
        // input structure (Attributes) and output strucutre (Varyings)
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "Dillation"

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_TexelSize;

                int _Type;
                int _Size;
                float _Separation;
                float _MinThreshold;
                float _MaxThreshold;
            CBUFFER_END

            // The fragment shader definition.
            half4 Frag(Varyings IN) : SV_Target
            {
                half4 c = SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, IN.texcoord).bgra;

                float2 texSize = _BaseMap_TexelSize.zw;
                float2 fragCoord = IN.texcoord;

                float max = 0.0;
                float4 cmax = c;

                for (int i = -_Size; i <= _Size; ++i)
                {
                    for (int j = -_Size; j <= _Size; ++j)
                    {
                        // Rectangular shape
                        // DEFAULT

                        // Diamond shape
                        if (_Type == 1)
                        {
                            if (!(abs(i) <= _Size - abs(j)))
                            {
                                continue;
                            }
                        }

                        // Circular shape
                        if (_Type == 2)
                        {
                            if (!(distance(float2(i, j), float2(0, 0)) <= _Size))
                            {
                                continue;
                            }
                        }

                        float4 col = SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, (IN.texcoord + (float2(i, j) * _Separation) / texSize));

                        float maxt = dot(col.rgb, float3(0.21, 0.72, 0.07));

                        if (maxt > max) {
                            max = maxt;
                            cmax = col;
                        }
                    }
                }

                c.rgb = lerp(c.rgb, cmax.rgb, smoothstep(_MinThreshold, _MaxThreshold, max));

                // Returning the ouput.
                return c;
            }

            ENDHLSL
        }
    }
}
