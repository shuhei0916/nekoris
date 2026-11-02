## 猫の見た目（体・耳・目・数字）を描く。
## 物理で動く猫と、表示だけの猫（構えている猫・次の猫）で共用する。
extends RefCounted

const BlobShape = preload("res://src/blob/blob_shape.gd")

const LINE_COLOR := Color(0.05, 0.05, 0.08)
const LINE_WIDTH := 3.0


## canvas に猫を描く。座標はすべて canvas のローカル座標。
## edge は体の外側の縁、center は体の中心、face_center は目と数字を置く位置。
static func paint(
	canvas: CanvasItem,
	edge: PackedVector2Array,
	center: Vector2,
	face_center: Vector2,
	radius: float,
	color: Color,
	label: String,
) -> void:
	var body := BlobShape.smooth(BlobShape.smooth(edge))
	if Geometry2D.triangulate_polygon(body).is_empty():
		return  # 輪がねじれた瞬間は描かない
	var ears := BlobShape.ear_indices(edge, center)
	_paint_ear(canvas, edge[ears.x], center, radius, color)
	_paint_ear(canvas, edge[ears.y], center, radius, color)
	canvas.draw_colored_polygon(body, color)
	body.append(body[0])
	canvas.draw_polyline(body, LINE_COLOR, LINE_WIDTH, true)
	_paint_face(canvas, face_center, radius, label)


## 円形の猫を描く。表示だけの猫に使う。
static func paint_round(
	canvas: CanvasItem, at: Vector2, radius: float, edge_points: int, color: Color, label: String
) -> void:
	var edge := BlobShape.circle(radius, edge_points)
	for i in edge.size():
		edge[i] += at
	paint(canvas, edge, at, at, radius, color, label)


static func _paint_ear(
	canvas: CanvasItem, base: Vector2, center: Vector2, radius: float, color: Color
) -> void:
	var outward := (base - center).normalized()
	var side := outward.orthogonal() * radius * 0.28
	var root := base - outward * radius * 0.15
	var ear := PackedVector2Array([root - side, base + outward * radius * 0.3, root + side])
	canvas.draw_colored_polygon(ear, color)
	ear.append(ear[0])
	canvas.draw_polyline(ear, LINE_COLOR, LINE_WIDTH, true)


static func _paint_face(canvas: CanvasItem, center: Vector2, radius: float, label: String) -> void:
	var eye := maxf(radius * 0.06, 2.0)
	canvas.draw_circle(center + Vector2(-radius * 0.28, -radius * 0.38), eye, LINE_COLOR)
	canvas.draw_circle(center + Vector2(radius * 0.28, -radius * 0.38), eye, LINE_COLOR)
	if label.is_empty():
		return
	var font := ThemeDB.fallback_font
	var font_size := maxi(int(radius * 0.6), 12)
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center + Vector2(-size.x / 2.0, font.get_ascent(font_size) / 2.0 - radius * 0.02)
	canvas.draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LINE_COLOR)
