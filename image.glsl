float rand2(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise2(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f *= f * (3.0 - 2.0 * f);

    float a = rand2(i), b = rand2(i + vec2(1, 0));
    float c = rand2(i + vec2(0, 1)), d = rand2(i + 1.0);

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 hsv(vec3 c)
{
    vec3 rgb = clamp(abs(mod(c.x * 6.0 +
        vec3(0, 4, 2), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb *= rgb * (3.0 - 2.0 * rgb);
    return c.z * mix(vec3(1), rgb, c.y);
}

float stars(vec2 p)
{
    vec2 g = p * 84.0, id = floor(g);
    vec2 f = fract(g) - 0.5;
    float h = rand2(id + vec2(2.7, 8.1));

    vec2 off = vec2(rand2(id + vec2(1.3, 4.1)),
                    rand2(id + vec2(7.2, 2.6))) - 0.5;
    vec2 q = f - off * 0.65;

    float r = mix(0.018, 0.070, rand2(id + 5.2));
    float tw = 0.72 + 0.28 * sin(iTime * (1.6 + h * 4.0) + h * 90.0);

    return exp(-dot(q, q) / (r * r))
         * smoothstep(0.966, 0.998, h) * tw;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float t = iTime;
    vec2 p = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 col = vec3(0);

    col += vec3(0.75) * stars(p) * 0.58;
    col += vec3(0.22) * pow(max(noise2(p * 135.0 +
        vec2(3, 7)) - 0.88, 0.0), 5.0);

    float a = 0.66, r = dot(p, p);
    float f = r * r - a * a * (p.x * p.x - p.y * p.y);

    vec2 g = vec2(4.0 * p.x * r - 2.0 * a * a * p.x,
                  4.0 * p.y * r + 2.0 * a * a * p.y);

    float s = f / max(length(g), 0.001);
    float d = abs(s), ang = atan(p.y, p.x);

    float w1 = 1.55 * sin(17.0*p.x - 13.0*p.y - t*1.8)
             + 0.72 * sin(11.0*p.y + 16.0*p.x + t*1.35);
    float w2 = 1.25 * sin(14.0*p.y + 12.0*p.x + t*1.65)
             + 0.68 * sin(22.0*p.x - 9.0*p.y - t*2.1);
    float w3 = 1.05 * sin(19.0*p.x + 8.0*p.y + t*1.25)
             - 0.82 * sin(13.0*p.y - 15.0*p.x - t*1.9);

    float l1 = pow(max(cos(s*510.0 + w1), 0.0), 22.0);
    float l2 = pow(max(cos(s*665.0 + w2), 0.0), 34.0);
    float l3 = pow(max(cos(s*805.0 + w3), 0.0), 30.0);

    float fade = exp(-d * 5.2);
    float flow = 0.72 + 0.28 * sin(p.x*24.0 - p.y*19.0 - t*3.1
                    + 1.2*sin(p.y*12.0 + t));

    float hue = fract(0.53 + 0.24*p.x - 0.21*p.y - t*0.065
              + 0.035*sin(ang*3.0 + t*0.45)
              + 0.025*sin(16.0*p.x + 12.0*p.y - t));

    float lines = (l1*0.64 + l2*0.46 + l3*0.30) * fade * flow;
    col += hsv(vec3(hue, 0.94, 1.0)) * lines * 0.95;

    float phase = 355.0*s + 1.9*sin(ang*2.5 - t*1.25)
                + 0.9*sin(18.0*p.x + 14.0*p.y - t*1.7);
    float loose = pow(max(cos(phase), 0.0), 20.0) * exp(-d*3.4);
    float hue2 = fract(hue + 0.16 + 0.10*sin(ang*2.0 - t));

    col += hsv(vec3(hue2, 0.90, 1.0)) * loose * 0.17;

    float shine = 0.5 + 0.5*sin(s*92.0 - t*4.2
                    + 9.0*sin(ang*2.0 + t));

    col += vec3(pow(shine, 18.0)*exp(-d*9.0)*0.16
              + 0.05*exp(-d*10.0)
              + 0.15*exp(-d*30.0)
              + 0.80*exp(-d*122.0)
              + exp(-d*300.0));

    col = pow(max(col, 0.0), vec3(0.92));
    fragColor = vec4(col, 1.0);
}
