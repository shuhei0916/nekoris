## 合体した猫をどこに出すかを決める純粋関数群。
## 合体した2匹の重心がほかの猫の体の上に来ることがあり、そのまま出すと
## 中が空っぽの輪がほかの猫を取り込んでしまう。
extends RefCounted

## 2匹の中心を結ぶ線分を何等分して候補を探すか。
const SAMPLES := 8
## 出すときの大きさの倍率の下限。玉が1か所に重なりすぎないようにする。
const MIN_START_SCALE := 0.1


## from から to への線分の上で、合体した猫を出す位置。
## preferred に needed 以上の空きがあればそこに、なければいちばん空いた候補に出す。
static func spot(
	from: Vector2, to: Vector2, preferred: Vector2, obstacles: PackedVector2Array, needed: float
) -> Vector2:
	var best := preferred
	var best_clearance := clearance(preferred, obstacles)
	if best_clearance >= needed:
		return preferred
	for i in SAMPLES + 1:
		var candidate := from.lerp(to, float(i) / SAMPLES)
		var c := clearance(candidate, obstacles)
		if c > best_clearance:
			best = candidate
			best_clearance = c
	return best


## at からいちばん近いほかの玉までの距離。
static func clearance(at: Vector2, obstacles: PackedVector2Array) -> float:
	var nearest := INF
	for p in obstacles:
		nearest = minf(nearest, at.distance_to(p))
	return nearest


## 空き clearance の位置に、輪の半径 ring_radius・玉の半径 bead_radius の猫を出すときの大きさの倍率。
## ほかの玉（同じ半径とみなす）に触れない大きさにし、max_scale を超えない。
static func start_scale(
	clearance: float, ring_radius: float, bead_radius: float, max_scale: float
) -> float:
	var fit := (clearance - 2.0 * bead_radius) / ring_radius
	return clampf(fit, MIN_START_SCALE, max_scale)
