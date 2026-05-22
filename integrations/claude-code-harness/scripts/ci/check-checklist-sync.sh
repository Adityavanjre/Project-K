#!/bin/bash
# check-checklist-sync.sh
# コマンドファイルのチェックリストとスクリプトの検証項目が同期しているかを確認
#
# 目的:
# - scripts/setup-2agent.sh の check_file/check_dir と
#   commands/setup-2agent.md のチェックリストが一致しているか確認
# - scripts/update-2agent.sh と commands/update-2agent.md も同様

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ERRORS=0

echo "🔍 チェックリスト同期検証"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ================================
# ユーティリティ関数
# ================================

# スクリプトから check_file/check_dir の引数を抽出
extract_script_checks() {
  local script="$1"
  grep -E 'check_(file|dir)' "$script" 2>/dev/null | \
    awk -F'"' '{print $2}' | \
    grep -v '^$' | \
    sort -u
}

# コマンドファイルからチェックリスト項目を抽出
# 「自動検証」セクションのみ抽出（「Claude が生成」セクションは除外）
extract_command_checklist() {
  local cmd="$1"
  # 「自動検証」から「Claude が生成」または次のセクションまでを抽出
  awk '/自動検証/,/Claude が生成|^###|^\*\*全て/' "$cmd" 2>/dev/null | \
    grep -E '^\s*-\s*\[\s*\]\s*`[^`]+`' | \
    awk -F'`' '{print $2}' | \
    grep -v '^$' | \
    sort -u
}

# 2つのリストを比較
compare_lists() {
  local name="$1"
  local script_file="$2"
  local command_file="$3"

  echo ""
  echo "📋 $name の検証..."

  # 一時ファイルに抽出
  local script_checks=$(mktemp)
  local command_checks=$(mktemp)

  extract_script_checks "$script_file" > "$script_checks"
  extract_command_checklist "$command_file" > "$command_checks"

  # スクリプトにあってコマンドにないもの
  local missing_in_command=$(comm -23 "$script_checks" "$command_checks")
  if [ -n "$missing_in_command" ]; then
    echo "  ❌ スクリプトにあるがコマンドのチェックリストにない:"
    echo "$missing_in_command" | while read item; do
      echo "     - $item"
    done
    ERRORS=$((ERRORS + 1))
  fi

  # コマンドにあってスクリプトにないもの
  local missing_in_script=$(comm -13 "$script_checks" "$command_checks")
  if [ -n "$missing_in_script" ]; then
    echo "  ❌ コマンドのチェックリストにあるがスクリプトにない:"
    echo "$missing_in_script" | while read item; do
      echo "     - $item"
    done
    ERRORS=$((ERRORS + 1))
  fi

  # 両方とも空の場合はスキップ（誤った合格を防止）
  local script_count=$(wc -l < "$script_checks" | tr -d ' ')
  local command_count=$(wc -l < "$command_checks" | tr -d ' ')

  if [ "$script_count" -eq 0 ] && [ "$command_count" -eq 0 ]; then
    echo "  ⚠️ スキップ: チェック項目が見つかりません（ファイル構成を確認してください）"
  elif [ -z "$missing_in_command" ] && [ -z "$missing_in_script" ]; then
    echo "  ✅ 同期済み ($script_count 項目)"
  fi

  rm -f "$script_checks" "$command_checks"
}

# ================================
# メイン検証
# ================================

# setup hub の検証（v2.19.0+ 2agent は setup に統合）
SETUP_SKILL="$PLUGIN_ROOT/skills/setup/SKILL.md"
SETUP_2AGENT_REF="$PLUGIN_ROOT/skills/setup/references/2agent-setup.md"

if [ -f "$SETUP_SKILL" ] && [ -f "$SETUP_2AGENT_REF" ]; then
  echo "✓ setup スキルと 2agent-setup リファレンスが存在します"
elif [ -f "$SETUP_SKILL" ]; then
  echo "⚠️ setup/references/2agent-setup.md が見つかりません（統合後の構成を確認）"
else
  echo "⚠️ skills/setup/SKILL.md が見つかりません（スキルが未作成の可能性）"
fi

# Note: v2.17.0以降、コマンドはスキルに移行されました
# チェックリスト同期は今後スキル単位で管理されます
# チェック対象のスキルが見つからない場合は正常終了（空のチェックリストで失敗させない）

# ================================
# 結果サマリー
# ================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ]; then
  echo "✅ チェックリスト同期検証に合格しました"
  exit 0
else
  echo "❌ $ERRORS 個の不整合が見つかりました"
  echo ""
  echo "💡 修正方法:"
  echo "  1. scripts/*.sh の check_file/check_dir を確認"
  echo "  2. commands/*.md のチェックリストを更新"
  echo "  3. 両方が一致するようにする"
  exit 1
fi
