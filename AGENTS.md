# agent-plugins

> **Note:** `CLAUDE.md` はこのファイルへのシンボリックリンクです。編集は `AGENTS.md` だけに行えば、Claude Code（`CLAUDE.md`）と Codex（`AGENTS.md`）の両方に反映されます。

個人用の、AI コーディングエージェント向けプラグイン集です。**Claude Code 用（`plugins/claude/`）を正本**として開発し、**OpenAI Codex 用（`plugins/codex/`）は必要になったときに claude 側から生成**します。これはこのリポジトリで作業するエージェント向けのコンテキストファイルです。利用者・コントリビューター向けの手順は [`README.md`](./README.md) を参照してください。

## コアコンセプト

| 概念 | 中身 | 例 |
| --- | --- | --- |
| **Plugin** | 配布単位のバンドル（スキル等をまとめたもの） | `terraform`、`aws` |
| **Skill** | ユーザーの意図に応じて自動起動する指示書（YAML フロントマターの `description` で判定） | 「この Terraform をレビューして」→ `code-review` スキル |
| **Marketplace** | プラグインのカタログ（インストール元） | `agent-plugins` |

### 設計上の要点：スキルは自動起動する

スキルは固定のスラッシュコマンド**ではありません**。エージェントが `SKILL.md` のフロントマター `description` を読み、ユーザーの意図に一致したときに自分で呼び出します。したがって `description` は「いつ使うか」が伝わるように書きます。

### 設計上の要点：claude が正本、codex は生成物

- 開発・改善・新規作成は **`plugins/claude/<name>/` だけ**で行います。
- `plugins/codex/<name>/` は、必要になったときに **Codex に claude 側を参照させて Codex 向けに最適化した形で生成する**成果物です。日常的には同期せず、claude 側より古くてもよく、対応物が存在しなくてもかまいません。
- 生成済みの codex プラグインは削除しません。Codex ユーザーはそのままインストールできます。

