
mat3 getCam(vec3 camF, vec3 camR, vec3 camU){
    return mat3(camR, camU, camF);
}

bool slabs(vec3 p0, vec3 p1, vec3 rayOrigin, vec3 invRaydir) {
    vec3 t0 = (p0 - rayOrigin) * invRaydir;
    vec3 t1 = (p1 - rayOrigin) * invRaydir;
    vec3 tmin = min(t0,t1), tmax = max(t0,t1);
    return Max(tmin) <= Min(tmax);
}

bool advancedIntersectAABB(vec3 ro, vec3 rd, vec3 lb, vec3 rt, out float tmin, out float tmax){
    // rd is unit direction vector of ray
    vec3 dirfrac = vec3(0);
    dirfrac.x = 1.0f / rd.x;
    dirfrac.y = 1.0f / rd.y;
    dirfrac.z = 1.0f / rd.z;
    // lb is the corner of AABB with minimal coordinates - left bottom, rt is maximal corner
    // ro is origin of ray
    float t1 = (lb.x - ro.x)*dirfrac.x;
    float t2 = (rt.x - ro.x)*dirfrac.x;
    float t3 = (lb.y - ro.y)*dirfrac.y;
    float t4 = (rt.y - ro.y)*dirfrac.y;
    float t5 = (lb.z - ro.z)*dirfrac.z;
    float t6 = (rt.z - ro.z)*dirfrac.z;

    tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6));
    tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6));

    // if tmax < 0, ray (line) is intersecting AABB, but the whole AABB is behind us
    if (tmax < 0)
    {
        // t = tmax;
        return false;
    }

    // if tmin > tmax, ray doesn't intersect AABB
    if (tmin > tmax)
    {
        // t = tmax;
        return false;
    }

    // t = tmin;
    return true;
}

bool advancedIntersectAABBdirfrac(vec3 ro, vec3 rd, vec3 lb, vec3 rt,vec3 dirfrac, out float tmin, out float tmax){
    // // rd is unit direction vector of ray
    // vec3 dirfrac = vec3(0);
    // dirfrac.x = 1.0f / rd.x;
    // dirfrac.y = 1.0f / rd.y;
    // dirfrac.z = 1.0f / rd.z;
    // lb is the corner of AABB with minimal coordinates - left bottom, rt is maximal corner
    // ro is origin of ray
    float t1 = (lb.x - ro.x)*dirfrac.x;
    float t2 = (rt.x - ro.x)*dirfrac.x;
    float t3 = (lb.y - ro.y)*dirfrac.y;
    float t4 = (rt.y - ro.y)*dirfrac.y;
    float t5 = (lb.z - ro.z)*dirfrac.z;
    float t6 = (rt.z - ro.z)*dirfrac.z;

    tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6));
    tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6));

    // if tmax < 0, ray (line) is intersecting AABB, but the whole AABB is behind us
    if (tmax < 0)
    {
        // t = tmax;
        return false;
    }

    // if tmin > tmax, ray doesn't intersect AABB
    if (tmin > tmax)
    {
        // t = tmax;
        return false;
    }

    // t = tmin;
    return true;
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
bool intersectAABBdist(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax, out float tNear, out float tFar) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    tNear = max(max(t1.x, t1.y), t1.z);
    tFar = min(min(t2.x, t2.y), t2.z);

    if (tFar < 0) return false;
    return tNear < tFar;

    // return tNear;
}

bool raySphereIntersect(vec3 r0, vec3 rd, vec3 s0, float sr) {
    float a = dot(rd, rd);
    vec3 s0_r0 = r0 - s0;
    float b = 2.0 * dot(rd, s0_r0);
    float c = dot(s0_r0, s0_r0) - (sr * sr);
    return (b*b - 4.0*a*c > 0.0);
}
bool raySphereIntersectDist(vec3 r0, vec3 rd, vec3 s0, float sr, out float dist) {
    float a = dot(rd, rd);
    vec3 s0_r0 = r0 - s0;
    float b = 2.0 * dot(rd, s0_r0);
    float c = dot(s0_r0, s0_r0) - (sr * sr);
    if (b*b - 4.0*a*c < 0.0) {
        dist = 0;
        return false;
    }else{
        dist = (-b - sqrt((b*b) - 4.0*a*c))/(2.0*a);
        return true;
    }
}

