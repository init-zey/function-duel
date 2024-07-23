shader_type canvas_item;

bool in_line(vec2 pxy, vec2 start, vec2 dir, float width){
	float d = dot(pxy - start, dir)/length(dir);
	return abs(dir.y* pxy.x-dir.x* pxy.y+((start.x+dir.x)*start.y-(start.y+dir.y)*start.x))/sqrt(pow(dir.y, 2)+pow(dir.x, 2))<=width&&d>-width&&d<length(dir)+width;
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

void fragment(){
	if(in_cube_xy(UV-vec2(.5), 0.2, 0.6, 0.5, 0.01)){
		COLOR = vec4(0., 0., 0., 1.);
	}
}