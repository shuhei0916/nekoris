## 落とした猫を毎フレーム観察し、着地の質感を数値にする。
## tools/drop_test.gd と質感のテストの両方から使う。
extends RefCounted

## 重りがこの速さ (px/s) 未満になったら揺れが収まったとみなす。
const SETTLED_SPEED := 10.0

## 出現から着地までのフレーム数（着地前は -1）。
var landed_frame := -1
## 着地直前の落下速度 (px/s)。
var impact := 0.0
## 着地後に顔（重り）が輪の中心より沈んだ最大量（半径に対する割合）。
var sink := 0.0
## 着地後に重りが上向きに跳ねた最大の速さ (px/s)。
var bounce := 0.0
## 着地後に輪（玉の平均）が上向きに跳ねた最大の速さ (px/s)。
var ring_bounce := 0.0
## 着地後に最も潰れたときの 高さ/幅。
var squash := INF
## 最後に観察したときの 高さ/幅。
var rest := 0.0
## 最後に重りが動いていたフレーム。
var last_moving_frame := 0

var _floor_y: float
var _frame := 0
var _prev_vy := 0.0


func _init(floor_y: float) -> void:
	_floor_y = floor_y


func has_landed() -> bool:
	return landed_frame >= 0


## 着地してから観察したフレーム数。
func frames_since_landing() -> int:
	return _frame - landed_frame if has_landed() else 0


## 着地から揺れが収まるまでのフレーム数。
func settle_frames() -> int:
	return last_moving_frame - landed_frame


func sample(cat: Node2D) -> void:
	_frame += 1
	var outline: PackedVector2Array = cat.get_outline()
	var bounds := Rect2(outline[0], Vector2.ZERO)
	var center := Vector2.ZERO
	for p in outline:
		bounds = bounds.expand(p)
		center += p
	center /= outline.size()
	var ring_velocity := Vector2.ZERO
	for bead in cat.get_beads():
		ring_velocity += bead.linear_velocity
	ring_velocity /= outline.size()
	var core: RigidBody2D = cat.get_core()
	var bead_radius: float = cat.bead_radius
	if not has_landed():
		if bounds.end.y + bead_radius >= _floor_y - 0.5:
			landed_frame = _frame
			impact = _prev_vy
		_prev_vy = core.linear_velocity.y
		return
	sink = maxf(sink, (core.global_position.y - center.y) / cat.radius)
	bounce = maxf(bounce, -core.linear_velocity.y)
	ring_bounce = maxf(ring_bounce, -ring_velocity.y)
	rest = (bounds.size.y + bead_radius * 2) / (bounds.size.x + bead_radius * 2)
	squash = minf(squash, rest)
	if core.linear_velocity.length() >= SETTLED_SPEED:
		last_moving_frame = _frame