int getNodeOffset(int[11] steps, int initialOffset){
    int offset = 5;
    
    for(int i = 0;i < 10;i++){
        if(steps[i] == -1){
            return offset;
        }

        for(int j = 0;j < steps[i];j++){
            int stateBytes = floatBitsToInt(TexelFetch1(offset + 1));
            int voxColor = floatBitsToInt(TexelFetch1(4));
            if(bitInt(stateBytes, OctDivided)){
                offset += voxColor + 1;
            }else{
                offset += 2;
            }
        }
    }
    return offset;
}

Voxel GetVoxel(int index, samplerBuffer tbo = u_tbo_tex){
    //col
    //state
    //pos
    int color = floatBitsToInt(TexelFetch1(4 + (5 * index), tbo));
    int state = floatBitsToInt(TexelFetch1(4 + (5 * index) + 1, tbo));
    vec3 position = vec3(
        TexelFetch1(4 + (5 * index) + 2, tbo),
        TexelFetch1(4 + (5 * index) + 3, tbo),
        TexelFetch1(4 + (5 * index) + 4, tbo)
    );
    return Voxel(color, state, position);
}


void getVoxelAABB(vec3 center, vec3 size, out vec3 minCorner, out vec3 maxCorner){
    minCorner = center - (size / 2);
    maxCorner = center + (size / 2);
    return;
}

int IndicesToIndex(ivec3 indices, int ssbo = 0){
    return ssbo * VOXELS_PER_CHUNK_EDGE * VOXELS_PER_CHUNK_EDGE * VOXELS_PER_CHUNK_EDGE
        + indices.z * VOXELS_PER_CHUNK_EDGE * VOXELS_PER_CHUNK_EDGE
        + indices.y * VOXELS_PER_CHUNK_EDGE
        + indices.x;
}

ivec3 IndexToIndices(int index){
    ivec3 ret = ivec3(0);
    ret.x = index % VOXELS_PER_CHUNK_EDGE;
    index = (index-ret.x)/VOXELS_PER_CHUNK_EDGE;

    ret.y = index % VOXELS_PER_CHUNK_EDGE;
    index = (index-ret.y)/VOXELS_PER_CHUNK_EDGE;

    ret.z = index % VOXELS_PER_CHUNK_EDGE;

    return ret;
}

void ClearVoxelArray(int ssbo = 0){
    // for(int i = 0;i < VOXELS_PER_CHUNK / 2;i++){
    //     DefVoxelArray[i] = -1;
    // }

    return;

    for(int x = 0;x < VOXELS_PER_CHUNK_EDGE;x++)
        for(int y = 0;y < VOXELS_PER_CHUNK_EDGE;y++)
            for(int z = 0;z < VOXELS_PER_CHUNK_EDGE;z++){
                DefVoxelArray[IndicesToIndex(ivec3(x,y,z))] = -2;
            }
}

ivec3 RelativePositionToArrayIndices(vec3 pos){
    //transform corner positions to [0,16]
    pos += vec3(HALF_CHUNK_SIZE);
    //transform corner positions to [0,1]
    pos /= vec3(CHUNK_SIZE);
    //convert relative position in chunk to indices in array
    ivec3 ind = clamp(ivec3(vec3(255) * pos), ivec3(0), ivec3(255));
    
    if (ind.x >= CHUNK_SIZE) ind.x = CHUNK_SIZE - 1;
    if (ind.y >= CHUNK_SIZE) ind.y = CHUNK_SIZE - 1;
    if (ind.z >= CHUNK_SIZE) ind.z = CHUNK_SIZE - 1;

    if (ind.x < 0) ind.x = 0;
    if (ind.y < 0) ind.y = 0;
    if (ind.z < 0) ind.z = 0;

    return ind;
}

void FillArrayWithVoxelLeaf(Voxel v, int id){
        ivec4 bytes = BytesFromInt(v.state);
        float size = CHUNK_SIZE / pow(2, (bytes.y));
        bool crossed = false;
        vec3 minCorn = vec3(-1);
        vec3 maxCorn = vec3(1);

        getVoxelAABB(v.position, vec3(size), minCorn, maxCorn);

        //adjust corner position to voxel center position
        maxCorn -= vec3(MIN_VOXEL_SIZE);

        ivec3 iMinCorn = RelativePositionToArrayIndices(minCorn);
        ivec3 iMaxCorn = RelativePositionToArrayIndices(maxCorn);

        iMinCorn = ivec3(0);
        iMaxCorn = ivec3(1);

        for(int x = iMinCorn.x;x < iMaxCorn.x;x++)
            for(int y = iMinCorn.y;y < iMaxCorn.y;y++)
                for(int z = iMinCorn.z;z < iMaxCorn.z;z++){
                    // DefVoxelArray[IndicesToIndex(ivec3(x,y,z))] = id;
                    DefVoxelArray[0] = id;
                    // id = DefVoxelArray[0];
                }
}

