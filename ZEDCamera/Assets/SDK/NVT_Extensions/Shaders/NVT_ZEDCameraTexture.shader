Shader "NVT/ZED Camera Texture"
{
    Properties
    {
        [NoScaleOffset] _CameraLeftTex("ZED Camera Left Eye Texture", 2D) = "defaulttexture" {}
        [NoScaleOffset] _CameraRightTex("ZED Camera Right Eye Texture", 2D) = "defaulttexture" {}
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

        // 0 -- Left Eye Texture
        Pass
        {
            Name "Left Eye"
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment frag

            TEXTURE2D_X(_CameraLeftTex);
            SAMPLER(sampler_CameraLeftTex);

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float4 color = SAMPLE_TEXTURE2D_X(_CameraLeftTex, sampler_CameraLeftTex, input.texcoord);
                return color;
            }

            ENDHLSL
        }

        // 1 -- Right Eye Texture
        Pass
        {
            Name "Right Eye"
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment frag

            TEXTURE2D_X(_CameraRightTex);
            SAMPLER(sampler_CameraRightTex);

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float4 color = SAMPLE_TEXTURE2D_X(_CameraRightTex, sampler_CameraRightTex, input.texcoord);
                return color;
            }

            ENDHLSL
        }
    }
}
