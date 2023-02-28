vec4 pblOpUnionId( vec4 d1, vec4 d2 )
{
    return d1.x < d2.x ? d1 : d2;
    return min(d1,d2);
}

vec4 pblOpSubtractionId( vec4 d1, vec4 d2 )
{
    return -d1.x > d2.x ? d1 : d2;
    return max(-d1,d2);
}

float pblOpIntersectionId( float d1, float d2 )
{
    return max(d1,d2);
}

void rotate(inout vec3 p, vec3 r){
	if(r.x != 0)
		pR(p.yz, r.x);
	if(r.y != 0)
		pR(p.xz, r.y);
	if(r.z != 0)
		pR(p.xy, r.z);

	// return p;
}
void rotate(inout vec3 p, float x = PI * 2, float y = PI * 2, float z = PI * 2){
	pR(p.yz, x);
	pR(p.xz, y);
	pR(p.xy, z);

	// return p;
}

void xRot(inout vec3 p, float r){
	pR(p.yz, r);
}
void yRot(inout vec3 p, float r){
	pR(p.xz, r);
}
void zRot(inout vec3 p, float r){
	pR(p.xy, r);
}


float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

// float rand(vec2 c){
// 	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
// }

float fNoise(vec2 p, float unit ){
	// float unit = screenWidth/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*fNoise(p, f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}

vec3 lerp3(vec3 a, vec3 b, float t){
	return (1 - t) * a + t * b;
}
vec4 lerp4(vec4 a, vec4 b, float t){
	return (1 - t) * a + t * b;
}
float lerp(float a, float b, float t){
	return (1 - t) * a + t * b;
}

// 2^x
int pow2(int x){
    int res = 1;
    for (int i=0;i<=31;i++){
        if (i<x){
            res *= 2;
        }
    }
    return res;
}

// a % n
float fmod(float a, int n){
    return a - (n * (a/n));
}

bool bitInt(int value, int bit){
	return ((value >> bit) & 1) == 1;
}
// return true if the bit at index bit is set
bool bitFloat(float value, int bit){

	return bitInt(floatBitsToInt(value), bit);
	
	return mod(floor((value + 0.5) / pow(2.0, float(bit))), 2.0) > 0;
	
    int bitShifts = pow2(bit);
    float bitShiftetValue = value / bitShifts;
    return fmod(bitShiftetValue, 2) > 0;
}
// a % n
int imod(int a, int n){
    return a - (n * (a/n));
}

// return true if the bit at index bit is set
// bool bitInt(int value, int bit){
	
//     int bitShifts = pow2(bit);
//     int bitShiftetValue = value / bitShifts;
//     return imod(bitShiftetValue, 2) > 0;
// }

float cbrt( float x )
{
	float y = sign(x) * uintBitsToFloat( floatBitsToUint( abs(x) ) / 3u + 0x2a514067u );

	for( int i = 0; i < NEWTON_ITER; ++i )
    	y = ( 2. * y + x / ( y * y ) ) * .333333333;

    for( int i = 0; i < HALLEY_ITER; ++i )
    {
    	float y3 = y * y * y;
        y *= ( y3 + 2. * x ) / ( 2. * y3 + x );
    }
    
    return y;
}

bool compare(float a, float b){
	// return false;
	// for(int i = 0;i < 32;i++){

	int b1 = 0;
	int b2 = 0;

	for (int i = 31; i >= 0; i--)
	{
		b1 = int(bitFloat(a, i));
		b2 = int(bitFloat(b, i));

		if(b1 + b2 == 1) break;
	}

	switch(b1 + b2){
		case 1:{
			switch(b1){
				case 1:{
					return true;
				}
				case 0:{
					return false;
				}
			}
		}
	}

	return false;
}

bool compareCheap(float a, float b){
	float c = a - b;
	return !bitFloat(c, 0);
}

Voxel fOpUnionVoxel(Voxel v1, Voxel v2){
	// return Voxel(min(v1.dist, v2.dist), v1.color);
	// return v2;a
	bool bb = false;

	// if(bitInt(t1, 0)){
	// 	return v2;
	// }

	// for(int i = 0;i < 32;i++){
	// // for(int i = 31;i >= 0;i--){
	// 	float a = v1.dist;
	// 	float b = v2.dist;
	// 	bool b1 = bitFloat(a, i);
	// 	bool b2 = bitFloat(b, i);
	// 	if(b1 != b2){
	// 		if(b1){
	// 			bb = true;
	// 			break;
	// 		}
	// 	}
	// }

	// if(bb){
	// 	return v1;
	// }else{
	// 	return v2;
	// }

	// return v2;

	// int a = int(abs(v1.dist * 10));
	// int b = int(abs(v2.dist * 10));

	// return compare(v1.dist * 1000, v2.dist * 1000) ? v2 : v1;
	// return compare(a, b) ? v1 : v2;
	// if(compare(a, b)){
	// 	a = b;
	// }else{
	// 	b = a;
	// }

	// return v2;
	// return compare(v1.iDist, v2.iDist) ? v1 : v2;

	// return ((v1.iDist) < (v2.iDist)) ? v1 : v2;
	// float f = abs(v1.dist - v2.dist);
	// if(f <= EPSILON){
	// 	return v2;
	// }
	// if(compareCheap(v1.dist, v2.dist)){
	// 	return v2;
	// }else{
	// 	return v1;
	// }
	return ((v1.dist) < (v2.dist)) ? v1 : v2;
	// return Voxel(min(v1.dist, v2.dist), 0, 0);
}

//how to pack 4 bytes values in dword
//as a side note, the order of the packed variables may be incorrect
//as I wrote this from memorydword
int PackValues (int x,int y,int z,int w){
	return (x<<24)+(y<<16)+(z<<8)+(w);
}
float pblfBoxCheap(vec3 p, vec3 b){
	return vmax(abs(p) - b);
	// return (pos.x * pos.x + pos.y * pos.y + pos.z * pos.z);
}
// Cheap Box: distance to corners is overestimated
// float fBoxCheap(vec3 p, vec3 b) { //cheap box
// 	return vmax(abs(p) - b);
// }

vec4 fOpUnionId(vec4 res1, vec4 res2){
    return (res1.x < res2.x) ? res1 : res2;
}
vec4 fOpDifferenceId(vec4 res1, vec4 res2){
    return (res1.x > -res2.x) ? res1 : vec4(
		-res2.x,
		res2.y,
		0,
		res1.y);
}
vec4 fOpDifferenceColumnsId(vec4 res1, vec4 res2, float r, float n){
    float dist = fOpDifferenceColumns(res1.x, res2.x, r, n);
    return (res1.x > -res2.x) ? vec4(dist, res1.y, 0, 0) : vec4(dist, res2.y, 0, 0);
}
vec4 fOpUnionRoundId(vec4 res1, vec4 res2, float r, float r2 = 1, float blendFactor = 0.0) {
    float dist = fOpUnionRound(res1.x, res2.x, r, r2);
	if(blendFactor != 0.0){
		return (res1.x < res2.x) ? vec4(
			dist,
			res1.y,
			// dist,
			lerp(0.5, 0.0, clamp((res2.x - res1.x) / r * blendFactor, 0, 1)),
			res2.y) : vec4(
				dist,
				res2.y,
				// 0.5,
				// dist,
				lerp(0.5, 0.0, clamp((res1.x - res2.x) / r * blendFactor, 0, 1)),
				res1.y);
	}else{
    	return (res1.x < res2.x) ? vec4(dist, res1.y, 0, res2.y) : vec4(dist, res2.y, 1, res1.y);
	}
}

float fDisplace(vec3 p, float s, float r, float t = 0){
    pR(p.yz, sin(t));
    return ((sin(p.x + (s * 2) * t) * sin(p.y + sin((s * 1) * t))) * sin(p.z + (s * 3) * t)) * r;
}

float rand(float n){return fract(sin(n) * 43758.5453123);}

float noise(float p){
	float fl = floor(p);
  float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}
	
float simpleNoise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
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


// vec3 hash3( in vec2 p )