VoxelHit renderChunk2(vec3 ro, vec3 rd, int tbo){
    int leafsCount = floatBitsToInt(TexelFetch1(0));
    vec3 chunkCenter = vec3(
        TexelFetch1(1),
        TexelFetch1(2),
        TexelFetch1(3)
    );

    float dist = 0;
    float distOut = 0;


    vec3 dirfrac = vec3(0);
    dirfrac.x = 1.0f / rd.x;
    dirfrac.y = 1.0f / rd.y;
    dirfrac.z = 1.0f / rd.z;

    bool intersect = advancedIntersectAABBdirfrac(ro, rd, chunkCenter - vec3(HALF_CHUNK_SIZE), chunkCenter + vec3(HALF_CHUNK_SIZE), dirfrac, dist, distOut);
    VoxelHit vh = VoxelHit(vec3(0), vec3(0), vec3(0), MAX_RENDER_DISTANCE, vec4(0), false, 0);


    return vh;
}

VoxelHit renderChunk(vec3 ro, vec3 rd, int tbo){
    int leafsCount = floatBitsToInt(TexelFetch1(0));
    vec3 chunkCenter = vec3(
        TexelFetch1(1),
        TexelFetch1(2),
        TexelFetch1(3)
    );

    float dist = 0;
    float distOut = 0;


    vec3 dirfrac = vec3(0);
    dirfrac.x = 1.0f / rd.x;
    dirfrac.y = 1.0f / rd.y;
    dirfrac.z = 1.0f / rd.z;

    bool intersect = advancedIntersectAABBdirfrac(ro, rd, chunkCenter - vec3(HALF_CHUNK_SIZE), chunkCenter + vec3(HALF_CHUNK_SIZE), dirfrac, dist, distOut);
    VoxelHit vh = VoxelHit(vec3(0), vec3(0), vec3(0), MAX_RENDER_DISTANCE, vec4(0), false, 0);
    if(!intersect){
        return vh;
    }
    intersect = false;
    vec3 rp = ro + (rd * (dist + 0.0001));
    bool intersectOnce = false;
    // rp = vec3(0);
    bool isInside = true;
    
    while(isInside && !intersect){
        for(int i = 0;i < leafsCount;i++){
            Voxel v = GetVoxel(i);
            v.position += chunkCenter;
            ivec4 bytes = BytesFromInt(v.state);
            float size = CHUNK_SIZE / pow(2, (bytes.y));
            
            vec3 minCorn = vec3(-1);
            vec3 maxCorn = vec3(1);

            getVoxelAABB(v.position, vec3(size), minCorn, maxCorn);
            // minCorn = vec3(-ha)
            if(IsPointInside(rp, minCorn, maxCorn )){
                intersect = advancedIntersectAABBdirfrac(ro, rd, minCorn, maxCorn, dirfrac, dist, distOut);
                if(bitInt(v.state, OctFillState)){
                    vh = VoxelHit(ro + (rd * dist), v.position, vec3(0), dist, colorFromBytes(v.color), intersect, v.state);
                    // vh.crossed = true;
                    // vh.color = vec4(0,1,0,1);
                    return vh;
                }else{
                    rp += rd * (abs(distOut - dist));
                    intersect = false;
                    // break;
                }
            }

        }
        isInside = IsPointInside(rp, chunkCenter + vec3(-HALF_CHUNK_SIZE), chunkCenter + vec3(HALF_CHUNK_SIZE));
    }
    
    // vh.crossed = true;
    // vh.color = vec4(1,0,0,0.5);
    
    
    return vh;
}


VoxelHit RenderChunks(vec3 ro, vec3 rd){

    vec3 pos = vec3(
        TexelFetch1(0),
        TexelFetch1(0),
        TexelFetch1(0)
    );
    if(mod(u_render_variant, 2) == 0)
        return renderChunk(ro, rd, 0);
    else
        return renderChunk2(ro, rd, 0);

    // for(int i = 1;i < u_chunks_count;i++){
    //     pos = vec3(
    //         TexelFetch1(0),
    //         TexelFetch1(0),
    //         TexelFetch1(0)
    //     );
    //     VoxelHit v = renderChunk(ro, rd, pos, dataOffset);
    //     if((v.dist < vh.dist && v.crossed == true) || (vh.crossed == false)){
    //         vh = v;
    //     }
    // }

    // return vh;
}

