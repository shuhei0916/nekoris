## 猫の段階（tier）に関するルール。tier 0 が数字 2 の猫。
extends RefCounted

const BASE_RADIUS := 24.0
## 段階が1つ上がるごとの半径の倍率。
const GROWTH := 1.12
## 発射される猫の最大の段階（数字 16 まで）。
const MAX_SPAWN_TIER := 3
## 黒い背景で見分けやすい鮮やかな色。段階ごとに順に使い、一巡したら繰り返す。
const PALETTE: Array[Color] = [
	Color("ffd23f"), Color("7bf05a"), Color("3ee8c0"), Color("3fa7ff"),
	Color("a35cff"), Color("ff4fb8"), Color("ff7a33"), Color("e5ff3d"),
	Color("40f0ff"), Color("4459ff"), Color("ff4f5e"),
]


static func value_of(tier: int) -> int:
	return 2 << tier


static func can_merge(tier_a: int, tier_b: int) -> bool:
	return tier_a == tier_b


static func merged_tier(tier: int) -> int:
	return tier + 1


## 段階 tier の猫どうしが合体したときに得る点数。
static func merge_score(tier: int) -> int:
	return value_of(merged_tier(tier))


## 見た目の半径。
static func radius_of(tier: int) -> float:
	return BASE_RADIUS * pow(GROWTH, tier)


static func color_of(tier: int) -> Color:
	return PALETTE[tier % PALETTE.size()]


static func next_spawn_tier(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(0, MAX_SPAWN_TIER)
