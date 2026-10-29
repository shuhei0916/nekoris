## 小さな剛体の玉を数珠状に並べ、皮の力と圧力でふにゃふにゃさせる猫。
## 中心には見えない重りがあり、質量の大半を受け持つ。
extends Node2D

const BlobForces = preload("res://src/physics/blob_forces.gd")
const BlobShape = preload("res://src/blob/blob_shape.gd")

const LINE_COLOR := Color(0.05, 0.05, 0.08)
const LINE_WIDTH := 3.0

## 猫の段階（tier 0 が数字 2）。
var tier := 0
## 体の中央に表示する文字（数字）。
var label := ""
## 見た目の半径（玉の外側の縁まで）。
@export var radius := 40.0
@export var bead_radius := 10.0
@export var bead_spacing := 14.0
@export var bead_mass := 1.0
## 面積あたりの質量の逆数。小さいほど重い。
@export var area_per_mass := 300.0
@export var skin_stiffness := 2000.0
@export var skin_damping := 8.0
@export var pressure_strength := 40.0
@export var pressure_max := 30000.0
@export var core_stiffness := 180.0
@export var core_damping := 12.0
@export var color := Color(1.0, 0.8, 0.55)
## 出現時の大きさの倍率。1未満なら grow_time かけて元の大きさまで膨らむ。
@export var start_scale := 1.0
@export var grow_time := 0.25

var _beads: Array[RigidBody2D] = []
var _core: RigidBody2D
var _rest_length := 0.0
var _target_area := 0.0
var _growth := 1.0


func _ready() -> void:
	var ring_radius := radius - bead_radius
	var count := BlobForces.bead_count_for(ring_radius, bead_spacing)
	_rest_length = 2.0 * ring_radius * sin(PI / count)
	var material := PhysicsMaterial.new()
	material.friction = 0.0
	material.bounce = 0.0
	_growth = start_scale
	var points := PackedVector2Array()
	for i in count:
		var p := Vector2.from_angle(TAU * i / count) * ring_radius
		points.append(p)
		_beads.append(_create_bead(p * _growth, material))
	_target_area = BlobForces.polygon_area(points)
	# 同じ猫の玉どうしは重なり合うことがあるので、衝突させない
	for a in _beads:
		for b in _beads:
			if a != b:
				a.add_collision_exception_with(b)
	var total_mass := PI * radius * radius / area_per_mass
	_core = _create_core(maxf(total_mass - count * bead_mass, bead_mass))


func get_beads() -> Array[RigidBody2D]:
	return _beads


func get_core() -> RigidBody2D:
	return _core


## 今の速度に velocity を加える。
func launch(velocity: Vector2) -> void:
	_core.linear_velocity += velocity
	for bead in _beads:
		bead.linear_velocity += velocity


func get_growth() -> float:
	return _growth


## delta 秒ぶん、元の大きさに向かって膨らむ。
func grow(delta: float) -> void:
	_growth = move_toward(_growth, 1.0, (1.0 - start_scale) * delta / grow_time)


func get_total_mass() -> float:
	return _core.mass + _beads.size() * bead_mass


## 玉の中心を結んだ多角形（グローバル座標）。
func get_outline() -> PackedVector2Array:
	var points := PackedVector2Array()
	for bead in _beads:
		points.append(bead.global_position)
	return points


func get_area_ratio() -> float:
	return BlobForces.polygon_area(get_outline()) / _target_area


func _physics_process(delta: float) -> void:
	grow(delta)
	var points := get_outline()
	var velocities := PackedVector2Array()
	var ring_center := Vector2.ZERO
	var ring_velocity := Vector2.ZERO
	for bead in _beads:
		velocities.append(bead.linear_velocity)
		ring_center += bead.global_position
		ring_velocity += bead.linear_velocity
	ring_center /= _beads.size()
	ring_velocity /= _beads.size()

	var skin := BlobForces.skin_forces(
		points, velocities, _rest_length * _growth, skin_stiffness, skin_damping
	)
	var pressure := BlobForces.pressure_forces(
		points, _target_area * _growth * _growth, pressure_strength, pressure_max
	)
	var core := BlobForces.core_force(
		ring_center, ring_velocity, _core.global_position, _core.linear_velocity,
		core_stiffness, core_damping
	) * _core.mass
	_core.apply_central_force(core)
	# 重りを引いた反作用を輪全体で受け持つ
	var core_reaction := -core / _beads.size()
	for i in _beads.size():
		_beads[i].apply_central_force((skin[i] + pressure[i]) * bead_mass + core_reaction)
	queue_redraw()


func _draw() -> void:
	var outline := get_outline()
	var center := Vector2.ZERO
	for p in outline:
		center += p
	center /= outline.size()
	# 玉の外側の縁まで膨らませる
	var edge := PackedVector2Array()
	for p in outline:
		edge.append(to_local(p + (p - center).normalized() * bead_radius))
	var local_center := to_local(center)
	var body := BlobShape.smooth(BlobShape.smooth(edge))
	if Geometry2D.triangulate_polygon(body).is_empty():
		return  # 輪がねじれた瞬間は描かない
	var ears := BlobShape.ear_indices(edge, local_center)
	_draw_ear(edge[ears.x], local_center)
	_draw_ear(edge[ears.y], local_center)
	draw_colored_polygon(body, color)
	body.append(body[0])
	draw_polyline(body, LINE_COLOR, LINE_WIDTH, true)
	_draw_face(to_local(_core.global_position))


func _draw_ear(base: Vector2, center: Vector2) -> void:
	var outward := (base - center).normalized()
	var side := outward.orthogonal() * radius * 0.28
	var root := base - outward * radius * 0.15
	var ear := PackedVector2Array([root - side, base + outward * radius * 0.3, root + side])
	draw_colored_polygon(ear, color)
	ear.append(ear[0])
	draw_polyline(ear, LINE_COLOR, LINE_WIDTH, true)


func _draw_face(center: Vector2) -> void:
	var eye := maxf(radius * 0.06, 2.0)
	draw_circle(center + Vector2(-radius * 0.28, -radius * 0.38), eye, LINE_COLOR)
	draw_circle(center + Vector2(radius * 0.28, -radius * 0.38), eye, LINE_COLOR)
	if label.is_empty():
		return
	var font := ThemeDB.fallback_font
	var font_size := maxi(int(radius * 0.6), 12)
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center + Vector2(-size.x / 2.0, font.get_ascent(font_size) / 2.0 - radius * 0.02)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LINE_COLOR)


func _create_bead(local_position: Vector2, material: PhysicsMaterial) -> RigidBody2D:
	var bead := RigidBody2D.new()
	bead.position = local_position
	bead.mass = bead_mass
	bead.lock_rotation = true
	bead.physics_material_override = material
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = bead_radius
	shape.shape = circle
	bead.add_child(shape)
	add_child(bead)
	return bead


func _create_core(core_mass: float) -> RigidBody2D:
	var core := RigidBody2D.new()
	core.mass = core_mass
	core.lock_rotation = true
	core.collision_layer = 0
	core.collision_mask = 0
	add_child(core)
	return core
