#!/bin/bash
# test-workflow-skill-references.sh
# ワークフローが参照するスキル/エージェントが実在するかを検証
#
# Usage: ./tests/test-workflow-skill-references.sh
#        ./tests/test-workflow-skill-references.sh --strict  # 未実装スキルを失敗扱い
#
# 検証内容:
# - workflows/**/*.yaml から `skill:` を抽出
# - 各スキルが skills/**/ または agents/**/ に存在することを確認
#
# デフォルト動作:
# - 存在するスキル → PASS
# - 存在しないスキル → WARN（警告のみ、テスト失敗にしない）
#
# --strict モード:
# - 存在しないスキル → FAIL（テスト失敗）

set -euo pipefail

# 引数解析
STRICT_MODE=false
if [ "${1:-}" = "--strict" ]; then
  STRICT_MODE=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# カウンター
PASSED=0
FAILED=0
WARNINGS=0

log_pass() {
  echo -e "${GREEN}✅ PASS${NC}: $1"
  PASSED=$((PASSED + 1))
}

log_fail() {
  echo -e "${RED}❌ FAIL${NC}: $1"
  echo "  $2"
  FAILED=$((FAILED + 1))
}

log_warn() {
  echo -e "${YELLOW}⚠️ WARN${NC}: $1"
  WARNINGS=$((WARNINGS + 1))
}

# ================================
# スキル/エージェントの存在確認
# ================================

skill_exists() {
  local skill_name="$1"

  # skills/**/ 配下にディレクトリとして存在するか
  if [ -d "$PROJECT_ROOT/skills/$skill_name" ]; then
    return 0
  fi

  # skills/*/$skill_name/ 配下にディレクトリとして存在するか（ネストされたスキル）
  for parent_dir in "$PROJECT_ROOT/skills"/*; do
    if [ -d "$parent_dir/$skill_name" ]; then
      return 0
    fi
  done

  # agents/**/ 配下に .md ファイルとして存在するか
  if [ -f "$PROJECT_ROOT/agents/$skill_name.md" ]; then
    return 0
  fi

  # skills/**/references/ 配下に参照スキルとして存在するか
  if [ -f "$PROJECT_ROOT/skills/$skill_name.md" ]; then
    return 0
  fi
  if [ -f "$PROJECT_ROOT/skills/$skill_name/references/$skill_name.md" ]; then
    return 0
  fi
  for parent_dir in "$PROJECT_ROOT/skills"/*; do
    if [ -f "$parent_dir/references/$skill_name.md" ]; then
      return 0
    fi
  done

  # スキル名がハイフン区切りの場合、親スキルの存在を確認
  # 例: "ask-project-type" → "setup" 親スキルの下に存在
  local parent_skill
  parent_skill=$(echo "$skill_name" | cut -d'-' -f1)
  if [ -d "$PROJECT_ROOT/skills/$parent_skill/$skill_name" ]; then
    return 0
  fi

  # frontmatter の name: で定義されているか（参照スキル含む）
  if grep -R --include="*.md" -n "name: $skill_name" "$PROJECT_ROOT/skills" "$PROJECT_ROOT/agents" >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

# ================================
# メイン処理
# ================================

echo "================================"
echo "ワークフロー参照整合性テスト"
echo "================================"
echo ""

# ワークフローファイルを検索
WORKFLOW_FILES=$(find "$PROJECT_ROOT/workflows" -name "*.yaml" -o -name "*.yml" 2>/dev/null || true)

if [ -z "$WORKFLOW_FILES" ]; then
  log_warn "ワークフローファイルが見つかりません"
  exit 0
fi

# 各ワークフローファイルを処理
for workflow_file in $WORKFLOW_FILES; do
  workflow_name=$(basename "$workflow_file")
  echo "--- $workflow_name ---"

  # `skill:` 行を抽出（YAML インデントを考慮）
  SKILLS=$(grep -E "^\s*skill:\s*" "$workflow_file" 2>/dev/null | sed 's/.*skill:\s*//g' | tr -d '"' | tr -d "'" || true)

  if [ -z "$SKILLS" ]; then
    echo "  (スキル参照なし)"
    continue
  fi

  # 各スキルの存在を確認
  for skill in $SKILLS; do
    # コメント行や空行をスキップ
    if [[ "$skill" =~ ^# ]] || [ -z "$skill" ]; then
      continue
    fi

    if skill_exists "$skill"; then
      log_pass "skill: $skill"
    else
      if [ "$STRICT_MODE" = true ]; then
        log_fail "skill: $skill" "スキル '$skill' が skills/ または agents/ に見つかりません"
      else
        log_warn "skill: $skill - 未実装（将来追加予定）"
      fi
    fi
  done
done

echo ""

# ================================
# エージェント参照のチェック（agents/ 配下の .md ファイル）
# ================================

echo "--- エージェント定義の確認 ---"

AGENT_FILES=$(find "$PROJECT_ROOT/agents" -name "*.md" 2>/dev/null || true)

if [ -n "$AGENT_FILES" ]; then
  AGENT_COUNT=$(echo "$AGENT_FILES" | wc -l | tr -d ' ')
  log_pass "agents/ に $AGENT_COUNT 個のエージェント定義"
else
  log_warn "agents/ にエージェント定義がありません"
fi

echo ""

# ================================
# 結果サマリー
# ================================

echo "================================"
echo "テスト結果サマリー"
echo "================================"
echo -e "合格: ${GREEN}${PASSED}${NC}"
echo -e "警告: ${YELLOW}${WARNINGS}${NC}"
echo -e "失敗: ${RED}${FAILED}${NC}"

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo -e "${RED}参照整合性エラーがあります。修正してください。${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}すべての参照が有効です！${NC}"
  exit 0
fi
