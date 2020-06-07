
struct Light
{
    int   type; // 0 for point, 1 for dir, 2 for spot
	vec3  color;
	
	vec3  v_pos;
	vec3  v_dir;
	
	float cos_inner;
	float cos_outer;
	
	float falloff;
	
	float shadow_bias;
	
	float intensity;
	
	int cast_shadow;
	
	mat4 vp;
};

struct DLight
{
	float far_plane;
	mat4 vp;
};