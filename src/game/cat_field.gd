## 容器の中の猫たちを管理し、同じ段階の猫がしばらく触れ続けたら合体させる。
extends Node2D

const Blob = preload("res://src/blob/blob.gd")
const BlobContact = preload("res://src/physics/blob_contact.gd")
const CatRules = preload("res://src/rules/cat_rules.gd")
const ContactTimer = preload("res://src/physics/contact_timer.gd")
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
			_merge(pairs[key][0], pairs[key][1])
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


func _merge(a: Node2D, b: Node2D) -> void:
	var mass_a: float = a.get_total_mass()
	var mass_b: float = b.get_total_mass()
	var at: Vector2 = (a.get_core().global_position * mass_a + b.get_core().global_position * mass_b) / (mass_a + mass_b)
	var velocity: Vector2 = (a.get_core().linear_velocity * mass_a + b.get_core().linear_velocity * mass_b) / (mass_a + mass_b)
	_remove(a)
	_remove(b)
	score.add_merge(a.tier)
	var cat := spawn_cat(CatRules.merged_tier(a.tier), at, MERGE_START_SCALE)
	cat.launch(velocity)
	merged.emit(cat.tier, at)


func _remove(cat: Node2D) -> void:
	_cats.erase(cat)
	cat.queue_free()
