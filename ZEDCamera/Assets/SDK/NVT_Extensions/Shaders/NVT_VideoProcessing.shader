Shader "NVT/VideoProcessing"
{
    Properties
    {
        [NoScaleOffset] [HideInInspector] _MainTex("MainTex", 2D) = "defaulttexture" {}
    }

    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #include "NVT_Fullscreen.hlsl"
        #include "NVT_Utils.cginc"

        SAMPLER(sampler_LinearClamp);

        TEXTURE2D_X(_MainTex);
        float4 _MainTex_TexelSize;

        half4 A;
        half4 B;
        half4 C;
        half4 D;
        half4 E;
        half4 F;
        half4 G;
        half4 H;
        half4 I;

        void Sample9Points(Varyings input)
        {
            float texelSize = _MainTex_TexelSize.x;
            float2 uv = UnityStereoTransformScreenSpaceTex(input.uv);

            A = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(-1.0, -1.0)); // 0
            B = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(0.0, -1.0)); // 1
            C = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(1.0, -1.0)); // 2
            D = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(-1.0, 0.0)); // 3
            E = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv); // 4
            F = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(1.0, 0.0)); // 5
            G = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(-1.0, 1.0)); // 6
            H = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(0.0, 1.0)); // 7
            I = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(1.0, 1.0)); // 8
        }

        half4 FragMean(Varyings input) : SV_Target
        {
            Sample9Points(input);

            float4 mean = (A + B + C + D + E + F + G + H + I) / 9.0;

            half3 color = mean.xyz;

            return half4(color, 1.0);
        }

        half4 FragHSV(Varyings input) : SV_Target
        {
            half3 color = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, input.uv).xyz;

            color = ColorspaceConversion_RGB_HSV_float(color.bgr);
            //color = ColorspaceConversion_LinearRGB_HSV_float(color.bgr);
            //color = RGBtoHSV(color);

            return half4(color.bgr, 1.0);
        }

        half4 FragGrayscale(Varyings input) : SV_Target
        {
            half3 color = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, input.uv).xyz;

            // Original color from ZED is BGR, converting it to RGB.
            color.rgb = dot(float3(0.299, 0.587, 0.114), color.bgr);

            // Output color has to be BGR again.
            return half4(color.bgr, 1.0);
        }

        half4 FragNeon(Varyings input) : SV_Target
        {
            Sample9Points(input);

            float4 sobelEdgeH = C + (2.0 * F) + I - (A + (2.0 * D) + G);
            float4 sobelEdgeV = A + (2.0 * B) + C - (G + (2.0 * H) + I);
            float4 sobel = sqrt((sobelEdgeH * sobelEdgeH) + (sobelEdgeV * sobelEdgeV));

            half3 color = E.xyz;

            // Negative multiplied with original color.
            color.rgb = saturate(1.0 - ((1.0 - color.rgb) * (1.0 - sobel.rgb)));

            return half4(color, 1.0);
        }

        half4 FragColorEdges(Varyings input) : SV_Target
        {
            Sample9Points(input);

            float4 sobelEdgeH = C + (2.0 * F) + I - (A + (2.0 * D) + G);
            float4 sobelEdgeV = A + (2.0 * B) + C - (G + (2.0 * H) + I);
            float4 sobel = sqrt((sobelEdgeH * sobelEdgeH) + (sobelEdgeV * sobelEdgeV));

            // Sobel edges only
            half3 color = saturate(sobel.rgb);

            return half4(color, 1.0);
        }

        half4 FragGrayscaleEdges(Varyings input) : SV_Target
        {
            Sample9Points(input);

            float4 sobelEdgeH = C + (2.0 * F) + I - (A + (2.0 * D) + G);
            float4 sobelEdgeV = A + (2.0 * B) + C - (G + (2.0 * H) + I);
            float4 sobel = sqrt((sobelEdgeH * sobelEdgeH) + (sobelEdgeV * sobelEdgeV));

            // Sobel edges converted to grayscale only
            float val = dot(float3(0.299, 0.587, 0.114), sobel.bgr);
            half3 color = saturate(half3(val, val, val));

            return half4(color, 1.0);
        }

        half4 FragColorEdgesAddedToGrayscale(Varyings input) : SV_Target
        {
            Sample9Points(input);

            float4 sobelEdgeH = C + (2.0 * F) + I - (A + (2.0 * D) + G);
            float4 sobelEdgeV = A + (2.0 * B) + C - (G + (2.0 * H) + I);
            float4 sobel = sqrt((sobelEdgeH * sobelEdgeH) + (sobelEdgeV * sobelEdgeV));

            // Sobel edges added to grayscale image
            float val = dot(float3(0.299, 0.587, 0.114), E.bgr);
            half3 color = saturate(val + sobel.rgb);

            return half4(color, 1.0);
        }

        half4 FragGrayscaleEdgesAddedToColor(Varyings input) : SV_Target
        {
            Sample9Points(input);

            float4 sobelEdgeH = C + (2.0 * F) + I - (A + (2.0 * D) + G);
            float4 sobelEdgeV = A + (2.0 * B) + C - (G + (2.0 * H) + I);
            float4 sobel = sqrt((sobelEdgeH * sobelEdgeH) + (sobelEdgeV * sobelEdgeV));

            // Grayscale sobel edges added to color image
            float val = dot(float3(0.299, 0.587, 0.114), sobel.bgr);
            half3 color = saturate(val + E.rgb);

            return half4(color, 1.0);
        }

        half4 FragGrayscaleEdgesAddedToGrayscale(Varyings input) : SV_Target
        {
            Sample9Points(input);

            float4 sobelEdgeH = C + (2.0 * F) + I - (A + (2.0 * D) + G);
            float4 sobelEdgeV = A + (2.0 * B) + C - (G + (2.0 * H) + I);
            float4 sobel = sqrt((sobelEdgeH * sobelEdgeH) + (sobelEdgeV * sobelEdgeV));

            // Grayscale sobel edges added to grayscale image
            float val = dot(float3(0.299, 0.587, 0.114), sobel.bgr);
            float val2 = dot(float3(0.299, 0.587, 0.114), E.bgr);

            half3 color = saturate(val + val2);

            return half4(color, 1.0);
        }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass // 0 - Grayscale
        {
            Name "Grayscale"

            HLSLPROGRAM

            #pragma vertex FullscreenVert
            #pragma fragment FragGrayscale

            ENDHLSL
        }

        Pass // 1 - Neon
        {
            Name "Neon"

            HLSLPROGRAM

            #pragma vertex FullscreenVert
            #pragma fragment FragNeon

            ENDHLSL
        }

        Pass // 2 - ColorEdges
        {
            Name "ColorEdges"

            HLSLPROGRAM

            #pragma vertex FullscreenVert
            #pragma fragment FragColorEdges

            ENDHLSL
        }

        Pass // 3 - GrayscaleEdges
        {
            Name "GrayscaleEdges"

            HLSLPROGRAM

            #pragma vertex FullscreenVert
            #pragma fragment FragGrayscaleEdges

            ENDHLSL
        }

        Pass // 4 - ColorEdgesAddedToGrayscale
        {
            Name "ColorEdgesAddedToGrayscale"

            HLSLPROGRAM

            #pragma vertex FullscreenVert
            #pragma fragment FragColorEdgesAddedToGrayscale

            ENDHLSL
        }

        Pass // 5 - GrayscaleEdgesAddedToColor
        {
            Name "GrayscaleEdgesAddedToColor"

            HLSLPROGRAM

            #pragma vertex FullscreenVert
            #pragma fragment FragGrayscaleEdgesAddedToColor

            ENDHLSL
        }

        Pass // 6 - GrayscaleEdgesAddedToGrayscale
        {
            Name "GrayscaleEdgesAddedToGrayscale"

            HLSLPROGRAM

            #pragma vertex FullscreenVert
            #pragma fragment FragGrayscaleEdgesAddedToGrayscale

            ENDHLSL
        }

    }
}
