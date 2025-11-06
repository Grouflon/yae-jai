#version 300 es
precision highp float;

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec2 inTexCoord;
layout (location = 2) in vec4 inColor;

out vec2 fragTexCoord;
out vec4 fragColor;

uniform mat4 uMvp;

void main()
{
    gl_Position = uMvp * vec4(inPosition.x, inPosition.y, inPosition.z, 1.0);
    fragTexCoord = inTexCoord;
    fragColor = inColor;
}
