## 猫を1匹ずつ床に落とし、着地の質感を数値で測る調整用スクリプト。
## 使い方: godot --headless --fixed-fps 120 -s tools/drop_test.gd -- [名前=値 ...]
##   例: -- gravity=600 damp=2 core_stiffness=400 core_damping=40
##   gravity / damp は空間全体の重力・空気抵抗、それ以外は猫（blob.gd）の同名の変数を上書きする。
## 出力の見方（段階ごと。詳しくは tools/landing_probe.gd）:
##   fall      出現から着地までの秒数
##   impact    着地直前の落下速度 (px/s)
##   sink      着地後に顔（重り）が輪の中心より沈んだ最大量（半径に対する割合）
##   bounce    着地後に重りが上向きに跳ねた最大の速さ (px/s)
##   ring      着地後に輪（玉の平均）が上向きに跳ねた最大の速さ (px/s)
##   squash    着地後に最も潰れたときの 高さ/幅
##   rest      静止後の 高さ/幅
##   settle    着地から揺れが収まる（重りの速さ < 10px/s）までの秒数
##   area      静止後の面積比（1.0 が元の面積）
extends SceneTree

const Blob = preload("res://src/blob/blob.gd")
const Demo = preload("res://src/game/demo.gd")
const CatRules = preload("res://src/rules/cat_rules.gd")
const LandingProbe = preload("res://tools/landing_probe.gd")

const TIERS := [0, 3, 6, 9]
const FRAMES_PER_CAT := 480

var _demo: Node2D
var _overrides := {}
var _tier_index := -1
var _cat: Node2D
var _probe: LandingProbe
var _frame := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		if kv.size() == 2:
			_overrides[kv[0]] = float(kv[1])
	_demo = Demo.new()
	root.add_child(_demo)
	var space := root.get_world_2d().space
	if _overrides.has("gravity"):
		PhysicsServer2D.area_set_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY, _overrides["gravity"])
	if _overrides.has("damp"):
		PhysicsServer2D.area_set_param(space, PhysicsServer2D.AREA_PARAM_LINEAR_DAMP, _overrides["damp"])
	print("overrides=%s" % [_overrides])


func _physics_process(_delta: float) -> bool:
	if _cat == null:
		_next_cat()
		return false
	_frame += 1
	_probe.sample(_cat)
	if _frame >= FRAMES_PER_CAT:
		_report()
		_cat.queue_free()
		_cat = null
		if _tier_index + 1 >= TIERS.size():
			quit()
	return false


func _next_cat() -> void:
	_tier_index += 1
	var tier: int = TIERS[_tier_index]
	# _ready で使われる変数（area_per_mass など）も効くよう、場に出す前に上書きする
	_cat = Blob.new()
	_cat.tier = tier
	_cat.radius = CatRules.radius_of(tier)
	_cat.position = Vector2(Demo.CONTAINER.get_center().x, Demo.CONTAINER.position.y - 60)
	for key in _overrides:
		if key in _cat:
			_cat.set(key, _overrides[key])
	_demo.field.add_child(_cat)
	_probe = LandingProbe.new(Demo.CONTAINER.end.y)
	_frame = 0


func _report() -> void:
	var tick := 1.0 / Engine.physics_ticks_per_second
	print("tier%d r=%.0f  fall=%.2fs impact=%.0f sink=%.2f bounce=%.0f ring=%.0f squash=%.2f rest=%.2f settle=%.2fs area=%.2f" % [
		_cat.tier, _cat.radius, _probe.landed_frame * tick, _probe.impact, _probe.sink,
		_probe.bounce, _probe.ring_bounce, _probe.squash, _probe.rest,
		_probe.settle_frames() * tick, _cat.get_area_ratio(),
	])
