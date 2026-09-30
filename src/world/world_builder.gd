class_name WorldBuilder
extends RefCounted
## Builds MAP_HOME and MAP_DRAIN (Act II places and MAP_LAKE: Act2Areas) (VERTICAL-SLICE §5–6, §16, docs/12) from primitives
## dressed with PBR materials (MaterialLibrary). Gameplay positions — interactables,
## colliders, spawns — are fixed here; art can replace the meshes without moving them.
## Water surfaces come from the fishing spots in data/maps so geometry and logic agree.
##
## Coordinates: +X east, +Z south, ground top at y = 0.
##   Home yard around the origin, road along z≈12, canal south of the road,
##   the big drain channel at x 60–80, z 30–100, reached by a dirt path at x≈55.

const C_BLACK := Color(0.06, 0.06, 0.06)
const C_GLASS := Color(0.12, 0.16, 0.18)
const C_BAMBOO := Color(0.50, 0.58, 0.28)
const C_LEAF := Color(0.22, 0.42, 0.15)
const PAINTS := [
	Color(0.98, 0.86, 0.50), Color(0.70, 0.85, 0.95), Color(0.98, 0.75, 0.72),
	Color(0.82, 0.92, 0.72), Color(0.97, 0.95, 0.88), Color(0.95, 0.80, 0.55),
]
const SIGN_COLORS := [Color(0.75, 0.12, 0.1), Color(0.1, 0.3, 0.7), Color(0.95, 0.75, 0.1), Color(0.1, 0.5, 0.25)]

## Rectangles [x0, z0, x1, z1] kept free of grass.
const GRASS_EXCLUDE := [
	[-45, 9.6, 100, 14.4],     # road
	[-8.2, -3.6, 8.2, 9.8],    # house + yard
	[5.4, -2.4, 7.6, -0.2],    # banana soil
	[52.6, 14, 58, 34],        # dirt path to the drain
	[56.3, 29.4, 83.7, 100.6], # drain channel and lips
	[-30.5, 16.4, 8.5, 23.6],  # canal
	[11.5, -0.5, 55, 9.6],     # north row houses + fishing shop
	[61.5, -4.5, 78.5, 8.5],   # scrap yard
	[82.5, 14.3, 101.5, 24],   # market
	[-40.5, -0.5, -11.5, 7.5],
	[13.5, 16, 46.5, 24.5],    # south row houses
	[59.5, 63.5, 80.5, 67],    # bridge
]

var root: Node3D
var lib := MaterialLibrary.new()
var spawns: Dictionary = {}  # name -> { position: Vector3, yaw: float (degrees) }
var act2: Act2Areas
var fisherman_spot: Vector3 = Vector3(-8, 0, 16.3)
var mother_spot: Vector3 = Vector3(1.8, 0, 4.8)
var grass_density: float = 5.0
var grass_distance: float = 42.0
var _flat: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func build(p_root: Node3D, data: DataRegistry) -> void:
	root = p_root
	_rng.seed = 20260930  # stable decoration layout
	_ground()
	_road()
	_home()
	_neighborhood()
	_canal()
	_drain()
	_water(data)
	_trees()
	_backdrop()
	_bounds()
	act2 = Act2Areas.new(self)
	act2.build(data)
	if grass_density > 0.0:
		GrassField.new(grass_density, grass_distance).build(root, [-45, -25, 100, 110], GRASS_EXCLUDE, _rng)
		GrassField.new(grass_density, grass_distance).build(root, [398, -82, 582, 82], Act2Areas.LAKE_GRASS_EXCLUDE, _rng)
	spawns = {
		"start": {"position": Vector3(30, 1, 12), "yaw": 90.0},
		"home": {"position": Vector3(0, 1, 7), "yaw": 0.0},
		"fisherman": {"position": Vector3(-8, 1, 13), "yaw": 180.0},
		"drain": {"position": Vector3(57.5, 1, 45), "yaw": -90.0},
		"shop": {"position": Vector3(52, 1, 11), "yaw": 0.0},
		"market": {"position": Vector3(90, 1, 12.5), "yaw": 180.0},
		"home_stop": {"position": Vector3(97, 1, 11), "yaw": 90.0},
		"lake_stop": {"position": Vector3(420, 1, -10), "yaw": -90.0},
		"lake": {"position": Vector3(450, 1, 0), "yaw": -90.0},
	}


# --- Primitive helpers --------------------------------------------------------

