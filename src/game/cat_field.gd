## 容器の中の猫たちを管理し、同じ段階の猫がしばらく触れ続けたら合体させる。
extends Node2D

const Blob = preload("res://src/blob/blob.gd")
const BlobContact = preload("res://src/physics/blob_contact.gd")
const CatRules = preload("res://src/rules/cat_rules.gd")
const ContactTimer = preload("res://src/physics/contact_timer.gd")
const MergePlacement = preload("res://src/physics/merge_placement.gd")
const ScoreBoard = preload("res://src/rules/score_board.gd")

## 玉どうしがこの距離だけ離れていても「触れている」とみなす余裕。
const CONTACT_MARGIN := 2.0
## 合体した猫は小さく出して膨らませ、周りの猫や壁に食い込まないようにする。
const MERGE_START_SCALE := 0.5
## 同じ段階の猫がこの秒数だけ触れ続けたら合体する。触れた瞬間ではなく、少し遅れて気付く感じにする。
const MERGE_DELAY := 0.5

signal merged(tier: int, at: Vector2)

var score := ScoreBoard.new()
var _cats: Array[Node2D] = []
var _contacts := ContactTimer.new()


func spawn_cat(tier: int, at: Vector2, start_scale := 1.0) -> Node2D:
	var cat: Node2D = Blob.new()
	cat.tier = tier
	cat.start_scale = start_scale
	cat.radius = CatRules.radius_of(tier)
	cat.color = CatRules.color_of(tier)
	cat.label = str(CatRules.value_of(tier))
	cat.position = at
	add_child(cat)
	_cats.append(cat)
	return cat


func get_cats() -> Array[Node2D]:
	return _cats


func _physics_process(delta: float) -> void:
	var pairs := _find_mergeable_touching_pairs()
	_contacts.update(pairs.keys(), delta)
	# 1フレームに合体は1組だけ
	for key in pairs:
		if _contacts.elapsed(key) >= MERGE_DELAY:
			merge(pairs[key][0], pairs[key][1])
			return


## 合体できる段階どうしで触れている組。組を表す文字列から2匹への辞書。
func _find_mergeable_touching_pairs() -> Dictionary:
	var pairs := {}
	for i in _cats.size():
		for j in range(i + 1, _cats.size()):
			var a := _cats[i]
			var b := _cats[j]
			if not CatRules.can_merge(a.tier, b.tier):
				continue
			var reach: float = a.bead_radius + b.bead_radius + CONTACT_MARGIN
			if BlobContact.are_touching(a.get_outline(), b.get_outline(), reach):
				pairs["%d-%d" % [a.get_instance_id(), b.get_instance_id()]] = [a, b]
	return pairs


## 2匹を合体させ、1つ上の段階の猫を出す。
## 2匹の重心に出すが、そこがほかの猫に近すぎるときは2匹の中心を結ぶ線分の上で空いた位置にずらし、
## 空きに収まる大きさで出す。中が空っぽの輪がほかの猫を取り込まないようにするため。
func merge(a: Node2D, b: Node2D) -> Node2D:
	var mass_a: float = a.get_total_mass()
	var mass_b: float = b.get_total_mass()
	var from: Vector2 = a.get_core().global_position
	var to: Vector2 = b.get_core().global_position
	var center := (from * mass_a + to * mass_b) / (mass_a + mass_b)
	var velocity: Vector2 = (a.get_core().linear_velocity * mass_a + b.get_core().linear_velocity * mass_b) / (mass_a + mass_b)
	var bead_radius: float = a.bead_radius
	_remove(a)
	_remove(b)
	score.add_merge(a.tier)
	var tier := CatRules.merged_tier(a.tier)
	var ring_radius := CatRules.radius_of(tier) - bead_radius
	var obstacles := _all_bead_positions()
	var needed := ring_radius * MERGE_START_SCALE + 2.0 * bead_radius
	var at := MergePlacement.spot(from, to, center, obstacles, needed)
	var start_scale := MergePlacement.start_scale(
		MergePlacement.clearance(at, obstacles), ring_radius, bead_radius, MERGE_START_SCALE
	)
	var cat := spawn_cat(tier, at, start_scale)
	cat.launch(velocity)
	merged.emit(cat.tier, at)
	return cat


## 今いる猫すべての玉の位置。
func _all_bead_positions() -> PackedVector2Array:
	var points := PackedVector2Array()
	for cat in _cats:
		points.append_array(cat.get_outline())
	return points


func _remove(cat: Node2D) -> void:
	_cats.erase(cat)
	cat.queue_free()
