
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
    float radius = mix(0.018, 0.070, hash21(id + 5.2));
    float star = exp(-dot(q, q) / (radius * radius));
    float visible = smoothstep(0.966, 0.998, h);
    float twinkle = 0.72 + 0.28 *
        sin(iTime * (1.6 + h * 4.0) + h * 90.0);

    return star * visible * twinkle;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float t = iTime;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 p = uv;

    vec3 col = vec3(0.0);
    col += vec3(0.72) * starField(uv) * 0.58;

    float tinyStars = pow(
        max(noise(uv * 135.0 + vec2(3.0, 7.0)) - 0.87, 0.0),
        5.0
    );
    col += vec3(0.18) * tinyStars;

    float a = 0.66;
    float r2 = dot(p, p);
    float field = r2 * r2 - a * a * (p.x * p.x - p.y * p.y);

    vec2 grad = vec2(
        4.0 * p.x * r2 - 2.0 * a * a * p.x,
        4.0 * p.y * r2 + 2.0 * a * a * p.y
    );

    float signedD = field / max(length(grad), 0.001);
    float d = abs(signedD);
    float angle = atan(p.y, p.x);

    float whiteHalo = exp(-d * 12.0);
    float whiteBody = exp(-d * 74.0);
    float whiteCore = exp(-d * 245.0);

    col += vec3(0.075) * whiteHalo;
    col += vec3(0.26) * whiteBody;
    col += vec3(0.86) * whiteCore;

    float phaseA = signedD * 255.0
        + 1.7 * sin(18.0 * p.x - 13.0 * p.y - t * 2.0)
        + 0.75 * sin(10.0 * p.y + 17.0 * p.x + t * 1.55);


    float phaseB = signedD * 342.0
        - 1.3 * sin(15.0 * p.y + 12.0 * p.x + t * 1.8)
        + 0.60 * sin(24.0 * p.x - 8.0 * p.y - t * 2.45);

    float threadsA = pow(max(cos(phaseA), 0.0), 19.0);
    float threadsB = pow(max(cos(phaseB), 0.0), 25.0);
    float threadEnvelope = exp(-d * 5.7);

    float threadShimmer = 0.68 + 0.32 * sin(
        23.0 * p.x - 17.0 * p.y - t * 3.0
        + 1.5 * sin(9.0 * p.y + t)
    );

    float threads = (threadsA * 0.74 + threadsB * 0.50)
                  * threadEnvelope * threadShimmer;

    float threadHue = fract(
        0.57 + 0.27 * p.x + 0.19 * p.y - t * 0.07
        + 0.035 * sin(11.0 * p.x + 13.0 * p.y - t)
    );

    vec3 threadColor = hsv2rgb(vec3(threadHue, 0.94, 1.0));
    col += threadColor * threads * 0.82;


    float looseWave = 0.5 + 0.5 * sin(
        38.0 * signedD + 2.5 * sin(angle * 3.0 - t * 1.4)
        + 1.2 * sin(p.x * 17.0 + p.y * 14.0 - t * 1.8)
    );

    float looseThreads = pow(looseWave, 11.0) * exp(-d * 3.9);
    float looseHue = fract(threadHue + 0.18
                          + 0.12 * sin(angle * 2.0 + t));

    col += hsv2rgb(vec3(looseHue, 0.88, 1.0))
         * looseThreads * 0.19;

    // Four orbs rotate around the infinity and change colors.
    for (int i = 0; i < 4; i++)
    {
        float fi = float(i);
        float phase = t * 0.78 + fi * 1.5707963;

        float s = sin(phase);
        float c = cos(phase);

        vec2 orbPos = a * vec2(c, s * c) / (1.0 + s * s);
        float orbDist = length(p - orbPos);

        float halo = exp(-orbDist * orbDist * 95.0);
        float glow = exp(-orbDist * orbDist * 360.0);
        float core = exp(-orbDist * orbDist * 1500.0);

        float orbHue = fract(
            fi * 0.235 + t * 0.115
            + 0.035 * sin(phase * 1.7)
        );

        vec3 orbColor = hsv2rgb(vec3(orbHue, 0.90, 1.0));

        col += orbColor * halo * 0.42;
        col += orbColor * glow * 1.25;
        col += vec3(1.0) * core * 1.65;

        // A faint colored wake follows each moving orb.
        vec2 tangent = normalize(vec2(-s, c - 2.0 * s * s));
        vec2 wake = p - (orbPos - tangent * 0.055);

        col += orbColor * exp(-length(wake) * 25.0) * 0.09;
    }

    // White-hot central crossing.
    float nexus = exp(-dot(p, p) * 160.0);
    col += vec3(0.30) * nexus;
    col += vec3(1.0) * exp(-dot(p, p) * 860.0) * 1.15;

    // Keep the background black and the white core luminous.
    col = col / (1.0 + col * 0.20);
    col = pow(max(col, 0.0), vec3(0.92));

    fragColor = vec4(col, 1.0);
}
