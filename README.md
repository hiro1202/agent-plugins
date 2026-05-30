# agent-plugins

Hirokazu Funaki 個人用の AI コーディングエージェント向けプラグイン集。**Claude Code** ではマーケットプレース／プラグインとして、**OpenAI Codex CLI** ではカスタムプロンプトとして、同じスキルを利用できます。各プラグインは `plugins/` 配下に置かれ、それぞれが独自の `plugin.json` と `CHANGELOG.md` を持って **独立にバージョン管理** されます。

## ディレクトリ構成

```
agent-plugins/
├── .claude-plugin/
│   └── marketplace.json          # Claude Code 用カタログ。全プラグインを列挙する
├── plugins/                      # Claude Code プラグイン本体（スキルの正本）
│   ├── terraform/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── CHANGELOG.md
│   │   └── skills/code-review/SKILL.md
│   └── aws/
│       ├── .claude-plugin/plugin.json
│       ├── CHANGELOG.md
│       └── skills/cost-estimate/SKILL.md
└── codex/                        # OpenAI Codex CLI 用ラッパー
    ├── install.sh                # プロンプトを ~/.codex/prompts/ に取り込む
    └── prompts/
        ├── agent-plugins-terraform-code-review.md
        └── agent-plugins-aws-cost-estimate.md
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

## Codex CLI で使う

OpenAI Codex CLI では、各スキルを [カスタムプロンプト](https://github.com/openai/codex)（`~/.codex/prompts/*.md`）として取り込みます。同梱のスクリプトが `codex/prompts/` 配下のファイルを `~/.codex/prompts/` にコピー（既定）またはシンボリックリンク（`--link`）します。

```sh
# このリポジトリのルートで実行
./codex/install.sh          # ~/.codex/prompts/ にコピー
./codex/install.sh --link   # 代わりにシンボリックリンクを張る（リポジトリ更新が即反映）
```

取り込み後、Codex CLI のセッションでスラッシュコマンドとして呼び出せます。

```
/agent-plugins-terraform-code-review
/agent-plugins-aws-cost-estimate
```

> プロンプト本体（`codex/prompts/`）は `plugins/` 配下の `SKILL.md` を Codex 向けに書き起こした派生物です。スキルを更新したら両方を揃えてください。

## プラグインごとのバージョン管理

各プラグインのバージョンは `plugins/<name>/.claude-plugin/plugin.json` の `version` フィールドで固定します。更新を配信する手順は次のとおりです。

1. `plugins/<name>/` 配下のファイルを編集する。
2. 当該プラグインの `plugin.json` の `version` を SemVer（MAJOR.MINOR.PATCH）で上げる。
3. 当該プラグインの `CHANGELOG.md` にエントリを追加する。
4. Codex 用にも提供しているスキルは `codex/prompts/` 側も同じ内容に更新する。
5. コミットする。Claude Code 側は `/plugin marketplace update` と `/plugin update <name>@agent-plugins` で、Codex 側は `./codex/install.sh` を再実行して取得する。

> `version` を上げない限り、新しいコミットを push しても Claude Code はキャッシュ済みのコピーを使い続けます。

## バリデーション

```sh
claude plugin validate ./plugins/terraform --strict
claude plugin validate ./plugins/aws --strict
```
