extends Node3D
## Gesture routing from real MediaPipe frames only. Rays require a direct object hit.
const OpenHand = preload("res://scripts/gestures/open_hand.gd")
const Heart = preload("res://scripts/gestures/heart.gd")
const Math = preload("res://scripts/gestures/gesture_math.gd")
const HOLD_SECONDS := 0.18
const RELEASE_SECONDS := 0.12
const GRAB_SPRING := 28.0
const GRAB_DAMPING := 7.0
const MAX_RAY_DISTANCE := 12.0

var tracking_source: Node
var world: Node3D
var _camera: Camera3D
var _latest_hands: Dictionary = {}
var _gesture_state := {"Left": {}, "Right": {}}
var _held_body: RigidBody3D
var _held_hand_side := ""
var _hold_distance := 1.5
var _grab_active := false

func _ready() -> void:
	_camera = get_viewport().get_camera_3d()
	for side in ["Left", "Right"]:
		_gesture_state[side] = {"candidate": "", "candidate_time": 0.0, "active": "", "release_time": 0.0}
	if tracking_source != null:
		tracking_source.hands_updated.connect(_on_hands_updated)

func _on_hands_updated(hands: Array) -> void:
	_latest_hands.clear()
	for value in hands:
		if value is Dictionary:
			var hand: Dictionary = value
			var side := str(hand.get("side", "Unknown"))
			if side in ["Left", "Right"] and Math.valid(hand.get("landmarks", [])):
				_latest_hands[side] = hand

func _process(delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	for side in ["Left", "Right"]:
		var detected := _detect(_latest_hands.get(side, {}))
		_update_stable_gesture(side, detected, delta)
		if _gesture_state[side]["active"] == "pinch" and _latest_hands.has(side):
			_update_grab(side)
	if not _latest_hands.has(_held_hand_side):
		release_object()

func _detect(hand: Dictionary) -> String:
	if hand.is_empty() or float(hand.get("confidence", 0.0)) < 0.55:
		return ""
	var points: Array = hand.get("landmarks", [])
	if Heart.evaluate(points):
		return "heart"
	if OpenHand.evaluate(points):
		return "wave"
	var palm_width := maxf(Math.distance(points, 5, 17), 0.04)
	if Math.distance(points, 4, 8) / palm_width < 0.30:
		return "pinch"
	return ""

func _update_stable_gesture(side: String, detected: String, delta: float) -> void:
	var state: Dictionary = _gesture_state[side]
	if detected == state["candidate"] and detected != "":
		state["candidate_time"] += delta
	else:
		state["candidate"] = detected
		state["candidate_time"] = 0.0
	if state["active"] == "" and detected != "" and state["candidate_time"] >= HOLD_SECONDS:
		state["active"] = detected
		_on_gesture_started(side, detected)
	elif state["active"] != "" and detected != state["active"]:
		state["release_time"] += delta
		if state["release_time"] >= RELEASE_SECONDS:
			var old_gesture: String = state["active"]
			state["active"] = ""
			state["release_time"] = 0.0
			_on_gesture_ended(side, old_gesture)
	else:
		state["release_time"] = 0.0
	_gesture_state[side] = state

func _on_gesture_started(side: String, gesture: String) -> void:
	var hand: Dictionary = _latest_hands.get(side, {})
	match gesture:
		"wave":
			_select_under_hand(hand)
		"heart":
			if world != null:
				world.group_selected_objects()
		"pinch":
			_grab_active = true
			_held_hand_side = side
			_held_body = _raycast_hand(hand, false)
			if _held_body != null:
				_hold_distance = _camera.global_position.distance_to(_held_body.global_position)

func _on_gesture_ended(side: String, gesture: String) -> void:
	if gesture == "pinch" and side == _held_hand_side:
		release_object()

func _select_under_hand(hand: Dictionary) -> void:
	if world == null or hand.is_empty():
		return
	var body := _raycast_hand(hand, false)
	if body != null:
		world.select_object(body)

func _update_grab(side: String) -> void:
	if not _grab_active or _held_body == null or not is_instance_valid(_held_body) or _camera == null:
		return
	var hand: Dictionary = _latest_hands.get(side, {})
	var points: Array = hand.get("landmarks", [])
	var pinch_point := (Math.point(points, 4) + Math.point(points, 8)) * 0.5
	var screen_size := get_viewport().get_visible_rect().size
	var screen := Vector2(pinch_point.x * screen_size.x, pinch_point.y * screen_size.y)
	var target := _camera.project_ray_origin(screen) + _camera.project_ray_normal(screen) * _hold_distance
	var error := (target - _held_body.global_position).limit_length(2.0)
	_held_body.apply_central_force(error * GRAB_SPRING - _held_body.linear_velocity * GRAB_DAMPING)

## Release without changing linear/angular velocity or sleeping state.
func release_object() -> void:
	_held_body = null
	_held_hand_side = ""
	_grab_active = false

func _raycast_hand(hand: Dictionary, ragdoll_only: bool) -> RigidBody3D:
	if _camera == null or hand.is_empty():
		return null
	var points: Array = hand.get("landmarks", [])
	if not Math.valid(points):
		return null
	var palm := Math.point(points, 0)
	var screen_size := get_viewport().get_visible_rect().size
	var screen := Vector2(palm.x * screen_size.x, palm.y * screen_size.y)
	var origin := _camera.project_ray_origin(screen)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + _camera.project_ray_normal(screen) * MAX_RAY_DISTANCE)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var node: Node = result.get("collider")
	while node != null and not (node is RigidBody3D):
		node = node.get_parent()
	if not (node is RigidBody3D):
		return null
	var body := node as RigidBody3D
	if ragdoll_only:
		return body if body.is_in_group("ragdoll_parts") else null
	return body if body.is_in_group("sandbox_objects") or body.is_in_group("ragdoll_parts") else null
