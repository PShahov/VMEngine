#version 330 core
// #pragma fragmentoption ARB_precision_hint_nicest

in vec4 vColor;
in vec2 vTexCoord;
in vec3 vNormal;
in vec3 vFragPos;

out vec4 fragColor;
const float FOV = 1.0;

#define EPSILON 0.000001
#define maxRenderDistance 100

#define GlobalIllumination
#define voxelNoise
#define SunBloom 0.005
#define LightDotMultiplier 5
#define ShadowDotMultiplier 1


// #define ShowLightCalculations

// #define showLOD

#define ChunkSize 3
#define ChunkSizeHalf 1.5
#define VoxelPerRow 30
#define VoxelSize 0.1
#define FloatsPerVoxel 5
#define PixelsInChunk ((VoxelPerRow * VoxelPerRow * VoxelPerRow * FloatsPerVoxel) + 3)
// #define PixelsInChunk 5003


uniform vec3 globalLightDirection = vec3(0.5, -0.25, 1);
vec4 globalLightColor = vec4(1, 1 , 0.85, 1);
vec4 ambient = vec4(1, 1, 1, 1);
vec4 backgroundColor = vec4(0.5, 0.8, 0.9, 1);
vec4 voivColor = vec4(0.1, 0.1, 0.1, 1);

uniform vec2 u_resolution;
uniform float u_time = 0;

uniform int u_chunks_count = 1;

uniform vec3 u_camera_position;
uniform vec3 u_camera_forward;
uniform vec3 u_camera_right;
uniform vec3 u_camera_up;
uniform float u_mouse_wheel = 1;

uniform samplerBuffer u_tbo_tex;

float specularStrength = 0.5;

const float toCamDistArray[5] = float[5](5, 4, 3, 2, 1);
const vec4 toCamDistArrayCol[5] = vec4[5](
    vec4(vec3(1),1),
    vec4(vec3(0.8),1),
    vec4(vec3(0.6),1),
    vec4(vec3(0.4),1),
    vec4(vec3(0.2),1)
);

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




float TexelFetch1(int offset){
    int cOffset = offset % 4;
    offset = (offset - cOffset) / 4;
    return texelFetch(u_tbo_tex, offset)[cOffset];
}
vec4 TexelFetch4(int offset){
    return texelFetch(u_tbo_tex, offset);
}

mat3 getCam(vec3 camF, vec3 camR, vec3 camU){
    return mat3(camR, camU, camF);
}

bool intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax, out float dist = 0) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    dist = tNear;
    if (tFar < 0) return false;
    return tNear < tFar;
}
float intersectAABBdist(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);

    return tNear;
}
void intersectAABBdist(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax, out float tNear, out float tFar) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    tNear = max(max(t1.x, t1.y), t1.z);
    tFar = min(min(t2.x, t2.y), t2.z);

    // return tNear;
}


Voxel GetVoxelByInd(ivec3 i, int chunkOffset){
    int v = 5;
    int offset = i.x * VoxelPerRow * VoxelPerRow + i.y * VoxelPerRow + i.z;
    // offset = x * N * N + y * N + z
    offset *= v;
    // offset += 500 * chunkOffset;
    offset += PixelsInChunk * chunkOffset;
    offset += 3;

    
    vec4 voxColor = vec4(
        TexelFetch1(offset + 0),
        TexelFetch1(offset + 1),
        TexelFetch1(offset + 2),
        TexelFetch1(offset + 3)
    );
    int state = floatBitsToInt(TexelFetch1(offset + 4));

    return Voxel(voxColor, state);
}

ivec3 GetIndByPos(vec3 pos, vec3 offset){

    pos -= offset;
    pos -= vec3(1) * ChunkSizeHalf;

    pos /= VoxelSize;

    pos *= -1;

    pos = pos - (vec3(1) * VoxelPerRow);
    pos *= -1;

    ivec3 ind = ivec3(
        floor(pos.x),
        floor(pos.y),
        floor(pos.z)
    );

    if (ind.x >= VoxelPerRow) ind.x = VoxelPerRow - 1;
    if (ind.y >= VoxelPerRow) ind.y = VoxelPerRow - 1;
    if (ind.z >= VoxelPerRow) ind.z = VoxelPerRow - 1;

    if (ind.x < 0) ind.x = 0;
    if (ind.y < 0) ind.y = 0;
    if (ind.z < 0) ind.z = 0;

    return ind;
}



