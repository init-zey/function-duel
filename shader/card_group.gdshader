shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec4 shadow_col : source_color;
uniform float mtime;

const float TWOPI = 6.282;
const float SIXPI = 18.846;

vec2 dist(float index, float dist_spd){
	float d1 = mod(index, TWOPI);
    float d2 = mod((index + 0.25) * 1.3, SIXPI);
    d1 = dist_spd * 0.07 + d1;
    d2 = dist_spd * 0.5 + d2;
    return vec2(
    	sin(d1) * 0.15 + cos(d2) * 0.05,
    	cos(d1) * 0.15 + cos(d2) * 0.05
    );
}

void fragment(){
	vec4 col = texture(screen_texture, SCREEN_UV + dist(SCREEN_UV.y + mtime, -2.0)*0.05);
	if(col.a > 0.0){
		COLOR = shadow_col;
	}else{
		COLOR = vec4(0.0);
	}
}