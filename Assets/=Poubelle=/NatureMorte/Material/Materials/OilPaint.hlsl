Texture2D _CameraOpaqueTexture;
SamplerState sampler_CameraOpaqueTexture;

void OilPaint_float(
    float2 UV,
    float Radius,
    float2 InvSize,
    float Lift,
    float Strength,
    out float3 Out
)
{
    int intensityCount[10];
    float avgR[10];
    float avgG[10];
    float avgB[10];

    for (int i = 0; i < 10; i++)
    {
        intensityCount[i] = 0;
        avgR[i] = 0.0;
        avgG[i] = 0.0;
        avgB[i] = 0.0;
    }

    float radius = max(Radius, 1.0);

    // 25 samples seulement
    const int SAMPLE_COUNT = 5;

    for (int y = 0; y < SAMPLE_COUNT; y++)
    {
        float fy = (float)y / (float)(SAMPLE_COUNT - 1);
        float offsetY = (fy - 0.5) * radius;

        for (int x = 0; x < SAMPLE_COUNT; x++)
        {
            float fx = (float)x / (float)(SAMPLE_COUNT - 1);
            float offsetX = (fx - 0.5) * radius;

            float2 sampleUV = UV + float2(
                offsetX * InvSize.x,
                offsetY * InvSize.y
            );

            float3 tex = _CameraOpaqueTexture.SampleLevel(
                sampler_CameraOpaqueTexture,
                sampleUV,
                0
            ).rgb;

            float intensity =
                ((tex.r + tex.g + tex.b) / 3.0) * 10.0;

            int index = min((int)intensity, 9);

            intensityCount[index]++;
            avgR[index] += tex.r;
            avgG[index] += tex.g;
            avgB[index] += tex.b;
        }
    }

    int maxIndex = 0;
    int maxCount = 0;

    for (int i = 0; i < 10; i++)
    {
        if (intensityCount[i] > maxCount)
        {
            maxCount = intensityCount[i];
            maxIndex = i;
        }
    }

    float3 original = _CameraOpaqueTexture.SampleLevel(
        sampler_CameraOpaqueTexture,
        UV,
        0
    ).rgb;

    float3 oilResult;

    if (maxCount == 0)
    {
        oilResult = original;
    }
    else
    {
        oilResult = float3(
            avgR[maxIndex],
            avgG[maxIndex],
            avgB[maxIndex]
        ) / maxCount;
    }

    // -----------------------------------------
    // FORCE DE L'EFFET OIL PAINT
    // -----------------------------------------

    Strength = saturate(Strength);

    float3 result = lerp(
        original,
        oilResult,
        Strength
    );

    // -----------------------------------------
    // LIFT DES ZONES SOMBRES
    // -----------------------------------------

    float luminance = dot(
        result,
        float3(0.2126, 0.7152, 0.0722)
    );

    // Plus c'est sombre, plus le boost est important
    float shadowMask = 1.0 - smoothstep(
        0.0,
        0.65,
        luminance
    );

    // Éclaircit principalement les ombres
    result += result * Lift * shadowMask;

    Out = saturate(result);
}