VoxelHit renderChunk(vec3 ro, vec3 rd, vec3 pos = vec3(0),  int offset = 0, float lastDist = 0){
    float dist = 0;
    bool intersect = intersectAABB(ro,rd, pos - vec3(ChunkSizeHalf), pos + vec3(ChunkSizeHalf), dist);
    VoxelHit vox = VoxelHit(vec3(0), vec3(0), vec3(0), maxRenderDistance + 1, vec4(1), false, 0);
    if(intersect == false){
        return vox;
    }

    vec3 rp = ro + (rd * (dist + 0.0001));
    ivec3 ind = GetIndByPos(rp, pos);
    Voxel vd = GetVoxelByInd(ind, offset);
    intersect = bitInt(vd.state, 24);

    vec3 dir = vec3(0);
    vec3 voxCenter = vec3(0);

    float c = 0;

    float toCamDist = 0;

    vec4 col = toCamDistArrayCol[0];

    while(IsPointInside(rp - pos) && intersect == false)
    {
        
        voxCenter =  pos - vec3(ChunkSizeHalf);
        voxCenter += ((vec3(ind) * VoxelSize));
        voxCenter += VoxelSize / 2;
        float pNear = 0;
        float pFar = 0;
        intersectAABBdist(ro, rd, voxCenter - vec3(VoxelSize / 2), voxCenter + vec3(VoxelSize / 2), pNear, pFar);

        float stpd = VoxelSize / 2;

        float stp = stpd / toCamDist;

        stp = abs(pFar - pNear) + EPSILON;
        // stp = clamp(stp, EPSILON, VoxelSize / 2);


        rp = rp + (rd * (stp));
        ind = GetIndByPos(rp, pos);
        vd = GetVoxelByInd(ind, offset);
        intersect = bitInt(vd.state, 24);
    }


    voxCenter =  pos - vec3(ChunkSizeHalf);
    voxCenter += ((vec3(ind) * VoxelSize));
    voxCenter += VoxelSize / 2;
    
    dir = voxCenter - rp;
    
    bool intersectVox = intersectAABB(ro, rd, voxCenter - vec3(VoxelSize / 2), voxCenter + vec3(VoxelSize / 2), dist);
    bool inside = IsPointInside(voxCenter - pos);
    
    
    vec3 hitPoint = ro + (rd * dist);

    float dt = dot(rd, ro - hitPoint);

    if(intersectVox = false){
        return vox;
    }

    dir = voxCenter - hitPoint;
    dir *= -1;
    dir = normalize(dir);
    vec3 normal = BoxNormal(dir);


    #ifdef showLOD
        vd.color = col;
    #endif


    dist = lengthSqr(ro - hitPoint);

    vox = VoxelHit(hitPoint, voxCenter, normal, dist, vd.color, intersect, vd.state);
    return vox;
}

