## 床に猫を1匹ずつ置き、静止したときの面積比を段階ごとに測る調整用スクリプト。
## 使い方: godot --headless -s tools/rest_test.gd -- <pressure_strength>
extends SceneTree

const Demo = preload("res://src/game/demo.gd")

var _demo: Node2D
var _frame := 0
var _cats := []


func _initialize() -> void:
	_demo = Demo.new()
	root.add_child(_demo)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		var args := OS.get_cmdline_user_args()
		for i in 4:
			var cat: Node2D = _demo.field.spawn_cat(i * 3, Vector2(140 + i * 100, 700))
			if not args.is_empty():
				cat.pressure_strength = float(args[0])
			_cats.append(cat)
	if _frame == 600:
		var line := ""
		for cat in _cats:
			line += "tier%d=%.2f " % [cat.tier, cat.get_area_ratio()]
		print(line)
		quit()
	return false
