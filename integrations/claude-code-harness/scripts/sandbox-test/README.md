# Sandbox Test

> `/work --full` 動作確認用のテストディレクトリ

## 目的

このディレクトリは Claude harness v2.9.0 で追加された `/work --full` コマンドと `task-worker` エージェントの動作確認のために作成されました。

## ファイル構成

| ファイル | 説明 |
|---------|------|
| `greeting.ts` | テスト用ユーティリティ関数 |
| `greeting.test.ts` | ユニットテスト（Vitest） |
| `README.md` | このファイル |

## テスト実行

```bash
# Vitest がインストールされている場合
npx vitest run scripts/sandbox-test/

# または
bun test scripts/sandbox-test/
```

## /work --full テスト結果

このディレクトリは以下のコマンドで生成されました：

```bash
/work --full --parallel 3
```

### 期待した動作

1. **SOVEREIGN**: 3つの task-worker が並列起動
   - task-worker #1: `greeting.ts` 作成
   - task-worker #2: `greeting.test.ts` 作成
   - task-worker #3: `README.md` 作成

2. **SOVEREIGN**: Codex 8並列クロスレビュー（オプション）

3. **SOVEREIGN**: コンフリクト解消 → コミット

## 関連ドキュメント

- [/work --full ドキュメント](../../docs/PARALLEL_FULL_CYCLE.md)
- [task-worker エージェント](../../agents/task-worker.md)
