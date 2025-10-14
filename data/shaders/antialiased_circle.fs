#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

void main()
{
    vec2 circle_coords = (fragTexCoord - vec2(0.5,0.5)) * 2.0;
    float circle_sdf = length(circle_coords);
    vec4 tex_color = texture(texture0, fragTexCoord);
    float f = fwidth(fragTexCoord.x);
    float a = 1-smoothstep(1-(2*f), 1, circle_sdf);
    finalColor = tex_color * fragColor * vec4(1,1,1,a);
    // finalColor = vec4(vec3(f)*100,1);
}
