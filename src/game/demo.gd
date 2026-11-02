## ふにゃふにゃ感を確かめるためのデモ。マウスで狙い、クリックで猫を落とす。
extends Node2D

const CatField = preload("res://src/game/cat_field.gd")
const CatPainter = preload("res://src/blob/cat_painter.gd")
const CatRules = preload("res://src/rules/cat_rules.gd")
const SpawnQueue = preload("res://src/rules/spawn_queue.gd")

const CONTAINER := Rect2(100, 200, 400, 650)
const WALL := 20.0
## 落とす前の猫を構える高さ。
const DROP_Y := CONTAINER.position.y - 60.0
## 次の猫を見せる丸い枠。
const NEXT_BOX_CENTER := Vector2(530, 88)
const NEXT_BOX_RADIUS := 46.0
## 枠の中に描く次の猫の最大の半径（耳の分の余白を残す）。
const NEXT_PREVIEW_MAX_RADIUS := 28.0
## 表示だけの猫の輪郭の点の数。
const PREVIEW_EDGE_POINTS := 12
const TEXT_COLOR := Color(0.85, 0.85, 0.88)
const FRAME_COLOR := Color(0.24, 0.24, 0.26)

var field: Node2D
var queue := SpawnQueue.new(RandomNumberGenerator.new())
## 今の猫を落とす横の位置。
var aim_x := CONTAINER.get_center().x
## 最後に狙った横の位置（壁で制限する前）。猫が入れ替わったら狙い直すのに使う。
var _wanted_x := aim_x


func _ready() -> void:
	field = CatField.new()
	add_child(field)
	var left := CONTAINER.position.x
	var right := CONTAINER.end.x
	var bottom := CONTAINER.end.y
	var height := CONTAINER.size.y
	_add_wall(Rect2(left - WALL, CONTAINER.position.y, WALL, height + WALL))
	_add_wall(Rect2(right, CONTAINER.position.y, WALL, height + WALL))
	_add_wall(Rect2(left, bottom, CONTAINER.size.x, WALL))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim(event.position.x)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		aim(event.position.x)
		drop()


## 横の位置 x を狙う。今の猫が容器の壁からはみ出さない範囲に限る。
func aim(x: float) -> void:
	_wanted_x = x
	var radius := CatRules.radius_of(queue.current)
	aim_x = clampf(x, CONTAINER.position.x + radius, CONTAINER.end.x - radius)
	queue_redraw()


## 今の猫を狙った位置から落とし、次の猫を構える。
func drop() -> void:
	field.spawn_cat(queue.take(), Vector2(aim_x, DROP_Y))
	aim(_wanted_x)


## 次の猫を枠の中に描くときの半径。
static func next_preview_radius(tier: int) -> float:
	return minf(CatRules.radius_of(tier), NEXT_PREVIEW_MAX_RADIUS)


func _add_wall(rect: Rect2) -> void:
	var wall := StaticBody2D.new()
	wall.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	wall.add_child(shape)
	wall.physics_material_override = PhysicsMaterial.new()
	wall.physics_material_override.friction = 0.1
	add_child(wall)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.11, 0.11, 0.12))
	draw_rect(CONTAINER, Color.BLACK)
	var wall_color := FRAME_COLOR
	draw_rect(Rect2(CONTAINER.position.x - WALL, CONTAINER.position.y, WALL, CONTAINER.size.y + WALL), wall_color)
	draw_rect(Rect2(CONTAINER.end.x, CONTAINER.position.y, WALL, CONTAINER.size.y + WALL), wall_color)
	draw_rect(Rect2(CONTAINER.position.x, CONTAINER.end.y, CONTAINER.size.x, WALL), wall_color)
	_draw_held_cat()
	_draw_next_cat()


## 容器の上で構えている今の猫。
func _draw_held_cat() -> void:
	var tier := queue.current
	_paint_cat(tier, Vector2(aim_x, DROP_Y), CatRules.radius_of(tier))


## 右上の枠に入った次の猫。
func _draw_next_cat() -> void:
	draw_circle(NEXT_BOX_CENTER, NEXT_BOX_RADIUS, Color.BLACK)
	draw_arc(NEXT_BOX_CENTER, NEXT_BOX_RADIUS, 0.0, TAU, 48, FRAME_COLOR, 4.0, true)
	var font := ThemeDB.fallback_font
	var font_size := 22
	var text := "次"
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := NEXT_BOX_CENTER + Vector2(-size.x / 2.0, -NEXT_BOX_RADIUS - 10.0)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)
	var tier := queue.next
	_paint_cat(tier, NEXT_BOX_CENTER + Vector2(0, 6), next_preview_radius(tier))


func _paint_cat(tier: int, at: Vector2, radius: float) -> void:
	CatPainter.paint_round(
		self, at, radius, PREVIEW_EDGE_POINTS, CatRules.color_of(tier), str(CatRules.value_of(tier))
	)
