class_name Act2Areas
extends RefCounted
## Act II places (docs/12): the fishing shop, the scrap yard and the morning market on
## the home road, and MAP_LAKE far to the east (x 395–585), reached only by bus.
## Also places every interactable whose data carries a "position", with a small visual.
##
## Uses WorldBuilder's primitives so materials and colliders stay consistent.

const LAKE_RECT := [395.0, -85.0, 585.0, 85.0]  # playable bounds (matches LOC_LAKE)
const LAKE_WATER := [440.0, -45.0, 540.0, 45.0]  # SPOT_LAKE_MAIN
const PIER_Z := 1.2  # pier half-width, centred on z = 0
const PIER_END := 454.0

## Grass-free rectangles for the lake grass field.
const LAKE_GRASS_EXCLUDE := [
	[439.0, -46.0, 541.0, 46.0],   # water and banks
	[414.0, -16.0, 440.0, -9.0],   # bus stop and path
	[426.0, -2.0, 440.0, 2.0],     # path to the pier
	[430.0, 16.5, 434.0, 19.5],    # bait soil
]

var b: WorldBuilder
var placed: Dictionary = {}  # interactable id -> visual Node3D (hidden while depleted)


func _init(builder: WorldBuilder) -> void:
	b = builder


func build(data: DataRegistry) -> void:
	_fishing_shop()
	_scrap_yard()
	_market()
	_lake()
	_place_interactables(data)


# --- Home road ------------------------------------------------------------------

func _fishing_shop() -> void:
	# Narrow shop house x 49.5–54.5, front (z = 7) open onto the road under an awning.
	var walls := b.surf("plaster", Color(0.72, 0.86, 0.80), Color(0.6, 0.72, 0.68))
	b.box(b.root, Vector3(49.5, 0, 0), Vector3(54.5, 6.8, 1.0), walls)
	b.box(b.root, Vector3(49.5, 0, 0), Vector3(49.8, 6.8, 7.0), walls)
	b.box(b.root, Vector3(54.2, 0, 0), Vector3(54.5, 6.8, 7.0), walls)
	b.box(b.root, Vector3(49.5, 3.0, 6.7), Vector3(54.5, 6.8, 7.0), walls)
	b.box(b.root, Vector3(49.8, 3.0, 1.0), Vector3(54.2, 3.1, 6.7), walls, false)  # ceiling
	b.box(b.root, Vector3(49.8, 0, 1.0), Vector3(54.2, 0.04, 7.0), b.surf("tiles", Color(0.9, 0.88, 0.84)), false)
	# Rods standing along the back wall, tackle boxes on shelves.
	var rng := RandomNumberGenerator.new()
	rng.seed = 49
	var x := 50.1
	while x < 54.0:
		var rod := b.cylinder(b.root, Vector3(x, 0.05, 1.25), 0.018, rng.randf_range(2.4, 2.9), [Color(0.1, 0.1, 0.12), Color(0.5, 0.35, 0.2), Color(0.2, 0.3, 0.55)][rng.randi() % 3])
		rod.rotation_degrees.x = -6
		x += 0.22
	for side in [49.85, 53.85]:
		for shelf in [0.9, 1.5, 2.1]:
			b.box(b.root, Vector3(side, shelf, 2.0), Vector3(side + 0.3, shelf + 0.04, 6.2), b.surf("wood", Color.WHITE, Color(0.45, 0.32, 0.2)), false)
			for k in 6:
				var z := 2.2 + k * 0.65
				b.box(b.root, Vector3(side + 0.03, shelf + 0.04, z), Vector3(side + 0.27, shelf + 0.24, z + 0.4), [Color(0.85, 0.3, 0.1), Color(0.2, 0.55, 0.3), Color(0.9, 0.8, 0.2), Color(0.25, 0.4, 0.8)][(k + int(shelf * 10)) % 4], false)
	# Glass counter beside the doorway, bait fridge, awning and sign.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.7, 0.85, 0.9, 0.35)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	b.box(b.root, Vector3(50.0, 0, 6.3), Vector3(51.3, 0.95, 6.9), glass)
	b.box(b.root, Vector3(53.0, 0, 5.6), Vector3(54.1, 1.0, 6.5), Color(0.92, 0.92, 0.9))
	var awning := b.box(b.root, Vector3(49.3, 0, 7.0), Vector3(54.7, 0.05, 9.2), Color(0.15, 0.45, 0.7), false)
	awning.position.y = 2.9
	awning.rotation_degrees.x = 10
	_sign_board(Vector3(52.0, 3.6, 7.05), "ĐỒ CÂU  •  MỒI", Color(0.1, 0.35, 0.65), 4.6)


