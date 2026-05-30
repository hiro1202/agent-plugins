# cc-toolbox

Hirokazu Funaki 個人用の Claude Code プラグインマーケットプレース。各プラグインは `plugins/` 配下に置かれ、それぞれが独自の `plugin.json` と `CHANGELOG.md` を持って **独立にバージョン管理** されます。

## ディレクトリ構成

```
cc-toolbox/
├── .claude-plugin/
│   └── marketplace.json          # カタログ。このリポジトリ内の全プラグインを列挙する
└── plugins/
    ├── terraform/
    │   ├── .claude-plugin/plugin.json
    │   ├── CHANGELOG.md
    │   └── skills/code-review/SKILL.md
    └── aws/
        ├── .claude-plugin/plugin.json
        ├── CHANGELOG.md
        └── skills/cost-estimate/SKILL.md
```

## 同梱プラグイン

| プラグイン | バージョン | 内容 |
| --- | --- | --- |
| `terraform` | 0.1.0 | `code-review` スキル。Terraform コードをセキュリティ / ベストプラクティス / 運用観点でレビューする。 |
| `aws` | 0.1.0 | `cost-estimate` スキル。説明文や IaC ファイルから月額 AWS コストを見積もる。 |

## ローカルからインストール

```sh
# 任意の Claude Code セッションで実行
/plugin marketplace add /Users/funakihirokazu/Develop/hiro1202/cc-toolbox
/plugin install terraform@cc-toolbox
/plugin install aws@cc-toolbox
```

インストール後は次のいずれかでスキルを呼び出します。

```
/terraform:code-review
/aws:cost-estimate
```

スキルの `description` を Claude が読んで自動ディスパッチもしてくれるので、自然言語で「この Terraform をレビューして」「この構成のコストを見積もって」と話しかけてもかまいません。

## プラグインごとのバージョン管理

各プラグインのバージョンは `plugins/<name>/.claude-plugin/plugin.json` の `version` フィールドで固定します。更新を配信する手順は次のとおりです。

1. `plugins/<name>/` 配下のファイルを編集する。
2. 当該プラグインの `plugin.json` の `version` を SemVer（MAJOR.MINOR.PATCH）で上げる。
3. 当該プラグインの `CHANGELOG.md` にエントリを追加する。
4. コミットする。ユーザーは `/plugin marketplace update` と `/plugin update <name>@cc-toolbox` で取得する。

> `version` を上げない限り、新しいコミットを push しても Claude Code はキャッシュ済みのコピーを使い続けます。

## バリデーション

```sh
claude plugin validate ./plugins/terraform --strict
claude plugin validate ./plugins/aws --strict
```
