extends RefCounted
const Math = preload("res://scripts/gestures/gesture_math.gd")
static func evaluate(points: Array) -> bool:
	if not Math.valid(points):
		return false
	var palm_width := maxf(Math.distance(points, 5, 17), 0.04)
	var pinch_ratio := Math.distance(points, 4, 8) / palm_width
	return pinch_ratio < 0.34 and Math.finger_extended(points, 12, 10) and Math.finger_extended(points, 16, 14) and Math.finger_extended(points, 20, 18)
