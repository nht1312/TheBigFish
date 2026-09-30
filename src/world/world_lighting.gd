class_name WorldLighting
extends Node3D
## Sky, sun, post-processing and weather visuals (docs/18 §33–35).
## Time of day drives the sun; weather swaps the sky, fog and rain.

const SKY_CLEAR := "res://assets/environments/sky/sky_clear.hdr"
const SKY_OVERCAST := "res://assets/environments/sky/sky_overcast.hdr"
const WEATHER_LIGHT := {"SUNNY": 1.0, "CLOUDY": 0.55, "LIGHT_RAIN": 0.4, "HEAVY_RAIN": 0.28, "STORM": 0.2}
const WEATHER_FOG := {"SUNNY": 0.0025, "CLOUDY": 0.004, "LIGHT_RAIN": 0.008, "HEAVY_RAIN": 0.015, "STORM": 0.022}

var settings: Dictionary
var environment: Environment
var sun: DirectionalLight3D
var rain: CPUParticles3D
var _sky_mat: Material
var _clear_tex: Texture2D
var _overcast_tex: Texture2D
var _weather: String = "SUNNY"


func setup(p_settings: Dictionary) -> void:
	settings = p_settings
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	if ResourceLoader.exists(SKY_CLEAR):
		_clear_tex = load(SKY_CLEAR)
		_overcast_tex = load(SKY_OVERCAST) if ResourceLoader.exists(SKY_OVERCAST) else _clear_tex
		var pano := PanoramaSkyMaterial.new()
		pano.panorama = _clear_tex
		_sky_mat = pano
	else:
		var procedural := ProceduralSkyMaterial.new()
		procedural.sky_top_color = Color(0.38, 0.55, 0.78)
		_sky_mat = procedural
	sky.sky_material = _sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.0
	environment.ssao_enabled = bool(settings.get("ssao", true))
	environment.ssao_radius = 1.2
	environment.ssao_intensity = 1.6
	environment.ssil_enabled = bool(settings.get("ssil", false))
	environment.ssr_enabled = bool(settings.get("ssr", true))
	environment.ssr_max_steps = 48
	environment.sdfgi_enabled = bool(settings.get("sdfgi", false))
	environment.glow_enabled = bool(settings.get("glow", true))
	environment.glow_intensity = 0.35
	environment.glow_bloom = 0.05
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.72, 0.76, 0.80)
	environment.fog_aerial_perspective = 0.6
	environment.fog_sky_affect = 0.25
	environment.volumetric_fog_enabled = bool(settings.get("volumetric_fog", true))
	environment.volumetric_fog_density = 0.006
	environment.volumetric_fog_albedo = Color(0.85, 0.87, 0.9)
	environment.volumetric_fog_length = 48.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	environment.adjustment_contrast = 1.05
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 90.0
	sun.light_angular_distance = 0.6  # soft penumbra
	sun.shadow_blur = 1.2
	sun.light_volumetric_fog_energy = 1.2
	add_child(sun)
	RenderingServer.directional_shadow_atlas_set_size(int(settings.get("shadow_size", 4096)), true)

	rain = CPUParticles3D.new()
	rain.emitting = false
	rain.amount = 900
	rain.lifetime = 0.9
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(14, 0.5, 14)
	rain.direction = Vector3.DOWN
	rain.spread = 3.0
	rain.gravity = Vector3(0, -30, 0)
	rain.initial_velocity_min = 8.0
	rain.initial_velocity_max = 10.0
	var drop := BoxMesh.new()
	drop.size = Vector3(0.008, 0.4, 0.008)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.8, 0.85, 0.95, 0.35)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = drop_mat
	rain.mesh = drop
	rain.top_level = true
	add_child(rain)


## Apply anti-aliasing to the viewport the world renders into.
func apply_viewport(viewport: Viewport) -> void:
	var msaa := int(settings.get("msaa", 2))
	viewport.msaa_3d = {0: Viewport.MSAA_DISABLED, 2: Viewport.MSAA_2X, 4: Viewport.MSAA_4X, 8: Viewport.MSAA_8X}.get(msaa, Viewport.MSAA_2X)
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if settings.get("fxaa", false) else Viewport.SCREEN_SPACE_AA_DISABLED


func set_weather(weather: String) -> void:
	_weather = weather
	var grey := weather != "SUNNY"
	if _sky_mat is PanoramaSkyMaterial:
		(_sky_mat as PanoramaSkyMaterial).panorama = _overcast_tex if grey else _clear_tex
	environment.fog_density = float(WEATHER_FOG.get(weather, 0.003))
	environment.volumetric_fog_density = 0.006 if not grey else 0.018
	rain.emitting = weather in ["LIGHT_RAIN", "HEAVY_RAIN", "STORM"]
	rain.amount = 400 if weather == "LIGHT_RAIN" else 1200


## hours: 0..24 (fractional).
func set_time(hours: float, follow: Vector3) -> void:
	var day_t := clampf((hours - 5.5) / 13.5, 0.0, 1.0)  # sunrise 05:30 → sunset 19:00
	var elevation := sin(day_t * PI) * 68.0
	# Light travels along its -Z: yaw 90 = sun in the east, 0 = south (northern hemisphere), -90 = west.
	sun.rotation_degrees = Vector3(-maxf(elevation, 3.0), 90.0 - day_t * 180.0, 0)
	var daylight := clampf(elevation / 22.0, 0.0, 1.0)
	var weather_mult := float(WEATHER_LIGHT.get(_weather, 1.0))
	sun.light_energy = lerpf(0.02, 1.6, daylight) * weather_mult
	sun.light_color = Color(1.0, 0.62, 0.38).lerp(Color(1.0, 0.96, 0.9), clampf(elevation / 35.0, 0.0, 1.0))
	sun.shadow_enabled = daylight > 0.02
	var night := 1.0 - clampf((elevation + 4.0) / 14.0, 0.0, 1.0)
	environment.background_energy_multiplier = lerpf(1.0, 0.04, night) * lerpf(1.0, 0.75, 1.0 - weather_mult)
	environment.ambient_light_energy = lerpf(1.0, 0.12, night)
	environment.fog_light_color = Color(0.72, 0.76, 0.80).lerp(Color(0.08, 0.1, 0.14), night)
	if rain.emitting:
		rain.global_position = follow + Vector3(0, 8, 0)
