# agent-plugins

Hirokazu Funaki 個人用の AI コーディングエージェント向けプラグイン集。**Claude Code** と **OpenAI Codex** の両方に対応しています。スキル本体（`SKILL.md`）は両エージェントで共有し、エージェントごとのカタログ／マニフェストだけを別々に持つ構成です（[awslabs/agent-plugins](https://github.com/awslabs/agent-plugins) の方式に準拠）。各プラグインは `plugins/` 配下に置かれ、それぞれが独自の `plugin.json` と `CHANGELOG.md` を持って **独立にバージョン管理** されます。

## ディレクトリ構成

```
agent-plugins/
├── .claude-plugin/
│   └── marketplace.json          # Claude Code 用カタログ
├── .agents/
│   └── plugins/marketplace.json  # Codex 用カタログ
└── plugins/                      # プラグイン本体（スキルは両エージェントで共有）
    ├── terraform/
    │   ├── .claude-plugin/plugin.json   # Claude Code 用マニフェスト
    │   ├── .codex-plugin/plugin.json    # Codex 用マニフェスト
    │   ├── CHANGELOG.md
    │   └── skills/code-review/SKILL.md
    └── aws/
        ├── .claude-plugin/plugin.json
        ├── .codex-plugin/plugin.json
        ├── CHANGELOG.md
        └── skills/cost-estimate/SKILL.md
```

## 同梱プラグイン

| プラグイン | バージョン | 内容 |
| --- | --- | --- |
| `terraform` | 0.1.0 | `code-review` スキル。Terraform コードをセキュリティ / ベストプラクティス / 運用観点でレビューする。 |
| `aws` | 0.1.0 | `cost-estimate` スキル。説明文や IaC ファイルから月額 AWS コストを見積もる。 |

## Claude Code で使う

```sh
# 任意の Claude Code セッションで実行
/plugin marketplace add /Users/funakihirokazu/Develop/hiro1202/agent-plugins
/plugin install terraform@agent-plugins
/plugin install aws@agent-plugins
```

> GitHub から直接追加する場合は `/plugin marketplace add hiro1202/agent-plugins` でもかまいません。

インストール後は次のいずれかでスキルを呼び出します。

```
/terraform:code-review
/aws:cost-estimate
```

スキルの `description` を Claude が読んで自動ディスパッチもしてくれるので、自然言語で「この Terraform をレビューして」「この構成のコストを見積もって」と話しかけてもかまいません。

## Codex で使う

Codex はリポジトリローカルのマーケットプレース（`.agents/plugins/marketplace.json`）と、各プラグインのマニフェスト（`plugins/*/.codex-plugin/plugin.json`）を読み取ります。本リポジトリは両方を同梱しており、[Build plugins](https://developers.openai.com/codex/plugins/build) の公式パッケージングガイダンスに沿っています。

このリポジトリから Codex で試す手順:

1. このリポジトリをローカルにクローンする。
2. Codex でこのリポジトリを開く（Codex が `.agents/plugins/marketplace.json` を検出する）。
3. Codex を再起動する。
4. プラグインディレクトリで `agent-plugins` マーケットプレースを選び、使いたいプラグインをインストールする。

インストール後は、Claude Code と同じスキルが Codex 側でも利用できます。

> 既知の制限: Claude Code 固有の自動フック（`hooks/`）は Codex マニフェストには接続していません。本リポジトリのプラグインは読み取り専用スキルのみのため、現状フックは含みません。

## プラグインごとのバージョン管理

各プラグインのバージョンは `plugins/<name>/.claude-plugin/plugin.json` の `version` フィールドで固定します。更新を配信する手順は次のとおりです。

1. `plugins/<name>/` 配下のファイル（共有スキルなど）を編集する。
2. 当該プラグインの `.claude-plugin/plugin.json` と `.codex-plugin/plugin.json` の `version` を SemVer（MAJOR.MINOR.PATCH）で揃えて上げる。
3. 当該プラグインの `CHANGELOG.md` にエントリを追加する。
4. コミットする。Claude Code 側は `/plugin marketplace update` と `/plugin update <name>@agent-plugins` で取得する。Codex 側はリポジトリを更新して再起動し、再インストールする。

> `version` を上げない限り、新しいコミットを push しても Claude Code はキャッシュ済みのコピーを使い続けます。`version` は 2 つのマニフェストで常に一致させてください。

## バリデーション

```sh
# Claude Code 用マニフェスト
claude plugin validate ./plugins/terraform --strict
claude plugin validate ./plugins/aws --strict

# Codex 用マーケットプレース（カタログとマニフェストの読み取りを確認）
codex plugin marketplace add "$(pwd)"
```
