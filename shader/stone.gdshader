shader_type canvas_item;
render_mode unshaded;

const float TWOPI = 6.283185307;
const float SIXPI = 18.84955592;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec2 resolution = vec2(335.75, 152.5);
uniform vec4 rock_col : source_color = vec4(0.4, 0.6, 0.6, 1.0);
uniform float mtime;

vec2 dist(float index){
	float d1 = mod(index, TWOPI);
    float d2 = mod((index + 0.25) * 1.3, SIXPI);
    d1 = 0.07 + d1;
    d2 = 0.5 + d2;
    return vec2(
    	sin(d1) * 0.15 + cos(d2) * 0.05,
    	cos(d1) * 0.15 + cos(d2) * 0.05
    );
}

void fragment() {
	vec2 pxy = floor(SCREEN_UV * resolution) + dist(SCREEN_UV.y+mtime)*5.0;
	vec4 col = textureLod(screen_texture, pxy/resolution, 0.0);
	col.rgb = rock_col.rgb;
	COLOR = col;
}
