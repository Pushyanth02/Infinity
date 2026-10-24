//Infinity
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
    f *= f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 hsv2rgb(vec3 c)
{
    vec3 rgb = clamp(
        abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
        0.0, 1.0
    );

    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

float starField(vec2 p)
{
    vec2 grid = p * 84.0;
    vec2 id = floor(grid);
    vec2 f = fract(grid) - 0.5;

    float h = hash21(id + vec2(2.7, 8.1));

    vec2 offset = vec2(
        hash21(id + vec2(1.3, 4.1)),
        hash21(id + vec2(7.2, 2.6))
    ) - 0.5;

    vec2 q = f - offset * 0.65;
    float r = mix(0.018, 0.070, hash21(id + 5.2));

    float star = exp(-dot(q, q) / (r * r));
    float visible = smoothstep(0.966, 0.998, h);
    float twinkle = 0.72 + 0.28 *
        sin(iTime * (1.6 + h * 4.0) + h * 90.0);

    return star * visible * twinkle;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float t = iTime;
    vec2 p = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    vec3 col = vec3(0.0);
    col += vec3(0.75) * starField(p) * 0.58;

    float tinyStars = pow(
        max(noise(p * 135.0 + vec2(3.0, 7.0)) - 0.88, 0.0),
        5.0
    );

    col += vec3(0.22) * tinyStars;

    float a = 0.66;
    float r2 = dot(p, p);
    float field = r2 * r2 - a * a * (p.x * p.x - p.y * p.y);

    vec2 grad = vec2(
        4.0 * p.x * r2 - 2.0 * a * a * p.x,
        4.0 * p.y * r2 + 2.0 * a * a * p.y
    );

    float sd = field / max(length(grad), 0.001);
    float d = abs(sd);
    float angle = atan(p.y, p.x);

    float warpA = 1.55 * sin(17.0 * p.x - 13.0 * p.y - t * 1.8)
                + 0.72 * sin(11.0 * p.y + 16.0 * p.x + t * 1.35);

    float warpB = 1.25 * sin(14.0 * p.y + 12.0 * p.x + t * 1.65)
                + 0.68 * sin(22.0 * p.x - 9.0 * p.y - t * 2.1);

    float warpC = 1.05 * sin(19.0 * p.x + 8.0 * p.y + t * 1.25)
                - 0.82 * sin(13.0 * p.y - 15.0 * p.x - t * 1.9);

    float threadsA = pow(max(cos(sd * 510.0 + warpA), 0.0), 22.0);
    float threadsB = pow(max(cos(sd * 665.0 + warpB), 0.0), 34.0);
    float threadsC = pow(max(cos(sd * 805.0 + warpC), 0.0), 30.0);

    float envelope = exp(-d * 5.2);

    float flow = 0.72 + 0.28 * sin(
        p.x * 24.0 - p.y * 19.0 - t * 3.1
        + 1.2 * sin(p.y * 12.0 + t)
    );

    float hue = fract(
        0.53 + 0.24 * p.x - 0.21 * p.y - t * 0.065
        + 0.035 * sin(angle * 3.0 + t * 0.45)
        + 0.025 * sin(16.0 * p.x + 12.0 * p.y - t)
    );

    vec3 threadColor = hsv2rgb(vec3(hue, 0.94, 1.0));

    float strength = (
        threadsA * 0.64 +
        threadsB * 0.46 +
        threadsC * 0.30
    ) * envelope * flow;

    col += threadColor * strength * 0.95;

    float loosePhase = 355.0 * sd
        + 1.9 * sin(angle * 2.5 - t * 1.25)
        + 0.9 * sin(18.0 * p.x + 14.0 * p.y - t * 1.7);

    float looseThreads = pow(max(cos(loosePhase), 0.0), 20.0)
                       * exp(-d * 3.4);

    float looseHue = fract(
        hue + 0.16 + 0.10 * sin(angle * 2.0 - t)
    );

    col += hsv2rgb(vec3(looseHue, 0.90, 1.0))
         * looseThreads * 0.17;

    float glintWave = 0.5 + 0.5 * sin(
        sd * 92.0 - t * 4.2
        + 9.0 * sin(angle * 2.0 + t)
    );

    col += vec3(1.0) * pow(glintWave, 18.0)
         * exp(-d * 9.0) * 0.16;

    col += vec3(0.05) * exp(-d * 10.0);
    col += vec3(0.15) * exp(-d * 30.0);
    col += vec3(0.80) * exp(-d * 122.0);
    col += vec3(1.0) * exp(-d * 300.0);

    float center = exp(-dot(p, p) * 170.0);
    col += vec3(0.24) * center;
    col += vec3(1.0) * exp(-dot(p, p) * 900.0) * 1.1;

    col = pow(max(col, 0.0), vec3(0.92));
    fragColor = vec4(col, 1.0);
}
