# Lab 00 — 前提条件のセットアップ

所要時間: 約 10 分

このラボでは、ハンズオンに必要なツールが揃っているか確認し、
`skills-for-fabric` プラグインを導入します。

---

## 0-1. 必要ツールの確認

ハンズオン当日までに、以下をご準備ください。

- **PC**: Webに接続可能なPCをご持参ください。プロキシ経由での接続などPCの設定により弊社ゲストWiFiに接続できない可能性がある場合は、ご自身のモバイルルーター等をご持参ください。
- **Visual Studio Code**: インストールください。  
  [Visual Studio Code — ダウンロード](https://code.visualstudio.com/)
- **Microsoft Authenticator**: スマートフォンにインストールください。  
  [Microsoft Authenticator のダウンロード | Microsoft Support](https://support.microsoft.com/ja-jp/account-billing/microsoft-authenticator-%E3%82%A2%E3%83%97%E3%83%AA%E3%81%AE%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89-351498fc-850a-45da-b7b6-27e523b8702a)
- **GitHub アカウント**: ご自身のアカウントをご用意ください。GitHub Copilot 環境はご自身のアカウントの利用、もしくは当日に限り参加者アカウントへの弊社ライセンス付与を行います。弊社ライセンスの付与を希望される場合は、本リンクを送付した事前案内メールに記載の手順をご確認ください。  
  アカウントをお持ちでない場合は以下から作成できます。弊社ライセンスの付与を希望される場合は **EMUアカウントではなく個人アカウント** をご用意ください（EMUアカウントには付与できません）。  
  [https://github.com/signup](https://github.com/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F&source=header-home)
- **Azure アカウント**: 弊社が用意しますのでご準備不要です。

---

ターミナルで以下を実行し、いずれもバージョンが表示されることを確認します。

```bash
# GitHub Copilot CLI
copilot --version

# Azure CLI
az version

# Python 3（REST API レスポンスの整形に使用）
python3 --version
```

| ツール | 未インストール時の対処 |
|--------|------------------------|
| GitHub Copilot CLI | macOS: `brew install gh` → `gh extension install github/gh-copilot` / Windows: [winget](https://learn.microsoft.com/ja-jp/copilot/github-copilot/gh-copilot-cli) `winget install GitHub.cli` → `gh extension install github/gh-copilot` / [公式手順](https://docs.github.com/ja/copilot/github-copilot-in-the-cli/using-github-copilot-in-the-cli) |
| Azure CLI | macOS: `brew install azure-cli` / Windows: `winget install Microsoft.AzureCLI` / [公式手順](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| Python 3 | macOS には標準搭載。なければ `brew install python` / Windows: [python.org](https://www.python.org/downloads/) からインストーラーを実行 |

---

## 0-2. skills-for-fabric プラグインの導入

GitHub Copilot CLI に Fabric スキルのマーケットプレースを追加し、バンドルをインストールします。

```text
# Copilot CLI のプロンプト内で実行（スラッシュコマンド）
/plugin marketplace add microsoft/skills-for-fabric
/plugin install fabric-skills@fabric-collection
```

用途を絞って入れる場合は、以下のいずれかでも構いません。

```text
# 読み取り中心（クエリ・探索）— 本ハンズオン推奨
/plugin install fabric-consumption@fabric-collection

# 作成・管理（REST API / 自動化 / ノートブック）
/plugin install fabric-authoring@fabric-collection
```

導入済みプラグインの確認:

```text
/plugin list
```

---

## ✅ チェックポイント

- [ ] `copilot --version` / `az version` / `python3 --version` がすべて表示される
- [ ] `/plugin list` に `fabric-skills`（または `fabric-consumption`）が表示される

すべて確認できたら **[Lab 01 — サインインとワークスペース接続](01-login-and-connect.md)** に進みます。
