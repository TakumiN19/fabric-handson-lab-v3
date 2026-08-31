# Lab 00 — 前提条件のセットアップ

所要時間: 約 10 分

このラボでは、ハンズオンに必要なツールが揃っているか確認し、
`skills-for-fabric` と `powerbi-authoring` プラグインを導入します。

> [!TIP]
> **GitHub Codespacesを使う場合**は、ルートREADMEの
> [「GitHub Codespacesで開始」](../README.md)からCodespaceを作成してください。
> 教材の取得と必要なCLI／プラグインの導入は自動で完了するため、0-2のZIPダウンロードと
> 0-4の手動インストールを省略できます。ターミナルで次を実行してから0-5へ進みます。
>
> ```bash
> bash .devcontainer/scripts/verify.sh
> ```
>
> ブラウザ、GitHubアカウント、GitHub Copilotライセンス、配布されたFabricアカウントは
> Codespaces利用時も必要です。

---

## 0-1. 必要ツールの確認

ハンズオン当日までに、以下をご準備ください。

- **PC**: Webに接続可能なPCをご持参ください。プロキシ経由での接続などPCの設定により弊社ゲストWiFiに接続できない可能性がある場合は、ご自身のモバイルルーター等をご持参ください。
- **Visual Studio Code**: ローカルPCで進める場合はインストールしてください。Codespacesではブラウザ版またはデスクトップ版VS Codeから接続できます。
  [Visual Studio Code — ダウンロード](https://code.visualstudio.com/)
- **Microsoft Authenticator**: スマートフォンにインストールしてください。  
  [Microsoft Authenticator のダウンロード | Microsoft Support](https://support.microsoft.com/ja-jp/account-billing/microsoft-authenticator-%E3%82%A2%E3%83%97%E3%83%AA%E3%81%AE%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89-351498fc-850a-45da-b7b6-27e523b8702a)
- **GitHub アカウント**: ご自身のアカウントをご用意ください。GitHub Copilot 環境はご自身のアカウントの利用、もしくは当日に限り参加者アカウントへの弊社ライセンス付与を行います。弊社ライセンスの付与を希望される場合は、本リンクを送付した事前案内メールに記載の手順をご確認ください。  
  アカウントをお持ちでない場合は以下から作成できます。弊社ライセンスの付与を希望される場合は **EMUアカウントではなく個人アカウント** をご用意ください（EMUアカウントには付与できません）。  
  [https://github.com/signup](https://github.com/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F&source=header-home)
- **Azure アカウント**: 弊社が用意しますのでご準備不要です。

---

## 0-2. ハンズオン教材を ZIP でダウンロードする

ハンズオンの手順書とサンプルデータ（`data/` の Parquet ファイルなど）を、リポジトリごとローカルに用意します。

1. ブラウザで教材リポジトリを開きます。
   [https://github.com/TakumiN19/fabric-handson-lab](https://github.com/TakumiN19/fabric-handson-lab)
2. 緑色の **「< > Code」** ボタンをクリックし、**「Download ZIP」** を選びます。
3. ダウンロードした ZIP ファイルを、分かりやすい場所（デスクトップなど）に **展開（解凍）** します。
   - Windows: ZIP を右クリック →「すべて展開」
   - macOS: ZIP をダブルクリック
4. `fabric-handson-lab-main` というフォルダーが作成されます。これを次の手順（0-3）で VS Code から開きます。

> 💡 Git を使う場合は、ZIP の代わりに次のコマンドでも取得できます（任意）。
>
> ```bash
> git clone https://github.com/TakumiN19/fabric-handson-lab.git
> ```

---

## 0-3. VS Code を起動してターミナルを開く

このハンズオンのコマンドは、すべて **VS Code の組み込みターミナル** で実行します。

1. **VS Code を起動**します。
   - Windows: スタートメニューで「Visual Studio Code」を検索して起動
   - macOS: Launchpad またはアプリケーションフォルダーから「Visual Studio Code」を起動
2. **0-2 で展開したフォルダー**（`fabric-handson-lab-main`）を開きます: メニュー **ファイル > フォルダーを開く…**（File > Open Folder…）。
3. **ターミナルを開きます**: メニュー **ターミナル > 新しいターミナル**（Terminal > New Terminal）を選択。
   - ショートカット: <kbd>Ctrl</kbd>+<kbd>`</kbd>（バッククォート）。日本語キーボードでは <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>@</kbd> の場合があります。
4. ウィンドウ下部に **ターミナルパネル** が開きます。以降のコマンドは、このターミナルに入力します。

> 💡 既定のシェルは Windows なら PowerShell、macOS なら zsh です。本ハンズオンのコマンドはどちらでも実行できます。

---

## 0-4. ツールのバージョンを確認

VS Code のターミナルで以下を実行し、いずれもバージョンが表示されることを確認します。

```bash
# GitHub Copilot CLI
copilot --version

# Azure CLI
az version

# Python 3（REST API レスポンスの整形に使用）
python3 --version

# Node.js / npm（Copilot CLI を npm で入れる場合・一部スキルで使用、Node.js 22 以上）
node --version
npm --version
```

| ツール | 未インストール時の対処 |
|--------|------------------------|
| GitHub Copilot CLI | macOS/Linux: `brew install copilot-cli` / Windows: `winget install GitHub.Copilot`（PowerShell v6+）/ npm（全OS・Node.js 22+）: `npm install -g @github/copilot` / [公式手順](https://docs.github.com/ja/copilot/how-tos/set-up/install-copilot-cli) |
| Azure CLI | macOS: `brew install azure-cli` / Windows: `winget install Microsoft.AzureCLI` / [公式手順](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| Python 3 | macOS には標準搭載。なければ `brew install python` / Windows: [python.org](https://www.python.org/downloads/) からインストーラーを実行 |
| Node.js / npm | 下の「💡 **Node.js のインストール**」を参照（Windows / bash 別の手順・**Node.js 22 以上**） |

> 💡 **Node.js のインストール** — `npm` で Copilot CLI を入れる場合や、Lab 06 のレポート作成スキル（`powerbi-report-authoring`）で使用します（**Node.js 22 以上**。`npm` は Node.js に同梱されます）。
>
> **Windows（PowerShell）**
>
> ```powershell
> winget install OpenJS.NodeJS.LTS
> ```
>
> インストール後、PowerShell を開き直してから `node --version` で確認します。
>
> **bash 環境（macOS / Linux / WSL）**
>
> ```bash
> # macOS（Homebrew）
> brew install node
>
> # Linux / WSL（nvm でユーザー権限のまま導入）
> curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
> # 表示される案内に従い、ターミナルを開き直してから:
> nvm install --lts
> ```
>
> うまくいかない場合は [nodejs.org のダウンロード](https://nodejs.org/en/download) からインストーラーでも導入できます。

---

## 0-5. GitHub Copilot CLI を起動してサインインする

VS Code のターミナル（0-3）で GitHub Copilot CLI を起動し、GitHub アカウントでサインインします。

1. ターミナルで Copilot CLI を起動します。

   ```bash
   copilot
   ```

2. 初回は、このフォルダーを信頼するか確認されます。**「1. Yes, proceed」**（このセッションのみ許可）を選びます。
   毎回聞かれないようにするには「2. Yes, and remember this folder…」を選びます。
3. サインインしていない場合は、`/login` を使うよう案内が表示されます。プロンプトに次を入力します。

   ```text
   /login
   ```

4. 画面の指示に従ってサインインします。ブラウザが開く（またはデバイスコードと URL `https://github.com/login/device` が表示される）ので、**ハンズオンで使う GitHub アカウント**で承認します。
5. サインインが完了すると、プロンプトが使えるようになります。
6. （推奨）使用するモデルを **Auto** にします。プロンプトで `/model` を実行し、一覧から **Auto** を選びます。

   ```text
   /model
   ```

   Auto は、タスクに応じて Copilot が最適なモデルを自動で選びます。起動時に `copilot --model auto` でも指定でき、設定は保存されて次回以降も有効です。

> 💡 GitHub Copilot CLI の利用には **有効な GitHub Copilot サブスクリプション** が必要です（0-1 参照）。
> CLI を終了するには、プロンプトで `/exit` を実行するか <kbd>Ctrl</kbd>+<kbd>C</kbd> を2回押します。
> これは **GitHub** へのサインインです（**Azure** へのサインインは [Lab 01](01-login-and-connect.md) で行います）。

---

## 0-6. skills-for-fabric プラグインの導入

0-5 で起動した Copilot CLI のプロンプトで実行します。

GitHub Copilot CLI に Fabric スキルのマーケットプレースを追加し、バンドルをインストールします。

```text
# Copilot CLI のプロンプト内で実行（スラッシュコマンド）
/plugin marketplace add microsoft/skills-for-fabric
/plugin install fabric-skills@fabric-collection
/plugin install powerbi-authoring@fabric-collection
```

> [!NOTE]
> Codespacesでは上記2プラグインがv0.3.14で自動導入されています。
> marketplace追加やinstallを再実行せず、次の`/plugin list`で確認できます。

導入済みプラグインの確認:

```text
/plugin list
```

---

## ✅ チェックポイント

- [ ] 教材リポジトリをZIPで展開した、またはCodespaceで開いた
- [ ] `copilot --version` / `az version` / `python3 --version` / `node --version` がすべて表示される
- [ ] `copilot` を起動し、`/login` で GitHub アカウントにサインインできた
- [ ] `/model` でモデルを **Auto** に設定した
- [ ] `/plugin list` に `fabric-skills` と `powerbi-authoring` が表示される

すべて確認できたら **[Lab 01 — サインインとワークスペース接続](01-login-and-connect.md)** に進みます。
