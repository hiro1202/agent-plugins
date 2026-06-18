# agent-plugins

> **Note:** `CLAUDE.md` はこのファイルへのシンボリックリンクです。編集は `AGENTS.md` だけに行えば、Claude Code（`CLAUDE.md`）と Codex（`AGENTS.md`）の両方に反映されます。

個人用の、AI コーディングエージェント向けプラグイン集です。**Claude Code** と **OpenAI Codex** の両方に対応します。これはそのリポジトリで作業するエージェント向けのコンテキストファイルです。利用者・コントリビューター向けの手順は [`README.md`](./README.md) を参照してください。

## コアコンセプト

| 概念 | 中身 | 例 |
| --- | --- | --- |
| **Plugin** | 配布単位のバンドル（スキル等をまとめたもの） | `terraform`、`aws` |
| **Skill** | ユーザーの意図に応じて自動起動する指示書（YAML フロントマターの `description` で判定） | 「この Terraform をレビューして」→ `code-review` スキル |
| **Marketplace** | プラグインのカタログ（インストール元） | `agent-plugins` |

### 設計上の要点：スキルは自動起動する

スキルは固定のスラッシュコマンド**ではありません**。エージェントが `SKILL.md` のフロントマター `description` を読み、ユーザーの意図に一致したときに自分で呼び出します。したがって `description` は「いつ使うか」が伝わるように書きます。

### 設計上の要点：エージェントごとに独立したツリー

プラグイン本体は **`plugins/claude/<name>/` と `plugins/codex/<name>/` にエージェントごと分けて**置きます。各ツリーはそのエージェント用のマニフェスト・スキル・`.mcp.json`（将来は hooks 等も）を**自己完結で**持ちます。これは、スキルだけでなく MCP や hooks まで増えると、両エージェントの仕様を同時に考えながら 1 ツリーで管理するのが現実的でないためです。

2 つのツリーは「**方向性が合っていれば中身は同一でなくてよい**」という緩い関係です。同期は手動でも AI 翻訳でもよく、**どちらを正本にしても構いません**（Claude をメインにする時期も、Codex をメインにする時期もありうる）。ツール名や起動構文などエージェント固有の差分は、各ツリーで素直に持たせます。

