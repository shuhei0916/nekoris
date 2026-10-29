## 猫の輪郭を描くための形の計算。
extends RefCounted

const EAR_LEFT := Vector2(-0.5, -0.8660254)  # 左上（-120度）
const EAR_RIGHT := Vector2(0.5, -0.8660254)  # 右上（-60度）


## Chaikin 法で1回なめらかにする。各辺を 1/4 と 3/4 の2点に置き換える。
static func smooth(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		result.append(a.lerp(b, 0.25))
		result.append(a.lerp(b, 0.75))
	return result


## 耳を付ける玉の番号（左耳, 右耳）。中心から見て左上・右上に最も近い玉を選ぶ。
static func ear_indices(points: PackedVector2Array, center: Vector2) -> Vector2i:
	return Vector2i(_closest_to(points, center, EAR_LEFT), _closest_to(points, center, EAR_RIGHT))


static func _closest_to(points: PackedVector2Array, center: Vector2, direction: Vector2) -> int:
	var best := 0
	var best_dot := -INF
	for i in points.size():
		var dot := (points[i] - center).normalized().dot(direction)
		if dot > best_dot:
			best_dot = dot
			best = i
	return best
