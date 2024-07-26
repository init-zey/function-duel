shader_type canvas_item;
uniform vec2 resolution = vec2(32, 32);
uniform vec2 card_size = vec2(16, 32);
uniform float round_rate = 0.1;
uniform float angle = 0;
uniform float revolve = 0;

uniform float dissolve_value : hint_range(0,1) = 1;
uniform float burn_size: hint_range(0.0, 1.0, 0.01) = 0.5;

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
	if(in_card(pxy, round_radius, card_size)){
		COLOR = vec4(1.0);
	}
	float noise = perlin(pxy);
	float burn_size_step = burn_size * step(0.001, dissolve_value) * step(dissolve_value, 0.999);
	float threshold = smoothstep(noise-burn_size_step, noise, dissolve_value);
	float border = smoothstep(noise, noise + burn_size_step, dissolve_value);
	COLOR.a *= threshold;
}