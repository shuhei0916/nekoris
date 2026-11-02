## ヘッドレスでデモを動かし、シーンツリーの状態を文字で出力する動作確認用スクリプト。
## ウィンドウを開かないので、ほかの作業の邪魔にならない。
## 使い方: godot --headless --fixed-fps 120 -s tools/inspect.gd -- [名前=値 ...]
##   drops=300,240,360  この横位置に順に猫を落とす（構えていないときは構えるまで待つ）
##   interval=70        落とす間隔（物理フレーム数）
##   frames=900         何フレーム動かすか
##   every=0            0 より大きければ、このフレームごとにも途中の状態を出す
##   seed=1             猫の順番を決める乱数の種
## 図の見方: 猫は段階の数字（0=「2」の猫, 1=「4」…, 10以上は a, b, …）、構えている猫は *、
##          容器の壁は | 、床は = 。1文字が横10px・縦20px。
extends SceneTree

const Demo = preload("res://src/game/demo.gd")
const CatRules = preload("res://src/rules/cat_rules.gd")
const SpawnQueue = preload("res://src/rules/spawn_queue.gd")

const CELL := Vector2(10, 20)
const MAP_TOP := 70.0
const TIER_CHARS := "0123456789abcdefghijklmnopqrstuvwxyz"

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
	_print_map()


## 容器のまわりを文字の図にする。
func _print_map() -> void:
	var left := Demo.CONTAINER.position.x - Demo.WALL
	var right := Demo.CONTAINER.end.x + Demo.WALL
	var bottom := Demo.CONTAINER.end.y + Demo.WALL
	var cats: Array = _demo.field.get_cats()
	var held_radius := CatRules.radius_of(_demo.queue.current)
	var held_at := Vector2(_demo.aim_x, Demo.DROP_Y)
	var y := MAP_TOP
	while y < bottom:
		var line := ""
		var x := left
		while x < right:
			line += _char_at(Vector2(x, y) + CELL / 2.0, cats, held_at, held_radius)
			x += CELL.x
		print(line)
		y += CELL.y


func _char_at(p: Vector2, cats: Array, held_at: Vector2, held_radius: float) -> String:
	for cat in cats:
		if _is_inside(p, cat):
			return TIER_CHARS[mini(cat.tier, TIER_CHARS.length() - 1)]
	if _demo.is_holding() and p.distance_to(held_at) <= held_radius:
		return "*"
	if p.y >= Demo.CONTAINER.end.y:
		return "=" if p.y < Demo.CONTAINER.end.y + Demo.WALL else " "
	if p.y >= Demo.CONTAINER.position.y and (p.x < Demo.CONTAINER.position.x or p.x > Demo.CONTAINER.end.x):
		return "|"
	return "." if Demo.CONTAINER.has_point(p) else " "


## 点 p が猫の体（玉の中心を結んだ多角形と、外周の玉）の中にあるか。
func _is_inside(p: Vector2, cat: Node2D) -> bool:
	var outline: PackedVector2Array = cat.get_outline()
	if Geometry2D.is_point_in_polygon(p, outline):
		return true
	for bead in outline:
		if p.distance_to(bead) <= cat.bead_radius:
			return true
	return false
