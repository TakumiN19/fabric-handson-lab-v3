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
   [https://github.com/TakumiN19/fabric-handson-lab-v3](https://github.com/TakumiN19/fabric-handson-lab-v3)
2. 緑色の **「< > Code」** ボタンをクリックし、**「Download ZIP」** を選びます。
3. ダウンロードした ZIP ファイルを、分かりやすい場所（デスクトップなど）に **展開（解凍）** します。
   - Windows: ZIP を右クリック →「すべて展開」
   - macOS: ZIP をダブルクリック
4. `fabric-handson-lab-v3-main` というフォルダーが作成されます。これを次の手順（0-3）で VS Code から開きます。

> 💡 Git を使う場合は、ZIP の代わりに次のコマンドでも取得できます（任意）。
>
> ```bash
> git clone https://github.com/TakumiN19/fabric-handson-lab-v3.git
> ```

---

## 0-3. VS Code を起動してターミナルを開く

このハンズオンのコマンドは、すべて **VS Code の組み込みターミナル** で実行します。

1. **VS Code を起動**します。
   - Windows: スタートメニューで「Visual Studio Code」を検索して起動
   - macOS: Launchpad またはアプリケーションフォルダーから「Visual Studio Code」を起動
2. **0-2 で展開したフォルダー**（`fabric-handson-lab-v3-main`）を開きます: メニュー **ファイル > フォルダーを開く…**（File > Open Folder…）。
3. **ターミナルを開きます**: メニュー **ターミナル > 新しいターミナル**（Terminal > New Terminal）を選択。
   - ショートカット: <kbd>Ctrl</kbd>+<kbd>`</kbd>（バッククォート）。日本語キーボードでは <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>@</kbd> の場合があります。
4. ウィンドウ下部に **ターミナルパネル** が開きます。以降のコマンドは、このターミナルに入力します。

> 💡 既定のシェルは Windows なら PowerShell、macOS なら zsh です。本ハンズオンのコマンドはどちらでも実行できます。

---

## 0-4. ツールをインストールしてバージョンを確認

**最初に Node.js / npm を準備してから、その他のツールを導入します。**
Node.js は Copilot CLI を `npm` で入れる場合や、Lab 06 のレポート作成スキル（`powerbi-report-authoring`）などで使用します。
本ハンズオンでは **Node.js 22.x または 24.x の LTS 版**を使用します。`npm` は Node.js に同梱されます。

> 💡 `winget` 自体の実行には Node.js は不要です。`npm install` を実行する場合は、先に Node.js / npm の導入が必要です。

### Windows（PowerShell）

1. **Node.js / npm をインストール**します。導入済みの場合は、バージョン確認へ進みます。

   ```powershell
   winget install OpenJS.NodeJS.LTS
   ```

   `winget` が使えない場合は、[nodejs.org のダウンロード](https://nodejs.org/en/download)から **22.x または 24.x LTS** の Windows 用インストーラーを実行します。

2. **VS Code を終了して起動し直し**、新しい PowerShell ターミナルでバージョンを確認します。

   ```powershell
   node --version
   npm --version
   ```

3. **その他の未導入ツールをインストール**します。

| ツール | 未インストール時の対処 |
|--------|------------------------|
| PowerShell 7 | `winget install Microsoft.PowerShell`。導入後、VS Code のターミナルのプロファイルで PowerShell 7 を選択 |
| GitHub Copilot CLI | `winget install GitHub.Copilot`（PowerShell v6+）または `npm install -g @github/copilot` / [公式手順](https://docs.github.com/ja/copilot/how-tos/set-up/install-copilot-cli) |
| Azure CLI | `winget install Microsoft.AzureCLI` / [公式手順](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| Python 3 | [python.org](https://www.python.org/downloads/) から Python 3.12 または 3.13 のインストーラーを実行（「Add python.exe to PATH」を選択） |

4. インストール後は **VS Code を再起動**し、新しい PowerShell ターミナルで確認します。

   ```powershell
   copilot --version
   az version
   python --version
   ```

   `python` が見つからない場合は `py --version` でも確認できます。

### macOS / Linux / WSL（bash / zsh）

1. **Node.js / npm をインストール**します。導入済みの場合は、バージョン確認へ進みます。

   - **macOS**: [nodejs.org のダウンロード](https://nodejs.org/en/download)から **22.x または 24.x LTS** の macOS 用インストーラーを実行します。
   - **Linux / WSL**: nvm でユーザー権限のまま導入します。

     ```bash
     curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
     # 表示される案内に従い、ターミナルを開き直してから:
     nvm install 24
     ```

2. 新しいターミナルでバージョンを確認します。

   ```bash
   node --version
   npm --version
   ```

3. **その他の未導入ツールをインストール**します。

| ツール | 未インストール時の対処 |
|--------|------------------------|
| GitHub Copilot CLI | macOS / Linux（Homebrew 導入済み）: `brew install copilot-cli` / 全環境: `npm install -g @github/copilot` / [公式手順](https://docs.github.com/ja/copilot/how-tos/set-up/install-copilot-cli) |
| Azure CLI | macOS: `brew install azure-cli` / Linux・WSL: [公式手順](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| Python 3 | Python 3.12 または 3.13 を導入。macOS（Homebrew）: `brew install python@3.13` / Linux・WSL: [Python 公式サイト](https://www.python.org/downloads/)または OS のパッケージ管理ツールで導入 |

4. 新しいターミナルで確認します。

   ```bash
   copilot --version
   az version
   python3 --version
   ```

   Homebrew の Python 3.13 を使う場合は `python3.13 --version` でも確認できます。

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

## 0-7. 自分の student 番号を一度だけ登録する

Copilot CLI のプロンプトに、次を貼り付けます。**`<番号>` を一か所だけ、自分に割り当てられた番号に置き換えてください。**
例: 番号が 3 なら、最初の行を「私の student 番号は 3 です。」にします。
先頭に 0 がある番号は、配布された表記のまま指定します。

```text
私の student 番号は <番号> です。
この番号を記憶して、以降の全 Lab で自分のアカウントとワークスペースに自動で反映してください。
```

教材の共通指示（`.github/copilot-instructions.md`）に従い、Copilot が番号から
**アカウント名とワークスペース名を自動生成**して、`.github/student.local.md` に保存します。
例えば番号が 3 なら、アカウントは `student3@M365x43914722.onmicrosoft.com`、
ワークスペース名は `student3` になります。**これらを別途入力する必要はありません。**

**表示された設定が配布されたアカウントと一致することを確認**したら、そのまま Lab 01 へ進みます。
参加者設定の保存だけでは、Copilot CLI の再起動は不要です。

> 💡 設定が保存されない場合は、`/instructions` で教材の `.github/copilot-instructions.md` が有効か確認します。
> 教材の共通指示を追加・更新したあとに既存の Copilot セッションを使っている場合は、
> `/exit` で終了し、同じ教材フォルダーで `copilot` を起動し直してから登録プロンプトを送ります。

> 💡 この設定は会話中の記憶だけでなく、**この教材フォルダー内のローカルファイル**に保存します。
> 同じフォルダーで新しい会話を始めても利用できます。別の PC や新しい Codespace には自動では引き継がれません。
> このファイルは `.gitignore` の対象なので Git にはコミットしません。共有・アップロードもしないでください。
> 番号を変更する場合だけ、この登録プロンプトを新しい番号で再実行し、以前の Workspace ID は削除してから再接続します。

以降のプロンプトは、**番号を入力せず、そのまま貼り付けて使えます**。
ブラウザのサインインや MFA は引き続き自分で行います。

---

## ✅ チェックポイント

- [ ] 教材リポジトリをZIPで展開した、またはCodespaceで開いた
- [ ] `copilot --version` / `az version` / `python3 --version` / `node --version` がすべて表示される
- [ ] `copilot` を起動し、`/login` で GitHub アカウントにサインインできた
- [ ] `/model` でモデルを **Auto** に設定した
- [ ] `/plugin list` に `fabric-skills` と `powerbi-authoring` が表示される
- [ ] student 番号を一度だけ伝え、自動生成・保存された自分のアカウントとワークスペース名を確認した

すべて確認できたら **[Lab 01 — サインインとワークスペース接続](01-login-and-connect.md)** に進みます。