func _scrap_yard() -> void:
	# Corrugated fence around x 62–78, z -4–8, open to the road; a tin shelter at the back.
	var tin := b.surf("tin_roof", Color(0.9, 0.9, 0.9), Color(0.5, 0.4, 0.35))
	b.box(b.root, Vector3(62, 0, -4.2), Vector3(78, 2.2, -4.0), tin)
	b.box(b.root, Vector3(61.8, 0, -4.2), Vector3(62, 2.2, 8.0), tin)
	b.box(b.root, Vector3(78, 0, -4.2), Vector3(78.2, 2.2, 8.0), tin)
	b.box(b.root, Vector3(62, 0, 7.8), Vector3(66.5, 2.2, 8.0), tin)
	b.box(b.root, Vector3(73.5, 0, 7.8), Vector3(78, 2.2, 8.0), tin)
	b.box(b.root, Vector3(62, 0, -4), Vector3(78, 0.03, 7.8), b.surf("concrete_old", Color(0.8, 0.8, 0.76)), false)
	for px in [63.0, 70.0, 77.0]:
		b.cylinder(b.root, Vector3(px, 0, 2.8), 0.07, 3.1, b.surf("rust"), true)
	var roof := b.box(b.root, Vector3(62.2, 0, -4.0), Vector3(77.8, 0.06, 3.0), tin, false)
	roof.position.y = 3.2
	roof.rotation_degrees.x = -5
	# Piles: sacks of bottles, flattened cardboard, cans, a heap of rusty metal.
	var rng := RandomNumberGenerator.new()
	rng.seed = 62
	var rust := b.surf("rust")
	for pile in [[64.5, -1.5, 0], [67.5, -2.3, 1], [74.5, -1.8, 2], [76.2, 1.0, 3]]:
		for k in 16:
			var p := Vector3(pile[0] + rng.randf_range(-1.3, 1.3), 0, pile[1] + rng.randf_range(-1.0, 1.0))
			var s := rng.randf_range(0.3, 0.7)
			match int(pile[2]):
				0:  # plastic sacks
					var sack := MeshInstance3D.new()
					var sm := SphereMesh.new()
					sm.radius = s * 0.7
					sm.height = s * 1.2
					sack.mesh = sm
					sack.material_override = b.material([Color(0.9, 0.9, 0.92), Color(0.3, 0.45, 0.75), Color(0.85, 0.85, 0.7)][k % 3])
					sack.position = p + Vector3(0, s * 0.5 + floorf(k / 6.0) * 0.35, 0)
					b.root.add_child(sack)
				1:  # cardboard stacks
					b.box(b.root, p + Vector3(0, floorf(k / 5.0) * 0.12, 0), p + Vector3(s * 1.4, floorf(k / 5.0) * 0.12 + 0.1, s), Color(0.62, 0.48, 0.32), false)
				2:  # cans
					b.box(b.root, p, p + Vector3(s * 0.5, s * 0.4, s * 0.5), [Color(0.75, 0.75, 0.78), Color(0.8, 0.15, 0.15), Color(0.15, 0.5, 0.2)][k % 3], false)
				3:  # metal
					var bar := b.box(b.root, Vector3.ZERO, Vector3(s * 2.0, 0.08, 0.08), rust, false)
					bar.position = p + Vector3(0, 0.05 + (k % 4) * 0.08, 0)
					bar.rotation_degrees.y = rng.randf_range(0, 180)
	# The scale (cân đồng hồ) in front of the scrap collector's stool.
	b.box(b.root, Vector3(70.9, 0, 5.8), Vector3(71.5, 0.12, 6.4), Color(0.2, 0.3, 0.6), false)
	b.box(b.root, Vector3(71.05, 0.12, 5.9), Vector3(71.35, 0.5, 6.2), Color(0.85, 0.2, 0.15), false)
	var dial := b.cylinder(b.root, Vector3.ZERO, 0.16, 0.04, Color(0.95, 0.95, 0.92))
	dial.rotation_degrees.x = 90
	dial.position = Vector3(71.2, 0.42, 6.22)
	b.stool(Vector3(70.0, 0, 6.6), 0.42, Color(0.15, 0.55, 0.3))
	_sign_board(Vector3(70.0, 2.6, 8.05), "VE CHAI  •  PHẾ LIỆU", Color(0.55, 0.12, 0.08), 6.5)


