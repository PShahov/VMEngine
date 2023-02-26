

Voxel mapStatic(vec3 p){
    Voxel res = Voxel(MAX_DIST_STATIC + 1, 0, MAX_DIST_STATIC + 1);
    //
    // res = _model(p1, 3);
    Voxel obj;

    float modX = 100000;

    // int v1 = floatBitsToInt(abs(fBoxCheap(p1 + offset, vec3(1))));
    // float v2 = 0.00000000000002;
    float v1 = 0.000000000000000000000001;
    float v2 = 0.00000000000000000000001;

    if(compareCheap(v1, v2))
    for(int i = 31; i >= 0;i--){
        vec3 p1 = p;

        vec3 offset = vec3(i * 4, 0, 0);

        bool b = bitFloat(v1, i);

        float boxDist = abs(fBoxCheap(p1 + offset, vec3(1, b ? 2 : 1, 1)));
        // boxDist = length(p1 + offset);
        int boxDistX = int(boxDist * modX);
        float boxId = 0;
        obj = Voxel(boxDist, boxId, boxDistX);
        res = fOpUnionVoxel(res, obj);
    }else
    for(int i = 31; i >= 0;i--){
        vec3 p1 = p;

        vec3 offset = vec3(i * 4, 5, 0);

        bool b = bitFloat(v2, i);

        float boxDist = abs(fBoxCheap(p1 + offset, vec3(1, b ? 2 : 1, 1)));
        u_opacity = 2;
        // boxDist = length(p1 + offset);
        int boxDistX = int(boxDist * modX);
        float boxId = 0;
        obj = Voxel(boxDist, boxId, boxDistX);
        res = fOpUnionVoxel(res, obj);
    }


    // for(int x = 0;x < 5;x++){
    //     for(int y = 0;y < 5;y++){
    //         for(int z = 0;z < 5;z++){
    //             vec3 p1 = p;

    //             vec3 offset = vec3(x * 4, y * 4, z * 4);

    //             float boxDist = abs(fBoxCheap(p1 + offset, vec3(1)));
    //             // boxDist = length(p1 + offset);
    //             float boxId = 0;
    //             obj = Voxel(boxDist, boxId, x * y * z);

    //             // float dt = dot(u_camera_forward, normalize(-u_camera_position - offset));
    //             // if(dt < 0.0){
    //             //     continue;
    //             // }
    //             // if(compare(res.dist, obj.dist)){
    //             //     float f = 0;
    //             // }

    //             res = fOpUnionVoxel(res, obj);

                
                
    //         }
    //     }
    // }

    // res = fOpUnionVoxel(res, obj);
    return res;

    // int i = 0;
    // float f = 0;
    // while(i < u_object_size * 5){
    //     vec3 p1 = p;
    //     vec3 offset = vec3(u_objects[i + 0],u_objects[i + 1],u_objects[i + 2]);

    //     offset = vec3(f, 0, 0);

    //     float dt = dot(u_camera_forward, normalize(-u_camera_position - offset));
    //     if(dt < 0.0){
    //         i += 5;
    //         f+= 3;
    //         continue;
    //     }

    //     offset += p1;
    //     vec3 b = vec3(1) * u_objects[i + 3] / 2;
    //     float boxDist = fBoxCheap(offset, b);
    //     float boxId = u_objects[i + 4];
    //     Voxel obj = Voxel(boxDist, boxId);

        
    //     // res = fOpUnionVoxel(res, obj);
    //     i += 5;
    //     f+= 3;

    // }
    // return res;
}

// Voxel mapStatic2(vec3 p, vec3 d){

// }

// Voxel rayMarchStatic(vec3 ro, vec3 rd){
//     Voxel hit;
// 	Voxel object;

//     Voxel res = Voxel(MAX_DIST_STATIC + 1, 0);
//     Voxel obj;
    
//     for(int x = 0;x < 10;x++){
//         for(int y = 0;y < 10;y++){
//             for(int z = 0;z < 2;z++){
//                 // vec3 p1 = p;

//                 vec3 offset = vec3(x * 4, y * 4, z * 4);
//                 offset += ro;
//                 vec3 dir = normalize(offset);
//                 float l = length(offset);
                
//                 // float dt = dot(u_camera_forward, normalize(offset));
//                 // if(dt < 0.5){
//                 //     continue;
//                 // }

//                 float boxDist = fBoxCheap(offset, vec3(1));
//                 // boxDist = 0.5;
//                 float boxId = 1;
//                 obj = Voxel(boxDist, boxId);

//                 res = fOpUnionVoxel(res, obj);
                
//             }
//         }
//     }
//     return res;
// }

