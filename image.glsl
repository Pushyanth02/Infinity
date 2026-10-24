
float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float starField(vec2 p)
{
    vec2 grid = p * 82.0;
    vec2 id = floor(grid);
    vec2 f = fract(grid) - 0.5;

    float h = hash21(id + vec2(2.7, 8.1));
    vec2 offset = vec2(
        hash21(id + vec2(1.3, 4.1)),
        hash21(id + vec2(7.2, 2.6))
    ) - 0.5;

    vec2 q = f - offset * 0.65;
    float radius = mix(0.018, 0.075, hash21(id + 5.2));
    float star = exp(-dot(q, q) / (radius * radius));
    float visible = smoothstep(0.975, 0.998, h);
    float twinkle = 0.65 + 0.35 *
        sin(iTime * (1.6 + h * 4.0) + h * 90.0);

    return star * visible * twinkle;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float t = iTime;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy)
              / iResolution.y;
    vec2 p = uv;

    float a = 0.66;
    float r2 = dot(p, p);

    float field = r2 * r2
                - a * a * (p.x * p.x - p.y * p.y);

    vec2 gradient = vec2(
        4.0 * p.x * r2 - 2.0 * a * a * p.x,
        4.0 * p.y * r2 + 2.0 * a * a * p.y
    );

    float d = abs(field) / max(length(gradient), 0.001);

    float wideGlow = exp(-d * 10.0);
    float softGlow = exp(-d * 28.0);
    float line = exp(-d * 100.0);
    float hotLine = exp(-d * 260.0);

    vec3 col = vec3(0.0);
    col += vec3(0.72) * starField(uv) * 0.65;

    float glints = pow(
        max(noise(uv * 110.0 + vec2(3.0, 7.0)) - 0.87, 0.0),
        5.0
    );
    col += vec3(0.22) * glints;

    col += vec3(0.10) * wideGlow;
    col += vec3(0.22) * softGlow;
    col += vec3(0.62) * line;
    col += vec3(1.0) * hotLine;

    for (int i = 0; i < 4; i++)
    {
        float phase = t * 0.82 + float(i) * 1.5707963;
        float s = sin(phase);
        float c = cos(phase);

        vec2 beadPos = a * vec2(c, s * c)
                     / (1.0 + s * s);

        float beadDist = length(p - beadPos);
        float beadGlow = exp(-beadDist * beadDist * 520.0);
        float beadCore = exp(-beadDist * beadDist * 2600.0);

        col += vec3(0.34) * exp(-beadDist * 22.0);
        col += vec3(0.78) * beadGlow;
        col += vec3(1.0) * beadCore;
    }

    float nexus = exp(-dot(p, p) * 155.0);
    col += vec3(0.32) * nexus;

    col = clamp(col, 0.0, 1.0);
    fragColor = vec4(col, 1.0);
}
