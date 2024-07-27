shader_type canvas_item;

uniform sampler2D face_pattern_texture : hint_default_transparent;

uniform vec2 resolution = vec2(32, 32);
uniform vec2 card_size = vec2(16, 32);
uniform float round_rate = 0.2;
uniform float angle = 0;
uniform float revolve = 0;
uniform float back_cube_rotation_speed = 1;
uniform float back_cube_pitch = 0.6;
uniform float face_sep_line_w_rate = 0.8;
uniform float face_sep_line_y_rate = 0.8;
uniform float face_sep_line_width = 0.5;
uniform float face_pattern_w_rate = 0.8;

uniform float confirm_rate = .0;
uniform float maxhighlight_rate = .0;

uniform vec4 face_bg_col : source_color = vec4(1.0);
uniform vec4 back_bg_col : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform vec4 back_cube_col : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 gray_col : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 dark_gray_col : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 confirm_col : source_color = vec4(0.2, 0.3, 1., 1.);
uniform vec4 maxhighlight_col : source_color = vec4(1.0, 0.0, 0.0, 1.0);

uniform float dissolve_value : hint_range(0,1) = 1.0;//溶解程度
uniform float burn_size: hint_range(0.0, 1.0, 0.01);//火焰大小
uniform vec4 ash_color: source_color = vec4(0,0,0,1.0);//灰烬颜色
uniform vec4 burn_color: source_color = vec4(0.882, 0.777, 0.169 , 1.0);//燃烧颜色
uniform vec4 proburn_color: source_color = vec4(0.804, 0.2, 0.093 , 1.0);//超级燃烧颜色


bool in_rect(vec2 pxy, vec2 pos, vec2 size){
	return pxy.x > pos.x && pxy.x < pos.x+size.x && pxy.y > pos.y && pxy.y < pos.y+size.y;
}

bool in_circle(vec2 pxy, vec2 o, float r){
	return length(pxy - o) < r;
}

bool in_card(vec2 pxy, float round_radius, vec2 csize){
	return in_rect(pxy, -csize*0.5+vec2(round_radius,0), csize-vec2(round_radius*2.0, 0))||
			in_rect(pxy, -csize*0.5+vec2(0,round_radius), csize-vec2(0, round_radius*2.0))||
			in_circle(pxy, vec2(csize.x, csize.y)*0.5-vec2(round_radius, round_radius), round_radius)||
			in_circle(pxy, vec2(-csize.x, -csize.y)*0.5-vec2(-round_radius, -round_radius), round_radius)||
			in_circle(pxy, vec2(csize.x, -csize.y)*0.5-vec2(round_radius, -round_radius), round_radius)||
			in_circle(pxy, vec2(-csize.x, csize.y)*0.5-vec2(-round_radius, round_radius), round_radius);
}

bool in_line(vec2 pxy, vec2 start, vec2 dir, float width){
	float d = dot(pxy - start, dir)/length(dir);
	return abs(dir.y* pxy.x-dir.x* pxy.y+((start.x+dir.x)*start.y-(start.y+dir.y)*start.x))/sqrt(pow(dir.y, 2)+pow(dir.x, 2))<=width*0.5&&d>-width*0.5&&d<length(dir)+width*0.5;
}

vec3 rotate(vec3 pos3, float yaw, float pitch){
	float x = pos3.x;
	float y = pos3.y;
	float z = pos3.z;
	return vec3(
			cos(yaw)*x+sin(pitch)*sin(yaw)*y+sin(yaw)*cos(pitch)*z,
			cos(pitch)*y-sin(pitch)*z,
			-sin(yaw)*x+sin(pitch)*cos(yaw)*y+cos(pitch)*cos(yaw)*z
		);
}

bool in_cube_xy(vec2 pxy, float l, float p, float y, float w){
	vec2 r = rotate(vec3(l, 0.0, 0.0), y, p).xy;
	vec2 u = rotate(vec3(0.0, l, 0.0), y, p).xy;
	vec2 f = rotate(vec3(0.0, 0.0, l), y, p).xy;
	vec2 o = (r+u+f)*-0.5;
	return in_line(pxy, o, r, w)||in_line(pxy, o,f, w)||in_line(pxy, o+r, f, w)||in_line(pxy, o+f, r, w)||in_line(pxy, o+u, r, w)||in_line(pxy, o+u, f, w)||in_line(pxy, o+u+r, f, w)||in_line(pxy, o+u+f, r, w)||in_line(pxy, o, u, w)||in_line(pxy, o+r, u, w)||in_line(pxy, o+f, u, w)||in_line(pxy, o+r+f, u, w);
}

