## ふにゃふにゃ感を確かめるためのデモ。クリックした位置の上から猫を落とす。
extends Node2D

const CatField = preload("res://src/game/cat_field.gd")
const CatRules = preload("res://src/rules/cat_rules.gd")

const CONTAINER := Rect2(100, 200, 400, 650)
const WALL := 20.0
var field: Node2D
var _rng := RandomNumberGenerator.new()


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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var x := clampf(event.position.x, CONTAINER.position.x + 70, CONTAINER.end.x - 70)
		field.spawn_cat(CatRules.next_spawn_tier(_rng), Vector2(x, CONTAINER.position.y - 60))


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
	var wall_color := Color(0.24, 0.24, 0.26)
	draw_rect(Rect2(CONTAINER.position.x - WALL, CONTAINER.position.y, WALL, CONTAINER.size.y + WALL), wall_color)
	draw_rect(Rect2(CONTAINER.end.x, CONTAINER.position.y, WALL, CONTAINER.size.y + WALL), wall_color)
	draw_rect(Rect2(CONTAINER.position.x, CONTAINER.end.y, CONTAINER.size.x, WALL), wall_color)
