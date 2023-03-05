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



Voxel CalcVoxel(vec3 ro, vec3 rd, vec3 pos, vec3 b, float col, Voxel res){
    vec3 voxPos = pos * 1;
    vec3 voxPosF = vec3(pos) * 1;

    bool voxCross = (intersectAABB(ro, rd, voxPosF - b, voxPosF + b));
    float dt = dot(u_camera_forward, normalize(voxPosF - u_camera_position));
    

    if(!voxCross) return res;

    voxPos = voxPos;
    
    // float voxDist = boxDist(voxPos - u_camera_position, b);
    float voxDist = intersectAABBdist(ro, rd, voxPosF - b, voxPosF + b);
    // pointDist = intersectAABBdist(ro, rd, vec3(2,0,0) + vec3(-1), vec3(2,0,0) + vec3(1));
    // float voxDist = fBoxCheap(voxPos - u_camera_position, b);
    float voxCol = col;
    // voxCol = 1;
    Voxel obj = Voxel(voxPos, voxDist, voxCol, dt, voxCross, b.x);

    if(obj.dist < res.dist) return obj;

    return res;

}

Voxel rayMarchStatic(vec3 ro, vec3 rd){
	Voxel res = Voxel(vec3(0), MAX_DIST_STATIC, 0, 1, false, 0);

    
    float dt = dot(rd, normalize(vec3(0) - u_camera_position));

    if(dt < 0){
        return res;
    }
    
    int d = 0;

    vec3 camForward = rd;

    bool b = intersectAABB(ro, rd, vec3(-CHUNK_HALF_SIZE - 5), vec3(CHUNK_HALF_SIZE + 5));
    if(!b) return res;

    for(int i = 0;i < u_object_size * 5;i+= 5){
        vec3 pos = vec3(
            (u_objects[i + 0]),
            (u_objects[i + 1]),
            (u_objects[i + 2])
        );
        vec3 b = vec3(u_objects[i + 3]) * 0.5;
        res = CalcVoxel(ro, rd, pos, b, u_objects[i + 4], res);
    }

    return res;
}




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

    
    vec3 lightPos = vec3(15, 15, -25);


    Voxel staticVox = rayMarchStatic(ro, rd);

    Voxel vox = staticVox;
    

    vec4 background = vec4(0.5, 0.8, 0.9, 1);
    
    if(vox.crossed){
        float cc = intBitsToFloat(0xFF0000FF);
        uint cf = floatBitsToUint(vox.col);
        vec4 cv = vec4(
            float(cf & uint(0xFF000000)),
            float(cf & uint(0x00FF0000)),
            float(cf & uint(0x0000FF00)),
            float(cf & uint(0x000000FF)));
        cv.x /= 256000000;//r
        cv.y /= 256000;//g
        cv.z /= 2560;//b
        cv.w /= 256000000;//a

        col = vec4(
            cv.x / 17,
            cv.y / 65.2,
            cv.z / 25.6,
            1
        );



        // N = abs(boxNormal(normalize(vec3(0.8,0.9,0.9))));

        // pointDist = fBoxCheap(vec3(2,0,0) - ro, vec3(2));
        vec3 b = vec3(vox.edge);
        float pointDist = intersectAABBdist(ro, rd, vox.pos - b, vox.pos + b);
        vec3 point = ro + (pointDist * rd);
        point = point - vox.pos;
        point = normalize(point);
        vec3 N = abs(boxNormal(point));
        // col += vec4(N,1);
        // col /= 2;

        switch(colorMode){
            case 1:{
                col = vec4(N, 1);
                break;
            }
            case 2:{
                float dist = lengthSqr(u_camera_position - vox.pos);
                float d = 1 + (dist / MAX_DIST_STATIC * -1);
                col = vec4(vec3(d), 1);
                break;
            }
        }

        col.w = 1;
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
    
    // col = pow(color, vec4(0.4545,0.4545,0.4545,1));
    col = pow(color, vec4(vec3(0.75),1));


    if(uv.x > -0.01 && uv.x < 0.01 && uv.y > -0.01 && uv.y < 0.01){
        col = abs(color - vec4(1));
    }

    col.w = color.w;
    fragColor = col;
}