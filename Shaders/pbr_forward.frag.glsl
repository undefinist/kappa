#version 450

#define MAX_LIGHTS 8

#include "globals.glsl"

uniform mat4 inverse_view_transform;

// uniform samplerCube irradiance_probe;
// uniform samplerCube environment_probe;
// uniform sampler2D   brdfLUT;  

in VS_OUT
{
    vec3 position;
    vec2 uv;
    vec3 normal;
    vec3 tangent;
    vec4 color;
} v2f;

#include "light.glsl"
uniform int light_count;
uniform Light lights[MAX_LIGHTS];
// uniform sampler2D shadow_maps[MAX_LIGHTS];

#include "pbr_utils.glsl"

// forward shading only cares about color!
out vec4 out_color;

void main()
{
    // declare initial values here
    vec3  view_pos  = v2f.position;
    vec3  normal    = normalize(v2f.normal);
    vec3  tangent   = normalize(v2f.tangent);
    vec2  uv        = v2f.uv;
    
    vec3  albedo    = vec3(1, 1, 1);
    float metallic  = 0;
    float roughness = 0;
    float ambient_o = 0;
    vec3  emissive  = vec3(0);
    
    vec3 view_dir = -normalize(view_pos);

    // then compute color here 

    vec3 light_accum = vec3(0);
    normal = normalize(normal);
    
    vec3 reflected = vec3(inverse_view_transform * vec4(reflect(-view_dir, normal),0));
    vec4 world_pos = inverse_view_transform * vec4(view_pos,1);
    
    for (int i = 0; i < light_count; ++i)
    {
        vec3 result = pbr_metallic(lights[i], view_pos.xyz, normal, reflected, albedo, metallic, roughness, ambient_o); 
        
        // if (LightBlk.lights[i].type == 1)
        // {
        //     if(LightBlk.lights[i].cast_shadow!=0)
        //         result *= vec3(1.f - ShadowCalculation(LightBlk.lights[i],shadow_maps[i],(LightBlk.lights[i].v_dir) ,normal ,LightBlk.lights[i].vp * world_pos));
        //     //vvvp = LightBlk.lights[i].vp;
        // }
        // if (LightBlk.lights[i].type == 2)
        // {
        //     if(LightBlk.lights[i].cast_shadow!=0)
        //         result *= (vec3(1-ShadowCalculation(LightBlk.lights[i],shadow_maps[i],LightBlk.lights[i].v_dir,normal ,LightBlk.lights[i].vp * world_pos)));
        // }
        
        light_accum += result;
    }

    // vec3 F = mix(vec3(0.04), albedo, metallic);
    // vec3 kS = fresnelRoughness(max(dot(normal,view_dir), 0.0), F, roughness);
    // vec3 kD = 1.0 - kS;
    // kD *= 1.0 - metallic;
    
    // vec3 irradiance = texture(irradiance_probe, normal).rgb;
    // vec3 diffuse = irradiance * albedo;
    
    // const float MAX_REFLECTION_LOD = 4.0;
    
    // //vec3 prefilteredColor = textureLod(environment_probe, reflected, roughness * MAX_REFLECTION_LOD).rgb;
    // //vec2 envBRDF = texture(brdfLUT, vec2(max(dot(normal, view_dir), 0.0), roughness)).rg;
    // //vec3 specular = prefilteredColor * (kS * envBRDF.x + envBRDF.y);
    // //vec3 ambient = (kD * diffuse + specular) * vec3(0.01);
    vec3 ambient = vec3(0.03) * albedo;
    
    vec3 color = light_accum + ambient + emissive;
	color = pow(color, vec3(1.0/2.2)); 
    out_color = vec4(color,1);
    
}