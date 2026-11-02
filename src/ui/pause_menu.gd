## Esc で開くポーズメニュー。開いている間はゲームを止める。
extends CanvasLayer

## 「ゲームを閉じる」が押された。
signal quit_requested

const DIM_COLOR := Color(0.25, 0.15, 0.05, 0.55)
const PANEL_COLOR := Color("fff1d6")
const PANEL_BORDER_COLOR := Color("e9b866")
const TEXT_COLOR := Color("6b4220")
const BUTTON_COLOR := Color("ea8a2a")
const BUTTON_HOVER_COLOR := Color("f39c3d")
const BUTTON_TEXT_COLOR := Color.WHITE

var resume_button: Button
var quit_button: Button


func _init() -> void:
	layer = 10
	visible = false
	# ゲームを止めている間も、このメニューだけは動かす
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL_COLOR, PANEL_BORDER_COLOR, 24, 28))
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)

	var title := Label.new()
	title.text = "ポーズ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	column.add_child(title)

	resume_button = _button("ゲームを再開")
	resume_button.pressed.connect(close)
	column.add_child(resume_button)

	quit_button = _button("ゲームを閉じる")
	quit_button.pressed.connect(quit_requested.emit)
	column.add_child(quit_button)


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 56)
	button.add_theme_font_size_override("font_size", 22)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, BUTTON_TEXT_COLOR)
	button.add_theme_stylebox_override("normal", _box(BUTTON_COLOR, BUTTON_COLOR, 14, 0))
	button.add_theme_stylebox_override("hover", _box(BUTTON_HOVER_COLOR, BUTTON_HOVER_COLOR, 14, 0))
	button.add_theme_stylebox_override("pressed", _box(BUTTON_COLOR.darkened(0.15), BUTTON_COLOR, 14, 0))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, Color.WHITE, 14, 0, 3))
	return button


func _box(fill: Color, border: Color, corner: int, padding: int, border_width := 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width if border != fill else 0)
	box.set_corner_radius_all(corner)
	box.set_content_margin_all(padding)
	return box
