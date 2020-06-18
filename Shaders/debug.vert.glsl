#version 450

in vec3 position;

uniform mat4 modelview_transform;
uniform mat4 projection_transform;

layout(location = 0) out gl_PerVertex
{
    vec4 gl_Position;
};

void main()
{
    gl_Position = projection_transform * modelview_transform * vec4(position, 1.0);
}