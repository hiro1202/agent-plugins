# agent-plugins

個人用の、AI コーディングエージェント向けプラグイン集。**Claude Code 用（`plugins/claude/`）を正本**として開発し、**OpenAI Codex 用（`plugins/codex/`）は必要になったときに Codex に claude 側を参照させて生成**します。Claude Code 側は [Claude Code 公式のプラグイン仕様](https://docs.claude.com/en/docs/claude-code/plugins)に、Codex 側は OpenAI 公式の [Build plugins](https://developers.openai.com/codex/plugins/build)・[Agent Skills](https://developers.openai.com/codex/skills) に準拠します。

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

---

## 手順 1: Claude Code で使う

### 1-1. マーケットプレースを追加する

```sh
# ローカルのクローンから
/plugin marketplace add <リポジトリをクローンしたパス>

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

`plugins/codex/` は claude 側から生成した成果物で、生成済みのプラグインだけがインストールできます（claude 側より古いことがあります。最新化は「手順 3」の生成手順で）。

### 2-1. マーケットプレースを追加する

```sh
# ローカルのクローンから（リポジトリのルートを指定）
codex plugin marketplace add <リポジトリをクローンしたパス>

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

新しいセッションなら、Claude Code と同じく自然言語で自動起動します。明示的に呼び出すときは `$プラグイン名:スキル名` の形式です（Claude Code の `/プラグイン名:スキル名` に対応）。

```
$terraform:code-review
$aws:cost-estimate
$git:commit-and-pr
```

`$` を打つとスキル名の補完候補が出ます。`/skills` でもインストール済みスキルの一覧から選べます。

---

## 手順 3: 新しいプラグイン／スキルを追加する

claude 側だけに作ります。Codex 版は毎回は作らず、必要になったときに生成します。

1. **スキルを作る** — `plugins/claude/<name>/skills/<skill>/SKILL.md`。フロントマターに `name` と「いつ使うか」が伝わる `description` を必ず書く（`description` が自動起動の判定材料になる）。MCP を使うなら `plugins/claude/<name>/.mcp.json` も置く。
2. **マニフェストを作る** — `plugins/claude/<name>/.claude-plugin/plugin.json`。
3. **カタログに登録する** — `.claude-plugin/marketplace.json` にエントリ（`./plugins/claude/<name>`）を追加する。
4. **バリデーションする** — 下記「手順 5」。
5. **README を更新する** — 上の「同梱プラグイン」表に追記する。

### Codex 版を生成する（必要になったときだけ）

1. Codex に `plugins/claude/<name>/` を読ませ、Codex の仕様に最適化した対応物を `plugins/codex/<name>/` に生成させる（`.codex-plugin/plugin.json` の `name` / `version` は claude 側と一致させる）。
2. `.agents/plugins/marketplace.json` にエントリ（`./plugins/codex/<name>`）を追加する。
3. claude 側を大きく変えたあとに Codex 版を使いたくなったら、同じ手順で再生成する。

---

## 手順 4: プラグインを更新・再配布する

1. `plugins/claude/<name>/` 配下のファイルを編集する（codex 側は再生成のタイミングでだけ更新する）。
2. `plugins/claude/<name>/.claude-plugin/plugin.json` の `version` を SemVer（MAJOR.MINOR.PATCH）で上げる。codex 側が存在する場合は再生成時に `version` を揃える。
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

# Codex 用カタログ（codex 側を生成・変更したときだけ）
# 注意: CODEX_HOME での隔離は効かず、実環境の ~/.codex/config.toml に登録される（codex 0.130 で確認）。
# ローカル登録は作業ディレクトリを直接参照するため、変更後の再登録は不要（upgrade は Git ソース専用）。
codex plugin marketplace add "$(pwd)"          # 初回のみ
codex plugin marketplace remove agent-plugins  # 後始末（任意）
```
