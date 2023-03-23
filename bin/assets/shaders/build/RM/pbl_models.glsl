vec4 _model(vec3 p, int modelId, vec4 rotation = vec4(0), vec3 scale = vec3(1), float materialId = -1){
    vec4 res = vec4(0);

    switch(modelId){
        case 0:{
            vec3 p1 = p + vec3(-2,1.5,0);
            float sphereR = 3 + fDisplace(p1, 1, 0.5, 29.7262 + u_time);
            // float boxDist = fBoxCheap(p1, vec3(sphereR));
            float boxDist = fSphere(p1, sphereR);
            // boxDist += bumpMapping(u_tex_01_bump, p1, p1 + sphereBumpFactor, boxDist, sphereBumpFactor, sphereScale);
            float boxId = 8.0;
            vec4 box = vec4(boxDist, boxId,0,0);
            
            p1 = p + vec3(1.5 + (sin(u_time) * 0.5),1 + sin(u_time),0);
            float boxDist2 = fSphere(p1, 2.5 + fDisplace(p * 0.5, 0.5, 1, u_time));
            float boxId2 = 9.0;
            vec4 box2 = vec4(boxDist2, boxId2,0,0);

            res = fOpUnionRoundId(box2, box, 0.5);
            break;
        }
        case 1:{
            vec4 q = rotation;
            vec3 temp = cross(q.xyz, p) + q.w * p;
            vec3 rotated = p + 2.0*cross(q.xyz, temp);
            vec3 b = vec3(2) * scale;
            float boxDist = fBoxCheap(rotated, b);
            float boxId = int(materialId) == -1 ? 7 : materialId;
            vec4 box = vec4(boxDist, boxId, 0, 0);
            res = box;
            break;
        }
        case 2:{
            vec3 p1 = p;

            // xRot(p1, -u_time + (PI / 9.5));
            // zRot(p1, PI / 2);

            vec3 b = vec3(1, 0.5, 1);
            float boxDist = fBoxCheap(p1, b);
            float boxId = 8.0;
            vec4 box = vec4(boxDist, boxId, 0, 0);

            // yRot(p1, PI / 4);
            boxDist = fBoxCheap(p1, b);
            vec4 box2 = vec4(boxDist, boxId, 0, 0);

            res = fOpUnionId(box, box2);

            break;
        }
        case 3:{
            vec4 q = vec4( 0.854, 0.354, 0.354, 0.146);
            vec3 temp = cross(q.xyz, p) + q.w * p;
            vec3 rotated = p + 2.0*cross(q.xyz, temp);
            // vec3 rotated = p;
            // xRot(rotated, 45);
            // yRot(rotated, 45);
            // vec3 p1 = p;
            // pMod1(p1.z, 7);
            vec3 b = vec3(2);
            float boxDist = fBoxCheap(rotated, b);
            float boxId = 7.0;
            vec4 box = vec4(boxDist, boxId, 0, 0);
            res = box;
            break;
        }
        case 4:{
            vec3 p1 = p;
            pMod1(p1.z, 7);
            vec3 b = vec3(2);
            float boxDist = fSphere(p1, b.x);
            float boxId = 8.0;
            vec4 box = vec4(boxDist, boxId, 0, 0);
            res = box;
            break;
        }
        case 5:{
            vec3 p1 = p;
            float b = 0.00001;
            float boxDist = fSphere(p1, b);
            float boxId = 9.0;
            vec4 box = vec4(boxDist, boxId, 0, 0);
            res = box;
            break;
        }
    }

    return res;
}