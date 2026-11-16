extends StaticBody3D
## Simple low-poly table with collision on the top and each leg.
const Baseplate = preload("res://scripts/materials/baseplate.gd")

const TOP_SIZE := Vector3(3.2, 0.22, 2.2)
const TOP_Y := 1.05
const LEG_HEIGHT := 1.0

func _ready() -> void:
	_add_box("Tabletop", Vector3(0, TOP_Y, 0), TOP_SIZE, Color(0.77, 0.39, 0.20))
	var leg_size := Vector3(0.18, LEG_HEIGHT, 0.18)
	for x in [-1.4, 1.4]:
		for z in [-0.9, 0.9]:
			_add_box("Leg", Vector3(x, LEG_HEIGHT / 2.0, z), leg_size, Color(0.68, 0.31, 0.17))

func _add_box(label: String, at: Vector3, dimensions: Vector3, tint: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.material_override = Baseplate.make(tint, 0.65)
	mesh_instance.position = at
	mesh_instance.name = label + "Mesh"
	add_child(mesh_instance)

	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collider.shape = shape
	collider.position = at
	collider.name = label + "Collision"
	add_child(collider)
