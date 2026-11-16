extends Node3D
## Physics-only ragdoll. Segment bodies remain independent RigidBody3D nodes.
const YELLOW := Color(1.0, 0.78, 0.08)
const JOINT_SOFTNESS := 0.8
const JOINT_BIAS := 0.3
const JOINT_RELAXATION := 1.0
var _parts: Dictionary = {}

func _ready() -> void:
	_build_body()

func _build_body() -> void:
	_add_part("Pelvis", Vector3(0, 1.03, 0), Vector3(0.23, 0.30, 0.16), Vector3.ZERO, 1.4)
	_add_part("Torso", Vector3(0, 1.43, 0), Vector3(0.25, 0.62, 0.18), Vector3.ZERO, 2.2)
	_add_part("Head", Vector3(0, 1.91, 0), Vector3(0.17, 0.34, 0.16), Vector3.ZERO, 0.75)
	_add_joint("Pelvis", "Torso", Vector3(0, 1.23, 0), 0.48, 0.28)
	_add_joint("Torso", "Head", Vector3(0, 1.75, 0), 0.42, 0.22)
	for side in [-1, 1]:
		var suffix := "L" if side < 0 else "R"
		var x := float(side)
		_add_part("Thigh" + suffix, Vector3(x * 0.17, 0.76, 0), Vector3(0.105, 0.42, 0.105), Vector3.ZERO, 0.9)
		_add_part("Shin" + suffix, Vector3(x * 0.17, 0.36, 0), Vector3(0.085, 0.40, 0.085), Vector3.ZERO, 0.7)
		_add_part("Foot" + suffix, Vector3(x * 0.17, 0.105, -0.075), Vector3(0.09, 0.24, 0.12), Vector3(-PI / 2.0, 0, 0), 0.35)
		_add_joint("Pelvis", "Thigh" + suffix, Vector3(x * 0.17, 0.90, 0), 0.68, 0.3)
		_add_joint("Thigh" + suffix, "Shin" + suffix, Vector3(x * 0.17, 0.55, 0), 0.12, 0.10)
		_add_joint("Shin" + suffix, "Foot" + suffix, Vector3(x * 0.17, 0.16, 0), 0.30, 0.18)
		_add_part("UpperArm" + suffix, Vector3(x * 0.43, 1.43, 0), Vector3(0.095, 0.37, 0.095), Vector3(0, 0, -x * PI / 2.0), 0.55)
		_add_part("Forearm" + suffix, Vector3(x * 0.68, 1.17, 0), Vector3(0.078, 0.34, 0.078), Vector3(0, 0, -x * PI / 2.0), 0.4)
		_add_part("Hand" + suffix, Vector3(x * 0.84, 0.96, 0), Vector3(0.10, 0.20, 0.09), Vector3(0, 0, -x * PI / 2.0), 0.22)
		_add_joint("Torso", "UpperArm" + suffix, Vector3(x * 0.30, 1.57, 0), 0.55, 0.35)
		_add_joint("UpperArm" + suffix, "Forearm" + suffix, Vector3(x * 0.56, 1.30, 0), 0.18, 0.12)
		_add_joint("Forearm" + suffix, "Hand" + suffix, Vector3(x * 0.78, 1.04, 0), 0.35, 0.20)

func _add_part(part_name: String, at: Vector3, dimensions: Vector3, rotation: Vector3, part_mass: float) -> void:
	var body := RigidBody3D.new()
	body.name = part_name
	body.position = at
	body.rotation = rotation
	body.mass = part_mass
	body.linear_damp = 0.15
	body.angular_damp = 0.35
	body.continuous_cd = true
	body.can_sleep = true
	var shape := CapsuleShape3D.new()
	shape.radius = dimensions.x
	shape.height = maxf(dimensions.y, dimensions.x * 2.0)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = dimensions.x
	mesh.height = shape.height
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = YELLOW
	material.roughness = 0.72
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var physics_material := PhysicsMaterial.new()
	physics_material.friction = 0.72
	physics_material.bounce = 0.03
	body.physics_material_override = physics_material
	body.add_to_group("ragdoll_parts")
	body.set_meta("ragdoll_root_id", get_instance_id())
	add_child(body)
	_parts[part_name] = body

func _add_joint(part_a: String, part_b: String, anchor: Vector3, swing_limit: float, twist_limit: float) -> void:
	var body_a: RigidBody3D = _parts.get(part_a)
	var body_b: RigidBody3D = _parts.get(part_b)
	if body_a == null or body_b == null:
		push_error("Ragdoll joint has missing body: %s -> %s" % [part_a, part_b])
		return
	var joint := ConeTwistJoint3D.new()
	joint.name = part_a + "To" + part_b
	add_child(joint)
	joint.global_transform = Transform3D(global_transform.basis, global_transform * anchor)
	joint.node_a = joint.get_path_to(body_a)
	joint.node_b = joint.get_path_to(body_b)
	joint.swing_span = swing_limit
	joint.twist_span = twist_limit
	joint.bias = JOINT_BIAS
	joint.softness = JOINT_SOFTNESS
	joint.relaxation = JOINT_RELAXATION
	body_a.add_collision_exception_with(body_b)

func apply_impact(impulse: Vector3, world_position: Vector3) -> void:
	var closest: RigidBody3D
	var closest_distance := INF
	for body: RigidBody3D in _parts.values():
		var distance := body.global_position.distance_squared_to(world_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = body
	if closest != null:
		closest.apply_impulse(impulse, world_position - closest.global_position)