func _market() -> void:
	# Morning market on the south side of the road: concrete slab, stalls under tarps.
	b.box(b.root, Vector3(83, 0, 14.3), Vector3(101, 0.05, 23.5), b.surf("concrete_old", Color(0.85, 0.85, 0.8)), false)
	var tarps := [Color(0.85, 0.2, 0.15), Color(0.15, 0.35, 0.75), Color(0.95, 0.7, 0.1), Color(0.2, 0.55, 0.3)]
	var i := 0
	for sx in [85.0, 91.5, 98.0]:
		for sz in [16.2, 21.2]:
			var tarp := b.box(b.root, Vector3(sx - 2.6, 0, sz - 1.9), Vector3(sx + 2.6, 0.04, sz + 1.9), tarps[i % tarps.size()], false)
			tarp.position.y = 2.5
			tarp.rotation_degrees.x = 4 if sz < 18 else -4
			for cx in [-2.4, 2.4]:
				for cz in [-1.7, 1.7]:
					b.cylinder(b.root, Vector3(sx + cx, 0, sz + cz), 0.04, 2.5, Color(0.55, 0.55, 0.58))
			i += 1
	# Fish stall: aluminium basins of water with fish, a board, the vendor's stool.
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.2, 0.26, 0.24)
	water.metallic = 0.3
	water.roughness = 0.1
	var tin := StandardMaterial3D.new()
	tin.albedo_color = Color(0.72, 0.73, 0.75)
	tin.metallic = 0.8
	tin.roughness = 0.35
	for bx in [86.6, 87.8, 89.0]:
		b.cylinder(b.root, Vector3(bx, 0, 16.4), 0.5, 0.22, tin, true)
		b.cylinder(b.root, Vector3(bx, 0.05, 16.4), 0.46, 0.15, water)
		for f in 3:
			var fish := MeshInstance3D.new()
			var fm := SphereMesh.new()
			fm.radius = 0.06
			fm.height = 0.12
			fish.mesh = fm
			fish.scale = Vector3(0.8, 0.7, 2.4)
			fish.material_override = b.material(Color(0.5, 0.52, 0.45))
			fish.position = Vector3(bx - 0.2 + f * 0.2, 0.22, 16.4 + (f - 1) * 0.12)
			fish.rotation_degrees.y = f * 50.0
			b.root.add_child(fish)
	b.box(b.root, Vector3(89.6, 0, 16.2), Vector3(90.6, 0.55, 16.9), b.surf("wood", Color.WHITE, Color(0.45, 0.32, 0.2)))
	b.stool(Vector3(88.0, 0, 17.4), 0.3, Color(0.85, 0.15, 0.15))
	# Vegetable stall: baskets of greens.
	for vx in [93.4, 94.5, 95.6]:
		b.vegetable_basket(Vector3(vx, 0.02, 16.5))
	b.stool(Vector3(94.5, 0, 17.4), 0.3, Color(0.15, 0.35, 0.8))
	# Other stalls (fruit, dry goods) — closed crates stacked.
	for crate in [[84.2, 21.0], [85.6, 21.4], [91.0, 20.8], [97.4, 20.9], [98.8, 21.3], [97.8, 16.3]]:
		var p := Vector3(crate[0], 0, crate[1])
		b.box(b.root, p, p + Vector3(0.9, 0.5, 0.6), b.surf("wood", Color(0.9, 0.8, 0.7), Color(0.55, 0.42, 0.28)))
		for f in 5:
			var fruit := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.09
			sm.height = 0.18
			fruit.mesh = sm
			fruit.material_override = b.material([Color(0.95, 0.6, 0.1), Color(0.85, 0.15, 0.2), Color(0.5, 0.75, 0.2)][int(crate[0]) % 3])
			fruit.position = p + Vector3(0.15 + f * 0.15, 0.56, 0.3)
			b.root.add_child(fruit)


