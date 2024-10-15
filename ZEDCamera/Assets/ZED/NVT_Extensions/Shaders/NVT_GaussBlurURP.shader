Shader "NVT/GaussBlur URP"
{
    Properties
    { 
        [NoScaleOffset] _BaseMap("Main Texture", 2D) = "black" {}
        [KeywordEnum(Horizontal, Vertical)] _DirectionEnum("Direction", int) = 0
        [HideInInspector] _Direction("Direction", Vector) = (0.0, 0.0, 0.0, 0.0)
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
            Name "Gaussian Blur (Horizontal/Vertical)"
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment FragHorizontal

            #pragma  shader_feature _DIRECTIONENUM_HORIZONTAL _DIRECTIONENUM_VERTICAL

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_TexelSize;

                float4 _Direction;
            CBUFFER_END

            // The fragment shader definition.
            half4 FragHorizontal(Varyings IN) : SV_Target
            {
                const float offset[] = {0.0, 1.0, 2.0, 3.0, 4.0};
                const float weight[] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };

                half4 c = SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, IN.texcoord).bgra;

                float2 texSize = _BaseMap_TexelSize.zw;

                float4 ppColor = c * weight[0];

                float4 fragmentColor = float4(0.0, 0.0, 0.0, 0.0);

#ifdef _DIRECTIONENUM_HORIZONTAL
                //(1.0, 0.0) -> horizontal blur
                _Direction.x = 1;
                _Direction.y = 0;
#elif _DIRECTIONENUM_VERTICAL
                //(0.0, 1.0) -> vertical blur
                _Direction.x = 0;
                _Direction.y = 1;
#endif
                float hstep = _Direction.x;
                float vstep = _Direction.y;

                for (int i = 1; i < 5; i++)
                {
                    fragmentColor +=
                        SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, IN.texcoord.xy + (float2(hstep * offset[i], vstep * offset[i]) / texSize)) * weight[i] +
                        SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, IN.texcoord.xy - (float2(hstep * offset[i], vstep * offset[i]) / texSize)) * weight[i];
                }

                ppColor += fragmentColor;

                c.rgb = ppColor.rgb;

                // Returning the output.
                return c;
            }

            ENDHLSL
        }

        Pass
        {
            Name "Blur Vertical"
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment FragVertical

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_TexelSize;

                float4 _Direction;
            CBUFFER_END

            half4 FragVertical(Varyings IN) : SV_Target
            {
                const float offset[] = {0.0, 1.0, 2.0, 3.0, 4.0};
                const float weight[] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };

                half4 c = SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, IN.texcoord).bgra;

                float2 texSize = _BaseMap_TexelSize.zw;

                float4 ppColor = c * weight[0];

                float4 fragmentColor = float4(0.0, 0.0, 0.0, 0.0);

                _Direction.x = 0;
                _Direction.y = 1;
                //(1.0, 0.0) -> horizontal blur
                //(0.0, 1.0) -> vertical blur
                float hstep = _Direction.x;
                float vstep = _Direction.y;

                for (int i = 1; i < 5; i++)
                {
                    fragmentColor +=
                        SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, IN.texcoord.xy + (float2(hstep * offset[i], vstep * offset[i]) / texSize)) * weight[i] +
                        SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, IN.texcoord.xy - (float2(hstep * offset[i], vstep * offset[i]) / texSize)) * weight[i];
                }

                ppColor += fragmentColor;

                c.rgb = ppColor.rgb;

                // Returning the output.
                return c;
            }

            ENDHLSL
        }
    }
}
