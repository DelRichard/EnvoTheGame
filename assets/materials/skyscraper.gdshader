/*
Shader from Godot Shaders - the free shader library.

Basic Skyscraper Window Lights shader

Based and modified from godotshaders.com/shader/brick-tiles

Feel free to further improve and change this shader according to your needs
and consider sharing the modified result on godotshaders.com as well.

Tiling effect from https://thebookofshaders.com/09/
*/

shader_type spatial;

uniform float size = 5.0;
uniform float thickness : hint_range (0.0, 0.5) = 0.08;
uniform vec2 ratio = vec2(0.5, 1.0);

uniform vec4 base_color : source_color = vec4(0.55, 0.55, 0.55, 1.0);
uniform vec4 window_color: source_color = vec4(0., 0., 1., 1.0);
uniform float window_intensity = 1.0;

uniform float window_freq = 0.18;

uniform vec2 scale = vec2(1.0); // Don't edit this, it is used by the script to get the nodes scale.

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

vec2 window_tile(vec2 _st, float _zoom)
{
	_st *= _zoom;
	return fract(_st);
}

float box(vec2 _st, vec2 _size, vec2 _ratio)
{
	_size = (vec2(0.5, 0.5) * _size * _ratio);
	vec2 uv = smoothstep(_size, _size + vec2(1e-4), _st);
	uv *= smoothstep(_size, _size + vec2(1e-4), (vec2(1.0) - _st));
	return uv.x * uv.y;
}

void fragment()
{
	// Set the brick shape
	vec2 base_uv = UV * scale * ratio;

	// Create the brick tiling
	base_uv = window_tile(base_uv, size);

	// Create the "mortar" lines
	vec3 color = vec3(box(base_uv, vec2(thickness), ratio));

	// get randomly lit windows
	vec2 window_uv = UV * scale * ratio * size;
	vec2 ipos = floor(window_uv);  // get the integer coords
	vec3 brick_colors =  vec3(random( ipos )) ;
	float gray = (brick_colors.r + brick_colors.g + brick_colors.b)/3.0;
	brick_colors = (1.0 - vec3(step(window_freq, gray))) * window_color.rgb;

	// Apply the colors
//	color = mix(base_color.rgb, brick_colors, color.r);
	color = base_color.rgb + brick_colors;

	EMISSION = brick_colors * window_intensity;
	ALBEDO = vec3(color);
}