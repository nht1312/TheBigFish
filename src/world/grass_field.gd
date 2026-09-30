class_name GrassField
extends RefCounted
## Scatters grass tufts as MultiMesh chunks. Each chunk is only drawn near the
## camera (visibility range), so dense grass stays cheap on modest GPUs.

const CHUNK := 12.0
const TUFT_BLADES := 11

var density: float = 5.0  # tufts per m²
var view_distance: float = 42.0
var _mesh: ArrayMesh
var _material: ShaderMaterial


func _init(p_density: float = 5.0, p_view_distance: float = 42.0) -> void:
	density = p_density
	view_distance = p_view_distance
	_mesh = _tuft_mesh()
	_material = ShaderMaterial.new()
	_material.shader = load("res://src/world/shaders/grass.gdshader")


## area: [x0, z0, x1, z1]; exclude: list of [x0, z0, x1, z1] kept clear (roads, yards, water).
func build(parent: Node3D, area: Array, exclude: Array, rng: RandomNumberGenerator) -> int:
	var total := 0
	var x := float(area[0])
	while x < float(area[2]):
		var z := float(area[1])
		while z < float(area[3]):
			total += _chunk(parent, x, z, exclude, rng)
			z += CHUNK
		x += CHUNK
	return total


func _chunk(parent: Node3D, x0: float, z0: float, exclude: Array, rng: RandomNumberGenerator) -> int:
	var points: Array[Vector3] = []
	var wanted := int(CHUNK * CHUNK * density)
	for i in wanted:
		var p := Vector3(x0 + rng.randf() * CHUNK, 0.0, z0 + rng.randf() * CHUNK)
		if not _excluded(p, exclude):
			points.append(p)
	if points.is_empty():
		return 0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _mesh
	mm.instance_count = points.size()
	var center := Vector3(x0 + CHUNK * 0.5, 0, z0 + CHUNK * 0.5)
	for i in points.size():
		var s := rng.randf_range(0.6, 1.35)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s))
		mm.set_instance_transform(i, Transform3D(basis, points[i] - center))
		var shade := rng.randf_range(0.75, 1.15)
		var dry := rng.randf() * 0.25  # some sun-dried blades
		mm.set_instance_color(i, Color(shade + dry, shade + dry * 0.6, shade * (1.0 - dry)))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = _material
	node.position = center
	node.visibility_range_end = view_distance
	node.visibility_range_end_margin = 6.0
	node.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return points.size()


func _excluded(p: Vector3, exclude: Array) -> bool:
	for r in exclude:
		if p.x >= float(r[0]) and p.x <= float(r[2]) and p.z >= float(r[1]) and p.z <= float(r[3]):
			return true
	return false


## A tuft: several tapered, slightly bent blades fanned around the origin.
func _tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for b in TUFT_BLADES:
		var angle := rng.randf() * TAU
		var dir := Vector3(cos(angle), 0, sin(angle))
		var side := dir.cross(Vector3.UP).normalized()
		var root := dir * rng.randf_range(0.0, 0.12)
		var height := rng.randf_range(0.12, 0.34)
		var lean := dir * rng.randf_range(0.04, 0.2)
		var width := 0.022
		var segments := 3
		for s in segments:
			var t0 := float(s) / segments
			var t1 := float(s + 1) / segments
			var p0 := root + Vector3.UP * height * t0 + lean * t0 * t0
			var p1 := root + Vector3.UP * height * t1 + lean * t1 * t1
			var w0 := width * (1.0 - t0)
			var w1 := width * (1.0 - t1)
			var a := p0 - side * w0
			var bb := p0 + side * w0
			var c := p1 + side * w1
			var d := p1 - side * w1
			for v in [[a, t0], [bb, t0], [c, t1], [a, t0], [c, t1], [d, t1]]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(0.5, v[1]))
				st.add_vertex(v[0])
	return st.commit()
