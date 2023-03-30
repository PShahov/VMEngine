

vec4 map(vec3 p){
    vec4 res;

    //plane
    float planeDist = fPlane(p, vec3(0,1,0), 5.0);
    float planeId = 2.0;
    vec4 plane = vec4(planeDist, planeId,0,0);

    //
    vec4 box1 = _model(vec3(p) - vec3(0, 0, 1.25), 1);
    vec4 box2 = _model(p + vec3(0, 0, 1.25), 2);
    res = fOpUnionId(box1, box2);
    // for(int i = 1;i < 3;i++){
    //     vec4 box1 = _model(vec3(p) - vec3(0, 0, 1.25) - vec3(0,i * 4,0), 1);
    //     vec4 box2 = _model(vec3(p) + vec3(0, 0, 1.25) - vec3(0,i * 4,0), 2);
    //     vec4 r = fOpUnionId(box1, box2);
    //     res = fOpUnionId(res, r);
    // }
    res = fOpUnionId(res, plane);
    return res;
}
vec4 mapStatic(vec3 p){
    vec4 res;

    //plane
    float planeDist = fPlane(p, vec3(0,1,0), 5.0);
    float planeId = 2.0;
    vec4 plane = vec4(planeDist, planeId,0,0);

    res = plane;
    // res = fOpUnionId(res, plane);

    return res;
}
vec4 mapDynamic(vec3 p){
    vec4 res;

    //
    vec4 box1 = _model(vec3(p) - vec3(0, 0, 1.25), 1);
    vec4 box2 = _model(p + vec3(0, 0, 1.25), 2);
    res = fOpUnionId(box1, box2);
    // for(int i = 1;i < 3;i++){
    //     vec4 box1 = _model(vec3(p) - vec3(0, 0, 1.25) - vec3(0,i * 4,0), 1);
    //     vec4 box2 = _model(vec3(p) + vec3(0, 0, 1.25) - vec3(0,i * 4,0), 2);
    //     vec4 r = fOpUnionId(box1, box2);
    //     res = fOpUnionId(res, r);
    // }
    return res;
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
vec4 rayMarchStatic(vec3 ro, vec3 rd){
    vec4 hit;
	vec4 object;
    for(int i = 0;i < MAX_STEPS_STATIC;i++){
        vec3 p = ro + object.x * rd;
        hit = mapStatic(p);
        object.x += hit.x;
        object.y = hit.y;
		object.z = hit.z;
		object.w = hit.w;
        if(abs(hit.x) < EPSILON || object.x > MAX_DIST_STATIC) break;
    }

    return object;
}


float getSoftShadow(vec3 p, vec3 lightPos, float lightSize = 0.5) {
    float res = 1.0;
    float dist = 0.05;
    // float lightSize = 0.5;
    for (int i = 0; i < MAX_STEPS_DYNAMIC; i++) {
        float hit = map(p + lightPos * dist).x;
        res = min(res, hit / (dist * lightSize));
        dist += hit;
        if (hit < 0.0001 || dist > 100.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

// float getEdgyShadow(vec3 p, vec3 lightPos){
// 	    float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
//     	return d;
// }

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
    vec3 lightPos = vec3(-5, 55, -25);
    vec3 lightPos2 = vec3(-5, 55, 25);
    vec3 L = normalize(lightPos - p);
    vec3 N = getNormal2(p);
    // vec3 N = vec3(0,1,0);
    vec3 V = -rd;
    vec3 R = reflect(-L, N);

    // return N;

	// t = 0;

    vec4 color = getMaterial(p, id, N);
	// if(t != 0.0 && t != 1.0){
	// 	// vec4 secondColor = getMaterial(p, secondId, N);
	// 	// color = lerp4(color, secondColor, t);
	// 	// color = vec3(
	// 	// 	lerp(secondColor.x, color.x, t),
	// 	// 	lerp(secondColor.y, color.y, t),
	// 	// 	lerp(secondColor.z, color.z, t)
	// 	// );
	// }
	// if(id != 2.0){
	// 	// color = vec3(lerp(0,1,t));
	// 	// color = vec3(t);
	// }
	vec4 specColor = getSpecColor(id);
	
	// return color;

    vec4 specular = 1.3 * specColor * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
    vec4 diffuse = 0.9 * color * clamp(dot(L, N), 0.0, 1.0);
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
    float shadow = getSoftShadow(p + N * 0.02, normalize(lightPos), 0.2);
    // float shadow = 1;
    // shadow += getSoftShadow(p + N * 0.02, normalize(lightPos2), 0.2);
	// shadow /= 2;
	// shadow = 0;
	// float shadow = 1;
    // shadow = 0;
    float occ = getAmbientOcclusion(p, N);
    // if(d < length(lightPos - p)) return ambient;
    // return (ambient + fresnel) * occ + (specular * occ + diffuse) * shadow;

    
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

    vec3 lookAt = vec3(0,0,0);


    // vec3 rd = getCam(ro, lookAt) * normalize((vec3(uv, FOV * u_mouse_wheel)));
    // vec3 rd = getCam(ro, u_camera_look_at) * normalize((vec3(uv, FOV * u_mouse_wheel)));
    vec3 rd = getCam(u_camera_forward, u_camera_right, u_camera_up) * normalize((vec3(uv, FOV * u_mouse_wheel)));


    vec4 dynamicObject = rayMarchDynamic(ro, rd);
    vec4 staticObject = rayMarchStatic(ro, rd);

    // vec4 object = staticObject;
    vec4 object = fOpUnionId(staticObject, dynamicObject);

    vec4 background = vec4(0.5, 0.8, 0.9, 1);


    if(object.x < min(MAX_DIST_DYNAMIC, MAX_DIST_STATIC)){
        vec3 p = ro + object.x * rd;
        col += getLight(p, rd, object.y, object.z, object.w);
        
        //fog aka antialiasing
        if(u_fog)
            col  = mix(col, background, 1.0 - exp(-0.00002 * object.x * object.x));
    }else{
        col += background - max(0.95 * rd.y, 0.0);
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
vec4 renderAAx1() {
    return render(getUV(vec2(0)));
}


vec4 renderAAx2() {
    float bxy = int(gl_FragCoord.x + gl_FragCoord.y) & 1;
    float nbxy = 1. - bxy;
    vec4 colAA = (render(getUV(vec2(0.33 * nbxy, 0.))) + render(getUV(vec2(0.33 * bxy, 0.66))));
    return colAA / 2.0;
}


vec4 renderAAx3() {
    float bxy = int(gl_FragCoord.x + gl_FragCoord.y) & 1;
    float nbxy = 1. - bxy;
    vec4 colAA = (render(getUV(vec2(0.66 * nbxy, 0.))) +
                  render(getUV(vec2(0.66 * bxy, 0.66))) +
                  render(getUV(vec2(0.33, 0.33))));
    return colAA / 3.0;
}

void main()
{
    // u_resolution = vec2(1080, 900);
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution.xy) / u_resolution.y;


    vec4 color = vec4(vec3(0), 1);
    switch(u_AA_type){
        case 0: color = render(uv); break;
        case 1: color = renderAAx1(); break;
        case 2: color = renderAAx2(); break;
        case 3: color = renderAAx3(); break;
        case 4: color = renderAAx4(); break;
    }

    //gamma
    vec4 col = color;
    // vec4 col = pow(color, vec4(0.4545,0.4545,0.4545,1));
    col = pow(color, vec4(0.4));
    // col.w = 0.5;
    u_opacity = col.w;
    // color = pow(color, vec3(0.4));
    // color.w = 0.;
    col.w = color.w;

    fragColor = col;
}