# Microsoft Fabric × GitHub Copilot CLI ハンズオン

GitHub Copilot CLIと**skills-for-fabric**、必要に応じて**powerbi-authoring**スキルを使い、
Microsoft Fabricを**自然言語のプロンプトだけで操作する**ハンズオンです。
各ラボは独立したMarkdown手順書になっています。

> 🤖 **プロンプト駆動ハンズオン**
> コマンドを手で打つのではなく、「やりたいこと」を日本語で Copilot CLI に伝えるだけ。
> CopilotがFabric／Power BI用スキルを使って`az`／REST APIコマンドやレポート定義を自動生成・実行します。
> 各ステップは 🗣️ **プロンプト** → 🤖 **Copilot の動き** → ✅ **期待する結果** の3点セットで記載。
> （仕組みを知りたい人向けに、裏側のコマンドも参考として併記しています）

---

## 🎯 このハンズオンで学ぶこと

- GitHub Copilot CLI から Microsoft Fabric に接続する方法
- `skills-for-fabric` スキルを使った Lakehouse / Warehouse / SQL Endpoint の操作
- Fabric REST API・SQL Endpoint を使ったデータ探索と分析
- 自然言語プロンプトで Fabric ワークロードを動かす流れ

## 🚀 GitHub Codespacesで開始（推奨）

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/TakumiN19/fabric-handson-lab?quickstart=1)

上のボタンからCodespaceを作成すると、Dev Containerのセットアップ完了まで待機した後、
次のローカルツールを検証済みバージョンで利用できます。

| 自動導入されるもの | 固定バージョン |
|--------------------|----------------|
| Python | 3.12.11 |
| Node.js／npm／npx | 22.22.0／10.9.4 |
| Azure CLI | 2.89.1 |
| GitHub Copilot CLI | 1.0.82 |
| Rayfin CLI | 1.34.0 |
| Power BIレポート作成CLI | 0.1.4 |
| go-sqlcmd | 1.10.0 |
| `fabric-skills`／`powerbi-authoring` | 0.3.14 |

Codespaceのターミナルが開いたら、GitHub CopilotとAzureへdevice-code flowでサインインします。
Azureへのサインインは[Lab 01](labs/01-login-and-connect.md)で実施しても構いません。

```bash
copilot login --device-code
az login --tenant e6c1292e-65b7-4e2d-9e1b-13f24e7753fd --allow-no-subscriptions --use-device-code

# 自動セットアップ結果を再確認
bash .devcontainer/scripts/verify.sh
```

> [!IMPORTANT]
> Dev Containerが自動化するのは**受講環境内のローカルツール**です。
> Fabric容量、テナント設定、Workspace権限、共有ADLS、Lab 08の中継プロキシなどは
> 自動作成されないため、「講師・テナント管理者向け事前確認」も完了してください。

> [!NOTE]
> Docker daemonとhost Docker socketは含めていません。Lab 08／10の主経路である
> Fabricへの直接デプロイには不要です。Fabric AppのローカルViteプレビュー用ポート
> `5173`は自動forwardされます。

## 🧰 受講者PCの必須環境

Codespacesを使う場合、下表のCLI／runtimeはDev Containerが自動導入します。
対応ブラウザ、GitHubアカウント、GitHub Copilotライセンス、配布されたFabricアカウントは
Codespaces利用時も必要です。ローカルPCで進める場合は下表に従って手動導入してください。

> [!IMPORTANT]
> GitHub Copilot CLIの利用には、**有効なGitHub Copilotサブスクリプション**と、
> 所属するOrganization／EnterpriseでCopilot CLIの利用が許可されていることが必要です。
> 当日にライセンス付与を受ける場合は、**EMUではない個人GitHubアカウント**を用意してください。

