class_name Act3Areas
extends RefCounted
## Act III places (docs/12 §7–8): the fenced fish pond south of the lake (MAP_POND),
## the mountain stream (MAP_STREAM, moving water) and the river (MAP_RIVER).
## Stream and river sit in their own regions, far from everything else, reached by bus.
## Water surfaces come from the fishing spots in data/maps (WorldBuilder._water).

const POND_WATER := Act2Areas.POND_WATER
const POND_FENCE_Z := 100.0
const POND_GAP := [470.0, 473.5]  # BARRIER_POND_GAP in data/maps
const POND_GATE := [560.0, 563.0]  # INT_POND_GATE
const POND_GRASS_EXCLUDE := [
	[468.5, 123.5, 531.5, 171.5],  # pond and banks
	[469.5, 99.0, 474.5, 124.0],   # trodden path from the gap
	[536.0, 125.0, 544.0, 133.0],  # guard hut
]

const STREAM_REGION := [360.0, 240.0, 720.0, 490.0]
const STREAM_BOUNDS := [395.0, 300.0, 600.0, 420.0]
const STREAM_CHANNEL := [360.0, 355.0, 720.0, 367.0]  # SPOT_STREAM_RUN
const STREAM_ROCKS := [Vector3(450, 0, 358.8), Vector3(500, 0, 359.2), Vector3(550, 0, 358.8)]

const RIVER_REGION := [360.0, 490.0, 760.0, 790.0]
const RIVER_BOUNDS := [395.0, 540.0, 700.0, 640.0]
const RIVER_WATER := [360.0, 600.0, 760.0, 690.0]  # SPOT_RIVER_MAIN
const BRIDGE_X := 582.0

var b: WorldBuilder
var stream_region: Node3D
var river_region: Node3D
var _rng := RandomNumberGenerator.new()


func _init(builder: WorldBuilder) -> void:
	b = builder


func build(_data: DataRegistry) -> void:
	_rng.seed = 3003
	var world_root := b.root
	b.root = b.act2.lake_region  # the pond shares the lake's region
	_pond()
	b.root = world_root
	stream_region = b.begin_region("STREAM", STREAM_REGION)
	_stream()
	b.end_region()
	river_region = b.begin_region("RIVER", RIVER_REGION)
	_river()
	b.end_region()


func grass_fields() -> Array:
	return [
		{"parent": stream_region, "area": [398, 303, 597, 354], "exclude": [
			[396, 326, 440, 336],   # road from the bus stop
			[418, 336, 422, 340],   # shrine
			[438, 338, 442, 342],   # bait soil
		]},
		{"parent": river_region, "area": [398, 543, 697, 598], "exclude": [
			[396, 556, 600, 566],   # dike road
			[574, 566, 590, 598],   # path to the bridge foot
			[468, 583, 472, 587],   # bait soil
		]},
	]


# --- The pond (MAP_POND) -------------------------------------------------------------

