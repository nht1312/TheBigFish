class_name WorldBuilder
extends RefCounted
## Greybox construction of MAP_HOME and MAP_DRAIN (VERTICAL-SLICE §5–6, §16, docs/12).
## Primitive shapes only — art replaces these later without touching gameplay code.
## Water surfaces come from the fishing spots in data/maps so geometry and logic agree.
##
## Coordinates: +X east, +Z south, ground top at y = 0.
##   Home yard around the origin, road along z≈12, canal south of the road,
##   the big drain channel at x 60–80, z 30–100, reached by a dirt path at x≈55.

const C_GRASS := Color(0.36, 0.45, 0.24)
const C_DIRT := Color(0.45, 0.36, 0.26)
const C_MUD := Color(0.30, 0.24, 0.17)
const C_CONCRETE := Color(0.62, 0.61, 0.58)
const C_CONCRETE_DARK := Color(0.42, 0.42, 0.40)
const C_ROAD := Color(0.36, 0.36, 0.37)
const C_WALL_CREAM := Color(0.90, 0.85, 0.70)
const C_ROOF := Color(0.55, 0.30, 0.22)
const C_BAMBOO := Color(0.45, 0.60, 0.25)
const C_LEAF := Color(0.25, 0.50, 0.20)
const C_RUST := Color(0.50, 0.30, 0.18)
const C_BLACK := Color(0.08, 0.08, 0.08)

var root: Node3D
var spawns: Dictionary = {}  # name -> { position: Vector3, yaw: float (degrees) }
var fisherman_spot: Vector3 = Vector3(-8, 0, 16.3)
var mother_spot: Vector3 = Vector3(1.8, 0, 4.8)
var _materials: Dictionary = {}
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
	_bounds()
	spawns = {
		"start": {"position": Vector3(30, 1, 12), "yaw": 90.0},
		"home": {"position": Vector3(0, 1, 7), "yaw": 0.0},
		"fisherman": {"position": Vector3(-8, 1, 13), "yaw": 180.0},
		"drain": {"position": Vector3(57.5, 1, 45), "yaw": -90.0},
	}


# --- Primitive helpers --------------------------------------------------------

