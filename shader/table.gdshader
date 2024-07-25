shader_type canvas_item;
uniform float mtime = 0;
uniform float slash_speed = -20;
uniform vec4 slash_color : source_color = vec4(0.2, 0.2, 0.2, 1.);
uniform vec4 bg_color : source_color = vec4(.4, .4, .4, 1.);
uniform vec2 resolution = vec2(288, 162);
uniform int slash_weight_pixel = 50;
uniform float left_blued_rate = .0;
uniform float right_blued_rate = .0;
uniform vec4 confirm_modulate : source_color = vec4(0.2, 0.3, 1., 1.);
uniform bool vertical = false;

void fragment(){
	ivec2 pxy = ivec2(floor(UV * resolution));
	int slash_depth = (pxy.x + pxy.y + int(mtime * slash_speed)) % (slash_weight_pixel * 2);
	if(slash_depth < slash_weight_pixel){
		COLOR = slash_color;
	}else{
		COLOR = bg_color;
	}
	float position_index = UV.x;
	if(vertical){
		position_index = UV.y;
	}
	float modv = smoothstep(-0.05, 0.05, (position_index-0.5));
	float fmodv = modv * right_blued_rate + (1.0-modv) * left_blued_rate;
	COLOR *= fmodv * confirm_modulate + (1.0-fmodv);
}