# --- The lake ----------------------------------------------------------------------

func _lake() -> void:
	var grass := b.surf("grass", Color(0.78, 1.0, 0.62), Color(0.36, 0.45, 0.24))
	var w: Array = LAKE_WATER
	# Ground slabs around the lake pit (the far ground is part of them).
	b.box(b.root, Vector3(360, -4, -220), Vector3(w[0], 0, 220), grass)
	b.box(b.root, Vector3(w[2], -4, -220), Vector3(720, 0, 220), grass)
	b.box(b.root, Vector3(w[0], -4, -220), Vector3(w[2], 0, w[1]), grass)
	b.box(b.root, Vector3(w[0], -4, w[3]), Vector3(w[2], 0, 220), grass)
	var mud := b.surf("mud", Color.WHITE, Color(0.3, 0.24, 0.17))
	b.box(b.root, Vector3(w[0], -3.2, w[1]), Vector3(w[2], -3.0, w[3]), mud)
	# Muddy banks: a thin rim at the waterline around the whole lake.
	for edge in [[w[0] - 1.2, w[1] - 1.2, w[2] + 1.2, w[1]], [w[0] - 1.2, w[3], w[2] + 1.2, w[3] + 1.2],
			[w[0] - 1.2, w[1], w[0], w[3]], [w[2], w[1], w[2] + 1.2, w[3]]]:
		b.box(b.root, Vector3(edge[0], 0, edge[1]), Vector3(edge[2], 0.02, edge[3]), mud, false)
	# Walls stop the player at the waterline, with a gap for the pier.
	b.invisible_wall(Vector3(w[0] - 0.2, 0, w[1]), Vector3(w[0], 1.4, -PIER_Z))
	b.invisible_wall(Vector3(w[0] - 0.2, 0, PIER_Z), Vector3(w[0], 1.4, w[3]))
	b.invisible_wall(Vector3(w[2], 0, w[1]), Vector3(w[2] + 0.2, 1.4, w[3]))
	b.invisible_wall(Vector3(w[0], 0, w[1] - 0.2), Vector3(w[2], 1.4, w[1]))
	b.invisible_wall(Vector3(w[0], 0, w[3]), Vector3(w[2], 1.4, w[3] + 0.2))
	_pier()
	# Dirt paths: bus stop → pier.
	var dirt := b.surf("dirt", Color.WHITE, Color(0.45, 0.36, 0.26))
	b.box(b.root, Vector3(410, 0, -15), Vector3(424, 0.025, -10.5), dirt, false)
	b.box(b.root, Vector3(421, 0, -11), Vector3(424.5, 0.025, 1.6), dirt, false)
	b.box(b.root, Vector3(421, 0, -1.6), Vector3(w[0], 0.025, 1.6), dirt, false)
	# A roadside drinks stall (quán nước) by the bus stop: tarp, low table, stools.
	var tarp := b.box(b.root, Vector3(408, 0, -21), Vector3(413, 0.04, -17), Color(0.2, 0.5, 0.3), false)
	tarp.position.y = 2.4
	for c in [[408.2, -20.8], [412.8, -20.8], [408.2, -17.2], [412.8, -17.2]]:
		b.cylinder(b.root, Vector3(c[0], 0, c[1]), 0.04, 2.4, Color(0.55, 0.55, 0.58))
	b.box(b.root, Vector3(409.8, 0, -19.6), Vector3(411.2, 0.45, -18.6), b.surf("wood", Color.WHITE, Color(0.45, 0.32, 0.2)))
	for s in [[409.3, -19.1, Color(0.85, 0.15, 0.15)], [411.7, -19.1, Color(0.15, 0.35, 0.8)], [410.5, -20.2, Color(0.85, 0.15, 0.15)]]:
		b.stool(Vector3(s[0], 0, s[1]), 0.25, s[2])
	b.box(b.root, Vector3(408.4, 0, -20.6), Vector3(409.2, 1.0, -20.0), Color(0.9, 0.9, 0.9))  # cooler
	# The lake fisherman's spot: folding chair, bait box and landing net.
	b.box(b.root, Vector3(437.6, 0, -21.4), Vector3(438.2, 0.3, -21.0), Color(0.3, 0.45, 0.3), false)
	b.cylinder(b.root, Vector3(438.4, 0, -23.2), 0.02, 1.6, Color(0.3, 0.3, 0.3)).rotation_degrees.z = 40
	_lake_trees()
	_lake_reeds()
	b.invisible_wall(Vector3(LAKE_RECT[0], 0, LAKE_RECT[1]), Vector3(LAKE_RECT[2], 10, LAKE_RECT[1] + 1))
	b.invisible_wall(Vector3(LAKE_RECT[0], 0, LAKE_RECT[3] - 1), Vector3(LAKE_RECT[2], 10, LAKE_RECT[3]))
	b.invisible_wall(Vector3(LAKE_RECT[0], 0, LAKE_RECT[1]), Vector3(LAKE_RECT[0] + 1, 10, LAKE_RECT[3]))
	b.invisible_wall(Vector3(LAKE_RECT[2] - 1, 0, LAKE_RECT[1]), Vector3(LAKE_RECT[2], 10, LAKE_RECT[3]))


