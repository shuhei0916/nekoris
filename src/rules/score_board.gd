## 合体で得た点数の累計。
extends RefCounted

const CatRules = preload("res://src/rules/cat_rules.gd")

var total := 0


func add_merge(tier: int) -> void:
	total += CatRules.merge_score(tier)
