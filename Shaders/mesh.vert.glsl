#version 450 

in vec3 position;
in vec3 normal;
in vec2 uv;
in vec3 tangent;

uniform mat4 modelview_transform;
uniform mat4 normal_transform;
uniform mat4 projection_transform;

out VS_OUT
{
    vec3 position;
    vec2 uv;
    vec3 normal;
    vec3 tangent;
    vec4 color;
} v2f;

out gl_PerVertex
{
    vec4 gl_Position;
};

void main()
{
    v2f.position = vec3(modelview_transform * vec4(position, 1.0));
    v2f.normal   = vec3(normal_transform * vec4(normal, 0.0));
    v2f.tangent  = vec3(normal_transform * vec4(tangent, 0.0));
    v2f.uv       = uv;
    v2f.color    = vec4(1);
    gl_Position  = projection_transform * vec4(v2f.position, 1.0);
}