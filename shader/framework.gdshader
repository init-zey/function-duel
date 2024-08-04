shader_type canvas_item;

void fragment() {
	if(UV.x > 0.2 && UV.y < 0.8 || UV.x<0.8 && UV.y > 0.2){
		COLOR.a = 0.0;
	}
}