各エージェントの規約は公式ドキュメントに従います。Claude Code 側は [Claude Code 公式のプラグイン仕様](https://docs.claude.com/en/docs/claude-code/plugins)、Codex 側は OpenAI 公式（[Build plugins](https://developers.openai.com/codex/plugins/build)、[Agent Skills](https://developers.openai.com/codex/skills)）。

### 設計上の要点：簡潔に保つ

ドキュメントもスキルも、人間がレビュー・修正できる分量に保ちます。生成物が長くなるほど問題の理解と修正が難しくなるため、追記より圧縮を優先します。

## ディレクトリ構成

```
agent-plugins/
├── AGENTS.md                     # このファイル（エージェント向けコンテキスト）
├── CLAUDE.md                     # → AGENTS.md へのシンボリックリンク
├── README.md                     # 利用者・コントリビューター向け手順書
├── .claude-plugin/
│   └── marketplace.json          # Claude Code 用カタログ（常に全プラグインを掲載）
├── .agents/
│   └── plugins/marketplace.json  # Codex 用カタログ（生成済みプラグインのみ掲載）
└── plugins/
    ├── claude/                   # 正本（Claude Code 用）
    │   ├── terraform/
    │   │   ├── .claude-plugin/plugin.json   # Claude Code 用マニフェスト
    │   │   ├── .mcp.json                    # MCP サーバー定義（自動検出）
    │   │   └── skills/code-review/SKILL.md
    │   ├── aws/    （.claude-plugin/plugin.json, .mcp.json, skills/cost-estimate/SKILL.md）
    │   └── git/    （.claude-plugin/plugin.json, skills/commit-and-pr/SKILL.md）
    └── codex/                    # 生成物（Codex 用。claude 側から必要時に生成）
        ├── terraform/  （.codex-plugin/plugin.json, .mcp.json, skills/code-review/SKILL.md）
        ├── aws/        （.codex-plugin/plugin.json, .mcp.json, skills/cost-estimate/SKILL.md）
        └── git/        （.codex-plugin/plugin.json, skills/commit-and-pr/SKILL.md）
```

## 共通化の方針（何を共有し、何を分けるか）

| 対象 | 方式 | 理由 |
| --- | --- | --- |
| エージェント指示書（`AGENTS.md` / `CLAUDE.md`） | **シンボリックリンクで共有**（`CLAUDE.md` → `AGENTS.md`） | ツール固有の記述が少なく、本当に同一でよい数少ないケース。両エージェントとも素の Markdown として読むだけ。 |
| プラグイン本体（マニフェスト・`SKILL.md`・`.mcp.json` 等） | **claude 側が正本、codex 側は必要時に生成** | スキーマ・仕組みがエージェントで異なる。両方を常時メンテするコストを払わず、Codex 版が要るときだけ AI に変換させる。 |
| マーケットプレースカタログ | **エージェントごとに別ファイル** | スキーマが異なる（Claude=`source` 文字列、Codex=`source` オブジェクト＋`policy`）。Codex 用カタログには生成済みプラグインだけを載せる。 |

> なお Codex は `.claude-plugin/marketplace.json` もレガシー互換として読めるが、`.agents/plugins/marketplace.json` が正式な置き場所（[公式: Build plugins](https://developers.openai.com/codex/plugins/build)）。

## 同梱プラグイン

| プラグイン | スキル | 内容 |
| --- | --- | --- |
| `terraform` | `code-review` | Terraform コード（.tf / .tfvars）をセキュリティ・ベストプラクティス・運用観点でレビューする（読み取り専用）。 |
| `aws` | `cost-estimate` | 説明文や IaC ファイルから月額 AWS コストを見積もる。 |
| `git` | `commit-and-pr` | 変更をコミットし、プルリクエストを作成する（Conventional Commits 準拠・安全なガードレール付き）。 |

## 新しいプラグイン／スキルを追加するときの手順

claude 側だけに作ります。Codex 版はこの時点では作りません。

1. `plugins/claude/<name>/skills/<skill>/SKILL.md` を作る。フロントマターに `name` と「いつ使うか」が伝わる `description` を必ず書く。MCP を使うなら `plugins/claude/<name>/.mcp.json` も置く。
2. `plugins/claude/<name>/.claude-plugin/plugin.json` を作る。
3. `.claude-plugin/marketplace.json` にエントリ（`./plugins/claude/<name>`）を追加する。
4. バリデーションを実行する（下記）。
5. README の「同梱プラグイン」表を更新する。

### Codex 版の生成（必要になったときだけ）

1. Codex に `plugins/claude/<name>/` を読ませ、Codex の仕様に最適化した対応物を `plugins/codex/<name>/` に生成させる（`.codex-plugin/plugin.json` の `name` / `version` は claude 側と一致させる）。
2. `.agents/plugins/marketplace.json` にエントリ（`./plugins/codex/<name>`）を追加する。
3. claude 側を大きく変えたあとに Codex 版を使いたくなったら、同じ手順で再生成する。

## バリデーション

```bash
# Claude Code 用マニフェスト
claude plugin validate ./plugins/claude/<name> --strict

# JSON の妥当性
python3 -m json.tool <file.json> >/dev/null

# Codex 用カタログ（codex 側を生成・変更したときだけ）
# 注意: CODEX_HOME での隔離は効かず、実環境の ~/.codex/config.toml に登録される（codex 0.130 で確認）。
# ローカル登録は作業ディレクトリを直接参照するため、変更後の再登録は不要（upgrade は Git ソース専用）。
codex plugin marketplace add "$(pwd)"          # 初回のみ
codex plugin marketplace remove agent-plugins  # 後始末（任意）
```

## 規約・境界

- 正本は `plugins/claude/`。`plugins/codex/` は生成物で、生成・再生成したときだけ更新する。生成済みのものは削除しない。
- `version` は SemVer。codex 側が存在するプラグインは、再生成のタイミングで `version` を claude 側に揃える。
- ドキュメント・スキルは簡潔に保つ。追記より圧縮を優先する。
- スキルはレビュー／見積もりなど読み取り中心。`terraform apply` やコスト確定など破壊的・確定的な操作はユーザーの明示的な依頼まで行わない。各スキルの「原則」セクションに従う。
- CHANGELOG は管理しない。変更履歴は Git のコミット履歴を正とする。
- 既存ファイルを大きく変更する前にはユーザーに一声かける。
