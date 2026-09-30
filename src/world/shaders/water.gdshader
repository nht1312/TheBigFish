// Murky still water (drain / canal). Opaque on purpose: this water is not clear,
// and opaque surfaces receive screen-space reflections of the sky and banks.
shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

uniform vec3 water_color : source_color = vec3(0.10, 0.13, 0.08);
uniform vec3 murk_color : source_color = vec3(0.20, 0.21, 0.12);
uniform sampler2D normal_a : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_b : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float wave_scale = 0.08;
uniform vec2 flow = vec2(0.0, 0.025);
uniform float wave_height = 0.015;
uniform float normal_strength = 0.55;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world_pos.x * 1.3 + TIME * 1.1) * wave_height
		+ cos(world_pos.z * 1.7 + TIME * 0.9) * wave_height;
}

void fragment() {
	vec2 uv = world_pos.xz * wave_scale;
	vec3 n1 = texture(normal_a, uv + flow * TIME).rgb;
	vec3 n2 = texture(normal_b, uv * 2.3 - flow.yx * TIME * 1.4).rgb;
	NORMAL_MAP = normalize(mix(n1, n2, 0.5));
	NORMAL_MAP_DEPTH = normal_strength;
	// Looking straight down you see murk; at grazing angles the surface mirrors the sky.
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	ALBEDO = mix(water_color, murk_color, facing * 0.6);
	ROUGHNESS = 0.04;
	METALLIC = 0.0;
	SPECULAR = 0.55;
}
