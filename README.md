# agent-plugins

個人用の、AI コーディングエージェント向けプラグイン集。**Claude Code** と **OpenAI Codex** の両方で同じスキルを利用できます。スキル本体（`SKILL.md`）は両エージェントで共有し、エージェントごとのカタログ／マニフェストだけを別々に持ちます（[awslabs/agent-plugins](https://github.com/awslabs/agent-plugins) の方式に準拠）。

エージェントがこのリポジトリで作業するための設計メモは [`AGENTS.md`](./AGENTS.md)（= `CLAUDE.md`）にあります。本書はインストール・利用・プラグイン追加の**手順書**です。

## 同梱プラグイン

| プラグイン | スキル | 内容 |
| --- | --- | --- |
| `terraform` | `code-review` | Terraform コード（.tf / .tfvars）をセキュリティ / ベストプラクティス / 運用観点でレビューする。 |
| `aws` | `cost-estimate` | 説明文や IaC ファイルから月額 AWS コストを見積もる。 |

## ディレクトリ構成

```
agent-plugins/
├── AGENTS.md / CLAUDE.md         # エージェント向けコンテキスト（CLAUDE.md は AGENTS.md へのシンボリックリンク）
├── .claude-plugin/
│   └── marketplace.json          # Claude Code 用カタログ
├── .agents/
│   └── plugins/marketplace.json  # Codex 用カタログ
└── plugins/                      # プラグイン本体（スキルは両エージェントで共有）
    ├── terraform/
    │   ├── .claude-plugin/plugin.json   # Claude Code 用マニフェスト
    │   ├── .codex-plugin/plugin.json    # Codex 用マニフェスト
    │   └── skills/code-review/SKILL.md
    └── aws/
        ├── .claude-plugin/plugin.json
        ├── .codex-plugin/plugin.json
        └── skills/cost-estimate/SKILL.md
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

Codex はリポジトリローカルのマーケットプレース（`.agents/plugins/marketplace.json`）と各プラグインのマニフェスト（`plugins/*/.codex-plugin/plugin.json`）を読み取ります（[公式: Build plugins](https://developers.openai.com/codex/plugins/build) に準拠）。

### 2-1. リポジトリを取得する

```sh
git clone https://github.com/hiro1202/agent-plugins.git
```

### 2-2. マーケットプレースを追加する

```sh
# リポジトリのルートを指定する
codex plugin marketplace add /path/to/agent-plugins
```

### 2-3. インストールして使う

1. Codex でこのリポジトリを開く（`.agents/plugins/marketplace.json` が検出される）。
2. Codex を再起動する。
3. プラグインディレクトリで `agent-plugins` マーケットプレースを選び、使いたいプラグインをインストールする。

インストール後は Claude Code と同じスキルが自動起動します。

> 既知の制限: Claude Code 固有の自動フック（`hooks/`）は Codex マニフェストには接続していません。本リポジトリのプラグインは読み取り専用スキルのみのため、現状フックは含みません。

---

## 手順 3: 新しいプラグイン／スキルを追加する

1. **スキルを作る** — `plugins/<name>/skills/<skill>/SKILL.md`。フロントマターに `name` と「いつ使うか」が伝わる `description` を必ず書く（`description` が自動起動の判定材料になる）。
2. **マニフェストを作る** — `plugins/<name>/.claude-plugin/plugin.json` と `plugins/<name>/.codex-plugin/plugin.json`。`name` と `version` は 2 ファイルで一致させる。
3. **カタログに登録する** — `.claude-plugin/marketplace.json` と `.agents/plugins/marketplace.json` の両方にエントリを追加する。
4. **バリデーションする** — 下記「手順 5」。
5. **README を更新する** — 上の「同梱プラグイン」表に追記する。

---

## 手順 4: プラグインを更新・再配布する

1. `plugins/<name>/` 配下のファイル（共有スキルなど）を編集する。
2. `.claude-plugin/plugin.json` と `.codex-plugin/plugin.json` の `version` を SemVer（MAJOR.MINOR.PATCH）で**揃えて**上げる。
3. コミットして push する。
4. 取得側の操作:
   - Claude Code: `/plugin marketplace update` のあと `/plugin update <name>@agent-plugins`。
   - Codex: リポジトリを更新して再起動し、再インストールする。

> `version` を上げない限り、新しいコミットを push しても Claude Code はキャッシュ済みのコピーを使い続けます。変更履歴は Git のコミット履歴を正とします（CHANGELOG は管理しません）。

---

## 手順 5: バリデーション

```sh
# Claude Code 用マニフェスト
claude plugin validate ./plugins/terraform --strict
claude plugin validate ./plugins/aws --strict

# Codex 用カタログ（読み込めることを確認。実環境を汚さないよう一時 CODEX_HOME で実行）
CODEX_HOME="$(mktemp -d)" codex plugin marketplace add "$(pwd)"
```
