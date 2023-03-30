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
    vec4 color;
    int state;
};

struct Chunk{
    int offset;
    float dist;
};



bool IsPointInside(vec3 pos)
{
    return pos.x <= ChunkSizeHalf && pos.x >= -ChunkSizeHalf && pos.y <= ChunkSizeHalf && pos.y >= -ChunkSizeHalf && pos.z <= ChunkSizeHalf && pos.z >= -ChunkSizeHalf;
}

bool bitInt(int value, int bit){
	return ((value >> bit) & 1) == 1;
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

float lengthSqr(vec3 x) {
	return dot(x, x);
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