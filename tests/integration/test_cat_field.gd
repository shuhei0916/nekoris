extends GutTest

const CatField = preload("res://src/game/cat_field.gd")
const CatRules = preload("res://src/rules/cat_rules.gd")

var _field: Node2D


func before_each() -> void:
	_field = CatField.new()
	add_child_autofree(_field)


## 2匹の猫を、外側の縁が少し食い込む位置に並べる。
## 玉は飛び飛びに並んでいるので、縁がちょうど接するだけでは玉どうしが触れないことがある。
func _spawn_side_by_side(tier_a: int, tier_b: int) -> void:
	var gap := CatRules.radius_of(tier_a) + CatRules.radius_of(tier_b) - 6.0
	_field.spawn_cat(tier_a, Vector2(200, 300))
	_field.spawn_cat(tier_b, Vector2(200 + gap, 300))


func test_出した猫は段階に応じた大きさになる():
	var cat: Node2D = _field.spawn_cat(3, Vector2(200, 300))
	assert_eq(cat.tier, 3)
	assert_eq(cat.radius, CatRules.radius_of(3))


func test_同じ段階の猫が触れると1つ上の段階の猫1匹になる():
	_spawn_side_by_side(0, 0)
	await wait_physics_frames(3)
	var cats: Array = _field.get_cats()
	assert_eq(cats.size(), 1)
	assert_eq(cats[0].tier, 1)


func test_合体すると点数が入る():
	_spawn_side_by_side(1, 1)
	await wait_physics_frames(3)
	assert_eq(_field.score.total, CatRules.merge_score(1))


func test_違う段階の猫は触れても合体しない():
	_spawn_side_by_side(0, 1)
	await wait_physics_frames(3)
	assert_eq(_field.get_cats().size(), 2)


func test_合体した猫は2匹の間に現れる():
	_spawn_side_by_side(2, 2)
	await wait_physics_frames(3)
	assert_eq(_field.get_cats().size(), 1)
	var expected_x := 200 + CatRules.radius_of(2) - 3.0
	assert_almost_eq(_field.get_cats()[0].get_core().global_position.x, expected_x, 5.0)


func test_合体した猫は小さく現れて膨らむ():
	_spawn_side_by_side(0, 0)
	await wait_physics_frames(3)
	var cat: Node2D = _field.get_cats()[0]
	assert_eq(cat.start_scale, CatField.MERGE_START_SCALE)
	assert_lt(cat.start_scale, 1.0)
