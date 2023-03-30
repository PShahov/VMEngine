bool intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);

    return tNear < tFar;
}
float intersectAABBdist(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);

    // return tNear < tFar;
    return tNear;
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
    // return t1 > t0;
}

bool compareInt(int a, int b){
    return bitInt(a - b, 31);
}


float boxDist(vec3 pos, vec3 size){
    return (abs(pos.x) + abs(pos.y) + abs(pos.z));
}

int boxDist(ivec3 pos){
    // return int(max(max(pos.x, pos.y), pos.z));
    return abs(pos.x) + abs(pos.y) + abs(pos.z);
    // return int(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z);
    // return int(lengthSqr(pos));
}

float TexelFetch(int offset){
    int cOffset = offset % 4;
    offset = (offset - cOffset) / 4;
    return texelFetch(u_tbo_tex, offset)[cOffset];
}

void CalcVoxel(vec3 ro, vec3 rd, ivec3 pos, out Voxel res){
    ivec3 voxPos = pos * 1;
    vec3 voxPosF = vec3(pos) * 1;

    vec3 b = vec3(1) * 0.5;
    // short f = 0.0;
    bool voxCross = (intersectAABB(ro, rd, voxPosF - b, voxPosF + b));
    float dt = dot(u_camera_forward, normalize(voxPosF - u_camera_position));

    if(!voxCross) return;

    voxPos = voxPos;
    int voxDist = boxDist(voxPos - u_camera_position_int);
    float voxCol = 1;
    voxCol = 1;
    res = Voxel(voxPos, voxDist, voxCol, dt, voxCross);
    // res.pos = voxPos;
    // res.dist = voxDist;
    // res.crossed = voxCross;
    // res = Voxel(voxPos, voxDist, voxCol, 0.0, voxCross);
    
    // if(voxDist < 1) continue;

    // res = compareInt(obj.dist, res.dist) ? obj : res;
    // if(compareInt(obj.dist, res.dist)){
    //     res = obj;
    // }

    //work but slow
    // res = obj.dist < res.dist ? obj : res;

    //work but toy
    // res = obj.dt > res.dt ? obj : res;

}

// Voxel LiteCalcVoxel(vec3 ro, vec3 rd, vec3 pos, vec3 b, float col, Voxel res){
//     vec3 voxPos = pos * 1;
//     vec3 voxPosF = vec3(pos) * 1;

//     bool voxCross = (intersectAABB(ro, rd, voxPosF - b, voxPosF + b));
    

//     if(!voxCross) return res;
//     float dt = dot(u_camera_forward, normalize(voxPosF - u_camera_position));

//     voxPos = voxPos;
    
//     float voxDist = intersectAABBdist(ro, rd, voxPosF - b, voxPosF + b);
//     float voxCol = col;
//     Voxel obj = Voxel(voxPos, voxDist, voxCol, dt, voxCross, b.x);


//     return obj;
// }


Voxel rayMarchStatic(vec3 ro, vec3 rd){
	Voxel res = Voxel(ivec3(0), MAX_DIST_STATIC + 1, 0, -1, false);


    
    float dt = dot(rd, normalize(vec3(0) - u_camera_position));
    
    int d = 0;

    vec3 camForward = rd;

    bool b = intersectAABB(ro, rd, vec3(-0.5), vec3(CHUNK_SIZE - 0.5));
    if(!b) return res;

    
    int xbit = int(bitFloat(camForward.x, 31));
    int ybit = int(bitFloat(camForward.y, 31));
    int zbit = int(bitFloat(camForward.z, 31));
    int bitSumm = xbit << 2 + ybit << 1 + zbit;

    //default
    // ivec3 start = ivec3(0);
    // ivec3 end = ivec3(CHUNK_SIZE);
    // ivec3 stp = ivec3(1);

    ivec3 start = ivec3(
        xbit * (CHUNK_SIZE - 1),
        ybit * (CHUNK_SIZE - 1),
        zbit * (CHUNK_SIZE - 1)
    );
    ivec3 end = ivec3(
        CHUNK_SIZE - (CHUNK_SIZE * xbit + xbit),
        CHUNK_SIZE - (CHUNK_SIZE * ybit + ybit),
        CHUNK_SIZE - (CHUNK_SIZE * zbit + zbit)
    );

    
    ivec3 stp = ivec3(
        1 - (2 * xbit),
        1 - (2 * ybit),
        1 - (2 * zbit)
    );

    // stp *= -1;

    // stp -= ivec3(0);

    int dir = 0;

    vec3 cf = abs(u_camera_forward);
    if(cf.x > cf.y && cf.x > cf.z){
        dir = 0;
    }else if(cf.y > cf.x && cf.y > cf.z){
        dir = 1;
    }else if(cf.z > cf.x && cf.z > cf.y){
        dir = 2;
    }


    switch(dir){
        case 0:{
            for(int x = start.x; x != end.x; x += stp.x){
                for(int y = start.y; y != end.y; y += stp.y){
                    for(int z = start.z; z != end.z; z += stp.z){
                        ivec3 pos = ivec3(x,y,z);
                        CalcVoxel(ro, rd, pos, res);
                        if(res.crossed) return res;
                    }
                }
            }
            break;
        }
        case 1:{
            for(int y = start.y; y != end.y; y += stp.y){
                for(int x = start.x; x != end.x; x += stp.x){
                    for(int z = start.z; z != end.z; z += stp.z){
                        ivec3 pos = ivec3(x,y,z);
                        CalcVoxel(ro, rd, pos, res);
                        if(res.crossed) return res;
                    }
                }
            }
            break;
        }
        case 2:{
            for(int z = start.z; z != end.z; z += stp.z){
                for(int x = start.x; x != end.x; x += stp.x){
                    for(int y = start.y; y != end.y; y += stp.y){
                        ivec3 pos = ivec3(x,y,z);
                        CalcVoxel(ro, rd, pos, res);
                        if(res.crossed) return res;
                    }
                }
            }
            break;
        }
    }


    return res;
}