func _pond() -> void:
	var w: Array = POND_WATER
	var mud := b.surf("mud", Color.WHITE, Color(0.3, 0.24, 0.17))
	b.box(b.root, Vector3(w[0], -2.4, w[1]), Vector3(w[2], -2.2, w[3]), mud)
	for edge in [[w[0] - 1.0, w[1] - 1.0, w[2] + 1.0, w[1]], [w[0] - 1.0, w[3], w[2] + 1.0, w[3] + 1.0],
			[w[0] - 1.0, w[1], w[0], w[3]], [w[2], w[1], w[2] + 1.0, w[3]]]:
		b.box(b.root, Vector3(edge[0], 0, edge[1]), Vector3(edge[2], 0.02, edge[3]), mud, false)
	b.invisible_wall(Vector3(w[0] - 0.2, 0, w[1]), Vector3(w[0], 1.4, w[3]))
	b.invisible_wall(Vector3(w[2], 0, w[1]), Vector3(w[2] + 0.2, 1.4, w[3]))
	b.invisible_wall(Vector3(w[0], 0, w[1] - 0.2), Vector3(w[2], 1.4, w[1]))
	b.invisible_wall(Vector3(w[0], 0, w[3]), Vector3(w[2], 1.4, w[3] + 0.2))
	# The fence between lake and pond: rusty posts and barbed wire, a gap and the owner's gate.
	var rust := b.surf("rust")
	for section in [[Act2Areas.LAKE_RECT[0], POND_GAP[0]], [POND_GAP[1], POND_GATE[0]], [POND_GATE[1], Act2Areas.LAKE_RECT[2]]]:
		var x0: float = section[0]
		var x1: float = section[1]
		var x := x0
		while x <= x1:
			var post := b.cylinder(b.root, Vector3(x, 0, POND_FENCE_Z), 0.04, 1.5, rust)
			post.rotation_degrees.z = _rng.randf_range(-6, 6)
			x += 2.5
		for y in [0.45, 0.9, 1.35]:
			b.box(b.root, Vector3(x0, y, POND_FENCE_Z - 0.01), Vector3(x1, y + 0.015, POND_FENCE_Z + 0.01), Color(0.35, 0.3, 0.28), false)
		b.invisible_wall(Vector3(x0, 0, POND_FENCE_Z - 0.2), Vector3(x1, 1.8, POND_FENCE_Z + 0.2))
	# Torn wire hanging at the gap.
	for k in 3:
		var wire := b.box(b.root, Vector3(0, 0, -0.01), Vector3(1.2, 0.015, 0.01), Color(0.35, 0.3, 0.28), false)
		wire.position = Vector3(POND_GAP[0], 0.45 + k * 0.45, POND_FENCE_Z)
		wire.rotation_degrees.z = -50 - k * 10
	# Trodden path from the gap to the water.
	b.box(b.root, Vector3(470.5, 0, 100.3), Vector3(473.5, 0.02, 124), b.surf("dirt", Color.WHITE, Color(0.45, 0.36, 0.26)), false)
	# Guard hut (chòi canh) on stilts, feeding platform, a boat hull turned upside down.
	var bamboo := b.material(WorldBuilder.C_BAMBOO)
	for c in [[537.5, 126.5], [542.5, 126.5], [537.5, 131.5], [542.5, 131.5]]:
		b.cylinder(b.root, Vector3(c[0], 0, c[1]), 0.08, 1.4, bamboo, true)
	b.box(b.root, Vector3(537, 1.4, 126), Vector3(543, 1.5, 132), b.surf("wood", Color(0.8, 0.7, 0.55)), false)
	for c in [[537.3, 126.3], [542.7, 126.3], [537.3, 131.7], [542.7, 131.7]]:
		b.cylinder(b.root, Vector3(c[0], 1.5, c[1]), 0.05, 1.6, bamboo)
	var thatch := b.box(b.root, Vector3(536.3, 0, 125.3), Vector3(543.7, 0.18, 132.7), Color(0.62, 0.52, 0.3), false)
	thatch.position.y = 3.2
	thatch.rotation_degrees.x = 8
	b.box(b.root, Vector3(539.2, 0, 132.2), Vector3(540.8, 1.45, 132.4), bamboo, false)  # ladder
	b.box(b.root, Vector3(w[2] - 3.0, -0.35, 145), Vector3(w[2] + 0.2, -0.25, 147), b.surf("wood", Color(0.7, 0.6, 0.5)), false)
	var hull := b.box(b.root, Vector3(546, 0, 140), Vector3(551, 0.5, 141.4), b.surf("wood", Color(0.55, 0.45, 0.35)), false)
	hull.rotation_degrees.y = 12
	# Banana plants and bushes: the pond is overgrown, easy to mistake for abandoned.
	for p in [Vector3(465, 0, 118), Vector3(534, 0, 118), Vector3(462, 0, 176), Vector3(520, 0, 180), Vector3(548, 0, 160)]:
		_banana(p)
	for k in 30:
		var p := Vector3(_rng.randf_range(445, 580), 0, _rng.randf_range(104, 196))
		if p.x > w[0] - 3 and p.x < w[2] + 3 and p.z > w[1] - 3 and p.z < w[3] + 3:
			continue
		_bush(p, _rng.randf_range(0.6, 1.3))
	for k in 60:
		var side := k % 4
		var p: Vector3
		match side:
			0: p = Vector3(_rng.randf_range(w[0], w[2]), -0.5, w[1] + _rng.randf_range(0.1, 1.5))
			1: p = Vector3(_rng.randf_range(w[0], w[2]), -0.5, w[3] - _rng.randf_range(0.1, 1.5))
			2: p = Vector3(w[0] + _rng.randf_range(0.1, 1.5), -0.5, _rng.randf_range(w[1], w[3]))
			_: p = Vector3(w[2] - _rng.randf_range(0.1, 1.5), -0.5, _rng.randf_range(w[1], w[3]))
		var reed := b.box(b.root, Vector3(-0.025, 0, -0.025), Vector3(0.025, _rng.randf_range(0.9, 1.8), 0.025), WorldBuilder.C_LEAF, false)
		reed.position = p
		reed.rotation_degrees = Vector3(_rng.randf_range(-12, 12), 0, _rng.randf_range(-12, 12))


