class_name MaterialLibrary
extends RefCounted
## PBR surface materials built from assets/textures/<key>/{albedo,normal,rough}.jpg
## (see assets/asset_manifest.json). World-space triplanar mapping, so generated
## greybox geometry tiles textures correctly without UVs. Missing textures fall back
## to a flat colour so the game still runs without the asset download.

const TEXTURE_ROOT := "res://assets/textures"
const MANIFEST := "res://assets/asset_manifest.json"

var _scales: Dictionary = {}
var _cache: Dictionary = {}


func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) if FileAccess.file_exists(MANIFEST) else null
	if parsed is Dictionary:
		for key in parsed.get("textures", {}):
			_scales[key] = float(parsed["textures"][key].get("scale", 0.5))


func has_textures(key: String) -> bool:
	return ResourceLoader.exists(TEXTURE_ROOT.path_join(key).path_join("albedo.jpg"))


## tint multiplies the texture (e.g. painted plaster in different colours).
func surface(key: String, tint: Color = Color.WHITE, fallback: Color = Color(0.5, 0.5, 0.5), scale_mult: float = 1.0) -> StandardMaterial3D:
	var cache_key := "%s|%s|%s" % [key, tint.to_html(), scale_mult]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var m := StandardMaterial3D.new()
	if has_textures(key):
		var dir := TEXTURE_ROOT.path_join(key)
		m.albedo_texture = load(dir.path_join("albedo.jpg"))
		m.albedo_color = tint
		m.normal_enabled = true
		m.normal_texture = load(dir.path_join("normal.jpg"))
		m.normal_scale = 1.0
		m.roughness_texture = load(dir.path_join("rough.jpg"))
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
		m.roughness = 1.0
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_triplanar_sharpness = 4.0
		var s := float(_scales.get(key, 0.5)) * scale_mult
		m.uv1_scale = Vector3(s, s, s)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	else:
		m.albedo_color = fallback * tint
		m.roughness = 0.9
	_cache[cache_key] = m
	return m
