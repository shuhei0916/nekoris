extends GutTest

func test_fail():
	assert_eq(1, 2, "このテストは失敗するはず")
