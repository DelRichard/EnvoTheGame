shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// ----------- TEXTURE (NEAREST FILTERING) -----------
uniform sampler2D grass_texture : source_color, filter_nearest;

// ----------- WIND CONTROL -----------
uniform float wind_speed_x : hint_range(0.0, 5.0) = 1.25;
uniform float wind_speed_z : hint_range(0.0, 5.0) = 0.45;

uniform float wind_strength_x : hint_range(0.0, 1.0) = 0.2;
uniform float wind_strength_z : hint_range(0.0, 1.0) = 0.15;

uniform float wind_scale : hint_range(0.0, 10.0) = 1.0;
uniform float height_influence : hint_range(0.0, 2.0) = 1.0;

// ----------- VERTEX -----------
void vertex() {
    NORMAL = vec3(0.0, 1.0, 0.0);

    float height_mask = pow(1.0 - UV.y, height_influence);

    float wave_x = sin((NODE_POSITION_WORLD.x * wind_scale) + TIME * wind_speed_x + UV.y);
    float wave_z = cos((NODE_POSITION_WORLD.z * wind_scale) + TIME * wind_speed_z + UV.y);

    VERTEX.x += wave_x * height_mask * wind_strength_x;
    VERTEX.z += wave_z * height_mask * wind_strength_z;
}

// ----------- FRAGMENT -----------
void fragment() {
    vec4 tex = texture(grass_texture, UV);

    ALBEDO = tex.rgb;
    ALPHA = tex.a;

    // Optional: crisp cutout
    // ALPHA_SCISSOR = tex.a;
}