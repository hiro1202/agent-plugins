#!/usr/bin/env bash
#
# agent-plugins のスキルを OpenAI Codex CLI のカスタムプロンプトとして取り込む。
# codex/prompts/*.md を ~/.codex/prompts/ にコピー（既定）またはシンボリックリンク（--link）する。
#
# 使い方:
#   ./codex/install.sh           # コピーして取り込む
#   ./codex/install.sh --link    # シンボリックリンクで取り込む（リポジトリ更新が即反映）
#
set -euo pipefail

LINK=0
for arg in "$@"; do
  case "$arg" in
    --link) LINK=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "不明な引数: $arg" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/prompts"
DEST_DIR="${CODEX_HOME:-$HOME/.codex}/prompts"

if [ ! -d "$SRC_DIR" ]; then
  echo "プロンプトディレクトリが見つかりません: $SRC_DIR" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

count=0
for src in "$SRC_DIR"/*.md; do
  [ -e "$src" ] || continue
  name="$(basename "$src")"
  dest="$DEST_DIR/$name"
  if [ "$LINK" -eq 1 ]; then
    ln -sf "$src" "$dest"
    echo "linked  $name"
  else
    cp -f "$src" "$dest"
    echo "copied  $name"
  fi
  count=$((count + 1))
done

echo ""
echo "$count 個のプロンプトを $DEST_DIR に取り込みました。"
echo "Codex CLI のセッションで /agent-plugins- から始まるスラッシュコマンドとして使えます。"
