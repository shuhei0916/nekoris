#!/bin/sh
# GUT をヘッドレスで実行する
GODOT="${GODOT:-/c/Users/shuhe/Godot/godot.exe}"
cd "$(dirname "$0")" && "$GODOT" --headless -s addons/gut/gut_cmdln.gd "$@"