各エージェントの規約は公式ドキュメントに従います。Codex 側は OpenAI 公式（[Build plugins](https://developers.openai.com/codex/plugins/build)、[Agent Skills](https://developers.openai.com/codex/skills)）、Claude Code 側は [Claude Code 公式のプラグイン仕様](https://docs.claude.com/en/docs/claude-code/plugins)。

## ディレクトリ構成

```
agent-plugins/
├── AGENTS.md                     # このファイル（エージェント向けコンテキスト）
├── CLAUDE.md                     # → AGENTS.md へのシンボリックリンク
├── README.md                     # 利用者・コントリビューター向け手順書
├── .claude-plugin/
│   └── marketplace.json          # Claude Code 用カタログ
├── .agents/
│   └── plugins/marketplace.json  # Codex 用カタログ
└── plugins/                      # プラグイン本体（エージェントごとに分割）
    ├── claude/                   # Claude Code 用ツリー
    │   ├── terraform/
    │   │   ├── .claude-plugin/plugin.json   # Claude Code 用マニフェスト
    │   │   ├── .mcp.json                    # MCP サーバー定義（自動検出）
    │   │   └── skills/code-review/SKILL.md
    │   ├── aws/
    │   │   ├── .claude-plugin/plugin.json
    │   │   ├── .mcp.json
    │   │   └── skills/cost-estimate/SKILL.md
    │   └── git/
    │       ├── .claude-plugin/plugin.json
    │       └── skills/commit-and-pr/SKILL.md
    └── codex/                    # Codex 用ツリー（claude/ と同じ並びで対応）
        ├── terraform/
        │   ├── .codex-plugin/plugin.json    # Codex 用マニフェスト
        │   ├── .mcp.json
        │   └── skills/code-review/SKILL.md
        ├── aws/
        │   ├── .codex-plugin/plugin.json
        │   ├── .mcp.json
        │   └── skills/cost-estimate/SKILL.md
        └── git/
            ├── .codex-plugin/plugin.json
            └── skills/commit-and-pr/SKILL.md
```

`plugins/claude/<name>/` と `plugins/codex/<name>/` は**同じ相対パスで 1:1 対応**します。片方を直したら、対応するパスのもう片方を（方向性が合う範囲で）合わせます。

## 共通化の方針（何を共有し、何を分けるか）

方針はシンプルです。**プラグイン本体はエージェントごとに別ツリー（`plugins/claude/` ・ `plugins/codex/`）として分け、リポジトリ全体の指示書だけ symlink で共有**します。エージェント間で増えていく仕様差（マニフェスト・MCP・hooks・スキル中のツール名や起動構文）を、1 ツリーで同時に背負わない、という割り切りです。

| 対象 | 方式 | 理由 |
| --- | --- | --- |
| エージェント指示書（`AGENTS.md` / `CLAUDE.md`） | **シンボリックリンクで共有**（`CLAUDE.md` → `AGENTS.md`） | リポジトリ全体の文脈で、ツール固有の記述が少なく本当に同一でよい数少ないケース。Codex は `AGENTS.md`、Claude Code は `CLAUDE.md` を素の Markdown として読むだけ。 |
| プラグイン本体（マニフェスト・`SKILL.md`・`.mcp.json`・hooks 等） | **エージェントごとに別ツリー**（`plugins/claude/` ・ `plugins/codex/`） | スキーマ・仕組みがエージェントで異なり、増えるほど差が開く。同じ相対パスで 1:1 対応させ、方向性が合う範囲で同期（手動／AI どちらでも、どちら向きでも可）。 |
| マーケットプレースカタログ | **エージェントごとに別ファイル** | スキーマが異なる（Claude=`source` 文字列＋`keywords`/`tags`、Codex=`source` オブジェクト＋`policy`）。それぞれ自分のツリー（`plugins/claude/*` / `plugins/codex/*`）を指す。 |

> 結論: symlink で共通化するのは `AGENTS.md` / `CLAUDE.md` の 1 組だけ。プラグイン本体は `plugins/<agent>/` でエージェント別に分け、2 ツリーを 1:1 対応で揃える。新しいエージェントを足す場合は `plugins/<agent>/` ツリーと専用カタログを追加し、指示書を読むなら `AGENTS.md` への symlink を増やす。なお Codex は `.claude-plugin/marketplace.json` もレガシー互換として読めるが、`.agents/plugins/marketplace.json` が正式な置き場所（[公式: Build plugins](https://developers.openai.com/codex/plugins/build)）。

## 同梱プラグイン

| プラグイン | スキル | 内容 |
| --- | --- | --- |
| `terraform` | `code-review` | Terraform コード（.tf / .tfvars）をセキュリティ・ベストプラクティス・運用観点でレビューする（読み取り専用）。 |
| `aws` | `cost-estimate` | 説明文や IaC ファイルから月額 AWS コストを見積もる。 |
| `git` | `commit-and-pr` | 変更をコミットし、プルリクエストを作成する（Conventional Commits 準拠・安全なガードレール付き）。 |

## 新しいプラグイン／スキルを追加するときの手順

メインで作る側（多くの場合 Claude）から作り、もう片方へ展開します。

1. `plugins/claude/<name>/skills/<skill>/SKILL.md` を作る。フロントマターに `name` と「いつ使うか」が伝わる `description` を必ず書く。MCP を使うなら `plugins/claude/<name>/.mcp.json` も置く。
2. `plugins/claude/<name>/.claude-plugin/plugin.json` を作る。
3. もう片方のツリー `plugins/codex/<name>/` に対応物を用意する。`.codex-plugin/plugin.json`（`name` / `version` は claude 側と一致させる）と、`skills/` ・ `.mcp.json` を方向性が合う範囲で展開する。ツール名・起動構文などエージェント固有の差分はここで吸収する。
4. `.claude-plugin/marketplace.json`（`./plugins/claude/<name>` を指す）と `.agents/plugins/marketplace.json`（`./plugins/codex/<name>` を指す）の両方にエントリを追加する。
5. バリデーションを実行する（下記）。
6. README の「同梱プラグイン」表を更新する。

## バリデーション

```bash
# Claude Code 用マニフェスト
claude plugin validate ./plugins/claude/<name> --strict

# Codex 用カタログ（読み込めることを確認）
# 注意: CODEX_HOME での隔離は効かず、実環境の ~/.codex/config.toml に登録される（codex 0.130 で確認）。
# ローカル登録は作業ディレクトリを直接参照するため、変更後の再登録は不要（upgrade は Git ソース専用）。
codex plugin marketplace add "$(pwd)"          # 初回のみ
codex plugin marketplace remove agent-plugins  # 後始末（任意）

# JSON の妥当性
python3 -m json.tool <file.json> >/dev/null
```

## 規約・境界

- プラグイン本体はエージェントごとに `plugins/claude/` ・ `plugins/codex/` に分ける。2 ツリーは同じ相対パスで 1:1 対応させ、方向性が合う範囲で同期する（手動／AI どちらでも、どちら向きでも可）。
- `version` を変更するときは対応する `plugins/claude/<name>/.claude-plugin/plugin.json` と `plugins/codex/<name>/.codex-plugin/plugin.json` を必ず揃える（SemVer）。
- スキルはレビュー／見積もりなど読み取り中心。`terraform apply` やコスト確定など破壊的・確定的な操作はユーザーの明示的な依頼まで行わない。各スキルの「原則」セクションに従う。
- CHANGELOG は管理しない。変更履歴は Git のコミット履歴を正とする。
- 既存ファイルを大きく変更する前にはユーザーに一声かける。
