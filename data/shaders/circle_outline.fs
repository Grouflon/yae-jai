#version 300 es
precision highp float;

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform float thickness_ratio;

// Output fragment color
out vec4 finalColor;

void main()
{
    vec2 circle_coords = (fragTexCoord - vec2(0.5,0.5)) * 2.0;
    float circle_sdf = length(circle_coords);
    vec4 tex_color = texture(texture0, fragTexCoord);
    float f = fwidth(fragTexCoord.x) * 2.0;
    float r = thickness_ratio * 0.5;
    float a1 = 1.0-smoothstep(1.0-f, 1.0, circle_sdf);
    float a2 = smoothstep(1.0-r-f, 1.0-r, circle_sdf);
    finalColor = tex_color * fragColor * vec4(1,1,1,a1*a2);
}
