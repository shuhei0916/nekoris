# TODO

未着手・確認待ちのタスク。終わったものは消すか、完了にチェックを付ける。

## 確認待ち
- [ ] 暖色系の背景とポーズメニューの見た目を、エディタでシーンを実行して確認する（AI はヘッドレスで動作のみ確認済み。色・レイアウトは未確認）
- [ ] 猫の配色を新しい背景に合わせて見直す（黄色の「2」の猫 `ffd23f` がクリーム色の容器 `ffe7b5` と近い色で見づらい可能性がある。`src/rules/cat_rules.gd` の `PALETTE`）

## 質感
- [ ] 猫の張りを出す。`src/blob/blob.gd` で `skin_stiffness=8000`・`internal_damping=80` を試す（README「張りを出したいとき」を参照）
  - 試すだけなら `tools/drop_test.gd -- skin_stiffness=8000 internal_damping=80`
  - 決めたら `tests/integration/test_landing_feel.gd` が通るか確かめる
- [ ] `tools/drop_test.gd` などで値を上げすぎると計算が発散して固まる（例: `skin_stiffness=15000 skin_damping=30`）。発散を検知して打ち切る仕組みを入れるか検討する

## ゲームとして足りないもの
- [ ] ゲームオーバー（猫が容器からあふれたら終わる）と、やり直し
- [ ] ベストスコアの保存と表示（参考画像のスコア枠の下にあるもの）
- [ ] ポーズメニューに「やり直す」を追加するか検討する

## 開発環境
- [ ] `run_tests.sh` の既定の Godot のパス（`/c/Users/shuhe/Godot/godot.exe`）が環境ごとに違う。環境変数 `GODOT` が無いときに分かりやすいエラーを出すなど、環境をまたいでも迷わないようにする
