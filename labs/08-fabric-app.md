# Lab 08 — 付録：Fabric App でダッシュボード＋入力フォーム＋チャットボット（プロンプト駆動）

所要時間: 約 30 分
前提:
- [Lab 05](05-semantic-model.md) 完了（`sm_taxi_warehouse` が登録済みのワークスペースに存在）
- [Lab 07](07-data-agent.md) 完了（`taxi_ride_agent` が **公開済み**）
- **Node.js**（v20 以上）がローカルにインストール済み（`node --version`）

> 💡 **作業指示だけで実行できます。** アカウント・ワークスペース・接続先 ID は Copilot が自動で補います。
> 各プロンプトはそのまま貼り付けてください。設定が見つからない場合は [Lab 00 の 0-7](00-prerequisites.md#0-7-自分の-student-番号を一度だけ登録する)を確認します。
> ブラウザ認証は本人が行います。講師提供のプロキシ URL は番号から生成できないため、配布資料や既存設定から取得できない場合だけ提供が必要です。

> 🎫 **機能注意**: **Fabric Apps（preview）** を使います。テナントで *Fabric Apps（preview）* ワークロードが有効になっており、Fabric 容量（**トライアル可**）が必要です。作成できない場合は講師に確認してください。

このラボでは、**Rayfin CLI** を使って React 製の **Fabric App** を作り、登録済みのワークスペースにデプロイします。アプリには 3 つの要素を載せます。

1. **ダッシュボード** — `sm_taxi_warehouse` のデータで KPI とグラフを表示
2. **入力フォーム** — 入力データが **Fabric SQL Database → OneLake へ自動ミラー**
3. **チャットボット** — `taxi_ride_agent` に質問できる右下のチャットドロワー

```
Rayfin で App 作成  →  ダッシュボード  →  入力フォーム(SQL DB→ミラー)  →  チャットボット  →  デプロイ
```

> 🤖 **裏側では何が動く？**
> **Fabric Apps** は preview のアプリ基盤です。Copilot CLI は **Rayfin CLI**（`@microsoft/rayfin-cli`）を使って
> プロジェクトをスキャフォールドし、**AppBackend** アイテムを作成して静的 React を Fabric にホストします
> （`*.webapp.fabricapps.net` で公開）。`data` サービスは **Fabric SQL Database** を作成し、書き込んだデータは
> **OneLake に自動ミラー**されます。

> 💡 認証はブラウザ（Entra SSO）で、**登録済みのアカウント**でサインインします。

---

> 📖 **分からない用語があれば** [用語集（Glossary）](glossary.md) で確認できます（Lakehouse・Delta・Livy・セマンティックモデル など）。

## 8-1. Rayfin CLI で Fabric App を作成してサインインする

> 🗣️ **プロンプト**
> ```text
> Rayfin CLI を使って taxi-dashboard という Fabric App プロジェクトを
> blankapp テンプレート（Fabric 認証つき）で作成して初期化して。
> そのあと Rayfin にブラウザ認証でサインインして。
> ```

🤖 **Copilot の動き**
- `npm create @microsoft/rayfin@latest taxi-dashboard --workspace "$WORKSPACE_NAME"`（または `npx rayfin init --template blankapp --auth-methods fabric --workspace "$WORKSPACE_NAME"`）で React + Vite + Tailwind のプロジェクトを生成。
- `npx rayfin login` を実行 → **ブラウザが開く**ので、登録済みのアカウントでサインイン。
- `$WORKSPACE_NAME` は Copilot が登録済み設定から設定します。コマンドの入力や置き換えは不要です。

✅ **期待する結果**
`taxi-dashboard/` プロジェクトが生成され、`Signed in` と表示される。

```text
✅ Signed in   Tenant: e6c1292e-...
project: taxi-dashboard (blankapp, fabric auth, static hosting)
```

> 💡 ブラウザのサインイン画面が出たら、**会社/個人アカウントではなく登録済みのアカウント**を選んでください。

---

## 8-2. ダッシュボードを作る（セマンティックモデルのデータ）

> 🗣️ **プロンプト**
> ```text
> taxi-dashboard アプリに「NYC Yellow Taxi Dashboard」を作って。
> データは sm_taxi_warehouse を DAX で集計してフロントに埋め込んで。
> - KPI カード6枚: Total Revenue / Total Passengers / Total Tolls /
>   Total Congestion Fee / Total Tips / Total Trips
> - 「Tips by Rate Code」横棒グラフ、「Revenue by Vendor」縦棒（CMT/VTS）、
>   「Revenue by Payment & Rate」積み上げ横棒
> - Payment Type と Rate Code のスライサー（クライアント側で絞り込み）
> ```

🤖 **Copilot の動き**
- Power BI の **Execute Queries**（DAX）で `sm_taxi_warehouse` を `payment_type × RatecodeID × VendorID` 粒度に集計し、結果を JSON でフロントに埋め込みます。
- React + Tailwind で KPI カード・グラフ・スライサーを実装（スライサーはクライアント側で再集計）。

> ⚠️ **設計ポイント**: `dimension_PaymentType` は fact と未結合のため、ディメンション経由で集計すると
> 全 payment が同値になります。**fact 自身の列（`payment_type` / `RatecodeID` / `VendorID`）で集計**します。

✅ **期待する結果**
KPI（例: Total Revenue ≈ **$931.8K**、Total Trips ≈ **37.9K**）とグラフが表示されるダッシュボード。

---

## 8-3. 入力フォームを追加する（Fabric SQL DB → OneLake 自動ミラー）

> 🗣️ **プロンプト**
> ```text
> 「Add Trip Record」という入力フォームを追加して。
> 入力項目: pickupDate / vendor / rateCode / paymentType / passengers /
> tripDistance / fare / tip / tolls / note（total は自動計算）。
> 保存したデータは Fabric SQL Database に入り、OneLake に自動ミラーされるようにして。
> 直近の登録も一覧表示して。
> ```

🤖 **Copilot の動き**
- Rayfin の **データモデル** に `@entity` で **`TripEntry`**（13 列）を定義します。
- `npx rayfin up` で **Fabric SQL Database** にテーブル（`dbo.TripEntries`）を provisioning（DAB / GraphQL を自動生成）。
- フォーム送信は `client.data.TripEntry.create({...})`、一覧は `client.data.TripEntry.select(...).orderBy(...)`。

✅ **期待する結果**
フォームから送信すると `dbo.TripEntries` に保存され、直近の登録が一覧に出る。

**ミラーを確認してみる:**

> 🗣️ **プロンプト**
> ```text
> taxi-dashboard の Fabric SQL Database に入れたデータが、
> OneLake のミラー（MirroredWarehouse の分析エンドポイント）でも見えるか確認して。
> ```

🤖 **Copilot の動き** … SQL DB（`*.database.fabric.microsoft.com`）と、ミラー先の **MirroredWarehouse**
（`*.datawarehouse.fabric.microsoft.com`、DB 名は `taxi-dashboard`）の両方で `dbo.TripEntries` をクエリし、
同じ行が出ることを示します。

✅ **期待する結果**
SQL DB に入れた行が、数秒後に OneLake（MirroredWarehouse）側でも参照できる。

> 📌 **これがミラーリングの肝**: **Fabric SQL Database は OneLake に自動ミラー**され、`MirroredWarehouse` の
> SQL 分析エンドポイントとして Delta 化されます。入力データは **手動 ETL なし**で Lakehouse へショートカット
> ／分析できます（`入力 → SQL DB → OneLake → Lakehouse`）。

---

## 8-4. チャットボット（`taxi_ride_agent`）を追加する

> 🗣️ **プロンプト**
> ```text
> 右下の「Ask Agent」ボタンを押すと右からスライドインするチャットドロワーを追加して。
> taxi_ride_agent に自然言語で質問できるようにして（候補質問チップつき、× で閉じる）。
> ```

🤖 **Copilot の動き**
- 画面右下に**ランチャーボタン**、クリックで**右スライドインのチャットパネル**を実装（候補質問チップ・入力欄）。
- ブラウザから Fabric Data Agent を**直接は呼べない**（CORS ＋ OpenAI Assistants の多段フロー）ため、
  チャットは **`VITE_AGENT_PROXY_URL`（小さな中継プロキシ）経由**で呼び出します。
- `taxi_ride_agent` の ID とワークスペース ID は API で特定します。講師配布のプロキシ URL が既存設定にあれば
  Copilot が設定し、なければ不足を明示します。URL を推測したり、未設定のままチャット接続が完了したと扱ったりしません。

✅ **期待する結果**
ドロワー UI が表示される。プロキシ URL を設定すると、`taxi_ride_agent` の**接地（grounded）回答**が返る
（例: 「総トリップ数は？」→ *37,948 件 / $931,791.43*）。

> 🔌 **プロキシについて（重要）**: ブラウザ単体では Data Agent を呼べないため、**中継プロキシが必要**です。
> 本ハンズオンでは **講師が用意したプロキシ URL** を `VITE_AGENT_PROXY_URL` に設定します
> （自分で動かす場合は末尾の「🔍 参考」を参照）。プロキシ未設定でもドロワー UI は表示され、
> 「プロキシが未設定です」と案内されます。

---

## 8-5. 自分のワークスペースにデプロイして確認する

> 🗣️ **プロンプト**
> ```text
> taxi-dashboard を Fabric にデプロイして、
> 公開 URL とポータルリンクを教えて。
> ```

🤖 **Copilot の動き** … 登録済みの名前を `$WORKSPACE_NAME` に設定し、`npx rayfin up --workspace "$WORKSPACE_NAME"` を実行。**AppBackend** アイテムを作成し、
静的コンテンツをビルド・アップロードして `*.webapp.fabricapps.net` で公開します。

✅ **期待する結果**
登録済みのワークスペースに `taxi-dashboard`（AppBackend）が作成され、公開 URL が表示される。
URL を開いて **登録済みのアカウントでサインイン**すると、ダッシュボード・入力フォーム・チャットドロワーが使える。

```text
🎉 deployed: taxi-dashboard (AppBackend)
🌐 公開 URL: Copilot がデプロイ結果から表示（*.webapp.fabricapps.net）
```
完成イメージ

<img width="1672" height="1328" alt="image" src="https://github.com/user-attachments/assets/a81f9115-d1e2-448c-a8b8-e4dfd800279b" />

---

## 🔍 （参考）裏側の仕組み

### ミラーリング（入力 → Lakehouse）
- `data` サービスは **Fabric SQL Database** を作成。書き込みは **OneLake に自動ミラー**され、
  `MirroredWarehouse` 型の SQL 分析エンドポイント（同名 `taxi-dashboard`）として Delta で参照できます。
- Lakehouse からはショートカットで参照でき、**ETL ジョブ不要**で分析・BI に流せます。

### チャットボットのプロキシ（`server/agent-proxy/`）
- 構成: **ブラウザ → プロキシ → Data Agent**（OpenAI Assistants: `assistant → thread → message → run → messages`）。
- Data Agent は **呼び出し元の権限**でデータソースを照会します。**grounded 回答にはデータソースへのアクセスが必要**。
  - **ユーザー権限のトークン**（登録済みのアカウントなど、対象データにアクセスできる人）→ 接地回答が返る。
  - **サービスプリンシパル**は、このテナントでは **セマンティックモデルの Execute Queries が拒否**されるため、
    そのままでは「authorization error」になります。
- プロキシは **ホスティングが必要**（例: Azure App Service）。`server/agent-proxy/README.md` に
  環境変数（`FABRIC_WORKSPACE_ID` / `FABRIC_DATAAGENT_ID` / `ALLOW_ORIGIN` / 認証）と
  デプロイ手順、セキュリティ注意（資格情報の取り扱い）を記載しています。
- ローカル開発（`npm run dev`）なら、ローカルでプロキシを起動して試すこともできます。

---

## ✅ チェックポイント

- [ ] Rayfin CLI で `taxi-dashboard` プロジェクトを作り、登録済みのアカウントでサインインできた
- [ ] `sm_taxi_warehouse` のデータで KPI・グラフ・スライサーのダッシュボードを作れた
- [ ] `Add Trip Record` フォームを追加し、`dbo.TripEntries` に保存できた
- [ ] 入力データが **OneLake（MirroredWarehouse）にミラー**されることを確認できた
- [ ] 右下ボタンで開く **チャットドロワー**（`taxi_ride_agent`）を追加できた
- [ ] 登録済みのワークスペースに **AppBackend をデプロイ**し、公開 URL で動作確認できた

---

## 🧹 トラブルシュート（プロンプトで対処）

| 症状 | プロンプト例 / 対処 |
|------|---------------------|
| `Fabric Apps` が作成できない | テナントで *Fabric Apps（preview）* が有効か、Fabric 容量かを確認（講師に連絡） |
| `rayfin login` のブラウザで別アカウント | 一度サインアウトし、**登録済みのアカウント**で入り直す（InPrivate 推奨） |
| ダッシュボードの数値が全 payment 同じ | 「ディメンション経由ではなく fact の列で集計し直して」 |
| フォーム保存でテーブルが無い | 先に「`rayfin up` で TripEntry テーブルを作成して」→ 再度送信 |
| ミラーが見えない | 数十秒待って再確認。DB 名は表示名 `taxi-dashboard`（GUID 付きカタログではない） |
| チャットが「プロキシ未設定」 | `VITE_AGENT_PROXY_URL` に**講師提供のプロキシ URL**を設定して再デプロイ |
| チャットが「authorization error」 | プロキシが**データにアクセスできる ID**で動いているか確認（参考セクション） |
| デプロイ後に画面が白い | サインイン済みか確認。`rayfin up status` でデプロイ状態を確認 |

---

## 🎉 おつかれさまでした！

これで全ラボ（Lab 00〜08）が完了です。
Lakehouse → ショートカット → Warehouse → セマンティックモデル → Power BI レポート →
会話型 AI（Data Agent）に加えて、**Fabric App（ダッシュボード＋入力フォーム＋チャットボット）** までを
**自然言語プロンプトだけ**で構築しました 🚀
入力データが **OneLake に自動ミラー**され、**Data Agent と会話できるアプリ**が自分のワークスペースで動いています。

> 🎨 **（任意）さらにデザインを磨く**:
> - [Lab 09 — 付録: デジタル庁スタイルに作り直す](09-appendix-digicho-dashboard-design.md) … Lab 06 の **Power BI レポート**をデジタル庁テンプレート（Blue）風に。
> - [Lab 10 — 付録: Fabric App を UX デザインで作り直す](10-rayfin-fabric-app-ux.md) … この **Fabric App** を独自デザインシステム（Midnight Dispatch）＋リッチな可視化＋ゾーン注釈でデモ映えさせる。
