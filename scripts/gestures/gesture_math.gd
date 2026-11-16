extends RefCounted
## Geometry helpers for normalized MediaPipe hand landmarks.
static func point(points: Array, index: int) -> Vector3:
	if index < 0 or index >= points.size() or not (points[index] is Dictionary):
		return Vector3.ZERO
	var p: Dictionary = points[index]
	return Vector3(float(p.get("x", 0.0)), float(p.get("y", 0.0)), float(p.get("z", 0.0)))

static func distance(points: Array, a: int, b: int) -> float:
	return point(points, a).distance_to(point(points, b))

static func finger_extended(points: Array, tip: int, pip: int) -> bool:
	return distance(points, 0, tip) > distance(points, 0, pip) * 1.16

static func valid(points: Array) -> bool:
	return points.size() == 21
