extends GutTest

const CatRules = preload("res://src/rules/cat_rules.gd")
const Demo = preload("res://src/game/demo.gd")

var _demo: Node2D


func before_each() -> void:
	_demo = Demo.new()
	add_child_autofree(_demo)


func _current_radius() -> float:
	return CatRules.radius_of(_demo.queue.current)


func test_狙う位置は容器の左の壁からはみ出さない():
	_demo.aim(0.0)
	assert_almost_eq(_demo.aim_x, Demo.CONTAINER.position.x + _current_radius(), 0.001)


func test_狙う位置は容器の右の壁からはみ出さない():
	_demo.aim(10000.0)
	assert_almost_eq(_demo.aim_x, Demo.CONTAINER.end.x - _current_radius(), 0.001)


func test_容器の内側ならマウスの位置をそのまま狙う():
	_demo.aim(300.0)
	assert_eq(_demo.aim_x, 300.0)


func test_落とすと今の猫が狙った位置の上から場に出る():
	var tier: int = _demo.queue.current
	_demo.aim(250.0)
	_demo.drop()
	var cats: Array = _demo.field.get_cats()
	assert_eq(cats.size(), 1)
	assert_eq(cats[0].tier, tier)
	assert_eq(cats[0].position, Vector2(250.0, Demo.DROP_Y))


func test_落とすと次の猫が今の猫になる():
	var next: int = _demo.queue.next
	_demo.drop()
	assert_eq(_demo.queue.current, next)


func test_次の猫は枠に収まる大きさで描く():
	for tier in CatRules.MAX_SPAWN_TIER + 1:
		assert_lte(Demo.next_preview_radius(tier), Demo.NEXT_PREVIEW_MAX_RADIUS)


func test_枠より小さい次の猫は本来の大きさで描く():
	assert_eq(Demo.next_preview_radius(0), CatRules.radius_of(0))


func test_はじめは今の猫を構えている():
	assert_true(_demo.is_holding())


func test_落とした直後は次の猫を構えていない():
	_demo.drop()
	assert_false(_demo.is_holding())


func test_構えていない間はクリックしても落ちない():
	_demo.drop()
	_demo.drop()
	assert_eq(_demo.field.get_cats().size(), 1)


func test_待ち時間が過ぎると次の猫を構えて落とせる():
	_demo.drop()
	_demo._process(Demo.DROP_COOLDOWN)
	assert_true(_demo.is_holding())
	_demo.drop()
	assert_eq(_demo.field.get_cats().size(), 2)


func test_はじめのスコアの表示は0():
	assert_eq(_demo.score_text(), "0")


func test_スコアの表示は合体で得た点数の合計():
	_demo.field.score.add_merge(0)
	_demo.field.score.add_merge(1)
	assert_eq(_demo.score_text(), str(CatRules.merge_score(0) + CatRules.merge_score(1)))


func test_escで開くポーズメニューがある():
	assert_not_null(_demo.pause_menu)
	assert_eq(_demo.pause_menu.get_parent(), _demo)


func test_ポーズメニューで閉じるを選ぶとゲームを終了する():
	assert_true(_demo.pause_menu.quit_requested.is_connected(_demo.quit_game))
