## デモに猫を何匹か落とし、落ち着いたところの画面を PNG に保存する確認用スクリプト。
## 画面を描くので --headless は付けずに実行する。ウィンドウが開くので、普段の動作確認は
## ヘッドレスで動く tools/inspect.gd を使い、見た目そのものを確かめたいときだけ使う。
## 使い方: godot -s tools/screenshot.gd -- <保存先.png>
extends SceneTree

const Demo = preload("res://src/game/demo.gd")

const DROPS := [130.0, 210.0, 300.0, 390.0, 470.0, 170.0, 350.0]
const DROP_INTERVAL := 70
const CAPTURE_FRAME := 900

var _demo: Node2D
var _frame := 0


func _initialize() -> void:
	_demo = Demo.new()
	_demo.queue = Demo.SpawnQueue.new(_seeded_rng())
	root.add_child(_demo)


func _seeded_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	return rng


func _physics_process(_delta: float) -> bool:
	_frame += 1
	var index := _frame / DROP_INTERVAL - 1
	if _frame % DROP_INTERVAL == 0 and index >= 0 and index < DROPS.size():
		_demo.aim(DROPS[index])
		_demo.drop()
	if _frame == CAPTURE_FRAME:
		_demo.aim(240.0)
	return false


func _process(_delta: float) -> bool:
	if _frame >= CAPTURE_FRAME + 2:
		var path := OS.get_cmdline_user_args()[0]
		root.get_texture().get_image().save_png(path)
		print("saved %s" % path)
		quit()
	return false
