extends GutTest

const BlobShape = preload("res://src/blob/blob_shape.gd")


func test_なめらかにすると各辺の4分の1と4分の3の点に置き換わる():
	var square := PackedVector2Array([
		Vector2(0, 0), Vector2(8, 0), Vector2(8, 8), Vector2(0, 8),
	])
	var smooth := BlobShape.smooth(square)
	assert_eq(smooth.size(), 8)
	assert_eq(smooth[0], Vector2(2, 0))
	assert_eq(smooth[1], Vector2(6, 0))
	assert_eq(smooth[7], Vector2(0, 2))


func _circle(count: int, offset_degrees := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		points.append(Vector2.from_angle(TAU * i / count + deg_to_rad(offset_degrees)) * 10.0)
	return points


func test_耳は左上と右上に最も近い玉に付く():
	# 30度刻み。画面は y が下向きなので、左上は -120度(=240度)、右上は -60度(=300度)
	assert_eq(BlobShape.ear_indices(_circle(12), Vector2.ZERO), Vector2i(8, 10))


func test_輪が回転しても耳は上を向いた玉に付く():
	# 輪全体を90度回すと、元の玉 i は角度 30i+90 度の位置にある
	assert_eq(BlobShape.ear_indices(_circle(12, 90.0), Vector2.ZERO), Vector2i(5, 7))
