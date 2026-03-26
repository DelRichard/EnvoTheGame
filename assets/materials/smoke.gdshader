shader_type spatial;
render_mode unshaded;

group_uniforms FlameShape;
uniform float top_radius : hint_range(0.0, 1.5);
uniform float bottom_radius : hint_range(0.0, 1.5);
uniform float center_radius : hint_range(0.0, 5.0);
uniform float center_position : hint_range(0.0, 1.0);
uniform float cylinder_height : hint_range(0.0, 10.0) = 1.0;
uniform float bottom_curve = 0.4;
uniform float _vibrate_amplitude = 0.015;
uniform float _vibrate_frequency = 200.0;
group_uniforms;

group_uniforms FlameAppearance;
uniform float _speed = 2.0;
uniform float _scale = 2.0;
// --- NEW COLOR UNIFORMS ---
uniform vec4 base_color : source_color = vec4(1.0, 0.75, 0.3, 1.0);
uniform vec4 tip_color : source_color = vec4(1.0, 0.1, 0.0, 1.0);
uniform float _color_intensity : hint_range(0.0, 5.0) = 1.5;
group_uniforms;

varying float cylinderheight;

// ... (Vertex function, noise functions, and helpers remain unchanged) ...

void vertex() {
    float topradius = top_radius;
    float bottomradius =  bottom_radius;
    float centerradius = center_radius;
    float centerposition = center_position;
    cylinderheight = cylinder_height;

    vec3 v_pos = VERTEX;
    float original_height = v_pos.y;
    float relative_height = (original_height + 1.0) / 2.0;

    float scaledHeight =  relative_height * cylinderheight;
    v_pos.y = scaledHeight + sin(TIME * _vibrate_frequency) * _vibrate_amplitude;

    float radius;
    if (relative_height <= centerposition) {
        float t = relative_height / centerposition;
		t = pow(t, bottom_curve);
        t = smoothstep(0.0, 1.0, t);
        radius = mix(bottom_radius, centerradius, t);
    } else {
        float t = (relative_height - centerposition) / (1.0 - centerposition);
        t = smoothstep(0.0, 1.0, t);
        radius = mix(centerradius, topradius, t);
    }

    float current_radius = length(vec2(v_pos.x, v_pos.z));
    if (current_radius > 0.0) {
        float scale_factor = radius / current_radius;
        v_pos.x *= scale_factor;
        v_pos.z *= scale_factor;
    }

    VERTEX = v_pos;
}

// (Keeping your original noise functions for compatibility)
vec3 mod2893(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy;
  vec3 x3 = x0 - D.yyy;
  i = mod2893(i);
  vec4 p = permute( permute( permute(
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));
  float n_ = 0.142857142857;
  vec3  ns = n_ * D.wyz - D.xzx;
  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );
  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3) ) );
}

float getNoise(vec2 uv, float t){
    float TRAVEL_SPEED = _speed;
    float SCALE = _scale;
    float noise = snoise( vec3(uv.x*SCALE ,uv.y*SCALE * 4. + t*TRAVEL_SPEED , 0.));
    SCALE = 6.0;
    noise += snoise( vec3(uv.x*SCALE + t*TRAVEL_SPEED,uv.y*SCALE , 0))* 0.2 ;
    return (noise/2. + 0.5);
}

float getDepth(float n, float cutoff, float steps){
	float d = (n - cutoff) / (1. - cutoff);
    return floor(d*steps)/steps;
}

void fragment() {
    float steps = 4.;
    float cutoff = 0.15; 

    vec2 uv = UV;
    uv.x *= 5.0;
    float t = TIME * 3.0;
    
    float noise = getNoise(uv, t);
    cutoff = 1.1 - uv.y * 2.5;

    if (noise < cutoff){
        discard; // More efficient than setting ALPHA to 0
    } else {
        // Calculate the depth (0.0 to 1.0) of the flame at this pixel
        float d = pow(getDepth(noise, cutoff, steps), 0.7);
        
        // Blend between your two chosen colors based on depth
        vec3 final_color = mix(tip_color.rgb, base_color.rgb, d);
        
        ALBEDO = final_color * _color_intensity;
        ALPHA = d; // Use the depth to handle transparency/fading
     }
}