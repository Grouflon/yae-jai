#version 300 es
precision highp float;

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 outColor;

uniform sampler2D uTexture;

void main()
{
    outColor = fragColor * texture(uTexture, fragTexCoord);
}