#if !defined(NVT_UTILS)
#define NVT_UTILS

//Converts RGB to normalized RGB
float3 RGBtoNormalizedRGB(float3 rgb)
{
    float sum = dot(rgb, float3(255.0, 255.0, 255.0));

    return saturate((rgb * 255.0 / sum).rgb);
}

//Converts RGB to YCrCb
float3 RGBtoYCrCb(float3 rgb)
{
    float y = dot(rgb, float3(0.299, 0.587, 0.114));
    float cr = (rgb.r - y) * 0.713 + 128.0 / 255.0;
    float cb = (rgb.b - y) * 0.564 + 128.0 / 255.0;

    return saturate(float3(y, cr, cb));
}

//Converts RGB to YCgCr
float3 RGBtoYCgCr(float3 rgb)
{
    float3x3 RGB2YCgCr = { 65.481 / 255.0,  128.553 / 255.0,  24.966 / 255.0,
                           -81.085 / 255.0,  112.0 / 255.0,  -30.915 / 255.0,
                           112.0 / 255.0,  -93.786 / 255.0,  -18.214 / 255.0 };

    float3 YCgCr = float3(16.0 / 255, 128.0 / 255.0, 128.0 / 255.0) + mul(RGB2YCgCr, rgb);

    return saturate(YCgCr);
}

float3 RGBToHSVHelper(float offset, float dominantcolor, float colorone, float colortwo)
{
    float H;
    float S;
    float V = dominantcolor;

    //we need to find out which is the minimum color
    if (V != 0.0)
    {
        //we check which color is smallest
        float small = 0.0;
        if (colorone > colortwo) small = colortwo;
        else small = colorone;

        float diff = V - small;

        //if the two values are not the same, we compute the like this
        if (diff != 0.0)
        {
            //S = max-min/max
            S = diff / V;
            //H = hue is offset by X, and is the difference between the two smallest colors
            H = offset + ((colorone - colortwo) / diff);
        }
        else
        {
            //S = 0 when the difference is zero
            S = 0.0;
            //H = 4 + (R-G) hue is offset by 4 when blue, and is the difference between the two smallest colors
            H = offset + (colorone - colortwo);
        }

        H /= 6.0;

        //conversion values
        if (H < 0.0)
            H += 1.0f;
    }
    else
    {
        S = 0.0;
        H = 0.0;
    }

    return float3(H, S, V);
}

float3 RGBtoHSV(float3 rgb)
{
    // when blue is highest valued
    if ((rgb.b > rgb.g) && (rgb.b > rgb.r))
        return RGBToHSVHelper(4.0, rgb.b, rgb.r, rgb.g);
    //when green is highest valued
    else if (rgb.g > rgb.r)
        return RGBToHSVHelper(2.0, rgb.g, rgb.b, rgb.r);
    //when red is highest valued
    else
        return RGBToHSVHelper(0.0, rgb.r, rgb.g, rgb.b);
}

float3 ColorspaceConversion_RGB_HSV_float(float3 In)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 P = lerp(float4(In.bg, K.wz), float4(In.gb, K.xy), step(In.b, In.g));
    float4 Q = lerp(float4(P.xyw, In.r), float4(In.r, P.yzx), step(P.x, In.r));
    float D = Q.x - min(Q.w, Q.y);
    float  E = 1e-10;
    return float3(abs(Q.z + (Q.w - Q.y) / (6.0 * D + E)), D / (Q.x + E), Q.x);
}

float3 ColorspaceConversion_LinearRGB_HSV_float(float3 In)
{
    float3 sRGBLo = In * 12.92;
    float3 sRGBHi = (pow(max(abs(In), 1.192092896e-07), float3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
    float3 Linear = float3(In <= 0.0031308) ? sRGBLo : sRGBHi;
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 P = lerp(float4(Linear.bg, K.wz), float4(Linear.gb, K.xy), step(Linear.b, Linear.g));
    float4 Q = lerp(float4(P.xyw, Linear.r), float4(Linear.r, P.yzx), step(P.x, Linear.r));
    float D = Q.x - min(Q.w, Q.y);
    float  E = 1e-10;
    return float3(abs(Q.z + (Q.w - Q.y) / (6.0 * D + E)), D / (Q.x + E), Q.x);
}
#endif
