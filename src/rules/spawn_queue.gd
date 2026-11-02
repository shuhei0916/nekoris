## これから落とす猫の段階の順番。今の猫と次の猫を決めておく。
extends RefCounted

const CatRules = preload("res://src/rules/cat_rules.gd")

## いま落とそうとしている猫の段階。
var current: int
## その次に落とす猫の段階。
var next: int

var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng
	current = CatRules.next_spawn_tier(_rng)
	next = CatRules.next_spawn_tier(_rng)


## 今の猫を取り出す。次の猫が今の猫になり、新しい次の猫が決まる。
func take() -> int:
	var taken := current
	current = next
	next = CatRules.next_spawn_tier(_rng)
	return taken
