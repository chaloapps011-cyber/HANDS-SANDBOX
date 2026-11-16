extends Node3D
## Stage 001 environment assembly plus the Stage 002 ragdoll spawn entry point.

const FloorModule = preload("res://scripts/world/floor.gd")
const TableModule = preload("res://scripts/world/table.gd")
const PlayerModule = preload("res://scripts/player/player_controller.gd")
const BlockModule = preload("res://scripts/objects/physical_block.gd")
const RagdollModule = preload("res://scripts/objects/ragdoll.gd")

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

## Public factory: each call adds a completely independent articulated ragdoll.
func spawn_ragdoll(at: Vector3) -> Node3D:
	var ragdoll: Node3D = RagdollModule.new()
	ragdoll.position = at
	add_child(ragdoll)
	return ragdoll
