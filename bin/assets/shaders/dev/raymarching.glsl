#version 330


void main(){

    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * viewRayDirection);
        if (dist < EPSILON) {
            // We're inside the scene surface!
            return depth;
        }
        // Move along the view ray
        depth += dist;

        if (depth >= end) {
            // Gone too far; give up
            return end;
        }
    }
    return end;
}