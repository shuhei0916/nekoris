## 猫どうしの接触判定。
extends RefCounted


## どちらかの輪の玉どうしが、中心間で reach 以内まで近づいていれば触れている。
static func are_touching(
	outline_a: PackedVector2Array, outline_b: PackedVector2Array, reach: float
) -> bool:
	var reach_squared := reach * reach
	for a in outline_a:
		for b in outline_b:
			if a.distance_squared_to(b) <= reach_squared:
				return true
	return false
