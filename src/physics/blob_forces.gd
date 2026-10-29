## ソフトボディ（数珠状の剛体の輪）に加える力を計算する純粋関数群。
extends RefCounted


## 多角形の面積（頂点の並び順によらず正の値）。
static func polygon_area(points: PackedVector2Array) -> float:
	return absf(_signed_area(points))


## 隣り合う玉の間隔が rest_length より伸びたときだけ、引き寄せる力。
## 縮んだときは押し返さないので、潰れた輪はぐにゃりと折れ曲がれる。
## 離れていく速さに damping を掛けた分だけ引く力が強まる。
static func skin_forces(
	points: PackedVector2Array,
	velocities: PackedVector2Array,
	rest_length: float,
	stiffness: float,
	damping: float,
) -> PackedVector2Array:
	var forces := PackedVector2Array()
	forces.resize(points.size())
	for i in points.size():
		var j := (i + 1) % points.size()
		var delta := points[j] - points[i]
		var stretch := delta.length() - rest_length
		if stretch <= 0.0:
			continue
		var direction := delta.normalized()
		var separating_speed := (velocities[j] - velocities[i]).dot(direction)
		var f := direction * (stretch * stiffness + separating_speed * damping)
		forces[i] += f
		forces[j] -= f
	return forces


## 面積を target_area に保とうとして、各玉を法線方向に押し引きする力。
## 大きさは strength * (目標面積 - 面積) で、1玉あたり max_force まで。
## 輪全体の合計は0に補正するので、圧力だけで猫が動き出すことはない。
static func pressure_forces(
	points: PackedVector2Array, target_area: float, strength: float, max_force: float
) -> PackedVector2Array:
	var signed_area := _signed_area(points)
	var magnitude := strength * (target_area - absf(signed_area))
	var orientation := signf(signed_area)
	var forces := PackedVector2Array()
	forces.resize(points.size())
	var total := Vector2.ZERO
	for i in points.size():
		var prev := points[(i - 1 + points.size()) % points.size()]
		var next := points[(i + 1) % points.size()]
		var tangent := next - prev
		var outward := Vector2(tangent.y, -tangent.x).normalized() * orientation
		forces[i] = (outward * magnitude).limit_length(max_force)
		total += forces[i]
	var mean := total / points.size()
	for i in points.size():
		forces[i] -= mean
	return forces


static func _signed_area(points: PackedVector2Array) -> float:
	var twice_area := 0.0
	for i in points.size():
		twice_area += points[i].cross(points[(i + 1) % points.size()])
	return twice_area / 2.0


## 中心の重りを輪の中心へ引き戻し、輪と同じ速さに揃える加速度（重りの質量を掛けて使う）。
static func core_force(
	ring_center: Vector2,
	ring_velocity: Vector2,
	core_position: Vector2,
	core_velocity: Vector2,
	stiffness: float,
	damping: float,
) -> Vector2:
	return (ring_center - core_position) * stiffness + (ring_velocity - core_velocity) * damping


## 半径 radius の円周に、間隔 spacing で並べる玉の数。
static func bead_count_for(radius: float, spacing: float) -> int:
	return maxi(3, roundi(TAU * radius / spacing))
