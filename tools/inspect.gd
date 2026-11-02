## ヘッドレスでデモを動かし、シーンツリーの状態を文字で出力する動作確認用スクリプト。
## ウィンドウを開かないので、ほかの作業の邪魔にならない。
## 使い方: godot --headless --fixed-fps 120 -s tools/inspect.gd -- [名前=値 ...]
##   drops=300,240,360  この横位置に順に猫を落とす（構えていないときは構えるまで待つ）
##   interval=70        落とす間隔（物理フレーム数）
##   frames=900         何フレーム動かすか
##   every=0            0 より大きければ、このフレームごとにも途中の状態を出す
##   seed=1             猫の順番を決める乱数の種
## 出力: スコア・今と次の猫・構えているか、猫ごとの状態、
##       容器からはみ出した玉の数（escaped）と、ほかの猫の体に入り込んだ玉の数（intruders）。
extends SceneTree

const Demo = preload("res://src/game/demo.gd")
const CatRules = preload("res://src/rules/cat_rules.gd")
const SpawnQueue = preload("res://src/rules/spawn_queue.gd")

## 玉の中心がこの距離 (px) を超えて容器の外に出たら、はみ出したとみなす。
const ESCAPE_TOLERANCE := 1.0

var _demo: Node2D
var _drops: Array[float] = []
var _interval := 70
var _frames := 900
var _every := 0
var _frame := 0


func _initialize() -> void:
	var seed_value := 1
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"drops":
				for x in kv[1].split(",", false):
					_drops.append(float(x))
			"interval":
				_interval = int(kv[1])
			"frames":
				_frames = int(kv[1])
			"every":
				_every = int(kv[1])
			"seed":
				seed_value = int(kv[1])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_demo = Demo.new()
	_demo.queue = SpawnQueue.new(rng)
	root.add_child(_demo)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if not _drops.is_empty() and _frame % _interval == 0 and _demo.is_holding():
		_demo.aim(_drops.pop_front())
		_demo.drop()
	if _every > 0 and _frame % _every == 0 and _frame < _frames:
		_report()
	if _frame >= _frames:
		_report()
		quit()
	return false


func _report() -> void:
	var queue: SpawnQueue = _demo.queue
	print("=== frame=%d (%.2fs)" % [_frame, float(_frame) / Engine.physics_ticks_per_second])
	print("score=%s holding=%s current=%d next=%d aim_x=%.0f cats=%d drops_left=%d" % [
		_demo.score_text(), _demo.is_holding(), CatRules.value_of(queue.current),
		CatRules.value_of(queue.next), _demo.aim_x, _demo.field.get_cats().size(), _drops.size(),
	])
	for cat in _demo.field.get_cats():
		var core: RigidBody2D = cat.get_core()
		print("  cat %4d  at=(%.0f, %.0f)  speed=%.0f  area=%.2f  growth=%.2f" % [
			CatRules.value_of(cat.tier), core.global_position.x, core.global_position.y,
			core.linear_velocity.length(), cat.get_area_ratio(), cat.get_growth(),
		])
	_print_checks()


## 容器からのはみ出しと、猫どうしの食い込みを数える。
func _print_checks() -> void:
	var cats: Array = _demo.field.get_cats()
	var escaped := 0
	var intruders := 0
	for cat in cats:
		for p in cat.get_outline():
			if _is_escaped(p):
				escaped += 1
		for other in cats:
			if other == cat:
				continue
			for p in other.get_outline():
				if Geometry2D.is_point_in_polygon(p, cat.get_outline()):
					intruders += 1
	print("checks: escaped=%d intruders=%d" % [escaped, intruders])


func _is_escaped(p: Vector2) -> bool:
	return (
		p.x < Demo.CONTAINER.position.x - ESCAPE_TOLERANCE
		or p.x > Demo.CONTAINER.end.x + ESCAPE_TOLERANCE
		or p.y > Demo.CONTAINER.end.y + ESCAPE_TOLERANCE
	)