Voxel rayMarchStatic(vec3 ro, vec3 rd){
    Voxel hit;
	Voxel object;
    for(int i = 0;i < MAX_STEPS_STATIC;i++){
        vec3 p = ro + object.dist * rd;
        hit = mapStatic(p);
        object.dist += hit.dist;
        object.color = hit.color;

        if(abs(hit.dist) < EPSILON || object.dist > MAX_DIST_STATIC) break;
    }

    return object;
}

vec4 mapDynamic(vec3 p){
    vec4 res = vec4(MAX_DIST_STATIC,0,0,0);
    //
    vec3 p1 = p;
    // res = _model(p1, 3);

    int i = 0;
    while(i < u_object_size * 5){
        
        vec3 offset = vec3(u_objects[i + 0],u_objects[i + 1],u_objects[i + 2]);
        // offset = vec3(o, 0, 0);
        // offset += vec3(i / 5, 0, 0);
        // offset = vec3(1.25, 1.25, 1.25);
        // offset = vec3()
        offset += vec3(p1.x,p1.y,p1.z);
        vec3 b = vec3(1) * u_objects[i + 3] / 2;
        float boxDist = fBoxCheap(offset, b);
        float boxId = u_objects[i + 4];
        vec4 obj = vec4(boxDist, boxId, 0, 0);
        // vec4 obj = _model(
        //     p1 + vec3(u_objects[i + 3], u_objects[i + 4], u_objects[i + 5]),
        //     int(u_objects[i + 2]),
        //     vec4(u_objects[i + 6], u_objects[i + 7], u_objects[i + 8], u_objects[i + 9])
        //     );

        switch(int(i)){
            case 0:{
                res = obj;
                break;
            }
            default:{
                res = fOpUnionId(res, obj);
                break;
            }
        }

        i += 5;
    }
    return res;
}

vec4 map(vec3 p){
    return vec4(1);
    // return mapDynamic(p);
    // return (fOpUnionId(mapStatic(p), mapDynamic(p)));
}

vec4 rayMarch(vec3 ro, vec3 rd){
    vec4 hit;
	vec4 object;
    for(int i = 0;i < MAX_STEPS_DYNAMIC;i++){
        vec3 p = ro + object.x * rd;
        hit = map(p);
        object.x += hit.x;
        object.y = hit.y;
		object.z = hit.z;
		object.w = hit.w;
        if(abs(hit.x) < EPSILON || object.x > MAX_DIST_DYNAMIC) break;
    }

    return object;
}
vec4 rayMarchDynamic(vec3 ro, vec3 rd){
    vec4 hit;
	vec4 object;
    for(int i = 0;i < MAX_STEPS_DYNAMIC;i++){
        vec3 p = ro + object.x * rd;
        hit = mapDynamic(p);
        object.x += hit.x;
        object.y = hit.y;
		object.z = hit.z;
		object.w = hit.w;
        if(abs(hit.x) < EPSILON || object.x > MAX_DIST_DYNAMIC) break;
    }

    return object;
}


