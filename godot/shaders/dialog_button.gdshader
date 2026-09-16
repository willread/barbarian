shader_type canvas_item;
uniform float heat : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 stone = texture(TEXTURE, UV);
	// Light the existing bronze bevel, keeping its exact silhouette and texture.
	float bronze = smoothstep(0.025, 0.16, stone.r - stone.b);
	float light = heat * bronze;
	stone.rgb += vec3(0.48, 0.22, 0.035) * light;
	COLOR = stone;
}
