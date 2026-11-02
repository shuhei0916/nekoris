## 落とした猫の着地の質感。水の中のようにふわっと落ち、ぽよんと跳ねずに床になじむ。
extends GutTest

const Demo = preload("res://src/game/demo.gd")
const LandingProbe = preload("res://tools/landing_probe.gd")

const TIER := 3
const SETTLE_FRAMES := 120

var _demo: Node2D
var _cat: Node2D
var _probe: LandingProbe


func before_all() -> void:
	_demo = Demo.new()
	add_child(_demo)
	var at := Vector2(Demo.CONTAINER.get_center().x, Demo.CONTAINER.position.y - 60)
	_cat = _demo.field.spawn_cat(TIER, at)
	_probe = LandingProbe.new(Demo.CONTAINER.end.y)
	while _probe.frames_since_landing() < SETTLE_FRAMES:
		await get_tree().physics_frame
		_probe.sample(_cat)


func after_all() -> void:
	_demo.free()


func test_空気抵抗でゆっくり床に届く():
	assert_lt(_probe.impact, 700.0)


func test_着地しても顔が体からはみ出さない():
	assert_lt(_probe.sink, 0.3)


func test_着地で体がぽよんと跳ね返らない():
	assert_lt(_probe.ring_bounce, 50.0)


func test_着地の瞬間にパンケーキのように潰れない():
	assert_gt(_probe.squash, 0.35)


func test_着地の揺れはすぐ収まる():
	assert_lt(_probe.settle_frames(), 60)
