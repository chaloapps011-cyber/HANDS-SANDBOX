extends Node3D
## Stage 001-003 world plus optional native Stage 004 hand-tracking bridge.

const FloorModule = preload("res://scripts/world/floor.gd")
const TableModule = preload("res://scripts/world/table.gd")
const PlayerModule = preload("res://scripts/player/player_controller.gd")
const BlockModule = preload("res://scripts/objects/physical_block.gd")
const RagdollModule = preload("res://scripts/objects/ragdoll.gd")
const PhysicalObjectModule = preload("res://scripts/objects/physical_object.gd")
const HandTrackingModule = preload("res://scripts/input/hand_tracking_bridge.gd")

func _ready() -> void:
	_build_environment()
	add_child(FloorModule.new())
	var table = TableModule.new()
	table.position = Vector3(0, 0, 0)
	add_child(table)
	var player = PlayerModule.new()
	player.position = Vector3(0, 0, 5)
	add_child(player)
	_add_block(Vector3(0.0, 1.15, 0.0), Color(0.78, 0.30, 0.18))
	_add_block(Vector3(0.32, 1.15, 0.0), Color(0.22, 0.48, 0.72))
	_add_block(Vector3(0.0, 2.15, 0.0), Color(0.80, 0.68, 0.24))
	spawn_ragdoll(Vector3(3.2, 0, 0))
	_spawn_sample_stack()
	add_child(HandTrackingModule.new())

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var requested_shape := -1
	match event.keycode:
		KEY_1:
			requested_shape = PhysicalObjectModule.ShapeType.CUBE
		KEY_2:
			requested_shape = PhysicalObjectModule.ShapeType.SPHERE
		KEY_3:
			requested_shape = PhysicalObjectModule.ShapeType.CYLINDER
		KEY_4:
			requested_shape = PhysicalObjectModule.ShapeType.BASEPLATE_BLOCK
	if requested_shape < 0:
		return
	var forward := -camera.global_transform.basis.z
	var spawn_at := camera.global_position + forward * 2.0
	spawn_at.y = maxf(spawn_at.y, 0.8)
	var yaw := camera.global_rotation.y
	spawn_physical_object(requested_shape, spawn_at, Vector3(0, yaw, 0))

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.58, 0.63, 0.72)
	environment.ambient_light_energy = 0.55
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -32, 0)
	sun.light_color = Color(1.0, 0.91, 0.78)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 35.0
	add_child(sun)

func _add_block(at: Vector3, tint: Color) -> void:
	var block = BlockModule.new()
	block.position = at
	block.tint = tint
	add_child(block)

## Creates one physics-independent object. Shape uses PhysicalObjectModule.ShapeType.
func spawn_physical_object(shape_type: int, at: Vector3, object_rotation: Vector3 = Vector3.ZERO, object_size: Vector3 = Vector3(0.5, 0.5, 0.5), tint: Color = Color(0.25, 0.58, 0.86), object_mass: float = 1.0, friction: float = 0.75, elasticity: float = 0.08, use_baseplate_material: bool = false) -> RigidBody3D:
	var object: RigidBody3D = PhysicalObjectModule.new()
	object.shape_type = shape_type
	object.position = at
	object.rotation = object_rotation
	object.object_size = object_size
	object.tint = tint
	object.object_mass = object_mass
	object.friction = friction
	object.elasticity = elasticity
	object.use_baseplate_material = use_baseplate_material
	add_child(object)
	return object

func _spawn_sample_stack() -> void:
	spawn_physical_object(PhysicalObjectModule.ShapeType.BASEPLATE_BLOCK, Vector3(-3.2, 0.28, 0), Vector3.ZERO, Vector3(0.56, 0.56, 0.56), Color(0.82, 0.32, 0.22), 1.0, 0.8, 0.05, true)
	spawn_physical_object(PhysicalObjectModule.ShapeType.CUBE, Vector3(-3.2, 0.84, 0), Vector3.ZERO, Vector3(0.48, 0.48, 0.48), Color(0.22, 0.52, 0.82), 0.8, 0.65, 0.1)
	spawn_physical_object(PhysicalObjectModule.ShapeType.SPHERE, Vector3(-3.2, 1.42, 0), Vector3.ZERO, Vector3(0.44, 0.44, 0.44), Color(0.86, 0.68, 0.20), 0.6, 0.45, 0.18)
	spawn_physical_object(PhysicalObjectModule.ShapeType.CYLINDER, Vector3(-3.2, 2.04, 0), Vector3.ZERO, Vector3(0.42, 0.52, 0.42), Color(0.32, 0.72, 0.47), 0.9, 0.7, 0.06)

func spawn_ragdoll(at: Vector3) -> Node3D:
	var ragdoll: Node3D = RagdollModule.new()
	ragdoll.position = at
	add_child(ragdoll)
	return ragdoll