VoxelHit renderChunkLights(vec3 ro, vec3 rd, vec3 pos = vec3(0),  int offset = 0){
    float dist = 0;
    bool intersect = intersectAABB(ro,rd, pos - vec3(ChunkSizeHalf), pos + vec3(ChunkSizeHalf), dist);
    VoxelHit vox = VoxelHit(vec3(0), vec3(0), vec3(0), maxRenderDistance + 1, vec4(1), false, 0);
    if(intersect == false){
        return vox;
    }

    vec3 rp = ro + (rd * (dist + 0.0001));
    ivec3 ind = GetIndByPos(rp, pos);
    Voxel vd = GetVoxelByInd(ind, offset);
    intersect = bitInt(vd.state, 24);

    vec3 dir = vec3(0);
    vec3 voxCenter = vec3(0);

    float c = 0;

    float toCamDist = 0;

    vec4 col = toCamDistArrayCol[0];

    while(IsPointInside(rp - pos) && intersect == false)
    {
        
        voxCenter =  pos - vec3(ChunkSizeHalf);
        voxCenter += ((vec3(ind) * VoxelSize));
        voxCenter += VoxelSize / 2;
        float pNear = 0;
        float pFar = 0;
        intersectAABBdist(ro, rd, voxCenter - vec3(VoxelSize / 2), voxCenter + vec3(VoxelSize / 2), pNear, pFar);

        float stpd = VoxelSize / 2;

        float stp = stpd / toCamDist;

        stp = abs(pFar - pNear) + EPSILON;
        // stp = clamp(stp, EPSILON, VoxelSize / 2);


        rp = rp + (rd * (stp));
        ind = GetIndByPos(rp, pos);
        vd = GetVoxelByInd(ind, offset);
        intersect = bitInt(vd.state, 24);
    }


    voxCenter =  pos - vec3(ChunkSizeHalf);
    voxCenter += ((vec3(ind) * VoxelSize));
    voxCenter += VoxelSize / 2;
    
    dir = voxCenter - rp;
    
    bool intersectVox = intersectAABB(ro, rd, voxCenter - vec3(VoxelSize / 2), voxCenter + vec3(VoxelSize / 2), dist);
    bool inside = IsPointInside(voxCenter - pos);
    
    
    vec3 hitPoint = ro + (rd * dist);

    float dt = dot(rd, ro - hitPoint);

    if(intersectVox = false){
        return vox;
    }

    dir = voxCenter - hitPoint;
    dir *= -1;
    dir = normalize(dir);
    vec3 normal = BoxNormal(dir);


    #ifdef showLOD
        vd.color = col;
    #endif


    dist = lengthSqr(ro - hitPoint);

    vox = VoxelHit(hitPoint, voxCenter, normal, dist, vd.color, intersect, vd.state);
    return vox;
}

VoxelHit RenderChunks(vec3 ro, vec3 rd){


    // Chunk chunks[MAX_CHUNKS];

    // for(int i = 0;i < u_chunks_count;i++){
    //     vec3 pos = vec3(
    //         TexelFetch4(i * PixelsInChunk + 0).x,
    //         TexelFetch4(i * PixelsInChunk + 1).x,
    //         TexelFetch4(i * PixelsInChunk + 2).x
    //     );
    //     float dist = lengthSqr(pos - ro);
    //     chunks[i] = Chunk(i, dist);
    // }
    // for(int i = 0;i < u_chunks_count;i++){
    //     for(int j = 0;j < u_chunks_count - 1;j++){
    //         if(chunks[j].dist > chunks[j + 1].dist){
    //             Chunk c = chunks[j];
    //             chunks[j] = chunks[j + 1];
    //             chunks[j + 1] = c;
    //         }
    //     }
    // }

    int o = 0;
    vec3 pos = vec3(
        TexelFetch1(o * PixelsInChunk + 0),
        TexelFetch1(o * PixelsInChunk + 1),
        TexelFetch1(o * PixelsInChunk + 2)
    );
    VoxelHit vh = renderChunk(ro, rd, pos, o);

    for(int i = 1;i < u_chunks_count;i++){
        pos = vec3(
            TexelFetch1(i * PixelsInChunk + 0),
            TexelFetch1(i * PixelsInChunk + 1),
            TexelFetch1(i * PixelsInChunk + 2)
        );
        VoxelHit v = renderChunk(ro, rd, pos, i);
        if((v.dist < vh.dist && v.crossed == true) || (vh.crossed == false)){
            vh = v;
            o = i;
        }
    }

    return vh;
}


