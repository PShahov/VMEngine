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


float boxDist(vec3 pos){
    // return int(max(max(pos.x, pos.y), pos.z));
    return int(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z);
    // return int(lengthSqr(pos));
}

Voxel rayMarchStatic(vec3 ro, vec3 rd){
	Voxel res = Voxel(vec3(0), MAX_DIST_STATIC + 1, 0, -1, false);

    int edge = 10;

    for(int x = 0;x < edge; x++){
        for(int y = 0;y < edge; y++){
            for(int z = 0;z < edge; z++){
                vec3 voxPos = vec3(x,y,z) * 0.4;
                // voxPos *= 5;
                // vec3 voxPos = vec3(i * 3, 0,0);

                if(x > 0 && x < edge - 1 && y > 0 && y < edge - 1 && z > 0 && z < edge - 1)
                    continue;


                vec3 b = vec3(1) * 0.1;

                float dt = dot(rd, normalize(-ro + voxPos));
                // if(dt < 0.0){
                //     i += 5;
                //     f+= 3;
                //     continue;
                // }

                bool voxCross = intersectAABB(ro, rd, voxPos - b, voxPos + b);
                // bool voxCross = dt > 0.99999;

                voxPos = voxPos + ro;

                // float voxDist = fBoxCheap(voxPos, b);
                float voxDist = boxDist(voxPos);
                float voxCol = 1;
                voxCol = 1;
                Voxel obj = Voxel(voxPos, voxDist, voxCol, dt, voxCross);

                if(voxCross)
                    res = obj.dist < res.dist ? obj : res;

                // res = obj.dt > res.dt ? obj : res;
            }
        }
    }

    return res;
}



// float getSoftShadow(vec3 p, vec3 lightPos, float lightSize = 0.5) {
//     float res = 1.0;
//     float dist = 0.05;
//     // float lightSize = 0.5;
//     for (int i = 0; i < MAX_STEPS_DYNAMIC; i++) {
//         float hit = mapDynamic(p + lightPos * dist).x;
//         res = min(res, hit / (dist * lightSize));
//         dist += hit;
//         if (hit < 0.0001 || dist > 100.0) break;
//     }
//     return clamp(res, 0.0, 1.0);
// }

// float getEdgyShadow(vec3 p, vec3 lightPos, vec3 N){
// 	    float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
//     	return d;
// }

// vec3 getNormal(vec3 p){
//     vec2 e = vec2(EPSILON, 0.0);
//     vec3 n = vec3(map(p).x) - vec3(map(p - e.xyy).x, map(p - e.yxy).x, map(p - e.yyx).x);
//     return normalize(n);
// }

mat3 getCam(vec3 camF, vec3 camR, vec3 camU){
    // vec3 camF = normalize(vec3(lookAt - ro));
    // vec3 camR = normalize(cross(vec3(0, 1, 0), camF));
    // vec3 camU = cross(camF, camR);
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
        col = vec4(vox.dist / 10, 0, 0,1);
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
    vec2 resol = vec2(900, 600);
    resol = u_resolution;
    vec2 uv = (2.0 * gl_FragCoord.xy - resol.xy) / resol.y;


    vec4 color = vec4(vec3(0), 1);

    color = render(uv);

    //gamma
    vec4 col = color;
    
    // vec4 col = pow(color, vec4(0.4545,0.4545,0.4545,1));

    col.w = color.w;

    fragColor = col;
}