## Flat-colour material for small props.
func material(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var key := "%s_%s" % [color.to_html(), transparent]
	if _flat.has(key):
		return _flat[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flat[key] = m
	return m


func surf(key: String, tint: Color = Color.WHITE, fallback: Color = Color(0.5, 0.5, 0.5)) -> StandardMaterial3D:
	return lib.surface(key, tint, fallback)


## Box by min/max corners. surface: Color (flat) or Material. collide=false for decoration.
func box(parent: Node3D, from: Vector3, to: Vector3, surface, collide: bool = true) -> Node3D:
	var size := (to - from).abs()
	var center := (from + to) * 0.5
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = surface if surface is Material else material(surface)
	if not collide:
		mesh.position = center
		parent.add_child(mesh)
		return mesh
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	body.add_child(mesh)
	parent.add_child(body)
	return body


func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, surface, collide: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 14
	mesh.mesh = cm
	mesh.material_override = surface if surface is Material else material(surface)
	mesh.position = pos + Vector3(0, height * 0.5, 0)
	parent.add_child(mesh)
	if collide:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = radius
		cs.height = height
		shape.shape = cs
		body.add_child(shape)
		mesh.add_child(body)
	return mesh


func invisible_wall(from: Vector3, to: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = (from + to) * 0.5
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = (to - from).abs()
	shape.shape = bs
	body.add_child(shape)
	root.add_child(body)


## Interactable anchored at pos (ground level) with a box trigger of size.
func interactable(id: String, pos: Vector3, size: Vector3) -> Interactable:
	var it := Interactable.create(id, size, Vector3(0, size.y * 0.5, 0))
	it.position = pos
	root.add_child(it)
	return it


## A thin sagging cable between two points.
func cable(a: Vector3, b: Vector3, sag: float) -> void:
	var segments := 8
	for i in segments:
		var t0 := float(i) / segments
		var t1 := float(i + 1) / segments
		var p0 := a.lerp(b, t0) - Vector3(0, sin(t0 * PI) * sag, 0)
		var p1 := a.lerp(b, t1) - Vector3(0, sin(t1 * PI) * sag, 0)
		var seg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.012
		cm.bottom_radius = 0.012
		cm.height = p0.distance_to(p1)
		cm.radial_segments = 4
		seg.mesh = cm
		seg.material_override = material(C_BLACK)
		root.add_child(seg)
		seg.global_position = (p0 + p1) * 0.5
		seg.look_at(p1, Vector3.UP if absf((p1 - p0).normalized().y) < 0.99 else Vector3.RIGHT)
		seg.rotate_object_local(Vector3.RIGHT, PI / 2)


# --- Areas --------------------------------------------------------------------

func _ground() -> void:
	var grass := surf("grass", Color(0.78, 1.0, 0.62), Color(0.36, 0.45, 0.24))
	# Four slabs leave a pit for the drain channel (x 60–80, z 30–100).
	box(root, Vector3(-60, -4, -40), Vector3(60, 0, 120), grass)
	box(root, Vector3(80, -4, -40), Vector3(120, 0, 120), grass)
	box(root, Vector3(60, -4, -40), Vector3(80, 0, 30), grass)
	box(root, Vector3(60, -4, 100), Vector3(80, 0, 120), grass)
	var dirt := surf("dirt", Color.WHITE, Color(0.45, 0.36, 0.26))
	for i in 18:
		var p := Vector3(_rng.randf_range(-50, 110), 0, _rng.randf_range(-35, 115))
		if p.x > 54 and p.x < 86 and p.z > 26 and p.z < 104:
			continue
		var s := _rng.randf_range(2, 6)
		box(root, p + Vector3(-s, 0, -s * 0.6), p + Vector3(s, 0.012, s * 0.6), dirt, false)


func _road() -> void:
	box(root, Vector3(-45, 0, 10), Vector3(100, 0.03, 14), surf("asphalt", Color.WHITE, Color(0.36, 0.36, 0.37)), false)
	var curb := surf("concrete_old", Color(0.9, 0.9, 0.88), Color(0.6, 0.6, 0.58))
	box(root, Vector3(-45, 0, 9.75), Vector3(100, 0.1, 10.0), curb, false)
	box(root, Vector3(-45, 0, 14.0), Vector3(100, 0.1, 14.25), curb, false)
	box(root, Vector3(53, 0, 14), Vector3(57.5, 0.025, 34), surf("dirt", Color.WHITE, Color(0.45, 0.36, 0.26)), false)
	# Utility poles with sagging, tangled cables — every Vietnamese street has them.
	var pole := surf("concrete_old", Color(0.85, 0.85, 0.82), Color(0.42, 0.42, 0.40))
	var x := -40.0
	while x <= 95.0:
		cylinder(root, Vector3(x, 0, 9.3), 0.14, 7.5, pole, true)
		box(root, Vector3(x - 0.8, 6.9, 9.2), Vector3(x + 0.8, 7.0, 9.4), pole, false)
		if x + 15.0 <= 95.0:
			for offset in [-0.6, -0.2, 0.6]:
				cable(Vector3(x + offset, 6.85, 9.3), Vector3(x + 15.0 + offset, 6.85, 9.3), _rng.randf_range(0.35, 0.8))
			cable(Vector3(x, 6.5, 9.3), Vector3(x + 15.0, 5.9, 9.3), 0.9)
		x += 15.0


func _home() -> void:
	# Single-storey house: painted plaster, rusty tin roof, doorway and window facing the yard.
	var walls := surf("plaster", Color(1.0, 0.93, 0.78), Color(0.90, 0.85, 0.70))
	box(root, Vector3(-4, 0, -3), Vector3(4, 3, 3), walls)
	var roof := box(root, Vector3(-4.8, 0, -3.8), Vector3(4.8, 0.08, 3.8), surf("tin_roof", Color.WHITE, Color(0.55, 0.30, 0.22)), false)
	roof.position.y = 3.25
	roof.rotation_degrees.x = -7
	box(root, Vector3(-2.2, 0, 3.0), Vector3(-0.8, 2.2, 3.04), Color(0.03, 0.03, 0.03), false)  # doorway
	box(root, Vector3(-2.3, 2.2, 2.98), Vector3(-0.7, 2.3, 3.06), surf("rust"), false)
	_window(Vector3(1.2, 1.1, 3.0), Vector3(2.8, 2.2, 3.0), 1)
	# Yard: tiles, low plastered wall, rusty gate posts.
	box(root, Vector3(-7, 0, 3), Vector3(7, 0.04, 9), surf("tiles", Color(0.95, 0.9, 0.85), Color(0.62, 0.61, 0.58)), false)
	var yard_wall := surf("plaster_worn", Color(1.0, 0.95, 0.82), Color(0.90, 0.85, 0.70))
	box(root, Vector3(-8, 0, 9.3), Vector3(-1.6, 1.1, 9.6), yard_wall)
	box(root, Vector3(1.6, 0, 9.3), Vector3(8, 1.1, 9.6), yard_wall)
	box(root, Vector3(-8, 0, 3), Vector3(-7.7, 1.1, 9.6), yard_wall)
	box(root, Vector3(7.7, 0, 3), Vector3(8, 1.1, 9.6), yard_wall)
	for gx in [-1.6, 1.3]:
		box(root, Vector3(gx, 0, 9.25), Vector3(gx + 0.3, 1.5, 9.65), surf("rust"), false)
	# Doorstep = crafting spot (sit down, materials, short sequence).
	box(root, Vector3(-2.4, 0, 3.05), Vector3(-0.6, 0.25, 3.7), surf("concrete", Color(0.8, 0.8, 0.78), Color(0.42, 0.42, 0.4)))
	interactable("INT_CRAFT_SPOT", Vector3(-1.5, 0, 3.4), Vector3(1.9, 0.6, 0.8))
	# Mother's motorbike.
	_motorbike(Vector3(4.6, 0, 6.2), 0.0, Color(0.6, 0.1, 0.1))
	interactable("INT_MOTORBIKE", Vector3(4.6, 0, 6.2), Vector3(0.7, 1.1, 2.0))
	# Rain water jar, buckets, plastic stools and basins.
	cylinder(root, Vector3(-5.5, 0, 4.2), 0.45, 0.9, Color(0.42, 0.24, 0.14), true)
	cylinder(root, Vector3(-5.5, 0.88, 4.2), 0.47, 0.04, Color(0.1, 0.1, 0.1))
	interactable("INT_WATER_JAR", Vector3(-5.5, 0, 4.2), Vector3(1.0, 1.0, 1.0))
	cylinder(root, Vector3(-4.6, 0, 5.1), 0.22, 0.35, Color(0.15, 0.35, 0.75))
	cylinder(root, Vector3(-6.4, 0, 5.3), 0.2, 0.3, Color(0.85, 0.2, 0.2))
	_plastic_stool(Vector3(-2.4, 0, 5.2), Color(0.85, 0.15, 0.15))
	_plastic_stool(Vector3(-3.1, 0, 5.6), Color(0.15, 0.35, 0.8))
	box(root, Vector3(5.8, 0, 3.4), Vector3(6.6, 0.4, 4.0), Color(0.9, 0.6, 0.1), false)
	# Clothesline with drying clothes.
	cylinder(root, Vector3(-6.8, 0, 7.6), 0.04, 1.9, surf("rust"))
	cylinder(root, Vector3(-2.8, 0, 7.6), 0.04, 1.9, surf("rust"))
	cable(Vector3(-6.8, 1.87, 7.6), Vector3(-2.8, 1.87, 7.6), 0.06)
	var cloth_colors := [Color(0.9, 0.9, 0.95), Color(0.3, 0.5, 0.8), Color(0.8, 0.4, 0.5)]
	for i in 3:
		var cx := -6.2 + i * 1.2
		box(root, Vector3(cx, 1.2, 7.58), Vector3(cx + 0.7, 1.82, 7.62), cloth_colors[i], false)
	interactable("INT_CLOTHESLINE", Vector3(-4.8, 0, 7.6), Vector3(4.0, 1.9, 0.4))
	# Banana plant over damp soil (bait).
	box(root, Vector3(5.6, 0, -2.2), Vector3(7.4, 0.03, -0.4), surf("mud", Color.WHITE, Color(0.3, 0.24, 0.17)), false)
	cylinder(root, Vector3(6.5, 0, -1.3), 0.14, 2.2, surf("bark", Color(0.8, 0.9, 0.6)))
	for i in 6:
		var leaf := box(root, Vector3(-0.18, -0.01, 0), Vector3(0.18, 0.01, 1.5), C_LEAF, false)
		leaf.position = Vector3(6.5, 2.1, -1.3)
		leaf.rotation_degrees = Vector3(-20 - _rng.randf() * 15, i * 60.0 + _rng.randf() * 20, 0)
	interactable("INT_BAIT_SOIL_HOME", Vector3(6.5, 0, -1.3), Vector3(1.8, 0.5, 1.8))
	# Bamboo clump behind the house, with leafy tops.
	for i in 13:
		var p := Vector3(-6.0 + _rng.randf_range(-1.2, 1.2), 0, -8.0 + _rng.randf_range(-1.2, 1.2))
		var h := _rng.randf_range(4.5, 7.0)
		var stalk := cylinder(root, p, 0.055, h, C_BAMBOO)
		stalk.rotation_degrees = Vector3(_rng.randf_range(-7, 7), 0, _rng.randf_range(-7, 7))
		for j in 3:
			var tuft := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.5
			sm.height = 0.5
			tuft.mesh = sm
			tuft.scale = Vector3(1.4, 0.5, 1.0)
			tuft.material_override = material(C_LEAF)
			tuft.position = p + Vector3(_rng.randf_range(-0.5, 0.5), h - j * 0.7, _rng.randf_range(-0.5, 0.5))
			root.add_child(tuft)
	interactable("INT_BAMBOO_CLUMP", Vector3(-6, 0, -8), Vector3(2.6, 3.0, 2.6))


func _neighborhood() -> void:
	# Narrow tube houses (nhà ống) along both sides of the road.
	var x := 12.0
	var i := 0
	while x < 44.0:  # the fishing shop stands at x 49.5
		var w := _rng.randf_range(4.0, 5.5)
		_tube_house(x, w, 0.0, 7.0, 1, _rng.randi_range(1, 3), i)
		x += w
		i += 1
	x = -40.0
	while x < -12.0:
		var w := _rng.randf_range(4.0, 5.5)
		_tube_house(x, w, 0.0, 7.0, 1, _rng.randi_range(1, 2), i)
		x += w
		i += 1
	x = 14.0
	while x < 46.0:
		var w := _rng.randf_range(4.5, 6.0)
		_tube_house(x, w, 16.5, 24.0, -1, _rng.randi_range(1, 3), i)
		x += w
		i += 1
	for bike in [[22.0, 8.4, 90.0], [31.5, 8.2, 80.0], [-25.0, 8.3, 95.0], [27.0, 15.7, -85.0], [40.5, 15.8, -95.0]]:
		_motorbike(Vector3(bike[0], 0, bike[1]), bike[2], SIGN_COLORS[_rng.randi() % SIGN_COLORS.size()])
	# Roadside rubbish: the discarded inner tube and the old shoe.
	var tube := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.25
	torus.outer_radius = 0.33
	tube.mesh = torus
	tube.material_override = material(Color(0.05, 0.05, 0.05))
	tube.position = Vector3(10.5, 0.05, 15.0)
	tube.rotation_degrees.x = 8
	root.add_child(tube)
	interactable("INT_INNER_TUBE", Vector3(10.5, 0, 15.0), Vector3(0.9, 0.5, 0.9))
	for j in 9:
		var p := Vector3(-18 + _rng.randf_range(-1.2, 1.2), 0, 8.4 + _rng.randf_range(-0.8, 0.6))
		var s := _rng.randf_range(0.25, 0.6)
		box(root, p, p + Vector3(s, s * 0.7, s), [Color(0.9, 0.9, 0.9), Color(0.2, 0.35, 0.2), Color(0.25, 0.25, 0.6)][j % 3], false)
	box(root, Vector3(-16.4, 0, 8.6), Vector3(-16.1, 0.12, 9.0), Color(0.35, 0.25, 0.2), false)  # the shoe
	interactable("INT_OLD_SHOE", Vector3(-17.2, 0, 8.7), Vector3(3.0, 0.8, 1.8))
	# Scrap pile (ve chai).
	var rust := surf("rust")
	for j in 14:
		var p := Vector3(38 + _rng.randf_range(-1.4, 1.4), 0, 8.2 + _rng.randf_range(-0.8, 0.5))
		var s := _rng.randf_range(0.2, 0.55)
		box(root, p, p + Vector3(s, s, s * 1.3), [rust, Color(0.5, 0.5, 0.55), Color(0.15, 0.5, 0.35)][j % 3], false)
	interactable("INT_SCRAP_PILE", Vector3(38, 0, 8.0), Vector3(3.2, 0.9, 1.8))


## One tube house between x0..x0+width and z0..z1. facing = +1 (front at z1) or -1 (front at z0).
func _tube_house(x0: float, width: float, z0: float, z1: float, facing: int, floors: int, index: int) -> void:
	var floor_h := 3.2
	var height := floors * floor_h + 0.5
	var x1 := x0 + width - 0.25
	var paint: Color = PAINTS[index % PAINTS.size()]
	box(root, Vector3(x0, 0, z0), Vector3(x1, height, z1), surf("plaster_worn" if index % 3 == 0 else "plaster", paint, paint * 0.85))
	var zf := z1 if facing > 0 else z0  # front plane
	var out := float(facing)
	# Ground floor: roller shutter, often half open onto a dark shop, with a signboard.
	var open := _rng.randf() < 0.5
	var shutter_top := 2.6 if not open else _rng.randf_range(1.9, 2.4)
	box(root, Vector3(x0 + 0.3, shutter_top - (2.6 if not open else 0.5), zf), Vector3(x1 - 0.3, shutter_top, zf + out * 0.06), surf("shutter", Color(0.85, 0.85, 0.82)), false)
	if open:
		box(root, Vector3(x0 + 0.3, 0, zf - out * 0.02), Vector3(x1 - 0.3, shutter_top - 0.5, zf + out * 0.01), Color(0.02, 0.02, 0.02), false)
	var sign_color: Color = SIGN_COLORS[index % SIGN_COLORS.size()]
	var sign_mat := StandardMaterial3D.new()
	sign_mat.albedo_color = sign_color
	sign_mat.emission_enabled = true
	sign_mat.emission = sign_color * 0.25
	box(root, Vector3(x0 + 0.2, 2.75, zf), Vector3(x1 - 0.2, 3.25, zf + out * 0.12), sign_mat, false)
	# Upper floors: balcony, railing, windows, sometimes an AC unit or potted plants.
	for f in range(1, floors):
		var y := f * floor_h
		box(root, Vector3(x0, y - 0.1, zf), Vector3(x1, y + 0.05, zf + out * 0.9), surf("concrete_old", Color(0.9, 0.9, 0.88)), false)
		box(root, Vector3(x0, y + 0.05, zf + out * 0.86), Vector3(x1, y + 1.0, zf + out * 0.9), surf("rust", Color(0.6, 0.6, 0.62)), false)
		_window(Vector3(x0 + 0.6, y + 0.4, zf), Vector3(x1 - 0.6, y + 2.5, zf), facing)
		if _rng.randf() < 0.5:
			box(root, Vector3(x1 - 1.1, y + 2.55, zf), Vector3(x1 - 0.3, y + 3.0, zf + out * 0.3), Color(0.9, 0.9, 0.88), false)
		if _rng.randf() < 0.6:
			for k in 3:
				var px := x0 + 0.5 + k * 0.6
				cylinder(root, Vector3(px, y + 0.05, zf + out * 0.6), 0.14, 0.25, Color(0.55, 0.3, 0.2))
				var plant := MeshInstance3D.new()
				var pm := SphereMesh.new()
				pm.radius = 0.2
				pm.height = 0.35
				plant.mesh = pm
				plant.material_override = material(C_LEAF)
				plant.position = Vector3(px, y + 0.45, zf + out * 0.6)
				root.add_child(plant)
	# Roof: low parapet, sometimes a tin shed on top.
	if _rng.randf() < 0.5:
		var shed := box(root, Vector3(x0, 0, z0 + 1.0), Vector3(x1, 0.06, z1 - 2.0), surf("tin_roof"), false)
		shed.position.y = height + 1.4
		shed.rotation_degrees.x = 5


func _window(from: Vector3, to: Vector3, facing: int) -> void:
	var out := float(facing)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = C_GLASS
	glass.metallic = 0.6
	glass.roughness = 0.08
	box(root, Vector3(from.x, from.y, from.z), Vector3(to.x, to.y, to.z + out * 0.03), glass, false)
	var frame := surf("rust", Color(0.55, 0.55, 0.6))
	box(root, Vector3(from.x - 0.06, from.y - 0.06, from.z), Vector3(to.x + 0.06, from.y, to.z + out * 0.07), frame, false)
	box(root, Vector3(from.x - 0.06, to.y, from.z), Vector3(to.x + 0.06, to.y + 0.06, to.z + out * 0.07), frame, false)
	var mid := (from.x + to.x) * 0.5
	box(root, Vector3(mid - 0.03, from.y, from.z), Vector3(mid + 0.03, to.y, to.z + out * 0.07), frame, false)
	# Security bars (song cửa sổ).
	var bx := from.x + 0.18
	while bx < to.x - 0.1:
		box(root, Vector3(bx - 0.01, from.y, from.z + out * 0.08), Vector3(bx + 0.01, to.y, from.z + out * 0.1), frame, false)
		bx += 0.22


func _motorbike(pos: Vector3, yaw: float, body_color: Color) -> void:
	var bike := Node3D.new()
	bike.position = pos
	bike.rotation_degrees.y = yaw
	root.add_child(bike)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = body_color
	paint.metallic = 0.3
	paint.roughness = 0.35
	box(bike, Vector3(-0.18, 0.35, -0.55), Vector3(0.18, 0.75, 0.6), paint, false)
	box(bike, Vector3(-0.2, 0.75, -0.35), Vector3(0.2, 0.86, 0.45), Color(0.08, 0.08, 0.08), false)  # seat
	box(bike, Vector3(-0.16, 0.45, -0.95), Vector3(0.16, 1.05, -0.7), paint, false)  # front shield
	box(bike, Vector3(-0.35, 1.05, -0.86), Vector3(0.35, 1.09, -0.8), Color(0.2, 0.2, 0.2), false)  # handlebar
	var chrome := StandardMaterial3D.new()
	chrome.albedo_color = Color(0.7, 0.7, 0.72)
	chrome.metallic = 1.0
	chrome.roughness = 0.2
	box(bike, Vector3(0.1, 0.25, 0.2), Vector3(0.18, 0.33, 0.85), chrome, false)  # exhaust
	for z in [-0.8, 0.75]:
		var wheel := cylinder(bike, Vector3.ZERO, 0.3, 0.1, Color(0.05, 0.05, 0.05))
		wheel.rotation_degrees.z = 90
		wheel.position = Vector3(0, 0.3, z)


func _plastic_stool(pos: Vector3, color: Color) -> void:
	var plastic := StandardMaterial3D.new()
	plastic.albedo_color = color
	plastic.roughness = 0.35
	box(root, pos + Vector3(-0.15, 0.25, -0.15), pos + Vector3(0.15, 0.28, 0.15), plastic, false)
	for dx in [-0.12, 0.12]:
		for dz in [-0.12, 0.12]:
			box(root, pos + Vector3(dx - 0.02, 0, dz - 0.02), pos + Vector3(dx + 0.02, 0.25, dz + 0.02), plastic, false)


## A plastic stool with its seat at `height` (for seated NPCs).
func stool(pos: Vector3, height: float, color: Color) -> void:
	var plastic := StandardMaterial3D.new()
	plastic.albedo_color = color
	plastic.roughness = 0.35
	box(root, pos + Vector3(-0.17, height - 0.03, -0.17), pos + Vector3(0.17, height, 0.17), plastic, false)
	for dx in [-0.14, 0.14]:
		for dz in [-0.14, 0.14]:
			box(root, pos + Vector3(dx - 0.025, 0, dz - 0.025), pos + Vector3(dx + 0.025, height - 0.03, dz + 0.025), plastic, false)


## A round woven basket of greens on the ground (rổ rau).
func vegetable_basket(pos: Vector3) -> void:
	var basket := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.26
	cm.bottom_radius = 0.2
	cm.height = 0.12
	basket.mesh = cm
	basket.material_override = surf("bark", Color(1.0, 0.85, 0.6), Color(0.6, 0.45, 0.25))
	basket.position = pos + Vector3(0, 0.06, 0)
	root.add_child(basket)
	for i in 9:
		var leaf := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.07
		leaf.mesh = sm
		leaf.scale = Vector3(1.4, 0.6, 1.0)
		leaf.material_override = material(Color(0.25, 0.55, 0.18).lerp(Color(0.4, 0.62, 0.22), _rng.randf()))
		leaf.position = pos + Vector3(_rng.randf_range(-0.16, 0.16), 0.13, _rng.randf_range(-0.16, 0.16))
		root.add_child(leaf)


func _canal() -> void:
	# Concrete lips and railings; the water surface is added by _water().
	var lip := surf("concrete_old", Color(0.9, 0.9, 0.88), Color(0.62, 0.61, 0.58))
	box(root, Vector3(-30, 0, 16.6), Vector3(8, 0.2, 17.0), lip)
	box(root, Vector3(-30, 0, 23.0), Vector3(8, 0.2, 23.4), lip)
	invisible_wall(Vector3(-30, 0, 16.9), Vector3(8, 2, 17.0))
	box(root, Vector3(-30, -0.4, 17.0), Vector3(8, 0.0, 23.0), surf("mud", Color.WHITE, Color(0.3, 0.24, 0.17)), false)
	# The old fisherman's stool and bucket are added by his actor.


func _drain() -> void:
	var lip := surf("concrete", Color(0.92, 0.92, 0.9), Color(0.62, 0.61, 0.58))
	var old := surf("concrete_old", Color(0.75, 0.78, 0.7), Color(0.42, 0.42, 0.40))
	var mud := surf("mud", Color.WHITE, Color(0.3, 0.24, 0.17))
	for bank in [[56.5, 60.0], [80.0, 83.5]]:
		box(root, Vector3(bank[0], 0, 30), Vector3(bank[1], 0.04, 100), lip, false)
	box(root, Vector3(59.8, -3.2, 30), Vector3(60.0, 0, 100), old, false)
	box(root, Vector3(80.0, -3.2, 30), Vector3(80.2, 0, 100), old, false)
	# Algae stain along the waterline.
	box(root, Vector3(59.78, -1.55, 30), Vector3(59.8, -1.05, 100), Color(0.12, 0.18, 0.08), false)
	box(root, Vector3(80.2, -1.55, 30), Vector3(80.22, -1.05, 100), Color(0.12, 0.18, 0.08), false)
	box(root, Vector3(60, -3.4, 30), Vector3(80, -3.2, 100), mud)
	# Low curb + invisible barrier so the player does not fall in.
	for x in [59.75, 80.0]:
		box(root, Vector3(x, 0, 30), Vector3(x + 0.25, 0.3, 100), old)
		invisible_wall(Vector3(x, 0, 30), Vector3(x + 0.25, 1.4, 100))
	invisible_wall(Vector3(60, 0, 29.8), Vector3(80, 1.4, 30.0))
	invisible_wall(Vector3(60, 0, 100.0), Vector3(80, 1.4, 100.2))
	# Landmark: the large concrete pipe in the north wall.
	var ring := cylinder(root, Vector3.ZERO, 2.3, 0.6, lip)
	ring.rotation_degrees.x = 90
	ring.position = Vector3(70, -1.4, 30.1)
	var hole := cylinder(root, Vector3.ZERO, 1.8, 0.62, Color(0.02, 0.02, 0.02))
	hole.rotation_degrees.x = 90
	hole.position = Vector3(70, -1.4, 30.12)
	box(root, Vector3(60, -3.2, 29.5), Vector3(80, 0, 30.0), old, false)
	interactable("INT_DRAIN_PIPE", Vector3(70, -0.6, 31.5), Vector3(6, 1.2, 1.5)).collision_layer = Interactable.LAYER
	# Small bridge across the channel.
	box(root, Vector3(60, -0.35, 64), Vector3(80, 0.05, 66.5), lip)
	box(root, Vector3(60, 0.05, 63.9), Vector3(80, 1.0, 64.1), old)
	box(root, Vector3(60, 0.05, 66.4), Vector3(80, 1.0, 66.6), old)
	# Mud patch for bait, the sign, rubbish, reeds along the banks.
	box(root, Vector3(56.8, 0, 47), Vector3(58.8, 0.05, 49.5), mud, false)
	interactable("INT_BAIT_SOIL_DRAIN", Vector3(57.8, 0, 48.2), Vector3(2.0, 0.4, 2.5))
	cylinder(root, Vector3(55.8, 0, 36), 0.04, 1.6, surf("rust"))
	box(root, Vector3(55.3, 1.3, 35.95), Vector3(56.3, 1.9, 36.05), surf("rust", Color(0.95, 0.95, 0.9)), false)
	interactable("INT_DRAIN_SIGN", Vector3(55.8, 0, 36), Vector3(1.2, 2.0, 0.6))
	for j in 16:
		var p := Vector3(_rng.randf_range(54, 58.5), 0, _rng.randf_range(32, 98))
		var s := _rng.randf_range(0.2, 0.45)
		box(root, p, p + Vector3(s, s * 0.6, s), [Color(0.95, 0.95, 0.95), Color(0.2, 0.3, 0.8), Color(0.8, 0.2, 0.2)][j % 3], false)
	for j in 70:
		var side := 55.0 if j % 2 == 0 else 85.0
		var p := Vector3(side + _rng.randf_range(-2.5, 1.5), 0, _rng.randf_range(26, 104))
		var reed := box(root, Vector3(-0.02, 0, -0.02), Vector3(0.02, _rng.randf_range(0.6, 1.4), 0.02), C_LEAF, false)
		reed.position = p
		reed.rotation_degrees = Vector3(_rng.randf_range(-12, 12), 0, _rng.randf_range(-12, 12))


func _water(data: DataRegistry) -> void:
	var shader := load("res://src/world/shaders/water.gdshader")
	var water := ShaderMaterial.new()
	water.shader = shader
	water.set_shader_parameter("normal_a", _noise_normal(1, 0.035))
	water.set_shader_parameter("normal_b", _noise_normal(2, 0.07))
	for map in data.all("maps"):
		for spot in map.get("fishing_spots", []):
			var r: Array = spot["rect"]
			var wy := float(spot["water_y"])
			var mesh := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
			pm.subdivide_width = int(pm.size.x)
			pm.subdivide_depth = int(pm.size.y)
			mesh.mesh = pm
			mesh.material_override = water
			mesh.position = Vector3((float(r[0]) + float(r[2])) * 0.5, wy, (float(r[1]) + float(r[3])) * 0.5)
			mesh.name = "Water_" + str(spot["id"])
			root.add_child(mesh)


func _noise_normal(seed: int, frequency: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = frequency
	noise.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.as_normal_map = true
	tex.bump_strength = 6.0
	tex.noise = noise
	return tex


## Shade trees inside the playable area, kept clear of paths and interactables.
func _trees() -> void:
	for p in [Vector3(-12, 0, -10), Vector3(11, 0, -9), Vector3(-24, 0, 30), Vector3(4, 0, 30),
			Vector3(50, 0, -6), Vector3(106, 0, 24), Vector3(89, 0, 62), Vector3(46, 0, 46),
			Vector3(-35, 0, -15), Vector3(25, 0, 35), Vector3(100, 0, 90), Vector3(-45, 0, 45)]:
		_tree(p, _rng.randf_range(6.0, 9.0), true)


## Tree line and far ground beyond the invisible walls, so the horizon reads as countryside.
func _backdrop() -> void:
	# Ring of far ground around the map (x -60..120, z -40..120) — never over the drain pit.
	var far := surf("grass", Color(0.7, 0.95, 0.55), Color(0.36, 0.45, 0.24))
	# Stops at x 360, where the lake's own ground begins.
	box(root, Vector3(-400, -0.05, -400), Vector3(360, -0.02, -40), far, false)
	box(root, Vector3(-400, -0.05, 120), Vector3(360, -0.02, 520), far, false)
	box(root, Vector3(-400, -0.05, -40), Vector3(-60, -0.02, 120), far, false)
	box(root, Vector3(120, -0.05, -40), Vector3(360, -0.02, 120), far, false)
	var x := -70.0
	while x < 130.0:
		for z in [_rng.randf_range(-58, -46), _rng.randf_range(126, 140)]:
			_tree(Vector3(x, 0, z), _rng.randf_range(7.0, 12.0), false)
		x += _rng.randf_range(5.0, 9.0)
	var z2 := -40.0
	while z2 < 125.0:
		for xx in [_rng.randf_range(-78, -66), _rng.randf_range(126, 140)]:
			_tree(Vector3(xx, 0, z2), _rng.randf_range(7.0, 12.0), false)
		z2 += _rng.randf_range(5.0, 9.0)


func _tree(pos: Vector3, height: float, collide: bool) -> void:
	var trunk := cylinder(root, pos, 0.18 * height / 7.0, height * 0.65, surf("bark"), collide)
	trunk.rotation_degrees = Vector3(_rng.randf_range(-5, 5), 0, _rng.randf_range(-5, 5))
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.16, 0.34, 0.10).lerp(Color(0.30, 0.45, 0.14), _rng.randf())
	leaves.roughness = 0.75
	leaves.backlight_enabled = true
	leaves.backlight = Color(0.15, 0.25, 0.05)
	for i in _rng.randi_range(4, 7):
		var blob := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := _rng.randf_range(1.2, 2.3) * height / 8.0
		sm.radius = r
		sm.height = r * 1.6
		sm.radial_segments = 12
		sm.rings = 6
		blob.mesh = sm
		blob.material_override = leaves
		blob.position = pos + Vector3(_rng.randf_range(-1.6, 1.6), height * _rng.randf_range(0.6, 0.95), _rng.randf_range(-1.6, 1.6)) * Vector3(height / 8.0, 1, height / 8.0)
		root.add_child(blob)


func _bounds() -> void:
	invisible_wall(Vector3(-60, 0, -41), Vector3(120, 10, -40))
	invisible_wall(Vector3(-60, 0, 120), Vector3(120, 10, 121))
	invisible_wall(Vector3(-61, 0, -40), Vector3(-60, 10, 120))
	invisible_wall(Vector3(120, 0, -40), Vector3(121, 10, 120))