func _pier() -> void:
	# Old wooden fishing pier (cầu câu) from the west bank out over the water.
	var wood := b.surf("wood", Color(0.95, 0.85, 0.72), Color(0.45, 0.32, 0.2))
	var dark := b.surf("wood", Color(0.55, 0.45, 0.38), Color(0.3, 0.22, 0.15))
	var x := LAKE_WATER[0] - 3.0
	while x < PIER_END:
		var plank := b.box(b.root, Vector3(x, 0.02, -PIER_Z), Vector3(x + 0.28, 0.14, PIER_Z), wood, false)
		plank.rotation_degrees.y = randf_range(-1.0, 1.0)
		x += 0.31
	# One collider for the whole deck, beams underneath and posts into the water.
	b.box(b.root, Vector3(LAKE_WATER[0] - 3.0, -0.2, -PIER_Z), Vector3(PIER_END, 0.12, PIER_Z), dark, true)
	for px in range(int(LAKE_WATER[0]), int(PIER_END) + 1, 3):
		for pz in [-PIER_Z + 0.1, PIER_Z - 0.1]:
			b.cylinder(b.root, Vector3(px, -3.0, pz), 0.09, 3.1, dark)
	for pz in [-PIER_Z, PIER_Z - 0.08]:
		b.box(b.root, Vector3(LAKE_WATER[0], 0.14, pz), Vector3(PIER_END, 0.26, pz + 0.08), dark, false)
	b.invisible_wall(Vector3(LAKE_WATER[0], 0, -PIER_Z - 0.2), Vector3(PIER_END, 1.4, -PIER_Z))
	b.invisible_wall(Vector3(LAKE_WATER[0], 0, PIER_Z), Vector3(PIER_END, 1.4, PIER_Z + 0.2))
	b.invisible_wall(Vector3(PIER_END, 0, -PIER_Z - 0.2), Vector3(PIER_END + 0.2, 1.4, PIER_Z + 0.2))


