#version 330 core
// #pragma fragmentoption ARB_precision_hint_nicest

in vec4 vColor;
in vec2 vTexCoord;
in vec3 vNormal;
in vec3 vFragPos;

out vec4 fragColor;
const float FOV = 1.0;

#define EPSILON 0.000001
#define maxRenderDistance 100

#define GlobalIllumination
#define SunBloom 0.005
#define LightDotMultiplier 5
#define ShadowDotMultiplier 1

#define ChunkSize 3
#define ChunkSizeHalf 1.5
#define VoxelPerRow 30
#define VoxelSize 0.1


uniform vec3 globalLightDirection = vec3(0.5, -0.25, 1);
vec4 globalLightColor = vec4(1, 1 , 0.85, 1);
vec4 ambient = vec4(1, 1, 1, 1);
vec4 backgroundColor = vec4(0.5, 0.8, 0.9, 1);

uniform vec2 u_resolution;
uniform float u_time = 0;

uniform vec3 u_camera_position;
uniform vec3 u_camera_forward;
uniform vec3 u_camera_right;
uniform vec3 u_camera_up;
uniform float u_mouse_wheel = 1;

uniform samplerBuffer u_tbo_tex;

float specularStrength = 0.5;