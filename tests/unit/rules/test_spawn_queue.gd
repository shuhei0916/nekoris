extends GutTest

const CatRules = preload("res://src/rules/cat_rules.gd")
const SpawnQueue = preload("res://src/rules/spawn_queue.gd")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_はじめから今の猫と次の猫が決まっている():
	var queue := SpawnQueue.new(_rng(1))
	var expected := _rng(1)
	assert_eq(queue.current, CatRules.next_spawn_tier(expected))
	assert_eq(queue.next, CatRules.next_spawn_tier(expected))


func test_今の猫を取り出すと次の猫が今の猫になる():
	var queue := SpawnQueue.new(_rng(1))
	var first := queue.current
	var second := queue.next
	assert_eq(queue.take(), first)
	assert_eq(queue.current, second)


func test_取り出すたびに新しい次の猫が決まる():
	var queue := SpawnQueue.new(_rng(1))
	var expected := _rng(1)
	for i in 2:
		CatRules.next_spawn_tier(expected)
	queue.take()
	assert_eq(queue.next, CatRules.next_spawn_tier(expected))