# --- The stream (MAP_STREAM) ---------------------------------------------------------

func _stream() -> void:
	var grass := b.surf("grass", Color(0.72, 1.0, 0.6), Color(0.34, 0.45, 0.22))
	var c: Array = STREAM_CHANNEL
	b.ground_with_pits([STREAM_REGION[0], 245, STREAM_REGION[2], 480], [c], grass)
	var rock := b.surf("concrete_old", Color(0.62, 0.63, 0.6), Color(0.45, 0.45, 0.43))
	var mud := b.surf("mud", Color(0.8, 0.78, 0.7), Color(0.3, 0.26, 0.2))
	# Pebble bed and stone-lined banks.
	b.box(b.root, Vector3(c[0], -1.1, c[1]), Vector3(c[2], -0.95, c[3]), mud)
	for z in [c[1], c[3]]:
		var x: float = c[0]
		while x < c[2]:
			var r := _rng.randf_range(0.35, 0.8)
			_rock(Vector3(x, -0.5, z + _rng.randf_range(-0.4, 0.4)), Vector3(r * 1.6, r, r * 1.2), rock)
			x += _rng.randf_range(0.8, 2.2)
	# The three big boulders; slack water (the pools in data) lies just downstream of each.
	for p in STREAM_ROCKS:
		_rock(p + Vector3(0, -0.4, 0), Vector3(2.6, 1.6, 2.2), rock)
		_rock(p + Vector3(-1.2, -0.5, 1.8), Vector3(1.4, 0.9, 1.2), rock)
		for k in 6:  # white water where the current hits the rock
			var foam := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.25
			sm.height = 0.1
			foam.mesh = sm
			foam.material_override = b.material(Color(0.92, 0.95, 0.95, 0.75), true)
			foam.position = p + Vector3(-1.4 - _rng.randf() * 0.6, -0.33, _rng.randf_range(-1.0, 1.0))
			b.root.add_child(foam)
	# Smaller stones scattered in the run.
	for k in 40:
		var p := Vector3(_rng.randf_range(c[0] + 20, c[2] - 20), -0.55, _rng.randf_range(c[1] + 1.5, c[3] - 1.0))
		var r := _rng.randf_range(0.2, 0.5)
		_rock(p, Vector3(r * 1.5, r, r * 1.3), rock)
	b.invisible_wall(Vector3(STREAM_BOUNDS[0], 0, c[1] - 0.2), Vector3(STREAM_BOUNDS[2], 1.4, c[1]))
	# Dirt road from the bus stop, the far bank thick with trees and bamboo, hills behind.
	var dirt := b.surf("dirt", Color.WHITE, Color(0.45, 0.36, 0.26))
	b.box(b.root, Vector3(396, 0, 327), Vector3(440, 0.025, 335), dirt, false)
	for k in 26:
		_bamboo(Vector3(_rng.randf_range(c[0] + 30, c[2] - 30), 0, _rng.randf_range(c[3] + 2, c[3] + 14)))
	var x := STREAM_REGION[0] + 30
	while x < STREAM_REGION[2] - 30:
		b._tree(Vector3(x, 0, _rng.randf_range(c[3] + 14, c[3] + 40)), _rng.randf_range(9.0, 14.0), false)
		x += _rng.randf_range(5.0, 9.0)
	for p in [Vector3(415, 0, 345), Vector3(470, 0, 322), Vector3(530, 0, 330), Vector3(585, 0, 345), Vector3(430, 0, 312)]:
		b._tree(p, _rng.randf_range(7.0, 10.0), true)
	for k in 6:
		_bamboo(Vector3(_rng.randf_range(400, 595), 0, _rng.randf_range(305, 318)))
	_hills(Vector3(540, 0, 470), 7)
	_bounds(STREAM_BOUNDS)
	_ring_trees(STREAM_BOUNDS, [STREAM_BOUNDS[1] - 12, STREAM_BOUNDS[1] - 4], false)