func material(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var key := "%s_%s" % [color.to_html(), transparent]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.15
		m.metallic_specular = 0.8
	_materials[key] = m
	return m


## Box by min/max corners. collide=false for decoration.
func box(parent: Node3D, from: Vector3, to: Vector3, color: Color, collide: bool = true) -> Node3D:
	var size := (to - from).abs()
	var center := (from + to) * 0.5
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = material(color)
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


func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, collide: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 12
	mesh.mesh = cm
	mesh.material_override = material(color)
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


# --- Areas --------------------------------------------------------------------

func _ground() -> void:
	# Four slabs leave a pit for the drain channel (x 60–80, z 30–100).
	box(root, Vector3(-60, -4, -40), Vector3(60, 0, 120), C_GRASS)
	box(root, Vector3(80, -4, -40), Vector3(120, 0, 120), C_GRASS)
	box(root, Vector3(60, -4, -40), Vector3(80, 0, 30), C_GRASS)
	box(root, Vector3(60, -4, 100), Vector3(80, 0, 120), C_GRASS)
	# Worn dirt patches.
	for i in 18:
		var p := Vector3(_rng.randf_range(-50, 110), 0, _rng.randf_range(-35, 115))
		if p.x > 56 and p.x < 84 and p.z > 26 and p.z < 104:
			continue
		var s := _rng.randf_range(2, 6)
		box(root, p + Vector3(-s, 0, -s * 0.6), p + Vector3(s, 0.015, s * 0.6), C_DIRT, false)


func _road() -> void:
	box(root, Vector3(-45, 0, 10), Vector3(100, 0.03, 14), C_ROAD, false)
	# Dirt path from the road down to the drain bank.
	box(root, Vector3(53, 0, 14), Vector3(57.5, 0.025, 34), C_DIRT, false)
	# Utility poles with sagging wires.
	var x := -40.0
	while x <= 95.0:
		cylinder(root, Vector3(x, 0, 9.3), 0.14, 7.5, C_CONCRETE_DARK, true)
		box(root, Vector3(x - 0.8, 6.9, 9.2), Vector3(x + 0.8, 7.0, 9.4), C_CONCRETE_DARK, false)
		if x + 15.0 <= 95.0:
			for offset in [-0.6, 0.6]:
				box(root, Vector3(x + offset, 6.85, 9.28), Vector3(x + 15.0 + offset, 6.88, 9.32), C_BLACK, false)
		x += 15.0


func _home() -> void:
	# House: cream walls, rust-red tin roof, dark doorway facing the yard.
	box(root, Vector3(-4, 0, -3), Vector3(4, 3, 3), C_WALL_CREAM)
	var roof := box(root, Vector3(-4.6, 0, -3.6), Vector3(4.6, 0.15, 3.6), C_ROOF, false)
	roof.position.y = 3.25
	roof.rotation_degrees.x = -6
	box(root, Vector3(-2.2, 0, 3.0), Vector3(-0.8, 2.2, 3.05), C_BLACK, false)  # doorway
	box(root, Vector3(1.2, 1.2, 3.0), Vector3(2.8, 2.2, 3.05), Color(0.2, 0.3, 0.35), false)  # window
	# Yard: concrete slab, low front wall with a gate gap.
	box(root, Vector3(-7, 0, 3), Vector3(7, 0.04, 9), C_CONCRETE, false)
	box(root, Vector3(-8, 0, 9.3), Vector3(-1.6, 1.1, 9.6), C_WALL_CREAM)
	box(root, Vector3(1.6, 0, 9.3), Vector3(8, 1.1, 9.6), C_WALL_CREAM)
	box(root, Vector3(-8, 0, 3), Vector3(-7.7, 1.1, 9.6), C_WALL_CREAM)
	box(root, Vector3(7.7, 0, 3), Vector3(8, 1.1, 9.6), C_WALL_CREAM)
	# Doorstep = crafting spot (sit down, materials, short sequence).
	box(root, Vector3(-2.4, 0, 3.05), Vector3(-0.6, 0.25, 3.7), C_CONCRETE_DARK)
	interactable("INT_CRAFT_SPOT", Vector3(-1.5, 0, 3.4), Vector3(1.9, 0.6, 0.8))
	# Motorbike.
	var bike := Node3D.new()
	bike.position = Vector3(4.6, 0, 6.2)
	root.add_child(bike)
	box(bike, Vector3(-0.2, 0.35, -0.9), Vector3(0.2, 0.9, 0.9), Color(0.6, 0.1, 0.1), false)
	box(bike, Vector3(-0.25, 0.9, -0.5), Vector3(0.25, 1.0, 0.4), C_BLACK, false)
	for z in [-0.75, 0.75]:
		var wheel := cylinder(bike, Vector3(0, 0, z), 0.32, 0.12, C_BLACK)
		wheel.rotation_degrees.z = 90
		wheel.position = Vector3(0, 0.32, z)
	interactable("INT_MOTORBIKE", Vector3(4.6, 0, 6.2), Vector3(0.7, 1.1, 2.0))
	# Rain water jar, buckets, plastic containers.
	cylinder(root, Vector3(-5.5, 0, 4.2), 0.45, 0.9, Color(0.45, 0.28, 0.18), true)
	interactable("INT_WATER_JAR", Vector3(-5.5, 0, 4.2), Vector3(1.0, 1.0, 1.0))
	cylinder(root, Vector3(-4.6, 0, 5.1), 0.22, 0.35, Color(0.15, 0.35, 0.75))
	cylinder(root, Vector3(-6.4, 0, 5.3), 0.2, 0.3, Color(0.85, 0.2, 0.2))
	box(root, Vector3(5.8, 0, 3.4), Vector3(6.6, 0.4, 4.0), Color(0.9, 0.6, 0.1), false)
	# Clothesline with drying clothes.
	cylinder(root, Vector3(-6.8, 0, 7.6), 0.05, 1.9, C_CONCRETE_DARK)
	cylinder(root, Vector3(-2.8, 0, 7.6), 0.05, 1.9, C_CONCRETE_DARK)
	box(root, Vector3(-6.8, 1.85, 7.58), Vector3(-2.8, 1.87, 7.62), C_BLACK, false)
	var cloth_colors := [Color(0.9, 0.9, 0.95), Color(0.3, 0.5, 0.8), Color(0.8, 0.4, 0.5)]
	for i in 3:
		var cx := -6.2 + i * 1.2
		box(root, Vector3(cx, 1.2, 7.57), Vector3(cx + 0.7, 1.85, 7.63), cloth_colors[i], false)
	interactable("INT_CLOTHESLINE", Vector3(-4.8, 0, 7.6), Vector3(4.0, 1.9, 0.4))
	# Banana plant over damp soil (bait).
	box(root, Vector3(5.6, 0, -2.2), Vector3(7.4, 0.03, -0.4), C_MUD, false)
	cylinder(root, Vector3(6.5, 0, -1.3), 0.14, 2.2, Color(0.4, 0.5, 0.25))
	for i in 5:
		var leaf := box(root, Vector3(-0.15, -0.02, 0), Vector3(0.15, 0.02, 1.4), C_LEAF, false)
		leaf.position = Vector3(6.5, 2.1, -1.3)
		leaf.rotation_degrees = Vector3(-25, i * 72.0, 0)
	interactable("INT_BAIT_SOIL_HOME", Vector3(6.5, 0, -1.3), Vector3(1.8, 0.5, 1.8))
	# Bamboo clump behind the house.
	for i in 11:
		var p := Vector3(-6.0 + _rng.randf_range(-1.1, 1.1), 0, -8.0 + _rng.randf_range(-1.1, 1.1))
		var stalk := cylinder(root, p, 0.06, _rng.randf_range(4.5, 6.5), C_BAMBOO)
		stalk.rotation_degrees = Vector3(_rng.randf_range(-6, 6), 0, _rng.randf_range(-6, 6))
	interactable("INT_BAMBOO_CLUMP", Vector3(-6, 0, -8), Vector3(2.6, 3.0, 2.6))


func _neighborhood() -> void:
	# Narrow, colourful tube houses along both sides of the road.
	var colors := [Color(0.92, 0.78, 0.35), Color(0.55, 0.72, 0.85), Color(0.88, 0.62, 0.62), Color(0.75, 0.82, 0.62), Color(0.9, 0.9, 0.85)]
	var x := 12.0
	var i := 0
	while x < 48.0:
		var w := _rng.randf_range(4.0, 5.5)
		var h := _rng.randf_range(4.5, 8.5)
		box(root, Vector3(x, 0, 0), Vector3(x + w - 0.3, h, 7), colors[i % colors.size()])
		box(root, Vector3(x + 0.8, 0, 7.0), Vector3(x + 2.2, 2.3, 7.05), C_BLACK, false)
		x += w
		i += 1
	x = -40.0
	while x < -12.0:
		var w := _rng.randf_range(4.0, 5.5)
		box(root, Vector3(x, 0, 0), Vector3(x + w - 0.3, _rng.randf_range(4.0, 7.0), 7), colors[(i + 2) % colors.size()])
		x += w
		i += 1
	x = 14.0
	while x < 46.0:
		var w := _rng.randf_range(4.5, 6.0)
		box(root, Vector3(x, 0, 16.5), Vector3(x + w - 0.3, _rng.randf_range(4.0, 7.5), 24), colors[(i + 1) % colors.size()])
		x += w
		i += 1
	# Roadside rubbish: the discarded inner tube and the old shoe.
	var tube := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.25
	torus.outer_radius = 0.33
	tube.mesh = torus
	tube.material_override = material(C_BLACK)
	tube.position = Vector3(10.5, 0.05, 15.0)
	tube.rotation_degrees.x = 8
	root.add_child(tube)
	interactable("INT_INNER_TUBE", Vector3(10.5, 0, 15.0), Vector3(0.9, 0.5, 0.9))
	for j in 7:
		var p := Vector3(-18 + _rng.randf_range(-1.2, 1.2), 0, 8.4 + _rng.randf_range(-0.8, 0.6))
		var s := _rng.randf_range(0.25, 0.6)
		box(root, p, p + Vector3(s, s * 0.7, s), [Color(0.9, 0.9, 0.9), Color(0.2, 0.4, 0.2), Color(0.3, 0.3, 0.7)][j % 3], false)
	box(root, Vector3(-16.4, 0, 8.6), Vector3(-16.1, 0.12, 9.0), Color(0.35, 0.25, 0.2), false)  # the shoe
	interactable("INT_OLD_SHOE", Vector3(-17.2, 0, 8.7), Vector3(3.0, 0.8, 1.8))
	# Scrap pile (ve chai).
	for j in 12:
		var p := Vector3(38 + _rng.randf_range(-1.4, 1.4), 0, 8.2 + _rng.randf_range(-0.8, 0.5))
		var s := _rng.randf_range(0.2, 0.55)
		box(root, p, p + Vector3(s, s, s * 1.3), [C_RUST, Color(0.5, 0.5, 0.55), Color(0.15, 0.5, 0.35)][j % 3], false)
	interactable("INT_SCRAP_PILE", Vector3(38, 0, 8.0), Vector3(3.2, 0.9, 1.8))


func _canal() -> void:
	# Concrete lips and railings; the water surface is added by _water().
	box(root, Vector3(-30, 0, 16.6), Vector3(8, 0.2, 17.0), C_CONCRETE)
	box(root, Vector3(-30, 0, 23.0), Vector3(8, 0.2, 23.4), C_CONCRETE)
	invisible_wall(Vector3(-30, 0, 16.9), Vector3(8, 2, 17.0))
	box(root, Vector3(-30, -0.4, 17.0), Vector3(8, 0.0, 23.0), C_MUD, false)
	# The old fisherman's stool and bucket are added by his actor.


func _drain() -> void:
	# Concrete lip along both banks, visible inner walls and a muddy floor.
	for bank in [[56.5, 60.0], [80.0, 83.5]]:
		box(root, Vector3(bank[0], 0, 30), Vector3(bank[1], 0.04, 100), C_CONCRETE, false)
	box(root, Vector3(59.9, -3.2, 30), Vector3(60.0, 0, 100), C_CONCRETE_DARK, false)
	box(root, Vector3(80.0, -3.2, 30), Vector3(80.1, 0, 100), C_CONCRETE_DARK, false)
	box(root, Vector3(60, -3.4, 30), Vector3(80, -3.2, 100), C_MUD)
	# Low curb + invisible barrier so the player does not fall in.
	for x in [59.75, 80.0]:
		box(root, Vector3(x, 0, 30), Vector3(x + 0.25, 0.3, 100), C_CONCRETE_DARK)
		invisible_wall(Vector3(x, 0, 30), Vector3(x + 0.25, 1.4, 100))
	invisible_wall(Vector3(60, 0, 29.8), Vector3(80, 1.4, 30.0))
	invisible_wall(Vector3(60, 0, 100.0), Vector3(80, 1.4, 100.2))
	# Landmark: the large concrete pipe in the north wall.
	var ring := cylinder(root, Vector3.ZERO, 2.3, 0.6, C_CONCRETE)
	ring.rotation_degrees.x = 90
	ring.position = Vector3(70, -1.4, 30.1)
	var hole := cylinder(root, Vector3.ZERO, 1.8, 0.62, C_BLACK)
	hole.rotation_degrees.x = 90
	hole.position = Vector3(70, -1.4, 30.12)
	box(root, Vector3(60, -3.2, 29.5), Vector3(80, 0, 30.0), C_CONCRETE_DARK, false)
	interactable("INT_DRAIN_PIPE", Vector3(70, -0.6, 31.5), Vector3(6, 1.2, 1.5)).collision_layer = Interactable.LAYER
	# Small bridge across the channel.
	box(root, Vector3(60, -0.35, 64), Vector3(80, 0.05, 66.5), C_CONCRETE)
	box(root, Vector3(60, 0.05, 63.9), Vector3(80, 1.0, 64.1), C_CONCRETE_DARK)
	box(root, Vector3(60, 0.05, 66.4), Vector3(80, 1.0, 66.6), C_CONCRETE_DARK)
	# Mud patch for bait, the sign, rubbish, grass tufts.
	box(root, Vector3(56.8, 0, 47), Vector3(58.8, 0.05, 49.5), C_MUD, false)
	interactable("INT_BAIT_SOIL_DRAIN", Vector3(57.8, 0, 48.2), Vector3(2.0, 0.4, 2.5))
	cylinder(root, Vector3(55.8, 0, 36), 0.05, 1.6, C_CONCRETE_DARK)
	box(root, Vector3(55.3, 1.3, 35.95), Vector3(56.3, 1.9, 36.05), Color(0.8, 0.8, 0.75), false)
	interactable("INT_DRAIN_SIGN", Vector3(55.8, 0, 36), Vector3(1.2, 2.0, 0.6))
	for j in 14:
		var p := Vector3(_rng.randf_range(54, 58.5), 0, _rng.randf_range(32, 98))
		var s := _rng.randf_range(0.2, 0.45)
		box(root, p, p + Vector3(s, s * 0.6, s), [Color(0.95, 0.95, 0.95), Color(0.2, 0.3, 0.8), Color(0.8, 0.2, 0.2)][j % 3], false)
	for j in 60:
		var side := 54.0 if j % 2 == 0 else 84.0
		var p := Vector3(side + _rng.randf_range(-2.5, 2.0), 0, _rng.randf_range(26, 104))
		box(root, p, p + Vector3(0.25, _rng.randf_range(0.3, 0.8), 0.25), C_LEAF, false)


func _water(data: DataRegistry) -> void:
	for map in data.all("maps"):
		for spot in map.get("fishing_spots", []):
			var r: Array = spot["rect"]
			var wy := float(spot["water_y"])
			var mesh := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
			mesh.mesh = pm
			mesh.material_override = material(Color(0.22, 0.30, 0.22, 0.88), true)
			mesh.position = Vector3((float(r[0]) + float(r[2])) * 0.5, wy, (float(r[1]) + float(r[3])) * 0.5)
			mesh.name = "Water_" + str(spot["id"])
			root.add_child(mesh)


func _bounds() -> void:
	invisible_wall(Vector3(-60, 0, -41), Vector3(120, 10, -40))
	invisible_wall(Vector3(-60, 0, 120), Vector3(120, 10, 121))
	invisible_wall(Vector3(-61, 0, -40), Vector3(-60, 10, 120))
	invisible_wall(Vector3(120, 0, -40), Vector3(121, 10, 120))
