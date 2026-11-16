extends StaticBody3D
## Large, collidable baseplate floor.
const Baseplate = preload("res://scripts/materials/baseplate.gd")

func _ready() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(32, 32)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = Baseplate.make(Color(0.48, 0.50, 0.52), 0.8)
	add_child(mesh_instance)

	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(32, 0.2, 32)
	collider.shape = shape
	collider.position.y = -0.1
	add_child(collider)