func _lake_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 440
	# Shade trees on the banks, a ring of tall trees along the boundary.
	for p in [Vector3(425, 0, -30), Vector3(430, 0, 35), Vector3(410, 0, 10), Vector3(460, 0, -60),
			Vector3(500, 0, -58), Vector3(530, 0, 60), Vector3(470, 0, 62), Vector3(560, 0, -10), Vector3(555, 0, 30)]:
		b._tree(p, rng.randf_range(7.0, 10.0), true)
	var x := LAKE_RECT[0] - 10.0
	while x < LAKE_RECT[2] + 10.0:
		for z in [rng.randf_range(-100, -90), rng.randf_range(90, 100)]:
			b._tree(Vector3(x, 0, z), rng.randf_range(8.0, 13.0), false)
		x += rng.randf_range(5.0, 9.0)
	var z2 := LAKE_RECT[1]
	while z2 < LAKE_RECT[3]:
		for xx in [rng.randf_range(LAKE_RECT[0] - 15, LAKE_RECT[0] - 5), rng.randf_range(LAKE_RECT[2] + 5, LAKE_RECT[2] + 15)]:
			b._tree(Vector3(xx, 0, z2), rng.randf_range(8.0, 13.0), false)
		z2 += rng.randf_range(5.0, 9.0)


func _lake_reeds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 441
	var w: Array = LAKE_WATER
	for j in 160:
		var p: Vector3
		match j % 4:
			0: p = Vector3(rng.randf_range(w[0], w[2]), -0.6, w[1] + rng.randf_range(0.1, 2.5))
			1: p = Vector3(rng.randf_range(w[0], w[2]), -0.6, w[3] - rng.randf_range(0.1, 2.5))
			2: p = Vector3(w[2] - rng.randf_range(0.1, 2.5), -0.6, rng.randf_range(w[1], w[3]))
			_: p = Vector3(w[0] + rng.randf_range(0.1, 2.5), -0.6, rng.randf_range(w[1], w[3]))
		if absf(p.z) < PIER_Z + 3.0 and p.x < PIER_END + 2.0:
			continue  # keep the pier clear
		var reed := b.box(b.root, Vector3(-0.025, 0, -0.025), Vector3(0.025, rng.randf_range(1.0, 2.0), 0.025), WorldBuilder.C_LEAF, false)
		reed.position = p
		reed.rotation_degrees = Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12))
	# Lily pads.
	for j in 40:
		var pad := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = rng.randf_range(0.2, 0.4)
		cm.bottom_radius = cm.top_radius
		cm.height = 0.01
		cm.radial_segments = 10
		pad.mesh = cm
		pad.material_override = b.material(Color(0.2, 0.42, 0.15))
		pad.position = Vector3(rng.randf_range(w[2] - 20, w[2] - 2), -0.585, rng.randf_range(w[1] + 2, w[3] - 2))
		b.root.add_child(pad)


# --- Data-placed interactables -----------------------------------------------------

func _place_interactables(data: DataRegistry) -> void:
	for def in data.all("interactables"):
		if not def.has("position"):
			continue
		var p: Array = def["position"]
		var s: Array = def.get("size", [1.0, 1.0, 1.0])
		var pos := Vector3(float(p[0]), float(p[1]), float(p[2]))
		b.interactable(str(def["id"]), pos, Vector3(float(s[0]), float(s[1]), float(s[2])))
		var visual := _visual(str(def.get("visual", "")), pos, str(def.get("name", "")), str(def["id"]).hash())
		if visual:
			placed[str(def["id"])] = visual