// Voxel rayMarchStaticLight(vec3 ro, vec3 rd, float dist){
// 	Voxel res = Voxel(vec3(0), MAX_DIST_STATIC, 0, 1, false, 0);

    
//     float dt = dot(rd, normalize(vec3(0) - u_camera_position));

    
//     int d = 0;

//     vec3 camForward = rd;

//     vec3 chunkCenter = vec3(TexelFetch(0),TexelFetch(1),TexelFetch(2));

//     bool b = intersectAABB(ro, rd, chunkCenter - vec3(CHUNK_HALF_SIZE), chunkCenter + vec3(CHUNK_HALF_SIZE));
//     if(!b) return res;

//     int voxelsInChunk = int(TexelFetch(3));

//     for(int i = 4;i < voxelsInChunk * 5;i+= 5){
//         vec3 pos = vec3(
//             (TexelFetch(i + 0)),
//             (TexelFetch(i + 1)),
//             (TexelFetch(i + 2))
//         );
//         vec3 b = vec3(TexelFetch(i + 3)) * 0.5;
//         res = CalcVoxel(ro, rd, pos, b, TexelFetch(i + 4), res);
//         if(res.dist < dist) return res;
//     }

//     return res;
// }




mat3 getCam(vec3 camF, vec3 camR, vec3 camU){
    return mat3(camR, camU, camF);
}

vec4 EncodeFloatRGBA( float v )
{
    vec4 kEncodeMul = vec4(1.0, 255.0, 65025.0, 160581375.0);
    float kEncodeBit = 1.0/255.0;
    vec4 enc = kEncodeMul * v;
    enc = fract (enc);
    enc -= enc.yzww * kEncodeBit;
    return enc;
}
float DecodeFloatRGBA( vec4 enc )
{
    vec4 kDecodeDot = vec4(1.0, 1/255.0, 1/65025.0, 1/160581375.0);
    return dot( enc, kDecodeDot );
}

vec3 BoxNormal(vec3 center, vec3 size, vec3 point)
{
    step(0.5, 1.0);
	vec3 pc = point - center;
	// step(edge,x) : x < edge ? 0 : 1
	vec3 normal = vec3(0.0);
	normal += vec3(sign(pc.x), 0.0, 0.0) * step(abs(abs(pc.x) - size.x), EPSILON);
	normal += vec3(0.0, sign(pc.y), 0.0) * step(abs(abs(pc.y) - size.y), EPSILON);
	normal += vec3(0.0, 0.0, sign(pc.z)) * step(abs(abs(pc.z) - size.z), EPSILON);
	return normalize(normal);
}

vec4 ColorBlend(vec4 a, vec4 b, float at, float bt){
    float tSumm = at + bt;
    at = 1 / tSumm * at;
    bt = 1 / tSumm * bt;
    return (a * at) + (b * bt);
}


vec3 boxNormal(vec3 dir){
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
        // col = vec4(vec3(vox.dt), 1);
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

    // texelFetch(u_tbo_tex, 0)
    float ratio = u_resolution.x / u_resolution.y;
    vec2 resol = vec2(u_resolution.x / 4, u_resolution.x / 4 / ratio);
    // resol = u_resolution;
    vec2 uv = (0.5 * gl_FragCoord.xy - resol.xy) / resol.y;



    // ivec2 uvi = ivec2(gl_FragCoord.xy);
    // int offset = ((uvi.x) * (uvi.y)) + uvi.x;
    // fragColor = vec4(TexelFetch(u_tbo_tex, offset));
    // int cOffset = offset % 4;
    // offset = (offset - cOffset) / 4;
    // fragColor = vec4(vec3(texelFetch(u_tbo_tex, offset)[cOffset]), 1);


    // return;

    vec4 color = vec4(vec3(0), 1);

    color = render(uv);

    //gamma
    vec4 col = color;
    
    // col = pow(color, vec4(0.4545,0.4545,0.4545,1));
    col = pow(color, vec4(vec3(0.75),1));


    if(uv.x > -0.01 && uv.x < 0.01 && uv.y > -0.01 && uv.y < 0.01){
        col = abs(color - vec4(1));
    }

    col.w = color.w;
    fragColor = col;
}
