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

### 設計上の要点：スキル本体は両エージェントで共有

`plugins/<name>/skills/.../SKILL.md` が唯一の正本です。Claude Code と Codex で内容を複製しません。エージェントごとに分けるのは**カタログとマニフェストだけ**です。Codex 側の規約は OpenAI 公式ドキュメント（[Build plugins](https://developers.openai.com/codex/plugins/build)、[Agent Skills](https://developers.openai.com/codex/skills)）に、Claude Code 側は [Claude Code 公式のプラグイン仕様](https://docs.claude.com/en/docs/claude-code/plugins)に準拠します。

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
└── plugins/                      # プラグイン本体（スキルは両エージェントで共有）
    ├── terraform/
    │   ├── .claude-plugin/plugin.json   # Claude Code 用マニフェスト
    │   ├── .codex-plugin/plugin.json    # Codex 用マニフェスト
    │   └── skills/code-review/
    │       ├── SKILL.md                 # スキル本体（両エージェント共有）
    │       └── agents/openai.yaml       # Codex 用スキル表示設定（任意）
    ├── aws/
    │   ├── .claude-plugin/plugin.json
    │   ├── .codex-plugin/plugin.json
    │   └── skills/cost-estimate/
    │       ├── SKILL.md
    │       └── agents/openai.yaml
    └── git/
        ├── .claude-plugin/plugin.json
        ├── .codex-plugin/plugin.json
        └── skills/commit-and-pr/
            ├── SKILL.md
            └── agents/openai.yaml
```

## 共通化の方針（何を共有し、何を分けるか）

Claude Code と Codex で内容が同じになるものは 1 ソースに寄せ、エージェント固有のものだけ分けます。判断基準は「スキーマ／構文がエージェント間で同一か」です。

| 対象 | 方式 | 理由 |
| --- | --- | --- |
| エージェント指示書（`AGENTS.md` / `CLAUDE.md`） | **シンボリックリンクで共有**（`CLAUDE.md` → `AGENTS.md`） | 同じ Markdown。Codex は `AGENTS.md`、Claude Code は `CLAUDE.md` を読むだけで中身は同一。 |
| スキル本体（`SKILL.md`、`references/`） | **単一ソースで共有**（両マニフェストが `./skills/` を参照） | 形式が共通。複製しない。 |
| マーケットプレースカタログ | **エージェントごとに別ファイル** | スキーマが異なる（Claude=`source` 文字列＋`keywords`/`tags`、Codex=`source` オブジェクト＋`policy`）。symlink 不可。 |
| プラグインマニフェスト（`plugin.json`） | **エージェントごとに別ファイル** | Codex 側に `interface` / `skills` / `mcpServers` が増える。共通フィールド（`name`/`version` 等）は手で揃える。 |

> 結論: symlink で共通化できる指示書は `AGENTS.md` / `CLAUDE.md` の 1 組のみ。カタログとマニフェストはスキーマ差のため別管理が正しい。新しい指示書フォーマットを読む別エージェントを足す場合は、同様に `AGENTS.md` へのシンボリックリンクを増やす。なお Codex は `.claude-plugin/marketplace.json` もレガシー互換として読めるが、`.agents/plugins/marketplace.json` が正式な置き場所（[公式: Build plugins](https://developers.openai.com/codex/plugins/build)）。

## 同梱プラグイン

| プラグイン | スキル | 内容 |
| --- | --- | --- |
| `terraform` | `code-review` | Terraform コード（.tf / .tfvars）をセキュリティ・ベストプラクティス・運用観点でレビューする（読み取り専用）。 |
| `aws` | `cost-estimate` | 説明文や IaC ファイルから月額 AWS コストを見積もる。 |
| `git` | `commit-and-pr` | 変更をコミットし、プルリクエストを作成する（Conventional Commits 準拠・安全なガードレール付き）。 |

## 新しいプラグイン／スキルを追加するときの手順

1. `plugins/<name>/skills/<skill>/SKILL.md` を作る。フロントマターに `name` と「いつ使うか」が伝わる `description` を必ず書く。あわせて `agents/openai.yaml`（Codex での表示名・自動起動可否の設定。任意だが推奨）を置く。
2. `plugins/<name>/.claude-plugin/plugin.json` と `plugins/<name>/.codex-plugin/plugin.json` を作る。`name` と `version` は 2 ファイルで一致させる。
3. `.claude-plugin/marketplace.json` と `.agents/plugins/marketplace.json` の両方にプラグインのエントリを追加する。
4. バリデーションを実行する（下記）。
5. README の「同梱プラグイン」表を更新する。

## バリデーション

```bash
# Claude Code 用マニフェスト
claude plugin validate ./plugins/<name> --strict

# Codex 用カタログ（読み込めることを確認）
# 注意: CODEX_HOME での隔離は効かず、実環境の ~/.codex/config.toml に登録される（codex 0.130 で確認）。
# ローカル登録は作業ディレクトリを直接参照するため、変更後の再登録は不要（upgrade は Git ソース専用）。
codex plugin marketplace add "$(pwd)"          # 初回のみ
codex plugin marketplace remove agent-plugins  # 後始末（任意）

# JSON の妥当性
python3 -m json.tool <file.json> >/dev/null
```

## 規約・境界

- スキル本体は `SKILL.md` を唯一の正本とし、エージェント間で複製しない。
- `version` を変更するときは `.claude-plugin/plugin.json` と `.codex-plugin/plugin.json` を必ず揃える（SemVer）。
- スキルはレビュー／見積もりなど読み取り中心。`terraform apply` やコスト確定など破壊的・確定的な操作はユーザーの明示的な依頼まで行わない。各スキルの「原則」セクションに従う。
- CHANGELOG は管理しない。変更履歴は Git のコミット履歴を正とする。
- 既存ファイルを大きく変更する前にはユーザーに一声かける。
