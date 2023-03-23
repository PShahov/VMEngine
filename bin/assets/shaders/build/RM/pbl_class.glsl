struct Surface
{
    float sd;
    vec3 col;
    // int materialId = 0;
};

// sparse voxel
struct Voxel{
    vec3 pos;
    float dist;
    float col;
    float dt;
    bool crossed;
    float edge;
};

//dense voxel
struct DenseVoxel{
    vec3 pos;
    float dist;
    float col;
    float dt;
    bool crossed;
};