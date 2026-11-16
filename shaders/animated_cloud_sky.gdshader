shader_type sky;
render_mode use_quarter_res_pass;

uniform vec3 sky_top_color : source_color = vec3(0.22, 0.43, 0.68);
uniform vec3 horizon_color : source_color = vec3(0.68, 0.78, 0.86);
uniform vec3 cloud_color : source_color = vec3(0.96, 0.97, 0.98);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.56;
uniform float cloud_speed : hint_range(0.0, 0.05) = 0.008;

float hash_value(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash_value(cell);
	float b = hash_value(cell + vec2(1.0, 0.0));
	float c = hash_value(cell + vec2(0.0, 1.0));
	float d = hash_value(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

void sky() {
	vec3 direction = normalize(EYEDIR);
	float vertical = clamp(direction.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(horizon_color, sky_top_color, smoothstep(0.38, 0.98, vertical));
	if (direction.y > -0.02) {
		vec2 uv = direction.xz / max(direction.y + 0.22, 0.18);
		uv = uv * 2.4 + vec2(TIME * cloud_speed, TIME * cloud_speed * 0.23);
		float noise_value = value_noise(uv) * 0.58 + value_noise(uv * 2.1 + 13.7) * 0.29 + value_noise(uv * 4.2 + 5.2) * 0.13;
		float clouds = smoothstep(cloud_coverage, min(cloud_coverage + 0.16, 0.98), noise_value);
		float horizon_fade = smoothstep(-0.02, 0.28, direction.y);
		base = mix(base, cloud_color, clouds * horizon_fade * 0.82);
	}
	COLOR = base;
}
