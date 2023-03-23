#version 410

layout(location = 0)in vec3 aPosition;
layout(location = 1)in vec4 aColor;
layout(location = 2) in vec2 aTexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 offset;

out vec4 vColor;
out vec2 texCoord;

void main()
{
    vColor = aColor;
    texCoord = aTexCoord;
    // gl_Position = vec4(aPosition + offset, 1.0) * view * projection;
    gl_Position = vec4(aPosition + offset, 1.0);
}