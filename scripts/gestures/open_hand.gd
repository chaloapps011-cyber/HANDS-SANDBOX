extends RefCounted
const Math = preload("res://scripts/gestures/gesture_math.gd")
static func evaluate(points: Array) -> bool:
	if not Math.valid(points):
		return false
	return Math.finger_extended(points, 4, 3) and Math.finger_extended(points, 8, 6) and Math.finger_extended(points, 12, 10) and Math.finger_extended(points, 16, 14) and Math.finger_extended(points, 20, 18)
