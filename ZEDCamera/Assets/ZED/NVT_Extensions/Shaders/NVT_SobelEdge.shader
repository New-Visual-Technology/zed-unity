Shader "NVT/SobelEdge"
{
    Properties
    { 
        [NoScaleOffset] _MainTex("MainTex", 2D) = "defaulttexture" {}
        _Type("Type: 0=Off; [1-9]=Variants", Range(0, 9)) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // The Core.hlsl file contains definitions of frequently used HLSL
            // macros and functions, and also contains #include references to other
            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // The structure definition defines which variables it contains.
            // This example uses the Attributes structure as an input structure in
            // the vertex shader.
            struct Attributes
            {
                // The positionOS variable contains the vertex positions in object
                // space.
                // The uv variable contains the uv postion of the vertex.
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
                float4 uv           : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            int _Type;
            float4 _MainTex_TexelSize;

            // The kernel calculation for soble edge detection.
            void kernel(inout float4 n[9], sampler2D tex, float2 coord)
            {
                float w = 1.0 / _MainTex_TexelSize.z;
                float h = 1.0 / _MainTex_TexelSize.w;

                n[0] = tex2D(tex, coord + float2(-w, -h));
                n[1] = tex2D(tex, coord + float2(0.0, -h));
                n[2] = tex2D(tex, coord + float2(w, -h));
                n[3] = tex2D(tex, coord + float2(-w, 0.0));
                n[4] = tex2D(tex, coord);
                n[5] = tex2D(tex, coord + float2(w, 0.0));
                n[6] = tex2D(tex, coord + float2(-w, h));
                n[7] = tex2D(tex, coord + float2(0.0, h));
                n[8] = tex2D(tex, coord + float2(w, h));
            }

            float toGrayscale(float3 rgb)
            {
                return dot(rgb, float3(0.299, 0.587, 0.114));
            }

            // The vertex shader definition with properties defined in the Varyings 
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes IN)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings OUT;

                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous space
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                OUT.uv.xy = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.uv.zw = 0;

                // Returning the output.
                return OUT;
            }

            // The fragment shader definition.
            half4 frag(Varyings IN) : SV_Target
            {
                float4 n[9];
                kernel(n, _MainTex, IN.uv.xy);

                float4 sobelEdgeH = n[2] + (2.0 * n[5]) + n[8] - (n[0] + (2.0 * n[3]) + n[6]);
                float4 sobelEdgeV = n[0] + (2.0 * n[1]) + n[2] - (n[6] + (2.0 * n[7]) + n[8]);
                float4 sobel = sqrt((sobelEdgeH * sobelEdgeH) + (sobelEdgeV * sobelEdgeV));

                half4 c = tex2D(_MainTex, IN.uv.xy).rgba;
                
                // Color sobel.
                if (_Type == 1)
                {
                    c.rgb = sobel.rgb;
                }

                // Grayscale Sobel using r channel.
                if (_Type == 2)
                {
                    c.rgb = sobel.rrr;
                }

                // Color Sobel multiplied with original color.
                if (_Type == 3)
                {
                    c.rgb = saturate(c.rgb * sobel.rgb);
                }

                // Color Sobel negative multiplied with original color.
                if (_Type == 4)
                {
                    c.rgb = saturate(1.0 - ((1.0 - c.rgb) * (1.0 - sobel.rgb)));
                }

                // Color Sobel added to original color.
                if (_Type == 5)
                {
                    c.rgb = saturate(c.rgb + sobel.rgb);
                }

                // Color Sobel added to grayscale image.
                if (_Type == 6)
                {
                    float result = dot(c.rgb, float3(0.299, 0.587, 0.114));
                    c.rgb = saturate(result + sobel.rgb);
                }

                // Grayscale Sobel converting color to grayscale.
                if (_Type == 7)
                {
                    float resultSobel = dot(sobel.rgb, float3(0.299, 0.587, 0.114));
                    c.rgb = saturate(float3(resultSobel, resultSobel, resultSobel));
                }

                // Grayscale Sobel added to original color.
                if (_Type == 8)
                {
                    float resultSobel = dot(sobel.rgb, float3(0.299, 0.587, 0.114));
                    c.rgb = saturate(resultSobel + c.rgb);
                }

                // Grayscale Sobel added to grayscale image.
                if (_Type == 9)
                {
                    float resultSobel = dot(sobel.rgb, float3(0.299, 0.587, 0.114));
                    float result = dot(c.rgb, float3(0.299, 0.587, 0.114));
                    c.rgb = saturate(float3(result + resultSobel, result + resultSobel, result + resultSobel));
                }

                // Returning the output.
                return c;
            }
            ENDHLSL
        }
    }
}
