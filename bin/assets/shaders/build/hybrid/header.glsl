#version 330 core
// #pragma fragmentoption ARB_precision_hint_nicest

#extension GL_ARB_arrays_of_arrays : require
#extension GL_ARB_shader_storage_buffer_object : require

in vec4 vColor;
in vec2 vTexCoord;
in vec3 vNormal;
in vec3 vFragPos;

out vec4 fragColor;
const float FOV = 1.0;

#define EPSILON 0.000001
#define MAX_RENDER_DISTANCE 100000

#define CHUNK_SIZE 32
#define HALF_CHUNK_SIZE 16
#define MIN_VOXEL_SIZE 0.0625
#define MIN_VOXEL_SIZE_HALF 0.03125
#define MIN_VOXEL_SIZE_QUART 0.015625

#define VOXELS_PER_CHUNK_EDGE 256
#define VOXELS_PER_CHUNK VOXELS_PER_CHUNK_EDGE * VOXELS_PER_CHUNK_EDGE * VOXELS_PER_CHUNK_EDGE

#define HYPOTENUSE 1.4142135624
#define M_PI 3.1415926535897932384626433832795

#define GLOBAL_ILUMINATION
#define VOXEL_NOISE
#define SUN_BLOOM 0.005
#define LightDotMultiplier 5
#define ShadowDotMultiplier 10
#define VOXEL_SIZE 0.0625

////    real value
// #define VOXEL_NOISE_MULTIPLIER 0.025
////    debug value
#define VOXEL_NOISE_MULTIPLIER 0.1


// States indices
#define OctFillState 24
#define OctFullfilled 25
#define OctSurrounded 26
#define OctOpacity 27
#define OctDivided 28
#define OctIsLeaf 8

// #define WIRECUBE_DEBUG
#define WIRECUBE_DISTANCE 5

// Octree nodes position offset

const vec3 OctNodeOffset[8] = vec3[8](
    vec3(1, 1, 1),
    vec3(-1, 1, 1),
    vec3(-1, -1, 1),
    vec3(1, -1, 1),
    
    vec3(1, 1, -1),
    vec3(-1, 1, -1),
    vec3(-1, -1, -1),
    vec3(1, -1, -1)
);

// #define ShowLightCalculations

// #define showLOD

// #define ChunkSize 32
// #define ChunkSizeHalf 16


uniform vec3 globalLightDirection = vec3(0.5, -0.25, 1);
// uniform vec3 globalLightDirection = vec3(0, 1, 0);
vec4 globalLightColor = vec4(1, 1 , 0.85, 1);
vec4 ambient = vec4(1, 1, 1, 1);
vec4 backgroundColor = vec4(0.5, 0.8, 0.9, 1);
vec4 voivColor = vec4(0.1, 0.1, 0.1, 1);

uniform vec2 u_resolution;
uniform float u_time = 0;

uniform int u_chunks_count = 1;

uniform vec3 u_camera_position;
uniform vec3 u_camera_forward;
uniform vec3 u_camera_right;
uniform vec3 u_camera_up;
uniform float u_mouse_wheel = 1;

uniform int u_render_variant = 0;

uniform samplerBuffer u_tbo_tex;
uniform samplerBuffer u_tbo_tex2;

float specularStrength = 0.5;

const float toCamDistArray[5] = float[5](5, 4, 3, 2, 1);
const vec4 toCamDistArrayCol[5] = vec4[5](
    vec4(vec3(1),1),
    vec4(vec3(0.8),1),
    vec4(vec3(0.6),1),
    vec4(vec3(0.4),1),
    vec4(vec3(0.2),1)
);

// int DefVoxelArray2[VOXELS_PER_CHUNK_EDGE, VOXELS_PER_CHUNK_EDGE, VOXELS_PER_CHUNK_EDGE];
// int DefVoxelArray[VOXELS_PER_CHUNK];

#define SSBO_LAYERS  64

layout(std430, binding = 3) buffer ssboLayout
{
    int DefVoxelArray[];
};

layout(std430, binding = 4) buffer ssboLayout2
{
    int DefVoxelArray2[];
};