func _visual(kind: String, pos: Vector3, label: String, seed: int) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var node := Node3D.new()
	node.position = pos
	b.root.add_child(node)
	match kind:
		"scrap":
			for k in 7:
				var q := Vector3(rng.randf_range(-0.45, 0.35), 0, rng.randf_range(-0.45, 0.35))
				var sz := rng.randf_range(0.12, 0.3)
				if k % 2 == 0:  # bottles lying on their side
					var bottle := b.cylinder(node, Vector3.ZERO, sz * 0.3, sz * 1.4, b.material([Color(0.85, 0.92, 0.95, 0.7), Color(0.3, 0.6, 0.35, 0.8)][(k % 4) >> 1], true))
					bottle.rotation_degrees = Vector3(90, rng.randf_range(0, 180), 0)
					bottle.position = q + Vector3(0, sz * 0.3, 0)
				else:
					b.box(node, q, q + Vector3(sz, sz * 0.6, sz), [Color(0.7, 0.7, 0.72), Color(0.8, 0.15, 0.15), Color(0.62, 0.48, 0.32)][k % 3], false)
		"metal":
			var rust := b.surf("rust")
			for k in 6:
				var bar := b.box(node, Vector3.ZERO, Vector3(rng.randf_range(0.6, 1.1), 0.06, 0.06), rust, false)
				bar.position = Vector3(rng.randf_range(-0.4, 0.0), 0.04 + k * 0.05, rng.randf_range(-0.3, 0.3))
				bar.rotation_degrees.y = rng.randf_range(0, 180)
		"mud":
			b.box(node, Vector3(-1.0, 0, -1.0), Vector3(1.0, 0.04, 1.0), b.surf("mud", Color.WHITE, Color(0.3, 0.24, 0.17)), false)
		"sign":
			b.cylinder(node, Vector3.ZERO, 0.04, 1.8, b.surf("rust"))
			b.box(node, Vector3(-0.45, 1.3, -0.03), Vector3(0.45, 1.8, 0.03), Color(0.95, 0.95, 0.9), false)
			var text := Label3D.new()
			text.text = label
			text.font_size = 22
			text.pixel_size = 0.004
			text.modulate = Color(0.15, 0.15, 0.2)
			text.outline_size = 0
			text.position = Vector3(0, 1.55, 0.04)
			text.width = 200
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			node.add_child(text)
			var back := text.duplicate() as Label3D
			back.position.z = -0.04
			back.rotation_degrees.y = 180
			node.add_child(back)
		"bus_stop":
			var steel := b.surf("rust", Color(0.55, 0.6, 0.7))
			for cx in [-1.3, 1.3]:
				b.cylinder(node, Vector3(cx, 0, -0.5), 0.05, 2.5, steel)
			b.box(node, Vector3(-1.5, 2.5, -1.0), Vector3(1.5, 2.58, 0.4), Color(0.2, 0.4, 0.75), false)
			b.box(node, Vector3(-1.3, 0.5, -0.8), Vector3(1.3, 2.4, -0.75), b.material(Color(0.7, 0.85, 0.9, 0.35), true), false)
			b.box(node, Vector3(-1.1, 0, -0.6), Vector3(1.1, 0.45, -0.25), b.surf("concrete_old", Color(0.85, 0.85, 0.8)), false)
			b.cylinder(node, Vector3(1.8, 0, 0.2), 0.04, 2.4, steel)
			b.box(node, Vector3(1.55, 2.0, 0.17), Vector3(2.05, 2.4, 0.23), Color(0.1, 0.35, 0.75), false)
			var text := Label3D.new()
			text.text = "XE BUÝT"
			text.font_size = 36
			text.pixel_size = 0.003
			text.position = Vector3(1.8, 2.2, 0.24)
			node.add_child(text)
		_:
			node.queue_free()
			return null
	return node


## A shop signboard across a facade, with the name in big letters.
func _sign_board(center: Vector3, text: String, color: Color, width: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.25
	b.box(b.root, center + Vector3(-width * 0.5, -0.35, 0), center + Vector3(width * 0.5, 0.35, 0.1), mat, false)
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = 0.006
	label.modulate = Color(1.0, 0.97, 0.85)
	label.outline_size = 8
	label.outline_modulate = color.darkened(0.5)
	label.position = center + Vector3(0, 0, 0.12)
	b.root.add_child(label)