| 要件 | 対象 | 推奨／対応バージョン | 確認コマンド |
|------|------|----------------------|--------------|
| Visual Studio Code | 全Lab | 最新安定版 | `code --version`（PATH設定済みの場合） |
| EdgeまたはChrome | 全Lab | 最新安定版 | — |
| ターミナル | 全Lab | Windows: PowerShell 7+／WSL、macOS・Linux: bashまたはzsh | `pwsh --version` または `$SHELL --version` |
| GitHub Copilot CLI | 全Lab | 最新安定版（監査時: 1.0.82） | `copilot --version` |
| Azure CLI (`az`) | Lab 01以降 | 最新安定版 | `az version` |
| Node.js／npm／npx | Lab 06・08・10 | **22.xまたは24.x LTS** | `node --version` / `npm --version` / `npx --version` |
| Rayfin CLI | Lab 08・10 | npm／npxで取得（監査時: 1.34.0） | `rayfin --version`または`npx rayfin --version` |
| Python | Lab 01〜04のREST補助、Lab 07・10 | **3.10以上3.14未満**（3.12／3.13推奨） | Windows: `python --version` または `py --version`、macOS・Linux: `python3 --version` |
| `curl` | REST APIの参考手順 | OS付属版または最新安定版 | `curl --version`（Windowsは必要に応じて`curl.exe --version`） |
| `sqlcmd`（Go版） | Lab 04・10 | go-sqlcmd（監査時検証: 1.10.0） | `sqlcmd --version` |
| `fabric-skills` | Lab 01以降 | `fabric-collection`（監査時: v0.3.14） | Copilot CLI内で`/plugin list` |
| `powerbi-authoring` | Lab 06・09 | `fabric-collection`（監査時: v0.3.14） | Copilot CLI内で`/plugin list` |
| Power BIレポート作成CLI | Lab 06・09 | 監査時: 0.1.4 | `powerbi-report-author --version` |

