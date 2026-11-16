extends RigidBody3D
## Configurable independent rigid object for the Stage 003 construction system.

const Baseplate = preload("res://scripts/materials/baseplate.gd")

enum ShapeType { CUBE, SPHERE, CYLINDER, BASEPLATE_BLOCK }

@export var shape_type: ShapeType = ShapeType.CUBE
@export var object_size := Vector3(0.5, 0.5, 0.5)
@export var tint := Color(0.25, 0.58, 0.86)
@export_range(0.05, 100.0, 0.05) var object_mass := 1.0
@export_range(0.0, 1.0, 0.01) var friction := 0.75
@export_range(0.0, 1.0, 0.01) var elasticity := 0.08
@export var use_baseplate_material := false

var object_id: StringName
static var _next_object_number := 1

func _ready() -> void:
	object_id = StringName("sandbox_object_%04d" % _next_object_number)
	_next_object_number += 1
	set_meta("sandbox_object_id", object_id)
	add_to_group("sandbox_objects")
	mass = maxf(object_mass, 0.05)
	continuous_cd = true
	can_sleep = true
	linear_damp = 0.05
	angular_damp = 0.08
	
	var safe_size := Vector3(maxf(object_size.x, 0.1), maxf(object_size.y, 0.1), maxf(object_size.z, 0.1))
	var collider := CollisionShape3D.new()
	var mesh_instance := MeshInstance3D.new()
	var mesh: PrimitiveMesh

	match shape_type:
		ShapeType.SPHERE:
			var radius := maxf(safe_size.x, maxf(safe_size.y, safe_size.z)) * 0.5
			var sphere_shape := SphereShape3D.new()
			sphere_shape.radius = radius
			collider.shape = sphere_shape
			var sphere_mesh := SphereMesh.new()
			sphere_mesh.radius = radius
			sphere_mesh.height = radius * 2.0
			mesh = sphere_mesh
		ShapeType.CYLINDER:
			var radius := maxf(safe_size.x, safe_size.z) * 0.5
			var cylinder_shape := CylinderShape3D.new()
			cylinder_shape.radius = radius
			cylinder_shape.height = safe_size.y
			collider.shape = cylinder_shape
			var cylinder_mesh := CylinderMesh.new()
			cylinder_mesh.top_radius = radius
			cylinder_mesh.bottom_radius = radius
			cylinder_mesh.height = safe_size.y
			mesh = cylinder_mesh
		_:
			var box_shape := BoxShape3D.new()
			box_shape.size = safe_size
			collider.shape = box_shape
			var box_mesh := BoxMesh.new()
			box_mesh.size = safe_size
			mesh = box_mesh

	add_child(collider)
	mesh_instance.mesh = mesh
	if use_baseplate_material or shape_type == ShapeType.BASEPLATE_BLOCK:
		mesh_instance.material_override = Baseplate.make(tint, 0.8)
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.roughness = 0.72
		mesh_instance.material_override = material
	add_child(mesh_instance)

	var physics_material := PhysicsMaterial.new()
	physics_material.friction = friction
	physics_material.bounce = elasticity
	physics_material_override = physics_material
