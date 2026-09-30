// Grass tufts drawn with MultiMesh. UV.y = 0 at the root, 1 at the tip.
// Per-instance COLOR varies the tint so fields do not look tiled.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;

uniform vec3 root_color : source_color = vec3(0.10, 0.17, 0.05);
uniform vec3 tip_color : source_color = vec3(0.42, 0.55, 0.20);
uniform float wind_strength = 0.12;
uniform float wind_speed = 1.6;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = UV.y * UV.y;
	float gust = sin(TIME * wind_speed + wp.x * 0.35 + wp.z * 0.21) * 0.7
		+ sin(TIME * wind_speed * 2.3 + wp.x * 1.7) * 0.3;
	VERTEX.x += gust * wind_strength * h;
	VERTEX.z += gust * wind_strength * 0.5 * h;
}

void fragment() {
	vec3 c = mix(root_color, tip_color, UV.y) * COLOR.rgb;
	ALBEDO = c;
	ROUGHNESS = 0.85;
	BACKLIGHT = c * 0.6;
	AO = mix(0.35, 1.0, UV.y);
	AO_LIGHT_AFFECT = 0.6;
}
