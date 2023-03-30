#version 330 core
// #pragma fragmentoption ARB_precision_hint_nicest

in vec4 vColor;
in vec2 vTexCoord;
in vec3 vNormal;
in vec3 vFragPos;

out vec4 fragColor;


#define GlobalIllumination;
#define SunBloom;

vec3 globalLightPosition = vec3(1,1, 1);
vec3 lightColor = vec3(1,1,1);
vec3 ambient = vec3(1,1,1);

uniform vec3 u_camera_position;

float specularStrength = 0.5;

void main()
{
    vec3 norm = normalize(vNormal);
    vec3 aNorm = abs(norm);
    if(aNorm.x > aNorm.y){
        norm.y = 0;
        if(aNorm.x > aNorm.z){
            norm.z = 0;
            norm.x = 1 * sign(norm.x);
        }else{
            norm.x = 0;
            norm.z = 1 * sign(norm.z);
        }
    }else{
        norm.x = 0;
        if(aNorm.y > aNorm.z){
            norm.z = 0;
            norm.y = 1 * sign(norm.y);
        }else{
            norm.y = 0;
            norm.z = 1 * sign(norm.z);
        }
    }
    vec3 lightDir = normalize(globalLightPosition);

    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    vec3 viewDir = normalize(u_camera_position - vFragPos);
    vec3 reflectDir = reflect(-lightDir, norm);

    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specular = specularStrength * spec * lightColor;

    vec3 result = (ambient + diffuse + specular) * vColor.xyz;
    fragColor = vec4(result, 1.0);

    // fragColor = vColor;
    // fragColor.w = 1;
    // fragColor = vec4(abs(vNormal), 1);
}
