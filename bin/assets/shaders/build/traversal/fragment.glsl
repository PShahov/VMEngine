#version 410

layout(location = 0)in vec3 aPosition;
layout(location = 1)in vec4 aColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 offset;

out vec4 vColor;
out vec2 vTexCoord;
out vec3 vNormal;
out vec3 vFragPos;

void main()
{
    vColor = aColor;
    vFragPos = vec3(model * vec4(aPosition, 1.0));

    // gl_Position = vec4(aPosition + offset, 1.0) * view * projection;
    gl_Position = vec4(aPosition + offset, 1.0);
}