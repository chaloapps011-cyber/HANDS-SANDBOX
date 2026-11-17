extends Node3D
## Android startup gate: show the existing permission screen before instantiating the game world.
const PermissionScreen = preload("res://scripts/startup/permission_screen.gd")
const WorldScript = preload("res://scripts/world/main_world.gd")

var _world_started := false
var _permission_screen: CanvasLayer

func _ready() -> void:
	if not OS.has_feature("android"):
		_start_world()
		return
	_permission_screen = PermissionScreen.new()
	_permission_screen.name = "PermissionScreen"
	_permission_screen.completed.connect(_on_permissions_completed, CONNECT_ONE_SHOT)
	add_child(_permission_screen)

func _on_permissions_completed() -> void:
	_permission_screen = null
	_start_world()

func _start_world() -> void:
	if _world_started:
		return
	_world_started = true
	var world := WorldScript.new()
	world.name = "SandboxWorld"
	add_child(world)
