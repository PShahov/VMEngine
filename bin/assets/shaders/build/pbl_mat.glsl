

vec3 triPlanar(sampler2D tex, vec3 p, vec3 normal) {
    normal = abs(normal);
    normal = pow(normal, vec3(5.0));
    normal /= normal.x + normal.y + normal.z;
    return (texture(tex, p.xy * 0.5 + 0.5) * normal.z +
            texture(tex, p.xz * 0.5 + 0.5) * normal.y +
            texture(tex, p.yz * 0.5 + 0.5) * normal.x).rgb;
}
float bumpMapping(sampler2D tex, vec3 p, vec3 n, float dist, float factor, float scale){
	float bump = 0.0;
	if(dist < 0.1){
		vec3 normal = normalize(n);
		bump += factor * triPlanar(tex, (p * scale), normal).r;
	}

	return bump;
}

vec4 getMaterial(vec3 p, float id, vec3 normal){
    vec4 m;

    return vec4(vec3(rand(vec2(id))),1);

    switch(int(id)){
        
        case 1:{//r
            m = vec4(1.0, 0.0, 0.0, 1);
            break;
		}
        case 2:{//g
            m = vec4(0.0, 1.0, 0.0, 1);
            break;
		}
        case 3:{//b
            m = vec4(0.0, 0.0, 1.0, 1);
            break;
		}
        case 4:{//cells
            m = vec4(vec3(0.2 + 0.4 * mod(floor(p.x) + floor(p.z), 2.0)), 1);
            break;
		}
        case 5:{
            m = vec4(0.7, 0.8, 0.9, 1);
            break;
		}
        case 6:{
            m = vec4(1, 0.6, 0.0, 1);
            break;
		}
        case 7:{//texture
            // m = vec3(0);
			normal = abs(normal);
			normal = pow(normal, vec3(5.0));
			normal /= (normal.x + normal.y + normal.z);
            m = vec4(triPlanar(u_tex_01, p * (1.0 / 3.0), normal), 1);
            break;
		}
		case 8:{//noise
			m = vec4(0, 1, 0, 1);
			break;
			m *= 1 + fDisplace(p / 4, 1, 1, u_time) / 5;
			m *= 1 + pow((noise(vec2(0, u_time / 2) + (p.xz / 5))), 3);
			break;
		}
        case 9:{
            m = vec4(vec3(noise3((p * 5))), 1);
            m = vec4(1);
            
            break;
        }
        case 10:{//sand
            // float bw1 = noise(p.xz * 200);
            // float bw2 = noise((p.xz + vec2(1000, 1000)) * 100);
            // vec4 m1 = vec4(lerp3(vec3(0.99, 0.87, 0.46), vec3(1.00, 0.93, 0.55), bw1), 1);
            // vec4 m2 = vec4(lerp3(vec3(1.00, 0.83, 0.37), vec3(0.77, 0.63, 0.29), bw2), 1);
            // m = (m1 + m2) / 2;
            float bw1 = pNoise(p.xz / 2, 0);
            float bw2 = pNoise(p.xz + vec2(100,100) / 2, 0);
            bw1 = (bw1 + bw2) / 2;
            float bw3 = pNoise(p.xz * 100, 0);

            float bwres = (bw1 + bw3) / 2;
            

            vec4 m1 = vec4(lerp3(vec3(1.00, 0.83, 0.37), vec3(0.77, 0.63, 0.29) / 2, bw1), 1);
            vec4 m2 = vec4(lerp3(vec3(0.99, 0.87, 0.46), vec3(1.00, 0.93, 0.55), bw3), 1);
            m = (m1 + m2) / 2;

            // m = vec4(vec3(bwres), 1);
            // m = vec4((vec3(bw1) + vec3(bw2)) / 2, 1);
            break;
        }
    }

    return m;
}

vec4 getSpecColor(float id){
	vec4 spec = vec4(0.6, 0.5, 0.4, 1);
	// vec4 spec = vec4(0.1,0,0, 0.1);
	switch(int(id)){
		case 5: spec = vec4(vec3(0.25), 1); break;
        case 7: spec = vec4(0.6, 0.5, 0.4, 1) / 50; break;
        case 10: spec = vec4(0.6, 0.5, 0.4, 1) / 50; break;
	}

	return spec;
}