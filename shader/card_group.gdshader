shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float hshadow_size = 0.0;
uniform float vshadow_size = 10.0;

uniform vec4 shadow_col : source_color;

void fragment(){
	vec4 ccol = texture(screen_texture, SCREEN_UV);
	vec4 ucol = texture(screen_texture, SCREEN_UV - vec2(SCREEN_PIXEL_SIZE.x*hshadow_size*2.0*(SCREEN_UV.x-0.5), SCREEN_PIXEL_SIZE.y*vshadow_size));
	if(ucol.a > 0.5&&ccol.a < 0.5){
		ccol = shadow_col;
	}
	COLOR = ccol;
}