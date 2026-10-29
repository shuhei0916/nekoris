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
