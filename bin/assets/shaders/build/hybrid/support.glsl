struct VoxelHit{
    vec3 pos;
    vec3 center;
    vec3 normal;
    float dist;
    vec4 color;
    bool crossed;
    int state;
};



struct Voxel{
    int color;
    int state;
    vec3 position;
};

struct OctreeNode{
    vec3 position;
    int offset;
};

struct Chunk{
    int offset;
    float dist;
};

vec4 invertColor(vec4 color){
    color.x = (color.x * -1) + 1;
    color.y = (color.y * -1) + 1;
    color.z = (color.z * -1) + 1;
    return color;
}

vec4 colorFromBytes(int colBytes){
    vec4 voxColor = vec4(1);
    voxColor.x = float((colBytes >> 24) & 0xff) / 255;
    voxColor.y = float((colBytes >> 16) & 0xff) / 255;
    voxColor.z = float((colBytes >> 8) & 0xff) / 255;
    voxColor.w = float((colBytes >> 0) & 0xff) / 255;

    return voxColor;
}

ivec4 BytesFromInt(int bytes){
    ivec4 voxColor = ivec4(1);
    voxColor.x = (bytes >> 24) & 0xff;
    voxColor.y = (bytes >> 16) & 0xff;
    voxColor.z = (bytes >> 8) & 0xff;
    voxColor.w = (bytes >> 0) & 0xff;

    return voxColor;
}


int getFloatBytes(float value, int index){
    int v = floatBitsToInt(value);

    return (v >> (index * 8)) & 0xff;
}
uint getUintBytes(uint v, int index){
    // int v = int(value);
    return (v >> (index * 8)) & uint(0xff);
}
uint bytesToUint(uint b1, uint b2, uint b3, uint b4){
    b1 = b1 << (3 * 8);
    b2 = b2 << (2 * 8);
    b3 = b3 << (1 * 8);
    return b1 + b2 + b3 + b4;
}

float TexelFetch1(int offset, samplerBuffer tbo = u_tbo_tex){
    int cOffset = offset % 4;
    offset = (offset - cOffset) / 4;
    return texelFetch(tbo, offset)[cOffset];
}

float GetLeafSize(uint index){
    return CHUNK_SIZE / (pow(2, index));
}

int TexelFetchByte(int offset){
    int ob = (offset % 16) % 4;
    int oi = offset % 4;
    int i = (offset - oi) / 4;

    // int cOffset = offset % 4;
    // offset = (offset - cOffset) / 4;
    int a = floatBitsToInt(texelFetch(u_tbo_tex, i - (i%4))[i % 4]);
    a = 0x5;
    int texel = ((a >> ((ob * 4))) & 0xff);

    return texel;
}

vec4 TexelFetch4(int offset){
    return texelFetch(u_tbo_tex, offset);
}

bool IsPointInside(vec3 pos, vec3 minCorn = vec3(-HALF_CHUNK_SIZE), vec3 maxCorn = vec3(HALF_CHUNK_SIZE))
{
    // return all(greaterThanEqual(pos, minCorn)) && all(lessThanEqual(pos, maxCorn));
    return pos.x <= maxCorn.x && pos.x >= minCorn.x && pos.y <= maxCorn.y && pos.y >= minCorn.y && pos.z <= maxCorn.z && pos.z >= minCorn.z;
}

bool PointAABB(vec3 v, vec3 bottomLeft, vec3 topRight, float eps = EPSILON) {
    vec3 s = step(bottomLeft - vec3(eps), v) - step(topRight + vec3(eps), v);
    return ( s.x * s.y * s.z) > 0; 
}

bool bitInt(int value, int bit){
	return ((value >> bit) & 1) == 1;
}

float SqrMagnitude(vec3 v){
    return v.x * v.x + v.y * v.y + v.z * v.z; 
}
float Magnitude(vec3 v){
    return sqrt(v.x * v.x + v.y * v.y + v.z * v.z); 
}

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float lengthSqr(vec3 x) {
	return dot(x, x);
}

vec3 BoxNormal(vec3 dir){
    // return dir;
    vec3 d = normalize(abs(dir));
    if(d.x >= d.y && d.x >= d.z){
        return vec3(1,0,0) * sign(dir.x);
    }
    if(d.y >= d.x && d.y >= d.z){
        return vec3(0,1,0) * sign(dir.y);
    }
    // if(d.z > d.x && d.z > d.y){
    //     return vec3(0,0,1) * sign(dir.z);
    // }
    return vec3(0,0,1) * sign(dir.z);
}
vec4 ColorBlend(vec4 a, vec4 b, float at, float bt){
    float tSumm = at + bt;
    at = 1 / tSumm * at;
    bt = 1 / tSumm * bt;
    return (a * at) + (b * bt);
}

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise3(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float Max(vec3 v) { return max(v.x, max(v.y, v.z)); }
float Min(vec3 v) { return min(v.x, min(v.y, v.z)); }

float MinNotNull(vec3 v){
    float f = 0.5;
    float eps = 0.1;
    if(v.x > eps){
        f = v.x;
        if(v.y > eps){
            f = min(f, v.y);
        }
        if(v.z > eps){
            f = min(f, v.z);
        }
    }else if(v.y > eps){
        f = v.y;
        if(v.z > eps){
            f = min(f, v.z);
        }
    }else{
        f = v.z;
    }

    return f;
}