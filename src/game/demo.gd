## ふにゃふにゃ感を確かめるためのデモ。クリックした位置の上から猫を落とす。
extends Node2D

const Blob = preload("res://src/blob/blob.gd")

const CONTAINER := Rect2(100, 200, 400, 650)
const WALL := 20.0
const COLORS := [
	Color(1.0, 0.8, 0.55), Color(0.95, 0.95, 0.95), Color(0.55, 0.55, 0.6),
	Color(0.35, 0.3, 0.3), Color(0.95, 0.65, 0.4),
]


func _ready() -> void:
	var left := CONTAINER.position.x
	var right := CONTAINER.end.x
	var bottom := CONTAINER.end.y
	var height := CONTAINER.size.y
	_add_wall(Rect2(left - WALL, CONTAINER.position.y, WALL, height + WALL))
	_add_wall(Rect2(right, CONTAINER.position.y, WALL, height + WALL))
	_add_wall(Rect2(left, bottom, CONTAINER.size.x, WALL))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var x := clampf(event.position.x, CONTAINER.position.x + 70, CONTAINER.end.x - 70)
		spawn_blob(Vector2(x, CONTAINER.position.y - 60), randf_range(30, 70))


func spawn_blob(at: Vector2, blob_radius: float) -> Node2D:
	var blob: Node2D = Blob.new()
	blob.position = at
	blob.radius = blob_radius
	blob.color = COLORS.pick_random()
	add_child(blob)
	return blob


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
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.2, 0.22, 0.3))
	draw_rect(CONTAINER, Color(0.28, 0.3, 0.4))
	var wall_color := Color(0.6, 0.45, 0.35)
	draw_rect(Rect2(CONTAINER.position.x - WALL, CONTAINER.position.y, WALL, CONTAINER.size.y + WALL), wall_color)
	draw_rect(Rect2(CONTAINER.end.x, CONTAINER.position.y, WALL, CONTAINER.size.y + WALL), wall_color)
	draw_rect(Rect2(CONTAINER.position.x, CONTAINER.end.y, CONTAINER.size.x, WALL), wall_color)
