class_name Interactable
extends StaticBody3D
## A physical object the player can look at and use. Behaviour comes from
## data/interactables via InteractionSystem; this node only carries the id.

const LAYER := 2

var interactable_id: String = ""


static func create(id: String, size: Vector3, offset: Vector3 = Vector3.ZERO) -> Interactable:
	var body := Interactable.new()
	body.interactable_id = id
	body.name = id
	body.collision_layer = 1 | LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = offset
	body.add_child(shape)
	return body
