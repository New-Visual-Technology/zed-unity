Shader "NVT/GaussBlur"
{
    Properties
    { 
        [NoScaleOffset] _BaseMap("Main Texture", 2D) = "defaulttexture" {}
        [HideInInspector]_Direction("Direction", Vector) = (0.0, 0.0, 0.0, 0.0)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE

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

        sampler2D _BaseMap;

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_TexelSize;
            float4 _BaseMap_ST;

            float4 _Direction;
        CBUFFER_END


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

            OUT.uv.xy = TRANSFORM_TEX(IN.uv, _BaseMap);
            OUT.uv.zw = 0;

            // Returning the output.
            return OUT;
        }

        // The fragment shader definition.
        half4 fragHorizontal(Varyings IN) : SV_Target
        {
            const float offset[] = {0.0, 1.0, 2.0, 3.0, 4.0};
            const float weight[] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };

            half4 c = tex2D(_BaseMap, IN.uv.xy).bgra;

            float2 texSize = _BaseMap_TexelSize.zw;

            float4 ppColor = c * weight[0];

            float4 fragmentColor = float4(0.0, 0.0, 0.0, 0.0);

            _Direction.x = 1;
            _Direction.y = 0;
            //(1.0, 0.0) -> horizontal blur
            //(0.0, 1.0) -> vertical blur
            float hstep = _Direction.x;
            float vstep = _Direction.y;

            for (int i = 1; i < 5; i++) {
                fragmentColor +=
                    tex2D(_BaseMap, IN.uv.xy + (float2(hstep * offset[i], vstep * offset[i]) / texSize)) * weight[i] +
                    tex2D(_BaseMap, IN.uv.xy - (float2(hstep * offset[i], vstep * offset[i]) / texSize)) * weight[i];
            }

            ppColor += fragmentColor;

            c.rgb = ppColor.rgb;

            // Returning the output.
            return c;
        }

        half4 fragVertical(Varyings IN) : SV_Target
        {
            const float offset[] = {0.0, 1.0, 2.0, 3.0, 4.0};
            const float weight[] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };

            half4 c = tex2D(_BaseMap, IN.uv.xy).bgra;

            float2 texSize = _BaseMap_TexelSize.zw;

            float4 ppColor = c * weight[0];

            float4 fragmentColor = float4(0.0, 0.0, 0.0, 0.0);

            _Direction.x = 0;
            _Direction.y = 1;
            //(1.0, 0.0) -> horizontal blur
            //(0.0, 1.0) -> vertical blur
            float hstep = _Direction.x;
            float vstep = _Direction.y;

            for (int i = 1; i < 5; i++) {
                fragmentColor +=
                    tex2D(_BaseMap, IN.uv.xy + (float2(hstep * offset[i], vstep * offset[i]) / texSize)) * weight[i] +
                    tex2D(_BaseMap, IN.uv.xy - (float2(hstep * offset[i], vstep * offset[i]) / texSize)) * weight[i];
            }

            ppColor += fragmentColor;

            c.rgb = ppColor.rgb;

            // Returning the output.
            return c;
        }

        ENDHLSL

        Pass
        {
            Name "Blur Horizontal"
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment fragHorizontal

            ENDHLSL
        }

        Pass
        {
            Name "Blur Vertical"
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment fragVertical

            ENDHLSL
        }
    }
}
