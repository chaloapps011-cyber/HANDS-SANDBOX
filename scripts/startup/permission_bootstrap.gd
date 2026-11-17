extends Node3D
## Startup gate: only creates the existing game world after the permission intro is completed.
const PermissionScreen = preload("res://scripts/startup/permission_screen.gd")
const WorldScript = preload("res://scripts/world/main_world.gd")

var _world_started := false

func _ready() -> void:
	if not OS.has_feature("android"):
		_start_world()
		return
	var permission_screen := PermissionScreen.new()
	permission_screen.completed.connect(_on_permissions_completed, CONNECT_ONE_SHOT)
	add_child(permission_screen)

func _on_permissions_completed() -> void:
	_start_world()

func _start_world() -> void:
	if _world_started:
		return
	_world_started = true
	var world := WorldScript.new()
	world.name = "SandboxWorld"
	add_child(world)