VoxelHit RenderChunksLight(vec3 ro, vec3 rd){

    int o = 0;
    vec3 pos = vec3(
        TexelFetch1(o * PixelsInChunk + 0),
        TexelFetch1(o * PixelsInChunk + 1),
        TexelFetch1(o * PixelsInChunk + 2)
    );
    VoxelHit vh = renderChunkLights(ro, rd, pos, o);

    // if(vh.crossed == false){
    //     return vh;
    // }

    for(int i = 1;i < u_chunks_count;i++){
        pos = vec3(
            TexelFetch1(i * PixelsInChunk + 0),
            TexelFetch1(i * PixelsInChunk + 1),
            TexelFetch1(i * PixelsInChunk + 2)
        );
        VoxelHit v = renderChunkLights(ro, rd, pos, i);
        
        // if(v.crossed == false){
        //     return vh;
        // }
        if((v.dist < vh.dist && v.crossed == true) || (vh.crossed == false)){
            vh = v;
            o = i;
        }
    }

    return vh;
}




vec4 render(in vec2 uv){
    vec4 col = vec4(0,0,0,0);
    vec3 ro = u_camera_position;
    vec3 rd = getCam(u_camera_forward, u_camera_right, u_camera_up) * normalize((vec3(uv, FOV * u_mouse_wheel)));

    vec4 color = vec4(0);



    

    VoxelHit vh = RenderChunks(ro, rd);
    
    if(vh.crossed)
    {
            color = vh.color;
            
            float lightDot = (dot(normalize(vh.normal), normalize(-globalLightDirection)));
            
            #ifdef GlobalIllumination
            if(lightDot > 0.0){
                //if need global light calculation (red)

                vec3 so = vh.pos;
                vec3 sd = globalLightDirection;
                so += sd * (maxRenderDistance * -0.5);
                // sd *= -1;
                
                VoxelHit srv = RenderChunksLight(so, sd);
                
                
                vec3 sunHitPoint = srv.pos;
                float dist = lengthSqr(abs(vh.pos - srv.pos));

                if(srv.crossed && dist < EPSILON){
                    color = ColorBlend(vh.color, globalLightColor, 1, lightDot / LightDotMultiplier);
                    // color = vec4(lightDot / 2,0,0,1);
                    
                    #ifdef ShowLightCalculations
                        //if light calculated and pixel in shadow(green)
                        color = vec4(0,1,0,1);
                    #endif
                }else{
                    color = ColorBlend(vh.color, vec4(0,0,0,1), 1, lightDot * ShadowDotMultiplier);
                    // color = vec4(0,1,0,1);

                    #ifdef ShowLightCalculations
                        //if the light is calculated and the pixel is lit(red)
                        color = vec4(1,0,0,1);
                    #endif
                }

                

            }else{

                //
                //sunray-normal dot-light
                //
                color = ColorBlend(vh.color, vec4(0,0,0,1), 1, abs(lightDot) * ShadowDotMultiplier);

                
                #ifdef ShowLightCalculations
                    //if no need to calc GL (blue)
                    color = vec4(0,0,1,1);
                #endif
            }
            #endif
            #ifdef voxelNoise
                float noise = noise3(vh.center * 10 - vec3(VoxelSize) * 5);
                color = ColorBlend(color, vec4(vec3(noise), 1), 1, 0.05);
            #endif

            
    }else{
        // color = vec3(0.15,0.55, 1);
        color = backgroundColor;
        #ifdef SunBloom

            float d = dot(rd * -1, normalize(globalLightDirection));
            if(d > 1 - SunBloom){
                color = globalLightColor;
            }

        #endif
    }

    // color = vec3(dot(rd, (u_camera_position - pos)));


    return color;
}

void main()
{
    float ratio = u_resolution.x / u_resolution.y;
    vec2 resol = vec2(u_resolution.x / 4, u_resolution.x / 4 / ratio);
    // resol = u_resolution;
    vec2 uv = (0.5 * gl_FragCoord.xy - resol.xy) / resol.y;

    vec4 color = render(uv);


    if(uv.x > -0.01 && uv.x < 0.01 && uv.y > -0.01 && uv.y < 0.01){
        // color = abs(color - vec3(1));
        color = vec4(1);
    }
        fragColor = color;

        // if(u_chunks_count ==)


    // fragColor = vec4(1,0,0,1);
}


