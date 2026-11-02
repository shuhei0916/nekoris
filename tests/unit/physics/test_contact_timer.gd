extends GutTest

const ContactTimer = preload("res://src/physics/contact_timer.gd")


func test_触れていない組の経過時間は0():
	var timer := ContactTimer.new()
	assert_eq(timer.elapsed("a-b"), 0.0)


func test_触れている間は経過時間が積み重なる():
	var timer := ContactTimer.new()
	timer.update(["a-b"], 0.1)
	timer.update(["a-b"], 0.2)
	assert_almost_eq(timer.elapsed("a-b"), 0.3, 0.0001)


func test_一度離れると経過時間は0から数え直す():
	var timer := ContactTimer.new()
	timer.update(["a-b"], 0.3)
	timer.update([], 0.1)
	timer.update(["a-b"], 0.1)
	assert_almost_eq(timer.elapsed("a-b"), 0.1, 0.0001)


func test_組ごとに別々に数える():
	var timer := ContactTimer.new()
	timer.update(["a-b"], 0.3)
	timer.update(["a-b", "c-d"], 0.1)
	assert_almost_eq(timer.elapsed("a-b"), 0.4, 0.0001)
	assert_almost_eq(timer.elapsed("c-d"), 0.1, 0.0001)
