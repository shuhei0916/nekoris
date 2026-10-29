extends GutTest

const BlobContact = preload("res://src/physics/blob_contact.gd")


func _ring(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(10, 0), center + Vector2(0, 10),
		center + Vector2(-10, 0), center + Vector2(0, -10),
	])


func test_玉どうしが接触距離より離れていれば触れていない():
	# 最も近い玉どうしの距離は 30 - 20 = 10
	assert_false(BlobContact.are_touching(_ring(Vector2.ZERO), _ring(Vector2(30, 0)), 9.0))


func test_玉どうしが接触距離以内なら触れている():
	assert_true(BlobContact.are_touching(_ring(Vector2.ZERO), _ring(Vector2(30, 0)), 10.5))
