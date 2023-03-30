in vec4 vColor;
in vec2 texCoord;

uniform vec2 u_resolution;
uniform float opacity = 1;
uniform float u_time = 0;
uniform vec2 u_mouse;

uniform float u_mouse_wheel = 1;

uniform vec3 u_camera_position;
uniform ivec3 u_camera_position_int;

uniform vec3 u_camera_forward;
uniform vec3 u_camera_right;
uniform vec3 u_camera_up;
uniform vec3 u_camera_look_at;

uniform float u_objects[1000];
uniform int u_object_size;

uniform bool u_fog = true;

// 0 - no AA
// 2,3,4 - AA x 2/3/4
uniform int u_AA_type = 0;

// 0 - no shadows
// 1 - edgy shadows
// 2 - soft shadows
uniform int u_shadow_quality = 2;

out vec4 fragColor;

out float u_opacity;

const float FOV = 1.0;

//
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
//dynamic obj
const int MAX_STEPS_DYNAMIC = 512;
const int MAX_DIST_DYNAMIC = 200;
//static obj
const int MAX_STEPS_STATIC = 50;
const int MAX_DIST_STATIC = 100 * 100;

const float SHADOW_DISTANCE_SQUARE = 200 * 200;

// const float EPSILON = 1.4;
const float EPSILON = 0.0001;
const float EPSILON_MULTIPLIER = 2;
const float EPSILON_DYNAMIC = 0.00001;
const float EPSILON_STATIC = 0.001;

const float sphereScale = 1.0 / 1;
const float sphereBumpFactor = 0.21;

//tex
uniform sampler1D u_chunk_buffer;

uniform samplerBuffer u_tbo_tex;

uniform sampler2D u_tex_01;
uniform sampler2D u_tex_01_bump;

#define NEWTON_ITER 2
#define HALLEY_ITER 0


///faster
// float ww = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), 64.0 - 63.0*v );
//better
// float ww = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), 1.0 + 63.0*pow(1.0-v,4.0) );

vec3 globalLightDirection = vec3(1,-1,0.5);
// vec4 globalLightColor = vec4(1.0, 0.81, 0.28, 1);
vec4 globalLightColor = vec4(1, 1, 1, 1);


const float CHUNK_SIZE = 1;
const float CHUNK_HALF_SIZE = 0.5;

//0 - full colored;
//1 - normals;
//2 - distance;
const int colorMode = 1;

#define VoxelEdging;
#define GlobalIllumination;
#define SunBloom;

const bool useAmbientOcclusion = false;
const bool useEdgeAmbient = false;


const bool voxelColorNoise = true;