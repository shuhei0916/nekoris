## 組ごとに、触れ続けている時間を数える。
extends RefCounted

var _elapsed := {}


## 今触れている組の一覧 touching を渡し、delta 秒ぶん時間を進める。
## 渡されなかった組は離れたとみなし、次に触れたら0から数え直す。
func update(touching: Array, delta: float) -> void:
	var next := {}
	for key in touching:
		next[key] = _elapsed.get(key, 0.0) + delta
	_elapsed = next


## 組 key が触れ続けている秒数。
func elapsed(key: Variant) -> float:
	return _elapsed.get(key, 0.0)
