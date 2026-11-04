extends GutTest

const CatField = preload("res://src/game/cat_field.gd")
const CatRules = preload("res://src/rules/cat_rules.gd")

var _field: Node2D


func before_each() -> void:
	_field = CatField.new()
	add_child_autofree(_field)


## 2匹の猫を、外側の縁が少し食い込む位置に並べる。
## 玉は飛び飛びに並んでいるので、縁がちょうど接するだけでは玉どうしが触れないことがある。
## 合体までの間に押し合って離れないよう、2匹がちょうど収まる箱に入れる。
func _spawn_side_by_side(tier_a: int, tier_b: int) -> void:
	var radius_a := CatRules.radius_of(tier_a)
	var radius_b := CatRules.radius_of(tier_b)
	var gap := radius_a + radius_b - 6.0
	var left := 200 - radius_a
	var right := 200 + gap + radius_b
	var bottom := 300 + maxf(radius_a, radius_b)
	_add_wall(Rect2(left - 20, 0, 20, bottom + 20))
	_add_wall(Rect2(right, 0, 20, bottom + 20))
	_add_wall(Rect2(left, bottom, right - left, 20))
	_field.spawn_cat(tier_a, Vector2(200, 300))
	_field.spawn_cat(tier_b, Vector2(200 + gap, 300))


func _add_wall(rect: Rect2) -> void:
	var wall := StaticBody2D.new()
	wall.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	wall.add_child(shape)
	add_child_autofree(wall)


## 合体の待ち時間が過ぎるまで待つ。
func _wait_for_merge() -> void:
	var ticks := ceili(CatField.MERGE_DELAY * Engine.physics_ticks_per_second)
	await wait_physics_frames(ticks + 3)


func test_出した猫は段階に応じた大きさになる():
	var cat: Node2D = _field.spawn_cat(3, Vector2(200, 300))
	assert_eq(cat.tier, 3)
	assert_eq(cat.radius, CatRules.radius_of(3))


func test_同じ段階の猫が触れると1つ上の段階の猫1匹になる():
	_spawn_side_by_side(0, 0)
	await _wait_for_merge()
	var cats: Array = _field.get_cats()
	assert_eq(cats.size(), 1)
	assert_eq(cats[0].tier, 1)


func test_合体すると点数が入る():
	_spawn_side_by_side(1, 1)
	await _wait_for_merge()
	assert_eq(_field.score.total, CatRules.merge_score(1))


func test_違う段階の猫は触れても合体しない():
	_spawn_side_by_side(0, 1)
	await _wait_for_merge()
	assert_eq(_field.get_cats().size(), 2)


func test_合体した猫は2匹の間に現れる():
	_spawn_side_by_side(2, 2)
	await _wait_for_merge()
	assert_eq(_field.get_cats().size(), 1)
	var expected_x := 200 + CatRules.radius_of(2) - 3.0
	assert_almost_eq(_field.get_cats()[0].get_core().global_position.x, expected_x, 5.0)


func test_合体した猫は小さく現れて膨らむ():
	_spawn_side_by_side(0, 0)
	await _wait_for_merge()
	var cat: Node2D = _field.get_cats()[0]
	assert_eq(cat.start_scale, CatField.MERGE_START_SCALE)
	assert_lt(cat.start_scale, 1.0)


func test_同じ段階の猫も触れてすぐには合体しない():
	_spawn_side_by_side(0, 0)
	await wait_physics_frames(3)
	assert_eq(_field.get_cats().size(), 2)



## outer の輪の内側に入り込んでいる inner の玉の数。
func _beads_inside(inner: Node2D, outer: Node2D) -> int:
	var count := 0
	for p in inner.get_outline():
		if Geometry2D.is_point_in_polygon(p, outer.get_outline()):
			count += 1
	return count


func test_合体した猫は2匹の重心にいたほかの猫を取り込まない():
	# 2匹が小さい猫を抱え込むように触れていると、2匹の重心が小さい猫の上に来る
	_add_wall(Rect2(0, 400, 600, 20))
	var radius := CatRules.radius_of(4)
	var left: Node2D = _field.spawn_cat(4, Vector2(300 - radius - 10, 400 - radius))
	var right: Node2D = _field.spawn_cat(4, Vector2(300 + radius + 10, 400 - radius))
	var small: Node2D = _field.spawn_cat(0, Vector2(300, 400 - radius))
	await wait_physics_frames(2)
	var merged: Node2D = _field.merge(left, right)
	await wait_seconds(1.0)
	assert_eq(_beads_inside(small, merged), 0, "小さい猫の玉が合体した猫の内側に入っていない")
	assert_false(
		Geometry2D.is_point_in_polygon(small.get_core().global_position, merged.get_outline()),
		"小さい猫の中心が合体した猫の内側に入っていない"
	)
