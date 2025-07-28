Shader "NVT/Compute Skin URP"
{
    Properties
    {
        [NoScaleOffset] _CameraTex("Texture from ZED", 2D) = "" {}
        [NoScaleOffset] _WorkpieceMaskTex("Workpiece Mask Texture", 2D) = "" {}
        [Toggle(USE_WORKPIECE_MASK)] _UseWorkpieceMask("Use Workpiece Mask", Float) = 0
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
            Cull Off
            ZWrite Off
            Lighting Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #pragma shader_feature USE_WORKPIECE_MASK

            #include "NVT_Utils.cginc"

            TEXTURE2D_X(_CameraTex);
            SAMPLER(sampler_CameraTex);

            TEXTURE2D_X(_WorkpieceMaskTex);
            SAMPLER(sampler_WorkpieceMaskTex);

            // The fragment shader definition.
            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                float alpha = 1;

#ifdef USE_WORKPIECE_MASK
                float3 workpiece = SAMPLE_TEXTURE2D_X(_WorkpieceMaskTex, sampler_WorkpieceMaskTex, uv).rgb;

                if (workpiece.r == 0)
                {
                    return float4(0, 0, 0, alpha);
                }
#endif

                uv.y = 1.0 - uv.y;
                float3 color = SAMPLE_TEXTURE2D_X(_CameraTex, sampler_CameraTex, uv).bgr;

                // Convert camera color to...
                // ...normalized RRG
                float3 normrgb = RGBtoNormalizedRGB(color);
                // ...YCbCR
                float3 ycrcb = RGBtoYCrCb(color);
                // ...HSV
                //float3 hsv = RGBtoHSV(color);
                float3 hsv = ColorspaceConversion_RGB_HSV_float(color);
                // ...YCgCr
                float3 ycgcr = RGBtoYCgCr(color);

                float R = normrgb.r;
                float G = normrgb.g;
                float H = hsv.x;
                float S = hsv.y;
                float V = hsv.z;
                float Cr = ycrcb.y;
                float Cb = ycrcb.z;

                float CG = ycgcr.y;
                float CR = ycgcr.z;
                float CG255 = CG * 255.0;

                //return saturate(float4(normrgb, alpha));
                //return saturate(float4(hsv, alpha));
                //return saturate(float4(ycgcr, alpha));

                //if (
                //    (H >= 0.0 && H <= (35.0 / 360.0))
                //    )
                //{
                //    return float4(0, 0, 0, alpha);
                //}

                //if (
                //    (R / G > 1.185)
                //    )
                //{
                //    return float4(0, 0, 0, alpha);
                //}

                //if (
                //    (H >= 0.0 && H <= (25.0 / 360.0)) || (H >= (335.0 / 360.0) && H <= (360.0 / 360.0))
                //    )
                //{
                //    return float4(0, 0, 0, alpha);
                //}

                if (
                    (R / G > 1.185)
                    &&
                    (H >= 0.0 && H <= (35.0 / 360.0)) || (H >= (335.0 / 360.0) && H <= (360.0 / 360.0))
                    && (S >= 0.2 && S <= 0.6)
                    && (Cb > (77.0 / 255.0) && Cb < (127.0 / 255.0))
                    && (Cr > (133.0 / 255.0) && Cr < (173.0 / 255.0))
                    )
                {
                    return float4(0, 0, 0, alpha);
                }

                //if (
                //    (R / G > 1.185)
                //    &&
                //    (H >= 0.0 && H <= (25.0 / 360.0)) || (H >= (335.0 / 360.0) && H <= (360.0 / 360.0))
                //    && (S >= 0.2 && S <= 0.6)
                //    && (CG >= (85.0 / 255.0) && CG <= (135.0 / 255.0))
                //    && (CR >= ((-CG255 + 260.0) / 255.0) && Cr <= ((-CG255 + 280.0) / 255.0))
                //    )
                //{
                //    return float4(0, 0, 0, alpha);
                //}

                //if (
                //    (CG >= (85.0 / 255.0) && CG <= (135.0 / 255.0))
                //    && (CR >= ((-CG255 + 260.0) / 255.0) && Cr <= ((-CG255 + 280.0) / 255.0))
                //    )
                //{
                //    return float4(0, 0, 0, alpha);
                //}

                return float4(1, 1, 1, alpha);
            }

            ENDHLSL
        }
    }
}
