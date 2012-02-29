// distance field ray caster
// simon green 06/01/2011
// 
// based on Inigo Quilezles's:
// http://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf

//precision mediump float;

varying vec2 vTexCoord;
uniform vec2 resolution;
uniform float time;

// CSG operations
float _union(float a, float b)
{
    return min(a, b);
}

float intersect(float a, float b)
{
    return max(a, b);
}

float difference(float a, float b)
{
//    return max(a, -b);
return max(a, 0.0-b); // work around PowerVR bug
}

// primitive functions
// these all return the distance to the surface from a given point

float plane(vec3 p, vec3 planeN, vec3 planePos)
{
    return dot(p - planePos, planeN);
}

float box(vec3 p, vec3 abc )
{
    vec3 di=max(abs(p)-abc, 0.0);
    //return dot(di,di);
    return length(di);
}

float sphere(vec3 p, float r)
{
    return length(p) - r;
}

// capsule in Y axis
float capsuleY(vec3 p, float r, float h)
{
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

// given segment ab and point c, computes closest point d on ab
// also returns t for the position of d, d(t) = a + t(b-a)
vec3 closestPtPointSegment(vec3 c, vec3 a, vec3 b, out float t)
{
    vec3 ab = b - a;
    // project c onto ab, computing parameterized position d(t) = a + t(b-a)
    t = dot(c - a, ab) / dot(ab, ab);
    // clamp to closest endpoint
    t = clamp(t, 0.0, 1.0);
    // compute projected position
    return a + t * ab;
}

// generic capsule
float capsule(vec3 p, vec3 a, vec3 b, float r)
{
    float t;
    vec3 c = closestPtPointSegment(p, a, b, t);
    return length(c - p) - r;
}

float cylinderY(vec3 p, float r, float h)
{
     float d = length(vec2(p.x, p.z)) - r;
     d = intersect(d, plane(p, vec3(0.0, 1.0, 0.0), vec3(0.0, h, 0.0)));
     d = intersect(d, plane(p, vec3(0.0, -1.0, 0.0), vec3(0.0)));
     return d;
}

// transforms
vec3 rotateX(vec3 p, float a)
{
    float sa = sin(a);
    float ca = cos(a);
    vec3 r;
    r.x = p.x;
    r.y = ca*p.y - sa*p.z;
    r.z = sa*p.y + ca*p.z;
    return r;
}

vec3 rotateY(vec3 p, float a)
{
    float sa = sin(a);
    float ca = cos(a);
    vec3 r;
    r.x = ca*p.x + sa*p.z;
    r.y = p.y;
    r.z = -sa*p.x + ca*p.z;
    return r;
}

float halfSphere(vec3 p, float r)
{
    return difference( 
               sphere(p, r),
               plane(p, vec3(0.0, 1.0, 0.0), vec3(0.0)) );
}

// distance to scene
float scene(vec3 p)
{
    float d;

#if 1
    // army of droids
    p += vec3(-3.0, 0.0, -3.0);
    p.x = mod(p.x, 6.0);
    p.z = mod(p.z, 6.0);
    p -= vec3(3.0, 0.0, 3.0);
#endif

    p.x = abs(p.x);  // mirror in X to reduce no. of primitives

    p -= vec3(0.0, 1.0, 0.0);
    //vec3 hp = rotateY(p, sin(time*0.5)*0.5);
    vec3 hp = p; //vec3(p.x, p.y-1.1, p.z);

    // head
    d = sphere(p, 1.0);
    //d = halfSphere(hp, 0.95);

    // eyes
    d = _union(d, sphere(hp - vec3(0.3, 0.3, 0.9), 0.1));
    //d = _union(d, sphere(hp - vec3(-0.3, 0.3, 0.9), 0.1));

    // antenna
    d = _union(d, capsule(hp, vec3(0.4, 0.7, 0.0), vec3(0.75, 1.2, 0.0), 0.05));
    //d = _union(d, capsule(hp, vec3(-0.4, 0.7, 0.0), vec3(-0.75, 1.2, 0.0), 0.05));

    // body
    //d = _union(d, cylinderY(p - vec3(0.0, -1.1, 0.0), 1.0, 1.0));
    d = _union(d, capsuleY((p*vec3(1.0, 4.0, 1.0) - vec3(0.0, -4.6, 0.0)), 1.0, 4.0));

    // arms
    //d = _union(d, capsuleY(p - vec3(-1.2, -0.9, 0.0), 0.2, 0.7));
    //d = _union(d, capsuleY(p - vec3(1.2, -0.9, 0.0), 0.2, 0.7));
    d = _union(d, capsuleY(rotateX(p, sin(time)) - vec3(1.2, -0.9, 0.0), 0.2, 0.7));
    //d = _union(d, capsuleY(rotateX(p, cos(time)) - vec3(-1.2, -0.9, 0.0), 0.2, 0.7));

    // legs
    d = _union(d, capsuleY(p - vec3(0.4, -1.8, 0.0), 0.2, 0.5));
    //d = _union(d, capsuleY(p - vec3(-0.4, -1.8, 0.0), 0.2, 0.5));

    // floor
    d = _union(d, plane(p, vec3(0.0, 1.0, 0.0), vec3(0.0, -2.0, 0.0)));

    return d;
}

// calculate scene normal
vec3 sceneNormal( in vec3 pos )
{
    float eps = 0.01;
    vec3 n;
#if 0
    // central difference
    n.x = scene( vec3(pos.x+eps, pos.y, pos.z) ) - scene( vec3(pos.x-eps, pos.y, pos.z) );
    n.y = scene( vec3(pos.x, pos.y+eps, pos.z) ) - scene( vec3(pos.x, pos.y-eps, pos.z) );
    n.z = scene( vec3(pos.x, pos.y, pos.z+eps) ) - scene( vec3(pos.x, pos.y, pos.z-eps) );
#else
    // forward difference
    float d = scene( vec3(pos.x, pos.y, pos.z) );
    n.x = scene( vec3(pos.x+eps, pos.y, pos.z) ) - d;
    n.y = scene( vec3(pos.x, pos.y+eps, pos.z) ) - d;
    n.z = scene( vec3(pos.x, pos.y, pos.z+eps) ) - d;
#endif
    return normalize(n);
}

// ambient occlusion approximation
float ambientOcclusion(vec3 p, vec3 n)
{
    const int steps = 3;
    const float delta = .5;

    float a = 0.0;
    float weight = 1.0;
    for(int i=1; i < steps; i++) {
        float d = (float(i) / float(steps)) * delta; 
        a += weight*(d - scene(p + n*d));
        weight *= 0.5;
    }
    return clamp(1.0 - a, 0.0, 1.0);
}

// lighting
vec3 shade(vec3 pos, vec3 n, vec3 eyePos)
{
    const vec3 lightPos = vec3(5.0, 10.0, 5.0);
    const vec3 color = vec3(0.643, 0.776, 0.223);
    const float shininess = 100.0;

    vec3 l = normalize(lightPos - pos);
    vec3 v = normalize(eyePos - pos);
    vec3 h = normalize(v + l);
    float diff = dot(n, l);
    float spec = max(0.0, pow(dot(n, h), shininess)) * float(diff > 0.0);
    //diff = max(0.5, diff);
    diff = 0.5+0.5*diff;

    float fresnel = pow(1.0 - dot(n, v), 5.0);
    float ao = ambientOcclusion(pos, n);

//    return vec3(diff*ao) * color + vec3(spec + fresnel*0.5);
//    return vec3(diff) * color + vec3(spec + fresnel*0.5);
//    return vec3(diff*ao) * color + vec3(spec + 0.2*fresnel);
    return diff * ao * color + spec + fresnel*0.2;
//    return vec3(diff*ao) * color + spec + vec3(fresnel)*0.5;
}

// trace ray using sphere tracing
vec3 trace(vec3 ro, vec3 rd, out bool hit)
{
    const int maxSteps = 44;
    const float hitThreshold = 0.001;
    hit = false;
    vec3 pos = ro + rd;

    for(int i=0; i < maxSteps; i++)
    {
        float d = scene(pos);
        if (d < hitThreshold) {
            hit = true;
            return pos;
        }
        pos += d*rd;
    }
    return pos;
}

vec3 background(vec3 rd)
{
     return mix(vec3(1.0), vec3(0.0, 0.25, 1.0), rd.y);
     //return vec3(0.0);
}

void main(void)
{
    // compute ray origin and direction
    vec3 rd = normalize(vec3(vTexCoord.x, vTexCoord.y, -2.0));
    vec3 ro = vec3(0.0, 0.5, 4.5);

#if 1
// move camera
    float a;
    a = sin(time*0.3)*1.0;
    //a = time*0.5;
    rd = rotateY(rd, a);
    ro = rotateY(ro, a);
#endif

#if 1
    a = sin(time*0.3)*0.3;
    rd = rotateX(rd, a);
    ro = rotateX(ro, a);
#endif

    // trace ray
    bool hit;
    vec3 pos = trace(ro, rd, hit);

    vec3 rgb;
    if(hit)
    {
        // calc normal
        vec3 n = sceneNormal(pos);
        // shade
        rgb = shade(pos, n, ro);

#if 1
        // reflection
        vec3 v = normalize(ro - pos);
        float fresnel = 0.1 + 0.4*pow(1.0 - dot(n, v), 5.0);

        ro = pos + n*0.1; // offset to avoid self-intersection
        rd = reflect(-v, n);
        pos = trace(ro, rd, hit);

        if (hit) {
            vec3 n = sceneNormal(pos);
            rgb += shade(pos, n, ro) * fresnel*1.0;
        } else {
            rgb += background(rd) * fresnel*1.0;
        }
#endif

     } else {
        rgb = background(rd);
     }

    // vignetting
    //rgb *= 0.5+0.5*smoothstep(1.8, 0.5, dot(rd, rd));

    gl_FragColor=vec4(rgb, 1.0);
}
