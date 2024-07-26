shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 shadow_col : source_color;

void fragment(){
	vec4 col = texture(screen_texture, SCREEN_UV);
	if(col.a > 0.0){
		COLOR = shadow_col;
	}else{
		COLOR = vec4(0.0);
	}
}