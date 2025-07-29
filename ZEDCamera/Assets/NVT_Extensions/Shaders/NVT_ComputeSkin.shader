Shader "NVT/Compute Skin"
{
    Properties
    {
        _MainTex("Texture from ZED", 2D) = "" {}
        _WorkpieceMaskTex("Workpiece Mask Texture", 2D) = "" {}
        [Toggle(USE_WORKPIECE_MASK)] _UseWorkpieceMask("Use Workpiece Mask", Float) = 0
    }

    SubShader
    {
        Pass
        {
            Cull Off
            ZWrite Off
            Lighting Off

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0

            #pragma shader_feature USE_WORKPIECE_MASK

            #include "UnityCG.cginc"
            #include "ZED_Utils.cginc"
            #include "NVT_Utils.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _WorkpieceMaskTex;
            float4 _WorkpieceMaskTex_ST;

            v2f vert(appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 _MainTex_TexelSize;


            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float alpha = 1;

#ifdef USE_WORKPIECE_MASK
                float3 workpiece = tex2D(_WorkpieceMaskTex, uv).rgb;

                if (workpiece.r == 0)
                    return float4(0, 0, 0, alpha);
#endif

                uv.y = 1.0 - uv.y;
                float3 color = tex2D(_MainTex, uv).bgr;

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

            ENDCG
        }
    }
}