# --- The river (MAP_RIVER) -----------------------------------------------------------

func _river() -> void:
	var grass := b.surf("grass", Color(0.78, 1.0, 0.62), Color(0.36, 0.45, 0.24))
	var w: Array = RIVER_WATER
	b.ground_with_pits([RIVER_REGION[0], 500, RIVER_REGION[2], 780], [w], grass, 6.0)
	var mud := b.surf("mud", Color.WHITE, Color(0.3, 0.24, 0.17))
	b.box(b.root, Vector3(w[0], -5.2, w[1]), Vector3(w[2], -5.0, w[3]), mud)
	# Concrete embankment (kè) on the near bank.
	var concrete := b.surf("concrete_old", Color(0.85, 0.85, 0.8), Color(0.55, 0.55, 0.52))
	b.box(b.root, Vector3(w[0], 0, w[1] - 0.8), Vector3(w[2], 0.3, w[1]), concrete)
	b.box(b.root, Vector3(w[0], -1.2, w[1] - 0.05), Vector3(w[2], 0, w[1] + 0.05), concrete, false)
	b.invisible_wall(Vector3(RIVER_BOUNDS[0], 0, w[1] - 0.4), Vector3(RIVER_BOUNDS[2], 1.4, w[1] - 0.2))
	# Dike road and the path down to the bridge foot.
	var asphalt := b.surf("asphalt", Color.WHITE, Color(0.36, 0.36, 0.37))
	b.box(b.root, Vector3(396, 0, 557), Vector3(RIVER_BOUNDS[2], 0.03, 565), asphalt, false)
	b.box(b.root, Vector3(575, 0, 565), Vector3(589, 0.025, 598), b.surf("dirt", Color.WHITE, Color(0.45, 0.36, 0.26)), false)
	# The concrete bridge: abutment on the near bank, pillars in the water, a deck overhead.
	b.box(b.root, Vector3(BRIDGE_X - 5, 0, w[1] - 6), Vector3(BRIDGE_X + 5, 4.2, w[1] - 3.5), concrete)
	for z in [615.0, 645.0, 675.0]:
		b.box(b.root, Vector3(BRIDGE_X - 4, -5, z - 1.2), Vector3(BRIDGE_X + 4, 3.8, z + 1.2), concrete, false)
	b.box(b.root, Vector3(BRIDGE_X - 4.5, 3.8, w[1] - 6), Vector3(BRIDGE_X + 4.5, 4.4, w[3] + 4), concrete, false)
	for side in [-4.4, 4.2]:
		b.box(b.root, Vector3(BRIDGE_X + side, 4.4, w[1] - 6), Vector3(BRIDGE_X + side + 0.2, 5.3, w[3] + 4), b.surf("rust", Color(0.7, 0.7, 0.75)), false)
	# Two moored wooden boats (ghe) and their bamboo mooring poles.
	for boat in [[520.0, 606.0, 8.0], [650.0, 612.0, -6.0]]:
		_boat(Vector3(boat[0], -1.0, boat[1]), boat[2])
		b.cylinder(b.root, Vector3(boat[0] - 3.5, -3.0, boat[1] - 1.5), 0.06, 5.0, b.material(WorldBuilder.C_BAMBOO))
	# Water hyacinth drifting past.
	for k in 50:
		var pad := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = _rng.randf_range(0.3, 0.7)
		sm.height = 0.25
		pad.mesh = sm
		pad.material_override = b.material(Color(0.22, 0.45, 0.16))
		pad.position = Vector3(_rng.randf_range(w[0] + 20, w[2] - 20), -0.95, _rng.randf_range(w[1] + 4, w[3] - 4))
		b.root.add_child(pad)
	# Bank life: banana plants, bamboo, a tea stall at the bridge foot, the far bank's trees.
	for p in [Vector3(430, 0, 590), Vector3(490, 0, 592), Vector3(620, 0, 590), Vector3(665, 0, 592)]:
		_banana(p)
	for k in 8:
		_bamboo(Vector3(_rng.randf_range(400, 690), 0, _rng.randf_range(543, 552)))
	var tarp := b.box(b.root, Vector3(592, 0, 568), Vector3(597, 0.04, 572), Color(0.15, 0.35, 0.7), false)
	tarp.position.y = 2.4
	for cpos in [[592.2, 568.2], [596.8, 568.2], [592.2, 571.8], [596.8, 571.8]]:
		b.cylinder(b.root, Vector3(cpos[0], 0, cpos[1]), 0.04, 2.4, Color(0.55, 0.55, 0.58))
	b.stool(Vector3(593.5, 0, 570), 0.25, Color(0.85, 0.15, 0.15))
	b.stool(Vector3(595.5, 0, 570), 0.25, Color(0.15, 0.35, 0.8))
	var x := RIVER_REGION[0] + 20
	while x < RIVER_REGION[2] - 20:
		b._tree(Vector3(x, 0, _rng.randf_range(w[3] + 8, w[3] + 40)), _rng.randf_range(9.0, 14.0), false)
		x += _rng.randf_range(5.0, 9.0)
	for p in [Vector3(440, 0, 575), Vector3(520, 0, 575), Vector3(640, 0, 575), Vector3(690, 0, 585)]:
		b._tree(p, _rng.randf_range(7.0, 10.0), true)
	_bounds(RIVER_BOUNDS)
	_ring_trees(RIVER_BOUNDS, [RIVER_BOUNDS[1] - 12, RIVER_BOUNDS[1] - 4], false)


