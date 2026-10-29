extends GutTest

const Blob = preload("res://src/blob/blob.gd")
const BlobForces = preload("res://src/physics/blob_forces.gd")


func _make_blob(radius: float) -> Node2D:
	var blob: Node2D = Blob.new()
	blob.radius = radius
	add_child_autofree(blob)
	return blob


func test_玉の数は大きさから決まり円周上に並ぶ():
	var blob := _make_blob(60.0)
	var ring_radius: float = 60.0 - blob.bead_radius
	var beads: Array = blob.get_beads()
	assert_eq(beads.size(), BlobForces.bead_count_for(ring_radius, blob.bead_spacing))
	for bead in beads:
		assert_almost_eq(bead.position.length(), ring_radius, 0.001)


func test_大きい猫ほど玉が多い():
	var small := _make_blob(30.0)
	var large := _make_blob(90.0)
	assert_gt(large.get_beads().size(), small.get_beads().size())


func test_玉は摩擦も反発もない():
	var bead: RigidBody2D = _make_blob(40.0).get_beads()[0]
	assert_eq(bead.physics_material_override.friction, 0.0)
	assert_eq(bead.physics_material_override.bounce, 0.0)


func test_中心に何とも衝突しない重りがある():
	var core: RigidBody2D = _make_blob(40.0).get_core()
	assert_eq(core.position, Vector2.ZERO)
	assert_eq(core.collision_layer, 0)
	assert_eq(core.collision_mask, 0)


func test_大きい猫ほど重い():
	var small := _make_blob(30.0)
	var large := _make_blob(90.0)
	assert_gt(large.get_total_mass(), small.get_total_mass())


func test_勢いをつけると全部の玉と重りに同じ速度が加わる():
	var blob := _make_blob(40.0)
	blob.launch(Vector2(100, -50))
	assert_eq(blob.get_core().linear_velocity, Vector2(100, -50))
	for bead in blob.get_beads():
		assert_eq(bead.linear_velocity, Vector2(100, -50))


func test_小さく出した猫は縮んだ輪から始まる():
	var blob: Node2D = Blob.new()
	blob.radius = 60.0
	blob.start_scale = 0.5
	add_child_autofree(blob)
	var ring_radius: float = 60.0 - blob.bead_radius
	assert_almost_eq(blob.get_beads()[0].position.length(), ring_radius * 0.5, 0.001)


func test_小さく出した猫は膨らむ時間が経つと元の大きさを目指す():
	var blob: Node2D = Blob.new()
	blob.start_scale = 0.5
	add_child_autofree(blob)
	assert_almost_eq(blob.get_growth(), 0.5, 0.001)
	blob.grow(blob.grow_time / 2.0)
	assert_almost_eq(blob.get_growth(), 0.75, 0.001)
	blob.grow(blob.grow_time)
	assert_almost_eq(blob.get_growth(), 1.0, 0.001)


func test_同じ猫の玉どうしは衝突しない():
	var beads: Array = _make_blob(60.0).get_beads()
	for i in beads.size():
		for j in beads.size():
			if i != j:
				assert_has(beads[i].get_collision_exceptions(), beads[j])
