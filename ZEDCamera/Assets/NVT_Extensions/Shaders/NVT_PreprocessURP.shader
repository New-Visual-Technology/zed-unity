Shader "NVT/Preprocess URP"
{
    Properties
    {
        _MainTex("Texture from ZED", 2D) = "white" {}
        _TmpWorkpieceMaskTex("Workpiece Mask Texture", 2D) = "" {}
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
        LOD 100

        Pass
        {
            Name "Preprocess"

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            TEXTURE2D_X(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D_X(_TmpWorkpieceMaskTex);
            SAMPLER(sampler_TmpWorkpieceMaskTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_TexelSize;

                float _erosion;
                uniform float _smoothness;
                uniform float _spill;
                float _whiteClip;
                float _blackClip;
            CBUFFER_END

            half4 Frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.texcoord;

                //Color from the camera
                float3 colorCamera = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, float2(uv.x, 1 - uv.y)).bgr;

                float alpha = SAMPLE_TEXTURE2D_X(_TmpWorkpieceMaskTex, sampler_TmpWorkpieceMaskTex, uv).r;
                float2 texSize = _MainTex_TexelSize.zw;

                float4 o;

                o.rgb = colorCamera.rgb;
                //o.a = 1;
                o.a = alpha;

                return o;

                // sample the texture
                float fullMask = pow(saturate(alpha / _smoothness), 1.5);
                //o.a = fullMask;
                //To use the despill
                float spillVal = pow(saturate(alpha / _spill), 1.5);
                float desat = (colorCamera.r * 0.2126 + colorCamera.g * 0.7152 + colorCamera.b * 0.0722);
                o.rgb = float3(desat, desat, desat) * (1. - spillVal) + colorCamera.rgb * (spillVal);

                float2 uv1 = clamp(uv + float2(-texSize.x * _erosion, 0), float2(texSize.x, texSize.y), float2(1 - texSize.x, 1 - texSize.y));
                float2 uv3 = clamp(uv + float2(0, -texSize.y * _erosion), float2(texSize.x, texSize.y), float2(1 - texSize.x, 1 - texSize.y));
                float2 uv5 = clamp(uv + float2(texSize.x * _erosion, 0), float2(texSize.x, texSize.y), float2(1 - texSize.x, 1 - texSize.y));
                float2 uv7 = clamp(uv + float2(0, texSize.y * _erosion), float2(texSize.x, texSize.y), float2(1 - texSize.x, 1 - texSize.y));

                if (_erosion >= 1) {

                    //Erosion with one pass not optimized, prefer erosion with multi pass
                    //0 | X | 0
                    //X | 0 | X
                    //0 | X | 0
                    //X are the sampling done
                    float a1 = pow(saturate(SAMPLE_TEXTURE2D_X(_TmpWorkpieceMaskTex, sampler_TmpWorkpieceMaskTex, uv1).r / _smoothness), 1.5);
                    float a2 = pow(saturate(SAMPLE_TEXTURE2D_X(_TmpWorkpieceMaskTex, sampler_TmpWorkpieceMaskTex, uv3).r / _smoothness), 1.5);
                    float a3 = pow(saturate(SAMPLE_TEXTURE2D_X(_TmpWorkpieceMaskTex, sampler_TmpWorkpieceMaskTex, uv5).r / _smoothness), 1.5);
                    float a4 = pow(saturate(SAMPLE_TEXTURE2D_X(_TmpWorkpieceMaskTex, sampler_TmpWorkpieceMaskTex, uv7).r / _smoothness), 1.5);

                    o.a = min(min(min(min(o.a, a1), a2), a3), a4);
                }
                else {
                    //o.a = fullMask;
                }

                //if (o.a > _whiteClip) o.a = 1;
                //else if (o.a < _blackClip) o.a = 0;

                return o;
            }
            ENDHLSL
        }
    }
}