# --- Props -------------------------------------------------------------------------------

func _rock(center: Vector3, size: Vector3, surface) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 6
	m.mesh = sm
	m.material_override = surface
	m.scale = size
	m.position = center
	m.rotation_degrees.y = _rng.randf_range(0, 180)
	b.root.add_child(m)


func _bush(p: Vector3, size: float) -> void:
	for k in 3:
		var m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = size * 0.6
		sm.height = size
		m.mesh = sm
		m.material_override = b.material(WorldBuilder.C_LEAF.darkened(0.08 * k))
		m.position = p + Vector3(_rng.randf_range(-0.5, 0.5) * size, size * 0.4, _rng.randf_range(-0.5, 0.5) * size)
		b.root.add_child(m)


func _banana(p: Vector3) -> void:
	b.cylinder(b.root, p, 0.13, 2.2, b.surf("bark", Color(0.8, 0.9, 0.6)))
	for i in 6:
		var leaf := b.box(b.root, Vector3(-0.2, -0.01, 0), Vector3(0.2, 0.01, 1.6), WorldBuilder.C_LEAF, false)
		leaf.position = p + Vector3(0, 2.1, 0)
		leaf.rotation_degrees = Vector3(-20 - _rng.randf() * 15, i * 60.0 + _rng.randf() * 20, 0)


