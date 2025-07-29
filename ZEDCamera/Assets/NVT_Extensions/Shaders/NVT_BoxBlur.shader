Shader "NVT/BoxBlur"
{
    Properties
    { 
        [NoScaleOffset] _MainTex("MainTex", 2D) = "defaulttexture" {}
        _Size("Kernel Size", Int) = 1
        _Separation("Separation",Range(1.0, 10.0)) = 1.0
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

            float4 _MainTex_TexelSize;

            int _Type;
            int _Size;
            float _Separation;
            float _MinThreshold;
            float _MaxThreshold;

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
                half4 c = tex2D(_MainTex, IN.uv.xy).bgra;

                float2 texSize = _MainTex_TexelSize.zw;

                half4 fragColor = half4(0.0, 0.0, 0.0, 0.0);
                float count = 0.0;

                for (int i = -_Size; i <= _Size; ++i)
                {
                    for (int j = -_Size; j <= _Size; ++j)
                    {
                        fragColor += tex2D(_MainTex, (IN.uv.xy + (float2(i, j) * _Separation) / texSize));

                        count += 1.0;
                    }
                }

                c.rgb = (fragColor / count).rgb;

                // Returning the ouput.
                return c;
            }
            ENDHLSL
        }
    }
}
