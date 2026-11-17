extends Node3D
## Polls real Android MediaPipe frames. Permission is requested by the startup screen.
signal hands_updated(hands: Array)
signal tracking_state_changed(active: bool)

const HANDS_TRACKING_SINGLETON := "HandsTracking"
const STALE_AFTER_SECONDS := 0.75

var _bridge: Object
var _last_timestamp := -1
var _was_active := false
var _indicator: MeshInstance3D
var _indicator_material: StandardMaterial3D
var _camera: Camera3D

func _ready() -> void:
	_create_world_indicator()
	_camera = get_viewport().get_camera_3d()
	if not OS.has_feature("android"):
		return
	if not Engine.has_singleton(HANDS_TRACKING_SINGLETON):
		push_warning("Native HandsTracking plugin is not installed in this Android export. Tracking remains unavailable.")
		return
	_bridge = Engine.get_singleton(HANDS_TRACKING_SINGLETON)
	if _bridge.has_camera_permission():
		_bridge.start_tracking()

func _process(_delta: float) -> void:
	if _bridge == null:
		return
	var frame: Dictionary = _bridge.get_latest_frame()
	var timestamp := int(frame.get("timestamp_ms", -1))
	var hands: Array = frame.get("hands", [])
	var fresh := timestamp >= 0 and float(Time.get_ticks_msec() - timestamp) / 1000.0 <= STALE_AFTER_SECONDS
	var active := bool(frame.get("camera_active", false)) and fresh and not hands.is_empty()
	if timestamp != _last_timestamp and timestamp >= 0:
		_last_timestamp = timestamp
		hands_updated.emit(hands if active else [])
	elif _was_active and not active:
		hands_updated.emit([])
	if active != _was_active:
		_was_active = active
		tracking_state_changed.emit(active)
	_update_indicator(active)

func _exit_tree() -> void:
	if _bridge != null:
		_bridge.stop_tracking()

func _create_world_indicator() -> void:
	_indicator = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.045
	sphere.height = 0.09
	_indicator.mesh = sphere
	_indicator_material = StandardMaterial3D.new()
	_indicator_material.albedo_color = Color(0.35, 0.35, 0.35)
	_indicator_material.emission_enabled = true
	_indicator_material.emission = Color(0.1, 0.1, 0.1)
	_indicator.material_override = _indicator_material
	add_child(_indicator)

func _update_indicator(active: bool) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if _camera != null:
		_indicator.global_position = _camera.global_position + (-_camera.global_transform.basis.z * 0.35) + (_camera.global_transform.basis.x * 0.24) + (-_camera.global_transform.basis.y * 0.20)
	_indicator_material.albedo_color = Color(0.15, 0.95, 0.30) if active else Color(0.35, 0.35, 0.35)
	_indicator_material.emission = Color(0.08, 0.65, 0.12) if active else Color(0.08, 0.08, 0.08)
