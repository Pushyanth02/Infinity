
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

float fbm(vec2 p)
{
    float value = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < 4; i++)
    {
        value += amplitude * noise(p);
        p = mat2(1.6, 1.2, -1.2, 1.6) * p + 7.1;
        amplitude *= 0.5;
    }

    return value;
}

float starField(vec2 p)
{
    vec2 grid = p * 64.0;
    vec2 id = floor(grid);
    vec2 f = fract(grid) - 0.5;

    float h = hash21(id + vec2(7.2, 3.1));
    vec2 offset = vec2(
        hash21(id + vec2(1.7, 9.2)),
        hash21(id + vec2(8.3, 2.7))
    ) - 0.5;

    vec2 delta = f - offset * 0.65;
    float radius = mix(0.025, 0.105, hash21(id + 2.8));
    float star = exp(-dot(delta, delta) / (radius * radius));
    float visibility = smoothstep(0.92, 0.995, h);
    float twinkle = 0.72 + 0.28 *
        sin(iTime * (1.8 + h * 4.0) + h * 80.0);

    return star * visibility * twinkle;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float t = iTime;

    // Centered coordinates with aspect-ratio correction.
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Subtle, slow cosmic drift.
    float rotation = 0.055 * sin(t * 0.18);
    mat2 rot = mat2(cos(rotation), -sin(rotation),
                    sin(rotation),  cos(rotation));
    vec2 p = rot * uv;

    // Procedural nebula using warped noise.
    vec2 warp = vec2(
        fbm(p * 2.3 + vec2(0.0, t * 0.025)),
        fbm(p * 2.3 + vec2(4.8, -t * 0.021))
    );

    float cloudA = fbm(
        p * 3.2 + warp * 1.7 + vec2(-t * 0.018, t * 0.012)
    );

    float cloudB = fbm(
        p * 5.1 - warp * 1.2 + vec2(t * 0.012, -t * 0.016)
    );

    vec3 col = vec3(0.003, 0.005, 0.020);

    float violetCloud = pow(max(cloudA - 0.34, 0.0), 1.5);
    float blueCloud   = pow(max(cloudB - 0.39, 0.0), 1.6);
    float pinkCloud   = pow(
        max(cloudA * 0.58 + cloudB * 0.42 - 0.52, 0.0), 2.0
    );

    col += vec3(0.20, 0.025, 0.48) * violetCloud * 1.65;
    col += vec3(0.025, 0.12, 0.42) * blueCloud * 1.65;
    col += vec3(0.36, 0.025, 0.27) * pinkCloud * 0.8;

    // Faint aura behind the infinity loop.
    float radius2 = dot(p, p);
    col += vec3(0.025, 0.018, 0.12) * exp(-radius2 * 1.8);

    // Distant stars and brighter pinpricks.
    float stars = starField(uv);
    col += vec3(0.50, 0.69, 1.0) * stars * 0.9;

    float sparkle = pow(
        max(noise(uv * 150.0 + vec2(2.1, 8.7)) - 0.78, 0.0)
        * 4.3, 6.0
    );
    col += vec3(0.28, 0.68, 1.0) * sparkle * 1.35;

    // Bernoulli lemniscate: the mathematical infinity curve.
    float a = 0.68;
    float r2 = dot(p, p);

    float field = r2 * r2 -
                  a * a * (p.x * p.x - p.y * p.y);

    vec2 gradient = vec2(
        4.0 * p.x * r2 - 2.0 * a * a * p.x,
        4.0 * p.y * r2 + 2.0 * a * a * p.y
    );

    float d = abs(field) / max(length(gradient), 0.001);

    // Layered glow: atmosphere, neon body, and bright filament.
    float outerGlow = exp(-d * 8.0);
    float body      = exp(-d * 42.0);
    float filament  = exp(-d * 145.0);
    float hotCore   = exp(-d * 330.0);

    // Cyan-to-violet-to-pink color cycling.
    float angle = atan(p.y, p.x);
    float hue = 0.5 + 0.5 * sin(
        2.3 * p.x - 1.7 * p.y + t * 0.62 + 2.0 * angle
    );

    vec3 cyan   = vec3(0.025, 0.83, 1.0);
    vec3 violet = vec3(0.42, 0.075, 1.0);
    vec3 pink   = vec3(1.0, 0.075, 0.57);

    vec3 energy = mix(cyan, violet, smoothstep(0.12, 0.72, hue));
    energy = mix(energy, pink, smoothstep(0.68, 0.98, hue));

    // Animated energy traveling along the infinity line.
    float flow = 0.72 + 0.28 * sin(
        19.0 * (p.x + p.y) - t * 3.1
        + 1.4 * sin(6.0 * p.x - t)
    );

    col += energy * outerGlow * 0.16;
    col += energy * body * (0.72 + 0.48 * flow);
    col += energy * filament * 1.35;
    col += vec3(0.68, 0.91, 1.0) * hotCore * 1.25;

    // Four luminous particles circulating along the infinity path.
    for (int i = 0; i < 4; i++)
    {
        float phase = t * 0.82 + float(i) * 1.5707963;
        float s = sin(phase);
        float c = cos(phase);

        vec2 particlePos = a * vec2(c, s * c) / (1.0 + s * s);

        float pd = length(p - particlePos);
        float particle = exp(-pd * pd * 1700.0);
        float trail = exp(-pd * 18.0);

        vec3 particleColor = mix(
            cyan, pink, 0.5 + 0.5 * sin(phase * 1.3)
        );

        col += particleColor * trail * 0.11;
        col += particleColor * particle * 2.6;
    }

    // Luminous nexus at the central crossing.
    float nexus = exp(-dot(p, p) * 105.0);

    col += vec3(0.20, 0.35, 1.0) * nexus * 0.55;
    col += vec3(0.68, 0.22, 1.0) * nexus * 0.25
           * (0.7 + 0.3 * sin(t * 2.0));

    // Cinematic vignette and gentle tonemapping.
    float vignette = 1.0 - 0.30 * smoothstep(0.30, 1.08, length(uv));
    col *= vignette;

    col = col / (1.0 + col * 0.30);
    col = pow(max(col, 0.0), vec3(0.92));

    fragColor = vec4(col, 1.0);
}
