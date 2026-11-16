extends RigidBody3D
## Reusable rigid physical block, ready for adding more physical props in later stages.
const Baseplate = preload("res://scripts/materials/baseplate.gd")

@export var tint := Color(0.78, 0.30, 0.18)
@export var edge_length := 0.48

func _ready() -> void:
	mass = 0.65
	continuous_cd = true
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * edge_length
	var collider := CollisionShape3D.new()
	collider.shape = box
	add_child(collider)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * edge_length
	mesh_instance.mesh = mesh
	mesh_instance.material_override = Baseplate.make(tint, 0.75)
	add_child(mesh_instance)

	var physics_material := PhysicsMaterial.new()
	physics_material.bounce = 0.08
	physics_material.friction = 0.8
	physics_material_override = physics_material