float edge_test(vec2 pxy, float rate){
	return (pow(max(abs(pxy.x) / (card_size.x*0.5), abs(pxy.y) / (card_size.y*0.5)), 6)+0.1) * rate;
}

float rand(vec2 input){
	return fract(sin(dot(input,vec2(23.53,44.0)))*42350.45);
}

float perlin(vec2 input){
	vec2 i = floor(input);
	vec2 j = fract(input);
	vec2 coord = smoothstep(0.,1.,j);
	
	float a = rand(i);
	float b = rand(i+vec2(1.0,0.0));
	float c = rand(i+vec2(0.0,1.0));
	float d = rand(i+vec2(1.0,1.0));

	return mix(mix(a,b,coord.x),mix(c,d,coord.x),coord.y);
}

void fragment(){
	vec2 ur_pxy = floor((UV-vec2(0.5)) * resolution)+vec2(0.5, 0.5);
	vec2 pxy = vec2(cos(angle)*ur_pxy.x-sin(angle)*ur_pxy.y, sin(angle)*ur_pxy.x+cos(angle)*ur_pxy.y);
	pxy.x /= cos(revolve);
	float round_radius = card_size.x * round_rate;
	if(cos(revolve) > 0.0){
		if(in_card(pxy, round_radius, card_size)&&COLOR.a==0.){
			COLOR = face_bg_col;
			if(
				abs(pxy.x) < card_size.x * face_sep_line_w_rate * 0.5 &&
				abs(pxy.y - card_size.y * (face_sep_line_y_rate - 0.5)) < face_sep_line_width
			){
				COLOR = dark_gray_col;
			}
			vec2 pattern_center = vec2(0, card_size.y * (face_sep_line_y_rate * 0.5 - 0.5));
			vec2 pattern_pxy = pxy - pattern_center;
			float pattern_length = card_size.x * 0.5 * face_pattern_w_rate;
			if(abs(pattern_pxy.x) < pattern_length && abs(pattern_pxy.y) < pattern_length){
				vec2 pattern_uv = (pattern_pxy + pattern_length) / (pattern_length*2.0);
				COLOR = texture(face_pattern_texture, pattern_uv);
				COLOR.rgb = COLOR.rgb * COLOR.a + face_bg_col.rgb * (1.0 - COLOR.a);
				COLOR.a = 1.0;
					
			}
			float local_confirm_rate = edge_test(pxy, confirm_rate);
			COLOR = COLOR * (1.0-local_confirm_rate) + confirm_col * local_confirm_rate;
			float local_maxhighlight_rate = edge_test(pxy, maxhighlight_rate);
			COLOR = COLOR * (1.0-local_maxhighlight_rate) + maxhighlight_col * local_maxhighlight_rate;
		}
	}else{
		pxy.x *= -1.0;
		if(in_card(pxy, round_radius, card_size)){
			COLOR = back_bg_col;
			if(in_cube_xy(pxy, 10., 0.5 * TIME * back_cube_pitch, TIME * back_cube_rotation_speed, 1.0)){
				COLOR = back_cube_col;
			}
		}
	}
	float noise = perlin(pxy);
	float burn_size_step = burn_size * step(0.001, dissolve_value) * step(dissolve_value, 0.999);
	float threshold = smoothstep(noise-burn_size_step, noise, dissolve_value);
	float border = smoothstep(noise, noise + burn_size_step, dissolve_value);
	
	COLOR.a *= threshold;
	vec3 new_burn_color1 = mix(proburn_color.rgb , burn_color.rgb , 1.0-pow(1.0-border , 5));
	vec3 new_burn_color2 = mix(ash_color.rgb , new_burn_color1 , 1.0-pow(1.0-border , 1000));
	COLOR.rgb = mix(new_burn_color2, COLOR.rgb, border);
}