vec4 rgb_sample(int coordinate)
{
    uint texValue = floatBitsToUint(texelFetch(u_tbo_tex, coordinate).r);
    return vec4(texValue & 4u, texValue & 2u, texValue & 1u, 1.0);
}

vec4 render(vec2 uv){
    vec4 col = vec4(0,0,0,0);
    vec3 ro = u_camera_position;
    vec3 rd = getCam(u_camera_forward, u_camera_right, u_camera_up) * normalize((vec3(uv, FOV * u_mouse_wheel)));

    vec4 color = vec4(0);


    VoxelHit vh = RenderChunks(ro, rd);

    
    if(vh.crossed){
        
        // float lightDot = (dot(vh.normal, globalLightDirection) * -1 + 1) / 4;
        float lightDot = dot(vh.normal, globalLightDirection) * -1;

            color = vh.color;
        
        if(lightDot > 0.0){
            color = vh.color;
            color = ColorBlend(vh.color, globalLightColor, 1, tan(lightDot) / LightDotMultiplier);
        }else{            
            color = ColorBlend(vh.color, vec4(0,0,0,1), 1, abs(lightDot) * ShadowDotMultiplier);
        }
        
        #ifdef VOXEL_NOISE
            float noise = noise3((vh.pos - mod(vh.pos, MIN_VOXEL_SIZE_HALF)) * CHUNK_SIZE * vec3(10,100,1000));
            color = ColorBlend(color, vec4(vec3(noise), 1), 1, VOXEL_NOISE_MULTIPLIER);
            // color = vec4(vec3(noise), 1);
        #endif
    }else{
        // if(TexelFetch1(0, u_tbo_tex2) == 0){
        //     color = vec4(0,1,0,1);
        // }else{
        //     color = backgroundColor;
        // }
            color = backgroundColor;
        #ifdef SUN_BLOOM

            float d = dot(rd * -1, normalize(globalLightDirection));
            if(d > 1 - SUN_BLOOM){
                color = globalLightColor;
            }

        #endif
        
    }

    #ifdef WIRECUBE_DEBUG

    vec3 pos = ro + (u_camera_forward * WIRECUBE_DISTANCE);
    pos = pos - mod(pos, vec3(0.25));
    float dist = 0;
    float distOut = 0;

    if(advancedIntersectAABB(ro, rd, pos - vec3(0.5), pos + vec3(0.5), dist, distOut)){
        vec3 hitpos = ro + (rd * dist);
        vec3 relhitpos = abs(hitpos - pos) * 2;
        
        vec3 hitposout = ro + (rd * distOut);
        vec3 relhitposout = abs(hitposout - pos) * 2;

        float f = 0.9;
        if(
            (relhitpos.x > f && relhitpos.y > f) ||
            (relhitpos.x > f && relhitpos.z > f) ||
            (relhitpos.z > f && relhitpos.y > f)
        ){
            if(dist > vh.dist)
                color = vec4(0,1,0,0.5);
            else
                color = vec4(0,1,0,1);
        }else if(
            (relhitposout.x > f && relhitposout.y > f) ||
            (relhitposout.x > f && relhitposout.z > f) ||
            (relhitposout.z > f && relhitposout.y > f)
        ){
            if(distOut > vh.dist)
                color = vec4(0,1,0,0.5);
            else
                color = vec4(0,1,0,1);
        }
    }

    #endif
    


    return color;
}


void main()
{
    float ratio = u_resolution.x / u_resolution.y;
    vec2 resol = vec2(u_resolution.x / 4, u_resolution.x / 4 / ratio);
    vec2 uv = (0.5 * gl_FragCoord.xy - resol.xy) / resol.y;

    vec4 color = vec4(0.2,0.2,0.2, 1);
    color = render(uv);

    

    if(uv.x > -0.01 && uv.x < 0.01 && uv.y > -0.01 && uv.y < 0.01){
        color = vec4(1);
        bool b = false;
        vec3 v = vec3(TexelFetch4(0));
        b = v.y == 1;
        if(b){
            color = vec4(0,1,0,1);
        }else{
            color = vec4(1,0,0,1);
        }
    }
    

    // if(PointAABB(vec3(0.9999999), vec3(-1), vec3(1))){
    //     color = vec4(1);
    // }

    fragColor = color;
}