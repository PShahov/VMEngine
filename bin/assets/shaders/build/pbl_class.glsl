struct Surface
{
    float sd;
    vec3 col;
    // int materialId = 0;
};

struct Voxel{
    ivec3 pos;
    int dist;
    float col;
    float dt;
    bool crossed;
};