float getSoftShadow(vec3 p, vec3 lightPos, float lightSize = 0.5) {
    float res = 1.0;
    float dist = 0.05;
    // float lightSize = 0.5;
    for (int i = 0; i < MAX_STEPS_DYNAMIC; i++) {
        float hit = mapDynamic(p + lightPos * dist).x;
        res = min(res, hit / (dist * lightSize));
        dist += hit;
        if (hit < 0.0001 || dist > 100.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

float getEdgyShadow(vec3 p, vec3 lightPos, vec3 N){
	    float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
    	return d;
}

vec3 getNormal(vec3 p){
    vec2 e = vec2(EPSILON, 0.0);
    vec3 n = vec3(map(p).x) - vec3(map(p - e.xyy).x, map(p - e.yxy).x, map(p - e.yyx).x);
    return normalize(n);
}
vec3 getNormal2( vec3 p ) // for function f(p)
{
    const float h = 0.0001;      // replace by an appropriate value
    // #define ZERO (min(iFrame,0)) // non-constant zero
    #define ZERO 0 // non-constant zero
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*h).x;
    }
    return normalize(n);
}

vec3 getNormal3( vec3 p){
    return vec3(0,1,0);
}

float getAmbientOcclusion(vec3 p, vec3 normal) {
    float occ = 0.0;
    float weight = 1.0;
    for (int i = 0; i < 8; i++) {
        float len = 0.01 + 0.02 * float(i * i);
        float dist = map(p + normal * len).x;
        occ += (len - dist) * weight;
        weight *= 0.85;
    }
    return 1.0 - clamp(0.6 * occ, 0.0, 1.0);
}

vec4 getLight(vec3 p, vec3 rd, float id, float t, float secondId){
    // vec3 lightPos = vec3(sin(u_alive) * 20.0, 30 + (cos(u_alive) * 10), cos(u_alive) * 30.0);
    vec3 lightPos = vec3(15, 15, -25);
    vec3 lightPos2 = vec3(-5, 55, 25);
    vec3 L = normalize(lightPos - p);
    vec3 N = getNormal2(p);
    // vec3 N = vec3(0,1,0);
    vec3 V = -rd;
    vec3 R = reflect(-L, N);

    // return N;

	// t = 0;

    vec4 color = getMaterial(p, id, N);
	if(t != 0.0 && t != 1.0){
		vec4 secondColor = getMaterial(p, secondId, N);
		color = lerp4(color, secondColor, t);
        color.w = 1;
		// color = vec4(
		// 	lerp(secondColor.x, color.x, t),
		// 	lerp(secondColor.y, color.y, t),
		// 	lerp(secondColor.z, color.z, t),
        //     1
		// );
	}
    // color = vec4(t,t,t,1);
	// if(id != 2.0){
	// 	// color = vec3(lerp(0,1,t));
	// 	// color = vec3(t);
	// }
	vec4 specColor = getSpecColor(id);
	
	// return color;

    vec4 specular = 1.3 * specColor * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
    vec4 diffuse = 0.9 * color * clamp(dot(L, N), 0.0, 1.0);
    // vec4 diffuse = color;
	// vec3 diffuse = vec3(0);
    vec4 ambient = 0.05 * color;
    vec4 fresnel = 0.15 * color * pow(1.0 + dot(rd, N), 3.0);

    
    // vec4 specular = specColor;
    // vec4 diffuse = color;
    
    fresnel.w = 0;
    diffuse.w = 1;
    ambient.w = 1;

	// float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
    // if (d < length(lightPos - p)) return ambient + fresnel;

    //shadows
    float shadow = 1;
    switch(u_shadow_quality){
        case 1:{
            float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
            if (d < length(lightPos - p)) return ambient + fresnel;
            break;
        }
        case 2:{
            if(lengthSqr(u_camera_position - p) <= SHADOW_DISTANCE_SQUARE)
                shadow = getSoftShadow(p + N * 0.02, normalize(lightPos), 0.2);
            break;
        }
    }


    float occ = getAmbientOcclusion(p, N);

    
    vec4 back = 0.05 * color * clamp(dot(N, -L), 0.0, 1.0);
	// vec3 back = vec3(0);
    // return color;
    vec4 col = (back + ambient + fresnel) * occ + (specular * occ + diffuse) * shadow;
    // col.w = color.w;
    // if(color.w != 1){
    //     col = vec4(1);
    // }
    // return vec4(N, 1);
    return col;
}

mat3 getCam(vec3 ro, vec3 lookAt){
    vec3 camF = normalize(vec3(lookAt - ro));
    vec3 camR = normalize(cross(vec3(0, 1, 0), camF));
    vec3 camU = cross(camF, camR);
    return mat3(camR, camU, camF);
}
mat3 getCam(vec3 camF, vec3 camR, vec3 camU){
    // vec3 camF = normalize(vec3(lookAt - ro));
    // vec3 camR = normalize(cross(vec3(0, 1, 0), camF));
    // vec3 camU = cross(camF, camR);
    return mat3(camR, camU, camF);
}

void mouseControl(inout vec3 ro){
    vec2 m = u_mouse / u_resolution;
    pR(ro.yz, m.y * PI * 0.5 - 0.5);
    pR(ro.xz, m.x * TAU);
}

vec4 render(in vec2 uv){
    vec4 col = vec4(0,0,0,0);
    vec3 ro = u_camera_position;
	// ro.x *= -1;
    // mouseControl(ro);


    // vec3 rd = getCam(ro, lookAt) * normalize((vec3(uv, FOV * u_mouse_wheel)));
    // vec3 rd = getCam(ro, u_camera_look_at) * normalize((vec3(uv, FOV * u_mouse_wheel)));
    vec3 rd = getCam(u_camera_forward, u_camera_right, u_camera_up) * normalize((vec3(uv, FOV * u_mouse_wheel)));


    // vec4 dynamicObject = rayMarchDynamic(ro, rd);
    Voxel staticVox = rayMarchStatic(ro, rd);

    Voxel vox = staticVox;
    // vec4 object = fOpUnionId(staticObject, dynamicObject);

    vec4 background = vec4(0.5, 0.8, 0.9, 1);
    
    if(vox.dist < MAX_DIST_STATIC){
        col = vec4(vox.dist, 0, 0,1);
    }else{
        col = background;
    }
        // col = background;

    // if(object.x < min(MAX_DIST_DYNAMIC, MAX_DIST_STATIC)){
    //     vec3 p = ro + object.x * rd;
    //     col += getLight(p, rd, object.y, object.z, object.w);
        
    //     //fog aka antialiasing
    //     if(u_fog)
    //         col  = mix(col, background, 1.0 - exp(-0.00003 * object.x * object.x));
    // }else{
    //     col += background - max(0.95 * rd.y, 0.0);
    // }

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