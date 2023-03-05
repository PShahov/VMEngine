struct Surface
{
    float sd;
    vec3 col;
    // int materialId = 0;
};

struct Voxel{
    vec3 pos;
    float dist;
    float col;
    float dt;
    bool crossed;
    float edge;
};