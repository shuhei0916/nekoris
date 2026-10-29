extends GutTest

const ScoreBoard = preload("res://src/rules/score_board.gd")


func test_はじめは0点():
	assert_eq(ScoreBoard.new().total, 0)


func test_合体するたびに点数が加算される():
	var board := ScoreBoard.new()
	board.add_merge(0)  # 2 + 2 -> 4
	board.add_merge(2)  # 8 + 8 -> 16
	assert_eq(board.total, 20)
