


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


Voxel GetVoxelByInd(ivec3 i){
    int v = 5;
    int offset = i.x * VoxelPerRow * VoxelPerRow + i.y * VoxelPerRow + i.z;
    // offset = x * N * N + y * N + z
    offset *= v;
    offset += 3;

    
    vec4 voxColor = vec4(
        TexelFetch4(offset + 0).x,
        TexelFetch4(offset + 1).x,
        TexelFetch4(offset + 2).x,
        TexelFetch4(offset + 3).x
    );
    int state = floatBitsToInt(TexelFetch4(offset + 4).x);

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



VoxelHit renderChunk(vec3 ro, vec3 rd, vec3 pos = vec3(0),  int offset = 0){
    float dist = 0;
    bool intersect = intersectAABB(ro,rd, pos - vec3(ChunkSizeHalf), pos + vec3(ChunkSizeHalf), dist);
    VoxelHit vox = VoxelHit(vec3(0), vec3(0), vec3(0), maxRenderDistance + 1, vec4(1), false, 0);
    if(intersect == false){
        return vox;
    }

    vec3 rp = ro + (rd * (dist + 0.0001));
    ivec3 ind = GetIndByPos(rp, pos);
    Voxel vd = GetVoxelByInd(ind);
    intersect = bitInt(vd.state, 24);

    while(IsPointInside(rp - pos) && intersect == false)
    {
        rp = rp + (rd * (VoxelSize / 50));
        ind = GetIndByPos(rp, pos);
        vd = GetVoxelByInd(ind);
        intersect = bitInt(vd.state, 24);
    }

    
    vec3 voxCenter =  pos - vec3(ChunkSizeHalf);
    voxCenter += ((vec3(ind) * VoxelSize));
    voxCenter += VoxelSize / 2;
    bool intersectVox = intersectAABB(ro, rd, voxCenter - vec3(VoxelSize / 2), voxCenter + vec3(VoxelSize / 2), dist);
    bool inside = IsPointInside(voxCenter - pos);
    
    
    vec3 hitPoint = ro + (rd * dist);

    float dt = dot(rd, ro - hitPoint);

    if(intersectVox = false){
        return vox;
    }

    vec3 dir = voxCenter - hitPoint;
    dir *= -1;
    dir = normalize(dir);
    vec3 normal = BoxNormal(dir);



    dist = lengthSqr(ro - hitPoint);

    vox = VoxelHit(hitPoint, voxCenter, normal, dist, vd.color, intersect, vd.state);
    return vox;
}


vec4 render(in vec2 uv){
    vec4 col = vec4(0,0,0,0);
    vec3 ro = u_camera_position;
    vec3 rd = getCam(u_camera_forward, u_camera_right, u_camera_up) * normalize((vec3(uv, FOV * u_mouse_wheel)));

    vec4 color = vec4(0);



    
    vec3 pos = vec3(
        TexelFetch4(0).x,
        TexelFetch4(1).x,
        TexelFetch4(2).x
    );
    // pos = vec3(0,0,0);

    VoxelHit vh = renderChunk(ro, rd, pos, 0);
    
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
                // sd = 
                
                VoxelHit srv = renderChunk(so, sd, pos, 0);
                
                
                vec3 sunHitPoint = srv.pos;
                float dist = lengthSqr(abs(vh.pos - srv.pos));

                if(srv.crossed && dist < EPSILON){
                    color = ColorBlend(vh.color, globalLightColor, 1, lightDot / LightDotMultiplier);
                    // color = vec4(lightDot / 2,0,0,1);
                }else{
                    color = ColorBlend(vh.color, vec4(0,0,0,1), 1, lightDot * ShadowDotMultiplier);
                    // color = vec4(0,1,0,1);
                }

            }else{
                //if no need to calc GL (blue)
                color = vec4(0,0,1,1);

                //
                //sunray-normal dot-light
                //
                color = ColorBlend(vh.color, vec4(0,0,0,1), 1, abs(lightDot) * ShadowDotMultiplier);
            }
            #endif

            float noise = noise3(vh.center * 10 - vec3(VoxelSize) * 5);
            color = ColorBlend(color, vec4(vec3(noise), 1), 1, 0.05);
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


    // fragColor = vec4(1,0,0,1);
}
