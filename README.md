# agent-plugins

個人用の、AI コーディングエージェント向けプラグイン集。**Claude Code** と **OpenAI Codex** の両方で同じプラグインを利用できます。プラグイン本体は `plugins/claude/` と `plugins/codex/` にエージェントごと分けて置き、同じ並びで 1:1 対応させます（方向性が合う範囲で同期）。Codex 側は OpenAI 公式の [Build plugins](https://developers.openai.com/codex/plugins/build)・[Agent Skills](https://developers.openai.com/codex/skills) に、Claude Code 側は [Claude Code 公式のプラグイン仕様](https://docs.claude.com/en/docs/claude-code/plugins)に準拠します。

エージェントがこのリポジトリで作業するための設計メモは [`AGENTS.md`](./AGENTS.md)（= `CLAUDE.md`）にあります。本書はインストール・利用・プラグイン追加の**手順書**です。

## 同梱プラグイン

| プラグイン | スキル | 内容 |
| --- | --- | --- |
| `terraform` | `code-review` | Terraform コード（.tf / .tfvars）をセキュリティ / ベストプラクティス / 運用観点でレビューする。 |
| `aws` | `cost-estimate` | 説明文や IaC ファイルから月額 AWS コストを見積もる。 |
| `git` | `commit-and-pr` | 変更をコミットし、プルリクエストを作成する（Conventional Commits 準拠・安全なガードレール付き）。 |

## ディレクトリ構成

```
agent-plugins/
├── AGENTS.md / CLAUDE.md         # エージェント向けコンテキスト（CLAUDE.md は AGENTS.md へのシンボリックリンク）
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
    │   ├── aws/    （.claude-plugin/plugin.json, .mcp.json, skills/cost-estimate/SKILL.md）
    │   └── git/    （.claude-plugin/plugin.json, skills/commit-and-pr/SKILL.md）
    └── codex/                    # Codex 用ツリー（claude/ と同じ並びで対応）
        ├── terraform/
        │   ├── .codex-plugin/plugin.json    # Codex 用マニフェスト
        │   ├── .mcp.json
        │   └── skills/code-review/SKILL.md
        ├── aws/    （.codex-plugin/plugin.json, .mcp.json, skills/cost-estimate/SKILL.md）
        └── git/    （.codex-plugin/plugin.json, skills/commit-and-pr/SKILL.md）
```

---

## 手順 1: Claude Code で使う

### 1-1. マーケットプレースを追加する

```sh
# ローカルのクローンから
/plugin marketplace add /Users/funakihirokazu/Develop/hiro1202/agent-plugins

# または GitHub から直接
/plugin marketplace add hiro1202/agent-plugins
```

### 1-2. プラグインをインストールする

```sh
/plugin install terraform@agent-plugins
/plugin install aws@agent-plugins
```

### 1-3. 使う

スキルは固定コマンドではなく、ユーザーの意図に応じて自動起動します。自然言語で話しかければ Claude が `description` を読んで該当スキルを呼び出します。

```
「この Terraform の差分をレビューして」
「この構成だと AWS で月いくらかかる？」
```

明示的に呼び出したい場合は次のようにします。

```
/terraform:code-review
/aws:cost-estimate
```

---

## 手順 2: Codex で使う

Codex はリポジトリローカルのマーケットプレース（`.agents/plugins/marketplace.json`）と各プラグインのマニフェスト（`plugins/codex/*/.codex-plugin/plugin.json`）を読み取ります（[公式: Build plugins](https://developers.openai.com/codex/plugins/build) に準拠）。

### 2-1. マーケットプレースを追加する

```sh
# ローカルのクローンから（リポジトリのルートを指定）
codex plugin marketplace add /Users/funakihirokazu/Develop/hiro1202/agent-plugins

# または GitHub から直接
codex plugin marketplace add hiro1202/agent-plugins
```

追加済みの確認は `codex plugin marketplace list`、削除は `codex plugin marketplace remove agent-plugins`。

### 2-2. プラグインをインストールする

Codex に `install` サブコマンドはありません。対話 TUI のプラグインブラウザから入れます。

1. `codex` を起動し、`/plugins` と打ってプラグインブラウザを開く。
2. タブを切り替えて `agent-plugins` マーケットプレースを選ぶ。
3. 入れたいプラグイン（`terraform` / `aws` / `git`）を選んでインストールする。

`✓ Installed ...` と出れば完了です。`codex plugin list` で `installed, enabled` を確認できます。

### 2-3. 使う

> **重要:** インストール直後の**同じセッションにはスキルが読み込まれません**。一度 Codex を完全に終了し、`codex` を起動し直してください（スキルはセッション開始時に読み込まれます）。

新しいセッションなら、Claude Code と同じく自然言語で自動起動します。

```
「この Terraform の差分をレビューして」
「この構成だと AWS で月いくらかかる？」
```

明示的に呼び出すときは `$プラグイン名:スキル名` の形式です（Claude Code の `/プラグイン名:スキル名` に対応）。

```
$terraform:code-review
$aws:cost-estimate
$git:commit-and-pr
```

`$` を打つとスキル名の補完候補が出ます。`/skills` でもインストール済みスキルの一覧から選べます。

> 既知の制限: Claude Code 固有の自動フック（`hooks/`）は Codex マニフェストには接続していません。本リポジトリのプラグインは読み取り専用スキルのみのため、現状フックは含みません。

---

## 手順 3: 新しいプラグイン／スキルを追加する

1. **スキルを作る** — `plugins/claude/<name>/skills/<skill>/SKILL.md`。フロントマターに `name` と「いつ使うか」が伝わる `description` を必ず書く（`description` が自動起動の判定材料になる）。MCP を使うなら `plugins/claude/<name>/.mcp.json` も置く。
2. **マニフェストを作る** — `plugins/claude/<name>/.claude-plugin/plugin.json`。
3. **もう片方のツリーへ展開する** — `plugins/codex/<name>/` に `.codex-plugin/plugin.json`（`name` / `version` は claude 側と一致）と `skills/` ・ `.mcp.json` を、方向性が合う範囲で用意する。ツール名・起動構文などエージェント固有の差分はここで吸収する。
4. **カタログに登録する** — `.claude-plugin/marketplace.json`（`./plugins/claude/<name>` を指す）と `.agents/plugins/marketplace.json`（`./plugins/codex/<name>` を指す）の両方にエントリを追加する。
5. **バリデーションする** — 下記「手順 5」。
6. **README を更新する** — 上の「同梱プラグイン」表に追記する。

---

## 手順 4: プラグインを更新・再配布する

1. `plugins/claude/<name>/`（および対応する `plugins/codex/<name>/`）配下のファイルを編集する。
2. `plugins/claude/<name>/.claude-plugin/plugin.json` と `plugins/codex/<name>/.codex-plugin/plugin.json` の `version` を SemVer（MAJOR.MINOR.PATCH）で**揃えて**上げる。
3. コミットして push する。
4. 取得側の操作:
   - Claude Code: `/plugin marketplace update` のあと `/plugin update <name>@agent-plugins`。
   - Codex: リポジトリを更新して再起動し、再インストールする。

> `version` を上げない限り、新しいコミットを push しても Claude Code はキャッシュ済みのコピーを使い続けます。変更履歴は Git のコミット履歴を正とします（CHANGELOG は管理しません）。

---

## 手順 5: バリデーション

```sh
# Claude Code 用マニフェスト
claude plugin validate ./plugins/claude/terraform --strict
claude plugin validate ./plugins/claude/aws --strict
claude plugin validate ./plugins/claude/git --strict

# Codex 用カタログ（読み込めることを確認）
# 注意: CODEX_HOME での隔離は効かず、実環境の ~/.codex/config.toml に登録される（codex 0.130 で確認）。
# ローカル登録は作業ディレクトリを直接参照するため、変更後の再登録は不要（upgrade は Git ソース専用）。
codex plugin marketplace add "$(pwd)"          # 初回のみ
codex plugin marketplace remove agent-plugins  # 後始末（任意）
```