未導入の基本ツールは、[VS Code](https://code.visualstudio.com/)、
[GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/set-up/install-copilot-cli)、
[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)、
[Node.js](https://nodejs.org/en/download)、[Python](https://www.python.org/downloads/)の
公式手順から導入してください。WindowsでPowerShell 7がない場合は
`winget install Microsoft.PowerShell`で導入できます。

Node.jsを`v20+`のような下限だけで指定すると、Rayfin CLI 1.34.0が対応していない21／23／25系も
含まれてしまいます。本ハンズオンでは、GitHub Copilot CLIのnpm版要件も満たす
**Node.js 22.xまたは24.xのLTS版**を共通基準とします。

### Copilotプラグインと補助CLI

GitHub Copilot CLIを起動し、プロンプト内で次を実行します。

```text
/plugin marketplace add microsoft/skills-for-fabric
/plugin install fabric-skills@fabric-collection
/plugin install powerbi-authoring@fabric-collection
```

続いて、通常のターミナルでPower BIレポート作成CLIをインストールします。

```bash
npm install -g @microsoft/powerbi-report-authoring-cli@0.1.4
```

> [!NOTE]
> `fabric-consumption`、`fabric-authoring`、`fabric-operations`は、現在はいずれも
> `fabric-skills`と同じバンドルを指すdeprecated alias〔非推奨の別名〕です。新規セットアップでは
> `fabric-skills@fabric-collection`を使用してください。

### go-sqlcmdのインストール

本ハンズオンでは、Lab 10の`--authentication-method`にも対応する**Go版sqlcmd**を使用します。

| OS | インストール |
|----|--------------|
| Windows | `winget install sqlcmd` |
| macOS | `brew install sqlcmd` |
| Linux／WSL | [Microsoft Learnのgo-sqlcmdインストール手順](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-download-install) |

その他のOS別インストール手順は、[Lab 00 — 前提条件のセットアップ](labs/00-prerequisites.md)と
[GitHub Copilot CLI公式手順](https://docs.github.com/copilot/how-tos/set-up/install-copilot-cli)を参照してください。

> [!WARNING]
> 現在の各Labに併記している参考コマンドには、`export`、`$(...)`、`wc`、`tr`、
> バックスラッシュによる行継続などの**bash固有構文**が含まれます。
> Windowsで参考コマンドをそのまま実行する場合はWSL／bashを使用するか、
> CopilotにPowerShell版へ変換させてください。

> [!TIP]
> GitはZIPで教材を取得する場合は任意です。Power BI Desktopも主経路では使用しません。
> DockerはFabric Appsをローカルのフルスタックで動かす場合のみ任意で使用します。
> 現在の配布用`studentX`アカウントはMFA不要のため、Microsoft Authenticatorは講師から
> 別途案内された場合のみ準備してください。

---

## 🧑‍🏫 講師・テナント管理者向け事前確認（preflight）

> [!IMPORTANT]
> **共有の有料Fabric容量**と、受講者個人の**Power BI Pro／PPU相当ライセンス**は別の要件です。
> 本ワークショップでは、講師が用意した有料F32容量に`studentX`ワークスペースを配置し、
> 必要な受講者だけがPower BI個人トライアルを有効化します。

- [ ] 有料F32容量が稼働中で、全`studentX`ワークスペースがその容量に割り当てられている
- [ ] 各受講者が自分のワークスペースでアイテムを作成でき、Fabric Apps用に`Contributor`／`Member`／`Admin`のいずれかのロールを持つ
- [ ] Lab 05・06・09の受講者にPower BI Pro／PPU相当の個人ライセンスがある
- [ ] Data Agent用に、[有料F2以上またはP1以上の容量](https://learn.microsoft.com/fabric/data-science/data-agent-mcp-server#prerequisites)を使用している
- [ ] [Data Agentのテナント設定](https://learn.microsoft.com/fabric/data-science/data-agent-tenant-settings)でCopilot、Fabric Copilot capacity、必要なリージョン外処理／保存（cross-geo processing／storage）を有効化した
- [ ] Data Agent設定は反映に最大1時間かかるため、開始1時間以上前に有効化した
- [ ] [Fabric Apps（preview）](https://learn.microsoft.com/fabric/apps/create-app-with-cli#prerequisites)ワークロードが有効で、利用する容量リージョンが対応している
- [ ] [`Dataset Execute Queries REST API`](https://learn.microsoft.com/rest/api/power-bi/datasets/execute-queries-in-group#permissions)を有効化し、Lab 08・10の受講者にセマンティックモデルのRead＋Build権限を付与した
- [ ] 共有ADLS Gen2と`adls-handson-sp-v3`接続を用意し、受講者に接続のUser権限を共有した
- [ ] ADLSアクセス用サービスプリンシパルに`Storage Blob Data Reader`を付与し、public network accessを有効化した
- [ ] Lab 08用のData Agent中継プロキシを用意し、URL、CORSで許可する配信元（origin）、認証方式を受講者へ配布した
- [ ] GitHub Copilotライセンス、Copilot CLIの組織ポリシー、npm／PyPI／Fabricへの通信を事前端末で確認した

> [!WARNING]
> [Fabric Trial capacity](https://learn.microsoft.com/fabric/fundamentals/fabric-trial#whats-includedand-whats-not)では、
> Data Agent、Copilot、AI functions、AI servicesを利用できません。
> 本ワークショップのData Agentは、講師が用意した**有料F32容量**上で実行してください。

---

## 🧩 Lab別の追加要件

| 対象 | 追加で必要なもの | 実施前の確認 |
|------|------------------|--------------|
| Lab 00〜03 | Azure CLI、Python／curl、共有ADLS接続 | Lab 03のADLSと接続は講師準備済みであること |
| Lab 04 | go-sqlcmd | Fabric WarehouseのTDS接続先へTCP 1433で接続できること |
| Lab 05 | Power BI Pro／PPU相当 | セマンティックモデルを作成・公開できること |
| Lab 06 | Node.js、`powerbi-authoring`、`powerbi-report-author`、Power BI Pro／PPU相当 | Lab 05のモデルが公開済みであること |
| Lab 07 | 有料F2+／P1+容量、Data Agentテナント設定 | 実際にはLab 06で作る`fact_greentrip_dates`にも依存 |
| Lab 08 | Node.js、Fabric Apps、Execute Queries、公開済みData Agent、講師提供の中継プロキシ | プロキシURLとCORS／認証を講師から受領していること |
| Lab 09（任意） | Lab 06成果物、Power BI authoring環境、デジタル庁テーマ | 下記の未同梱スキルに注意 |
| Lab 10（任意） | Lab 08とLab 06の成果物、Node.js、Python、go-sqlcmd、Execute Queries | Read＋Build権限とTCP 1433疎通を確認 |

---

## ⚠️ 現在の既知制約

以下はインストールだけでは解消しない、現行ラボ本文側の制約です。

| 対象 | 現状 | 実施時の扱い |
|------|------|--------------|
| Lab 00 | ローカルPC向けのgo-sqlcmd／Power BI CLI手動導入手順はREADMEと未同期。Codespacesでは自動導入済み | Codespacesを使用するか、このREADMEの必須環境を優先 |
| Lab 07 | SDKの旧管理メソッドは現行0.1.30a0にも残るがdeprecated〔非推奨〕。問い合わせ経路は`FabricOpenAI`／Assistants API前提 | 現行公式の[Data Agent MCP接続先](https://learn.microsoft.com/fabric/data-science/data-agent-mcp-server)へ更新後に実施 |
| Lab 07・10 | `fact_greentrip_dates`はLab 06で作成される一方、前提がLab 05になっている。Lab 07の`[Avg Fare]`／`[# Trips (Dates)]`とLab 10の`[Avg Fare]`も現行モデルに存在しない | 前提Labとメジャー名を統一してから実施 |
| Lab 08 | `server/agent-proxy/README.md`を参照するが、プロキシ実装はリポジトリに未同梱。説明も旧Assistants APIフロー | 講師提供のMCP対応プロキシを使用 |
| Lab 09 | `powerbi-digicho-dashboard-authoring`は標準の`skills-for-fabric`／`powerbi-authoring`に未収録 | カスタムスキルまたは固定テーマ定義を講師が配布 |
| Lab 10 | `RAYFIN_TOKEN`取得例にアクセストークン抽出が不足 | `az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv`を使用 |

---

## 🌐 ネットワーク要件

企業ネットワークやプロキシ配下で実施する場合は、少なくとも次の通信を許可してください。

| 通信 | 主な接続先 | 用途 |
|------|------------|------|
| HTTPS 443 | `github.com`、`api.github.com`、`raw.githubusercontent.com`、`codeload.github.com`、`release-assets.githubusercontent.com` | Copilot認証、教材・プラグイン・go-sqlcmd取得 |
| HTTPS 443 | `mcr.microsoft.com`、`ghcr.io`、`pkg-containers.githubusercontent.com` | Dev ContainerのベースイメージとFeature取得 |
| HTTPS 443 | `nodejs.org`、`packages.microsoft.com`、`deb.debian.org` | Dev Container内のNode.js、Azure CLI、OS依存パッケージ取得 |
| HTTPS 443 | `registry.npmjs.org`、`pypi.org`、`files.pythonhosted.org` | Node.js／Pythonパッケージ取得 |
| HTTPS 443 | `login.microsoftonline.com`、`microsoft.com/devicelogin` | Microsoft Entra ID認証 |
| HTTPS 443 | `app.fabric.microsoft.com`、`api.fabric.microsoft.com`、`api.powerbi.com` | Fabricポータル／REST API／Execute Queries |
| HTTPS 443 | `onelake.dfs.fabric.microsoft.com`、`st0taxihandson0616.dfs.core.windows.net` | OneLake／共有ADLSデータアクセス |
| HTTPS 443 | `*.rayfin.windows.net`、`*.webapp.fabricapps.net`、講師提供の中継プロキシ | Fabric AppsとData Agentチャット |
| HTTPS 443 | `www.digital.go.jp` | Lab 09のデジタル庁デザイン参照 |
| TCP 1433 | Fabric Warehouse／SQL DatabaseのTDS接続先 | Lab 04・10のgo-sqlcmd接続 |

> [!NOTE]
> 制限の厳しいファイアウォールでは、TDS接続先のFQDNだけでなく、
> Microsoftが公開するPower BI／SQLのservice tag〔サービス タグ〕も使用してください。
> [Fabric Warehouse接続要件](https://learn.microsoft.com/fabric/data-warehouse/connectivity)では、
> SQL接続にTCP 1433が必要で、FQDNだけの許可では不十分とされています。

## 🔐 接続に使うアカウント / 環境（本ハンズオン用）

| 項目 | 値 |
|------|-----|
| サインインユーザー | `student<番号>@M365x43914722.onmicrosoft.com`（各自に配布） |
| テナント ID | `e6c1292e-65b7-4e2d-9e1b-13f24e7753fd` |
| ワークスペース | `student<番号>`（自分に割り当てられた番号） |
| Workspace ID | 自分のワークスペース ID（Lab 01 で確認） |
| Lakehouse | `taxi_lakehouse`（Lab 02 で作成） |
| Fabric容量 | 講師が用意した共有の**有料F32** |
| Power BI個人ライセンス | Lab 05・06・09のみPro／PPU相当が必要 |

> ⚠️ `student<番号>` は各受講者に割り当てられた番号（例: `student3`）に読み替えてください。
> Lakehouse・Warehouse などのアイテムは、各ラボで自分のワークスペースに作成します。

---

## 🔑 受講者向け: Fabric へのサインイン（最初に実施）

ハンズオンを始める前に、配布された `studentX` アカウントで Microsoft Fabric（Web ポータル）に
サインインします。手順は **[受講者向け — Microsoft Fabric へのサインイン手順](labs/fabric-portal-login.md)** を参照してください。

> [!TIP]
> すでに会社・個人アカウントでサインインしている場合は、Profileパネルの**Sign out**で
> サインアウトしてから`studentX`アカウントに切り替えます（シークレット／InPrivateウィンドウ推奨）。

> [!IMPORTANT]
> **Lab 05・06・09（Power BI）**を行う場合は、サインイン後にProfileパネルから
> Power BI個人トライアル（60日・PPU相当）を開始してください。
> `studentX`ワークスペースは講師の有料F32容量上に置いたままにし、
> 別のFabric Trial capacityへ移動しないでください。

---

## 📚 ラボ一覧

状態欄の`✅`は現行手順で実施可能、`⚠️`は上記の既知制約または講師準備が必要であることを示します。

| # | ラボ | 内容 | 状態 |
|---|------|------|------|
| — | [Fabric へのサインイン（受講者向け）](labs/fabric-portal-login.md) | 配布された `studentX` アカウントで Fabric Web ポータルにサインイン | ✅ |
| 00 | [前提条件のセットアップ](labs/00-prerequisites.md) | ツール確認・プラグイン導入 | ✅ |
| 01 | [サインインとワークスペース接続](labs/01-login-and-connect.md) | ブラウザ認証で `az login`、自分の `student<番号>` に接続 | ✅ |
| 02 | [Lakehouse 作成・データ取り込み・変換](labs/02-lakehouse-load-and-transform.md) | Lakehouse 作成 → Parquet アップロード → Delta 変換（列削除・null 除去） | ✅ |
| 03 | [ADLS Gen2 + OneLake ショートカット](labs/03-adls-shortcut.md) | 講師準備済みの共有ADLS Gen2 → Fabric接続 → OneLakeショートカット作成 | ✅ |
| 04 | [Warehouse ディメンション＆ファクトテーブル作成](labs/04-warehouse-dimensions.md) | Warehouse 作成 → ディメンション 5 本 → fact_greentrip_copilot (CTAS) | ✅ |
| 05 | [セマンティックモデル作成](labs/05-semantic-model.md) | Warehouse テーブルからセマンティックモデル構築・リレーションシップ定義 | ✅ |
| 06 | [Power BI レポート作成](labs/06-powerbi-report.md) | セマンティックモデルを使った多角分析レポート（5ビジュアル）を Fabric に公開 | ✅ |
| 07 | [Data Agent 作成](labs/07-data-agent.md) | `sm_taxi_warehouse` に接続する会話型 AI（Data Agent）を作成・指示と代表質問5つを整備して公開 | ⚠️ |
| 08 | [Fabric App（ダッシュボード＋入力＋チャットボット）](labs/08-fabric-app.md) | Rayfin CLI で Fabric App を作成。`sm_taxi_warehouse` のダッシュボード＋入力フォーム（SQL DB→OneLake 自動ミラー）＋ `taxi_ride_agent` チャットドロワーを自分の WS にデプロイ | ⚠️ |
| 09 | [付録: デジタル庁スタイルに作り直す](labs/09-appendix-digicho-dashboard-design.md) | （任意）乗車分析レポートをデジタル庁ダッシュボードデザインテンプレート（Blue）風に作り直す（左スライサー rail・青ヒーロー KPI 他）。前提: Lab 06 | ⚠️ |
| 10 | [付録: Fabric App を UX デザインで作り直す](labs/10-rayfin-fabric-app-ux.md) | （任意）Lab 08 の Fabric App を独自デザインシステム（Midnight Dispatch）＋リッチな Recharts 可視化＋ゾーン注釈でデモ映えさせる。前提: Lab 08＋Lab 06成果物 | ⚠️ |
| 📖 | [用語集（Glossary）](labs/glossary.md) | Lab 02〜10 に登場する Fabric/データ用語の早見表（定義＋本ハンズオンでの使われ方＋公式リンク） | ✅ |

---

## ▶️ 進め方

1. 講師は上記の事前確認を完了し、容量・テナント設定・ADLS・中継プロキシ・ネットワークを確認する
2. 受講者はCodespacesを起動するか、このREADMEの必須環境を確認してから、[Lab 00](labs/00-prerequisites.md)でツールとプラグインを準備する
3. [Fabric へのサインイン](labs/fabric-portal-login.md)で、配布された`studentX`アカウントでFabricにサインインする
4. [Lab 01](labs/01-login-and-connect.md)で**プロンプトから**サインインし、自分のワークスペースへ接続する
5. Lab 02以降も、各ステップの自然言語プロンプトをCopilot CLIへ入力して進める
6. `⚠️`のLabへ進む前に、「現在の既知制約」と講師からの更新案内を確認する

各ステップは 🗣️ プロンプト → 🤖 Copilot の動き → ✅ 期待する結果 で構成。
ラボの末尾には **✅ チェックポイント**（完了確認）と
**🧹 トラブルシュート**（プロンプトでの対処）を用意しています。

> 💡 Copilot がコマンド実行の許可を求めたら、内容を確認して承認してください。