func _bamboo(p: Vector3) -> void:
	for i in 7:
		var q := p + Vector3(_rng.randf_range(-1.0, 1.0), 0, _rng.randf_range(-1.0, 1.0))
		var h := _rng.randf_range(5.0, 8.0)
		var stalk := b.cylinder(b.root, q, 0.055, h, WorldBuilder.C_BAMBOO)
		stalk.rotation_degrees = Vector3(_rng.randf_range(-8, 8), 0, _rng.randf_range(-8, 8))
		for j in 3:
			var tuft := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.75
			sm.height = 1.3
			tuft.mesh = sm
			tuft.material_override = b.material(WorldBuilder.C_LEAF.darkened(0.06 * j))
			tuft.position = q + Vector3(_rng.randf_range(-0.6, 0.6), h - 0.4 - j * 0.9, _rng.randf_range(-0.6, 0.6))
			b.root.add_child(tuft)


func _boat(p: Vector3, yaw: float) -> void:
	var boat := Node3D.new()
	boat.position = p
	boat.rotation_degrees.y = yaw
	b.root.add_child(boat)
	var wood := b.surf("wood", Color(0.6, 0.5, 0.4), Color(0.35, 0.25, 0.18))
	b.box(boat, Vector3(-3.0, -0.15, -0.7), Vector3(3.0, 0.05, 0.7), wood, false)
	for z in [-0.72, 0.62]:
		b.box(boat, Vector3(-3.0, 0.05, z), Vector3(3.0, 0.45, z + 0.1), wood, false)
	for x in [-3.0, 2.9]:
		b.box(boat, Vector3(x, 0.05, -0.7), Vector3(x + 0.1, 0.55, 0.7), wood, false)
	var cover := b.box(boat, Vector3(-1.0, 0, -0.8), Vector3(1.0, 0.05, 0.8), Color(0.35, 0.3, 0.22), false)
	cover.position.y = 1.2


## Distant hills (núi) behind the stream.
func _hills(center: Vector3, count: int) -> void:
	for k in count:
		var m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = 16
		sm.rings = 8
		m.mesh = sm
		m.material_override = b.material(Color(0.2, 0.32, 0.18).lerp(Color(0.28, 0.4, 0.26), _rng.randf()))
		var r := _rng.randf_range(40, 70)
		m.scale = Vector3(r * 1.4, r * 0.55, r)
		m.position = center + Vector3((k - count * 0.5) * 55 + _rng.randf_range(-15, 15), -r * 0.1, _rng.randf_range(0, 40))
		b.root.add_child(m)


func _bounds(r: Array) -> void:
	b.invisible_wall(Vector3(r[0], 0, r[1]), Vector3(r[2], 10, r[1] + 1))
	b.invisible_wall(Vector3(r[0], 0, r[3] - 1), Vector3(r[2], 10, r[3]))
	b.invisible_wall(Vector3(r[0], 0, r[1]), Vector3(r[0] + 1, 10, r[3]))
	b.invisible_wall(Vector3(r[2] - 1, 0, r[1]), Vector3(r[2], 10, r[3]))


## Tall trees just outside the back and side walls.
func _ring_trees(r: Array, back_z: Array, _collide: bool) -> void:
	var x: float = r[0] - 10
	while x < r[2] + 10:
		b._tree(Vector3(x, 0, _rng.randf_range(back_z[0], back_z[1])), _rng.randf_range(8.0, 13.0), false)
		x += _rng.randf_range(5.0, 9.0)
	var z: float = r[1]
	while z < r[3]:
		for xx in [_rng.randf_range(r[0] - 14, r[0] - 5), _rng.randf_range(r[2] + 5, r[2] + 14)]:
			b._tree(Vector3(xx, 0, z), _rng.randf_range(8.0, 13.0), false)
		z += _rng.randf_range(6.0, 10.0)
