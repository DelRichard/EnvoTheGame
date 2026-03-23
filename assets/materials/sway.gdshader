shader_type spatial;

// ----------- RENDER MODE SETTINGS -----------
render_mode blend_mix, depth_draw_opaque, cull_disabled;
// cull_disabled = renders both sides (fix for planes)

// ----------- TEXTURE -----------
uniform sampler2D albedo_texture : source_color;

// ----------- SWAY PARAMETERS -----------
uniform float sway_amount : hint_range(0.0, 1.0) = 0.1;
uniform float sway_scale : hint_range(0.0, 10.0) = 1.0;
uniform float sway_duration : hint_range(0.01, 10.0) = 2.0;
uniform vec3 sway_direction = vec3(1.0, 0.0, 0.0);

// ----------- MATERIAL PARAMETERS -----------
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

// ----------- VERTEX FUNCTION -----------
void vertex() {
    float sway_time = (TIME / sway_duration) * 6.28318;
    float sway = sin(VERTEX.y * sway_scale + sway_time) * sway_amount;
    VERTEX.xyz += sway * sway_direction;
}

// ----------- FRAGMENT FUNCTION -----------
void fragment() {
    // Sample texture
    vec4 tex = texture(albedo_texture, UV);

    // Combine texture with color (like StandardMaterial tint)
    vec3 final_color = tex.rgb * albedo_color.rgb;

    ALBEDO = final_color;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = specular;

    // Combine texture alpha with opacity control
    ALPHA = tex.a * albedo_color.a * opacity;
}