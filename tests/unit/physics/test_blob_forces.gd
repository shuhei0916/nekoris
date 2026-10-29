extends GutTest

const BlobForces = preload("res://src/physics/blob_forces.gd")


func test_一辺10の正方形の面積は100():
	var square := PackedVector2Array([
		Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10),
	])
	assert_almost_eq(BlobForces.polygon_area(square), 100.0, 0.001)


func _square(side: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, 0), Vector2(side, 0), Vector2(side, side), Vector2(0, side),
	])


func _still(count: int) -> PackedVector2Array:
	var velocities := PackedVector2Array()
	velocities.resize(count)
	return velocities


func test_隣との間隔が自然長なら皮の力は0():
	var forces := BlobForces.skin_forces(_square(10), _still(4), 10.0, 2.0, 0.0)
	for f in forces:
		assert_almost_eq(f, Vector2.ZERO, Vector2(0.001, 0.001))


func test_伸びた皮は隣の玉を引き寄せる():
	# 各辺が自然長より10伸びている -> 両隣へ 2.0 * 10 ずつ引かれる
	var forces := BlobForces.skin_forces(_square(20), _still(4), 10.0, 2.0, 0.0)
	assert_almost_eq(forces[0], Vector2(20, 20), Vector2(0.001, 0.001))
	assert_almost_eq(forces[2], Vector2(-20, -20), Vector2(0.001, 0.001))


func test_縮んだ皮は押し返さない():
	var forces := BlobForces.skin_forces(_square(5), _still(4), 10.0, 2.0, 0.0)
	for f in forces:
		assert_almost_eq(f, Vector2.ZERO, Vector2(0.001, 0.001))


func test_伸びた皮が離れていく速さに応じて引く力が強まる():
	# 玉0と玉1が辺に沿って速さ2で離れていく -> 減衰 3.0 * 2 が上乗せされる
	var velocities := _still(4)
	velocities[0] = Vector2(-1, 0)
	velocities[1] = Vector2(1, 0)
	var forces := BlobForces.skin_forces(_square(20), velocities, 10.0, 2.0, 3.0)
	assert_almost_eq(forces[0], Vector2(26, 20), Vector2(0.001, 0.001))


func test_面積が目標どおりなら圧力は0():
	var forces := BlobForces.pressure_forces(_square(10), 100.0, 0.1, 1000.0)
	for f in forces:
		assert_almost_eq(f, Vector2.ZERO, Vector2(0.001, 0.001))


func test_つぶれて面積が足りないと外向きに押し出す():
	# 目標200に対して面積100 -> 不足100 * 強さ0.1 = 10 の大きさで外向き
	var forces := BlobForces.pressure_forces(_square(10), 200.0, 0.1, 1000.0)
	var outward := Vector2(-1, -1).normalized()
	assert_almost_eq(forces[0], outward * 10.0, Vector2(0.001, 0.001))


func test_膨らみすぎると内向きに引き込む():
	var forces := BlobForces.pressure_forces(_square(10), 50.0, 0.1, 1000.0)
	var inward := Vector2(1, 1).normalized()
	assert_almost_eq(forces[0], inward * 5.0, Vector2(0.001, 0.001))


func test_頂点の並びが逆回りでも圧力は外向き():
	var reversed := _square(10)
	reversed.reverse()
	var forces := BlobForces.pressure_forces(reversed, 200.0, 0.1, 1000.0)
	# reverse 後の末尾が元の (0, 0)
	var outward := Vector2(-1, -1).normalized()
	assert_almost_eq(forces[3], outward * 10.0, Vector2(0.001, 0.001))


func test_玉1つあたりの圧力には上限がある():
	var forces := BlobForces.pressure_forces(_square(10), 200.0, 10.0, 30.0)
	var outward := Vector2(-1, -1).normalized()
	assert_almost_eq(forces[0], outward * 30.0, Vector2(0.001, 0.001))


func test_圧力で輪全体が動き出すことはない():
	var triangle := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(0, 10)])
	var forces := BlobForces.pressure_forces(triangle, 200.0, 0.1, 1000.0)
	var total := Vector2.ZERO
	for f in forces:
		total += f
	assert_almost_eq(total, Vector2.ZERO, Vector2(0.001, 0.001))


func test_重りが輪の中心で同じ速さなら力は0():
	var f := BlobForces.core_force(Vector2(5, 5), Vector2(1, 0), Vector2(5, 5), Vector2(1, 0), 200.0, 15.0)
	assert_almost_eq(f, Vector2.ZERO, Vector2(0.001, 0.001))


func test_重りは輪の中心へ引き戻される():
	var f := BlobForces.core_force(Vector2(5, 5), Vector2.ZERO, Vector2(5, 3), Vector2.ZERO, 200.0, 15.0)
	assert_almost_eq(f, Vector2(0, 400), Vector2(0.001, 0.001))


func test_重りは輪と同じ速さに揃えられる():
	var f := BlobForces.core_force(Vector2(5, 5), Vector2(4, 0), Vector2(5, 5), Vector2(1, 0), 200.0, 15.0)
	assert_almost_eq(f, Vector2(45, 0), Vector2(0.001, 0.001))


func test_玉の数は円周を玉の間隔で割った数():
	# 2π * 40 / 16 = 15.7...
	assert_eq(BlobForces.bead_count_for(40.0, 16.0), 16)


func test_小さすぎても玉は3つ以上():
	assert_eq(BlobForces.bead_count_for(1.0, 16.0), 3)
