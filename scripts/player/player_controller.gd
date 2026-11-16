extends CharacterBody3D
## First-person walking and look. Touch: drag left half to move, right half to look.
## Desktop testing: WASD + mouse; Escape releases the captured mouse.

const WALK_SPEED := 3.2
const LOOK_SENSITIVITY := 0.003
const TOUCH_LOOK_SENSITIVITY := 0.006
const GRAVITY := 9.8

var _pitch := 0.0
var _touch_positions: Dictionary = {}
var _look_finger := -1
var _move_finger := -1
var _move_origin := Vector2.ZERO
var _move_vector := Vector2.ZERO
var _camera: Camera3D

func _ready() -> void:
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.8
	capsule.shape = shape
	capsule.position.y = 0.9
	add_child(capsule)

	_camera = Camera3D.new()
	_camera.position = Vector3(0, 1.62, 0)
	_camera.current = true
	_camera.fov = 78.0
	add_child(_camera)
	floor_snap_length = 0.25

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative, LOOK_SENSITIVITY)
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _physics_process(delta: float) -> void:
	var input_2d := Vector2.ZERO
	if _move_finger != -1:
		input_2d = _move_vector
	else:
		input_2d = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (global_transform.basis * Vector3(input_2d.x, 0, input_2d.y)).normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_positions[event.index] = event.position
		var half := get_viewport().get_visible_rect().size.x * 0.5
		if event.position.x < half and _move_finger == -1:
			_move_finger = event.index
			_move_origin = event.position
			_move_vector = Vector2.ZERO
		elif _look_finger == -1:
			_look_finger = event.index
	else:
		_touch_positions.erase(event.index)
		if event.index == _move_finger:
			_move_finger = -1
			_move_vector = Vector2.ZERO
		if event.index == _look_finger:
			_look_finger = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _move_finger:
		_move_vector = (event.position - _move_origin).limit_length(70.0) / 70.0
	elif event.index == _look_finger:
		_apply_look(event.relative, TOUCH_LOOK_SENSITIVITY)

func _apply_look(relative: Vector2, sensitivity: float) -> void:
	rotation.y -= relative.x * sensitivity
	_pitch = clampf(_pitch - relative.y * sensitivity, deg_to_rad(-80), deg_to_rad(80))
	_camera.rotation.x = _pitch
