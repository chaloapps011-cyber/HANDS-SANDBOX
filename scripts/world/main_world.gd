extends Node3D
## Stage 001-004 world, physical grouping, and tracked-hand interactions.
const FloorModule = preload("res://scripts/world/floor.gd")
const TableModule = preload("res://scripts/world/table.gd")
const PlayerModule = preload("res://scripts/player/player_controller.gd")
const BlockModule = preload("res://scripts/objects/physical_block.gd")
const RagdollModule = preload("res://scripts/objects/ragdoll.gd")
const PhysicalObjectModule = preload("res://scripts/objects/physical_object.gd")
const HandTrackingModule = preload("res://scripts/input/hand_tracking_bridge.gd")
const GestureInteraction = preload("res://scripts/gestures/gesture_interaction.gd")
const WorldMenu = preload("res://scripts/ui/world_menu_3d.gd")

var selected_object: RigidBody3D
var gravity_enabled := true
var active_tool := "select"
var _grouped_objects: Array[RigidBody3D] = []
var _group_counter := 1
var _interaction: Node

func _ready() -> void:
	_build_environment()
	add_child(FloorModule.new())
	add_child(TableModule.new())
	var player = PlayerModule.new()
	player.position = Vector3(0, 0, 5)
	add_child(player)
	_add_block(Vector3(0.0, 1.15, 0.0), Color(0.78, 0.30, 0.18))
	_add_block(Vector3(0.32, 1.15, 0.0), Color(0.22, 0.48, 0.72))
	_add_block(Vector3(0.0, 2.15, 0.0), Color(0.80, 0.68, 0.24))
	spawn_ragdoll(Vector3(3.2, 0, 0))
	_spawn_sample_stack()
	var tracking := HandTrackingModule.new()
	add_child(tracking)
	_interaction = GestureInteraction.new()
	_interaction.tracking_source = tracking
	_interaction.world = self
	add_child(_interaction)
	var menu := WorldMenu.new()
	menu.world = self
	menu.camera = player.get_node("Camera3D")
	add_child(menu)

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

func select_object(body: RigidBody3D) -> void:
	if body == null or not is_instance_valid(body):
		return
	if not body.is_in_group("sandbox_objects") and not body.is_in_group("ragdoll_parts"):
		return
	selected_object = body
	if body.is_in_group("sandbox_objects") and body not in _grouped_objects:
		_grouped_objects.append(body)

## Group rigid bodies using pin constraints, never by reparenting them mid-simulation.
## Joint creation is deferred so the physics space is not modified during a query/callback.
func group_selected_objects() -> void:
	_grouped_objects = _valid_group_members()
	if _grouped_objects.size() < 2:
		_show_world_message("Precisa de outro objeto!", selected_object.global_position if selected_object != null and is_instance_valid(selected_object) else Vector3.ZERO)
		return
	var group_id := "physical_group_%04d" % _group_counter
	_group_counter += 1
	var members := _grouped_objects.duplicate()
	_grouped_objects.clear()
	call_deferred("_create_group_constraints", members, group_id)

func _valid_group_members() -> Array[RigidBody3D]:
	var valid: Array[RigidBody3D] = []
	for body in _grouped_objects:
		if is_instance_valid(body) and body.is_in_group("sandbox_objects") and body not in valid:
			valid.append(body)
	return valid

func _create_group_constraints(members: Array[RigidBody3D], group_id: String) -> void:
	if not is_inside_tree() or members.size() < 2:
		return
	for body in members:
		if not is_instance_valid(body):
			return
		body.set_meta("physical_group_id", group_id)
		body.add_to_group(group_id)
	# A spanning chain of pin joints preserves each body's world transform and lets each remain a RigidBody.
	for index in range(1, members.size()):
		var a := members[index - 1]
		var b := members[index]
		var joint := PinJoint3D.new()
		joint.name = "GroupPin_" + group_id + "_%02d" % index
		add_child(joint)
		joint.global_position = (a.global_position + b.global_position) * 0.5
		joint.node_a = joint.get_path_to(a)
		joint.node_b = joint.get_path_to(b)

func _show_world_message(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 30
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.global_position = at + Vector3.UP * 0.7
	add_child(label)
	get_tree().create_timer(1.4).timeout.connect(func(): if is_instance_valid(label): label.queue_free())

func spawn_ragdoll(at: Vector3) -> Node3D:
	var ragdoll: Node3D = RagdollModule.new()
	ragdoll.position = at
	add_child(ragdoll)
	return ragdoll
