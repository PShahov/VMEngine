bool intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    // return vec2(tNear, tFar);

    return tNear < tFar;
    
    //no interesct
    // vec.x > vec.y
}

bool BBoxIntersect(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tbot = rayDir * (boxMin - rayOrigin);
    vec3 ttop = rayDir * (boxMax - rayOrigin);
    vec3 tmin = min(ttop, tbot);
    vec3 tmax = max(ttop, tbot);
    vec2 t = max(tmin.xx, tmin.yz);
    float t0 = max(t.x, t.y);
    t = min(tmax.xx, tmax.yz);
    float t1 = min(t.x, t.y);
    return t1 > max(t0, 0.0);
}

bool compareInt(int a, int b){
    return bitInt(a - b, 31);
}


int boxDist(ivec3 pos){
    // return int(max(max(pos.x, pos.y), pos.z));
    return abs(pos.x) + abs(pos.y) + abs(pos.z);
    // return int(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z);
    // return int(lengthSqr(pos));
}

Voxel rayMarchStatic(vec3 ro, vec3 rd){
	Voxel res = Voxel(ivec3(0), MAX_DIST_STATIC + 1, 0, -1, false);

    // int fori = 5 * u_object_size;
    // for(int i = 0;i < fori;i+= 5){
    //             vec3 voxPos = vec3(u_objects[i + 0], u_objects[i + 1], u_objects[i + 2]) * 2;
    //             // vec3 voxPos = vec3(i,0,0);

    //             vec3 b = vec3(1) * u_objects[i + 3];
    //             // vec3 b = vec3(0.1);
    //             // vec3 b = vec3(1) * 10;

    //             float dt = dot(rd, normalize(-ro + voxPos));
    //             // if(dt < 0.0){
    //             //     continue;
    //             // }

    //             bool voxCross = intersectAABB(ro, rd, voxPos - b, voxPos + b);

    //             if(!voxCross) continue;

    //             voxPos = voxPos;
    //             float voxDist = boxDist(voxPos - ro);
    //             float voxCol = 1;
    //             voxCol = 1;
    //             Voxel obj = Voxel(voxPos, voxDist, voxCol, dt, voxCross);

    //             res = obj.dist < res.dist ? obj : res;
    // }

    // return res;

    int edge = 10;
    // edge = int(cbrt(8));
    for(int x = 0;x < edge; x++){
        for(int y = 0;y < edge; y++){
            for(int z = 0;z < edge; z++){
                ivec3 voxPos = ivec3(x,y,z) * 2;
                vec3 voxPosF = vec3(x,y,z) * 2;

                vec3 b = vec3(1) * 0.5;

                // if(x > 0 && x < edge - 1 && y > 0 && y < edge - 1 && z > 0 && z < edge - 1) continue;

                // float dt = dot(rd, normalize(-ro + voxPos));
                // int dt = int(bitInt(floatBitsToInt(dot(rd, normalize(-ro + voxPos))), 31));
                // if(dt == 1){
                //     continue;
                // }

                bool voxCross = intersectAABB(ro, rd, voxPosF - b, voxPosF + b);
                // bool voxCross = BBoxIntersect(ro, rd, voxPosF - b, voxPosF + b);

                if(!voxCross) continue;

                voxPos = voxPos;
                int voxDist = boxDist(voxPos - u_camera_position_int);
                float voxCol = 1;
                voxCol = 1;
                Voxel obj = Voxel(voxPos, voxDist, voxCol, 0.0, voxCross);
                

                res = compareInt(obj.dist, res.dist) ? obj : res;

                //work but slow
                // res = obj.dist < res.dist ? obj : res;

                //work but toy
                // res = obj.dt > res.dt ? obj : res;
            }
        }
    }

    return res;
}




mat3 getCam(vec3 camF, vec3 camR, vec3 camU){
    return mat3(camR, camU, camF);
}

vec4 render(in vec2 uv){
    vec4 col = vec4(0,0,0,0);
    vec3 ro = u_camera_position;
    vec3 rd = getCam(u_camera_forward, u_camera_right, u_camera_up) * normalize((vec3(uv, FOV * u_mouse_wheel)));


    Voxel staticVox = rayMarchStatic(ro, rd);

    Voxel vox = staticVox;
    
        // float dt = dot(u_camera_forward, normalize(-u_camera_position - vox.pos));

    vec4 background = vec4(0.5, 0.8, 0.9, 1);
    
    // if(vox.dt >= 0.9){
    if(vox.crossed){
    // if(vox.dist < MAX_DIST_STATIC){
        col = vec4(vec3(noise3(vox.pos)),1);
    }else{
        col = background;
    }

    return col;
}

vec2 getUV(vec2 offset, float div = 1){
    return (2.0 * (gl_FragCoord.xy + offset) - (u_resolution.xy / div)) / (u_resolution.y / div);
}
vec4 renderAAx4(){
    vec4 e = vec4(0.125, -0.125, 0.375, -0.375);
    vec4 colAA = render(getUV(e.xz)) + render(getUV(e.yw)) + render(getUV(e.wx)) + render(getUV(e.zy));
    return colAA / 4.0;
}

void main()
{
    float ratio = u_resolution.x / u_resolution.y;
    vec2 resol = vec2(u_resolution.x / 4, u_resolution.x / 4 / ratio);
    // resol = u_resolution;
    vec2 uv = (0.5 * gl_FragCoord.xy - resol.xy) / resol.y;


    vec4 color = vec4(vec3(0), 1);

    color = render(uv);

    //gamma
    vec4 col = color;
    
    // vec4 col = pow(color, vec4(0.4545,0.4545,0.4545,1));

    col.w = color.w;

    fragColor = col;
}