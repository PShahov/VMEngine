#version 330 core

in vec4 vColor;
in vec2 texCoord;

uniform float opacity = 1;
uniform sampler2D texture0;
uniform sampler2D texture1;

out vec4 fragColor;


#define MAX_STEPS 100;
#define MAX_DIST 100;
#define SURF_DIST .001;

void main()
{
    // fragColor = vec4(1,0,0,1);
    fragColor = vec4(vColor.x, vColor.y, vColor.z, opacity);
}
