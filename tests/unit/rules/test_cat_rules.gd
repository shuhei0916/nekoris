extends GutTest

const CatRules = preload("res://src/rules/cat_rules.gd")


func test_最初の段階の猫は2():
	assert_eq(CatRules.value_of(0), 2)


func test_段階が1つ上がると数字は倍になる():
	assert_eq(CatRules.value_of(1), 4)
	assert_eq(CatRules.value_of(10), 2048)


func test_同じ段階の猫どうしは合体できる():
	assert_true(CatRules.can_merge(3, 3))


func test_違う段階の猫どうしは合体できない():
	assert_false(CatRules.can_merge(3, 4))


func test_合体すると1つ上の段階になる():
	assert_eq(CatRules.merged_tier(3), 4)


func test_合体で得られる点数はできた猫の数字():
	# 8 + 8 -> 16 で 16 点
	assert_eq(CatRules.merge_score(2), 16)


func test_最初の段階の猫の大きさは基準の半径():
	assert_eq(CatRules.radius_of(0), CatRules.BASE_RADIUS)


func test_段階が1つ上がるごとに一定の割合で大きくなる():
	for tier in 10:
		assert_almost_eq(CatRules.radius_of(tier + 1) / CatRules.radius_of(tier), CatRules.GROWTH, 0.0001)


func test_隣り合う段階の猫は色が違う():
	for tier in 12:
		assert_ne(CatRules.color_of(tier), CatRules.color_of(tier + 1))


func test_色は一巡すると繰り返す():
	var cycle: int = CatRules.PALETTE.size()
	assert_eq(CatRules.color_of(2 + cycle), CatRules.color_of(2))


func test_次に出る猫は小さい段階だけから選ばれる():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var seen := {}
	for i in 200:
		var tier := CatRules.next_spawn_tier(rng)
		assert_between(tier, 0, CatRules.MAX_SPAWN_TIER)
		seen[tier] = true
	assert_eq(seen.size(), CatRules.MAX_SPAWN_TIER + 1, "どの段階も出ることがある")
