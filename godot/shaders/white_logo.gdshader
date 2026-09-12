shader_type canvas_item;
// Use the supplied white artwork as coverage, rather than compositing its black canvas.
void fragment() {
 vec4 source = texture(TEXTURE, UV);
 float coverage = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
 COLOR = vec4(vec3(1.0), COLOR.a * source.a * coverage);
}
