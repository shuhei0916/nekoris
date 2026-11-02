extends GutTest

const PauseMenu = preload("res://src/ui/pause_menu.gd")

var _menu: CanvasLayer


func before_each() -> void:
	_menu = PauseMenu.new()
	add_child_autofree(_menu)


func after_each() -> void:
	get_tree().paused = false


func _press_escape() -> void:
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	_menu._unhandled_input(event)


func test_はじめはメニューを閉じていてゲームは動いている():
	assert_false(_menu.visible)
	assert_false(get_tree().paused)


func test_escでメニューを開くとゲームが止まる():
	_press_escape()
	assert_true(_menu.visible)
	assert_true(get_tree().paused)


func test_もう一度escを押すとメニューを閉じてゲームを再開する():
	_press_escape()
	_press_escape()
	assert_false(_menu.visible)
	assert_false(get_tree().paused)


func test_再開ボタンでメニューを閉じてゲームを再開する():
	_menu.open()
	_menu.resume_button.pressed.emit()
	assert_false(_menu.visible)
	assert_false(get_tree().paused)


func test_閉じるボタンでゲームを閉じるよう求める():
	watch_signals(_menu)
	_menu.open()
	_menu.quit_button.pressed.emit()
	assert_signal_emitted(_menu, "quit_requested")


func test_止めている間もメニューは動く():
	assert_eq(_menu.process_mode, Node.PROCESS_MODE_ALWAYS)
