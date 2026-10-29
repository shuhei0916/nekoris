## ヘッドレスでデモに猫を積み、面積比と飛び出しを計測する調整用スクリプト。
## 使い方: godot --headless -s tools/soak.gd
extends SceneTree

const Demo = preload("res://src/game/demo.gd")

var _demo: Node2D
var _blobs: Array = []
var _frame := 0


func _initialize() -> void:
	seed(1)
	_demo = Demo.new()
	root.add_child(_demo)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame % 60 == 0 and _blobs.size() < 14:
		var at := Vector2(200 + (_blobs.size() % 5) * 50, 100)
		var blob_radius := randf_range(30, 70)
		if _is_clear(at, blob_radius):
			_blobs.append(_demo.spawn_blob(at, blob_radius))
	if _frame % 240 == 0:
		_report()
	if _frame >= 3600:
		quit()
	return false


func _is_clear(at: Vector2, blob_radius: float) -> bool:
	for blob in _blobs:
		for p in blob.get_outline():
			if p.distance_to(at) < blob_radius + blob.bead_radius:
				return false
	return true


func _report() -> void:
	var min_ratio := INF
	var max_ratio := 0.0
	var escaped := 0
	var intruders := 0
	for blob in _blobs:
		var r: float = blob.get_area_ratio()
		min_ratio = minf(min_ratio, r)
		max_ratio = maxf(max_ratio, r)
		for p in blob.get_outline():
			if p.x < Demo.CONTAINER.position.x - 1 or p.x > Demo.CONTAINER.end.x + 1 or p.y > Demo.CONTAINER.end.y + 1:
				escaped += 1
		for other in _blobs:
			if other != blob:
				for p in other.get_outline():
					if Geometry2D.is_point_in_polygon(p, blob.get_outline()):
						intruders += 1
	print("frame=%d blobs=%d area_ratio=[%.2f, %.2f] escaped_beads=%d intruders=%d" % [_frame, _blobs.size(), min_ratio, max_ratio, escaped, intruders])
