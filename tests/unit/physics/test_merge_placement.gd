extends GutTest

const MergePlacement = preload("res://src/physics/merge_placement.gd")


func test_まわりに何もなければ望みの位置に出す():
	var at: Vector2 = MergePlacement.spot(
		Vector2(0, 0), Vector2(100, 0), Vector2(50, 0), PackedVector2Array(), 30.0
	)
	assert_eq(at, Vector2(50, 0))


func test_望みの位置に必要な空きがあればそのまま出す():
	var obstacles := PackedVector2Array([Vector2(50, 40)])
	var at: Vector2 = MergePlacement.spot(Vector2(0, 0), Vector2(100, 0), Vector2(50, 0), obstacles, 30.0)
	assert_eq(at, Vector2(50, 0))


func test_望みの位置が狭ければ線分の上でいちばん空いた位置に出す():
	var obstacles := PackedVector2Array([Vector2(45, 0)])
	var at: Vector2 = MergePlacement.spot(Vector2(0, 0), Vector2(100, 0), Vector2(50, 0), obstacles, 30.0)
	assert_eq(at, Vector2(100, 0))


func test_空きはいちばん近いほかの玉までの距離():
	var obstacles := PackedVector2Array([Vector2(30, 0), Vector2(0, 20)])
	assert_almost_eq(MergePlacement.clearance(Vector2.ZERO, obstacles), 20.0, 0.0001)


func test_ほかの玉がなければ空きは無限():
	assert_eq(MergePlacement.clearance(Vector2.ZERO, PackedVector2Array()), INF)


func test_空きが十分なら出すときの大きさは上限のまま():
	assert_eq(MergePlacement.start_scale(INF, 40.0, 10.0, 0.5), 0.5)


func test_空きが狭ければほかの玉に触れない大きさまで縮める():
	# 輪の半径 40 * 0.25 + 自分の玉 10 + ほかの玉 10 = 空き 30
	assert_almost_eq(MergePlacement.start_scale(30.0, 40.0, 10.0, 0.5), 0.25, 0.0001)


func test_どれだけ狭くても下限より小さくはしない():
	assert_eq(MergePlacement.start_scale(5.0, 40.0, 10.0, 0.5), MergePlacement.MIN_START_SCALE)
