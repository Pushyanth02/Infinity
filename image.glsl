
// INFINITY COSMOS — Prismatic Energy Edition
// Black background, rainbow infinity, colorful glowing orbs,
// flowing energy rays, and animated stars.

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

vec3 hsv2rgb(vec3 c)
{
    vec3 rgb = clamp(
        abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0)
        - 1.0,
        0.0, 1.0
    );
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

float starField(vec2 p)
{
    vec2 grid = p * 86.0;
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
    float visible = smoothstep(0.965, 0.998, h);
    float twinkle = 0.68 + 0.32 *
        sin(iTime * (1.6 + h * 4.0) + h * 90.0);

    return star * visible * twinkle;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float t = iTime;

    // Centered coordinates with correct screen proportions.
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 p = uv;

    float radius = length(p);
    float angle = atan(p.y, p.x);

    // Pure black space with white stars.
    vec3 col = vec3(0.0);
    col += vec3(0.78) * starField(uv) * 0.65;

    float tinyStars = pow(
        max(noise(uv * 132.0 + vec2(3.0, 7.0)) - 0.86, 0.0),
        5.0
    );
    col += vec3(0.25) * tinyStars;

    // Mathematical infinity curve.
    float a = 0.66;
    float r2 = dot(p, p);

    float field = r2 * r2
        - a * a * (p.x * p.x - p.y * p.y);

    vec2 gradient = vec2(
        4.0 * p.x * r2 - 2.0 * a * a * p.x,
        4.0 * p.y * r2 + 2.0 * a * a * p.y
    );

    float d = abs(field) / max(length(gradient), 0.001);

    // Flowing rainbow color along the infinity ribbon.
    float hue = fract(
        0.52 + 0.28 * p.x + 0.42 * p.y - t * 0.105
        + 0.035 * sin(12.0 * (p.x - p.y) - t * 1.7)
    );

    vec3 rainbow = hsv2rgb(vec3(hue, 0.88, 1.0));

    float flow = 0.68 + 0.32 * sin(
        26.0 * (p.x + p.y) - t * 4.1
        + 1.8 * sin(7.0 * p.y - t * 1.3)
    );

    float broadGlow = exp(-d * 8.5);
    float colorAura = exp(-d * 22.0);
    float whiteLine = exp(-d * 105.0);
    float whiteHotCore = exp(-d * 275.0);

    // Multicolored outer energy and brilliant white center.
    col += rainbow * broadGlow * 0.22;
    col += rainbow * colorAura * (0.48 + 0.42 * flow);
    col += rainbow * exp(-d * 48.0) * 0.26 * flow;

    col += vec3(0.90, 0.95, 1.0) *
        whiteLine * (0.70 + 0.30 * flow);

    col += vec3(1.0) * whiteHotCore * 1.15;

    // Rainbow energy rays spreading from the central crossing.
    float rayPattern = pow(
        max(0.0, cos(
            angle * 31.0
            + 0.45 * sin(angle * 7.0)
            - t * 0.22
        )),
        22.0
    );

    float rayFade = exp(-radius * 2.45)
        * smoothstep(0.025, 0.15, radius);

    float rayFlicker = 0.70 + 0.30 * sin(
        t * 2.6 + angle * 9.0 + noise(p * 18.0) * 4.0
    );

    vec3 rayColor = hsv2rgb(vec3(
        fract(angle / 6.2831853 + t * 0.045 + 0.15),
        0.92,
        1.0
    ));

    col += rayColor * rayPattern * rayFade * rayFlicker * 0.48;

    // Moving colored energy streaks flowing outward.
    float radialWave = 0.5 + 0.5 * sin(
        radius * 37.0 - t * 3.0 + noise(uv * 15.0) * 3.0
    );

    float wisps = pow(radialWave, 15.0) * exp(-radius * 2.2);

    vec3 wispColor = hsv2rgb(vec3(
        fract(angle / 6.2831853 - t * 0.055),
        0.84,
        1.0
    ));

    col += wispColor * wisps * 0.12;

    // Four colorful glowing orbs moving around the infinity symbol.
    for (int i = 0; i < 4; i++)
    {
        float phase = t * 0.78 + float(i) * 1.5707963;

        float s = sin(phase);
        float c = cos(phase);

        vec2 orbPos = a * vec2(c, s * c) / (1.0 + s * s);
        float orbDist = length(p - orbPos);

        float orbHalo = exp(-orbDist * orbDist * 125.0);
        float orbGlow = exp(-orbDist * orbDist * 620.0);
        float orbCore = exp(-orbDist * orbDist * 2600.0);

        float orbHue = fract(
            float(i) * 0.23 + t * 0.075
            + 0.08 * sin(phase * 1.7)
        );

        vec3 orbColor = hsv2rgb(vec3(orbHue, 0.92, 1.0));

        col += orbColor * orbHalo * 0.60;
        col += orbColor * orbGlow * 1.20;
        col += vec3(1.0) * orbCore * 1.65;
    }

    // Brilliant central nexus with a rainbow corona.
    float nexus = exp(-dot(p, p) * 155.0);
    float nexusPulse = 0.82 + 0.18 * sin(t * 2.2);

    col += hsv2rgb(vec3(
        fract(t * 0.07), 0.75, 1.0
    )) * nexus * 0.45 * nexusPulse;

    col += vec3(1.0) * exp(-dot(p, p) * 800.0) * 1.2;

    // Keep the background dark while softening bright highlights.
    col = col / (1.0 + col * 0.22);
    col = pow(max(col, 0.0), vec3(0.92));

    fragColor = vec4(col, 1.0);
}
