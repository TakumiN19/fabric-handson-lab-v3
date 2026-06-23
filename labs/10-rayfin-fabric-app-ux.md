# Lab 10 — 付録: Fabric App を UX デザインシステムでデモ映えさせる（プロンプト駆動）

所要時間: 約 35 分
前提:
- [Lab 08](08-fabric-app.md) 完了（**Rayfin CLI で Fabric App を作る基本**に習熟していること）
- [Lab 05](05-semantic-model.md) 完了（`sm_taxi_warehouse` が自分の `student<番号>` ワークスペースに存在）
- **Node.js**（v20 以上）/ **`sqlcmd`**（go-sqlcmd）/ `az login`（`student<番号>`）

> 🎫 **機能注意**: **Fabric Apps（preview）** を使います（Lab 08 と同じ）。Fabric 容量（**トライアル可**）が必要です。

この付録は、Lab 08 で作った **Fabric App** を一段引き上げ、**「デモ映えする UX」** に仕立て直すラボです。
Lab 08 が *機能*（ダッシュボード＋入力＋チャット）を最短で載せたのに対し、ここでは **デザインを主役**にします。

> 🎨 **Lab 09 との対応**: Lab 09 が **Power BI レポート**を「デジタル庁デザイン」に作り直す付録なら、
> この **Lab 10 は Fabric App（Rayfin）** を **独自のデザインシステム**で作り直す付録です。BI とアプリ、両方の「デザイン版」が揃います。

この付録で Lab 08 に**上乗せ**する 3 点:

1. **設計システム**を起こす — 設計エージェントで UX 要件とダークテーマ "Midnight Dispatch"（配色・タイポ・コンポーネント）を定義。
2. **リッチでインタラクティブな可視化** — Recharts で KPI／ボロー別／時間帯別／トップゾーン／ベンダー／乗車種別を描画し、**ボロー→ゾーンのクロスフィルタ**を実装。
3. **ゾーン注釈（メモ／タグ）の書き込み** — 分析画面に業務操作（write-back）を統合（Power BI にはできない体験）。

> 🤖 **裏側では何が動く？** Lab 08 と同じく Copilot CLI が **Rayfin CLI**（`@microsoft/rayfin-cli`）でプロジェクトをスキャフォールドし、
> **AppBackend** を作って React を Fabric にホストします（`*.webapp.fabricapps.net`）。
> 数値は `sm_taxi_warehouse` から **DAX（Execute Queries）** で取得し、**アプリ専用の Fabric SQL Database にスナップショット**として取り込みます。

---

> 📖 **分からない用語があれば** [用語集（Glossary）](glossary.md) で確認できます（Lakehouse・Delta・Livy・セマンティックモデル など）。

## 🧠 重要な考え方: 「コードファースト」と「スナップショット橋渡し」

- **Rayfin はコードファースト**。エンティティ（TypeScript クラス）を書くと、SQL スキーマ・DAB・型付きクライアント（`client.data.*`）が生成されます。
  **可視化や画面デザインは Rayfin の対象外**（React 側の責務）＝**UX 要件は作る人が決める**。だから 10-1 で設計から入ります。
- **Fabric App のデータはアプリ専用 MSSQL**。`sm_taxi_warehouse` を直接は読みません。集計値は **DAX → アプリ DB** に取り込みます。

```
[ sm_taxi_warehouse ]  ──DAX(Execute Queries)──▶  [ refresh-analytics ]  ──sqlcmd──▶  [ アプリ専用 SQL DB ]
                                                                                          │ Rayfin DAB が自動配信
                                                                                          ▼
                                                              [ Fabric App ]  client.data.* でネイティブ取得
```

> 💡 **なぜ DB スナップショットか**: Lab 08 は集計 JSON を**フロントに埋め込み**ました（再集計はクライアント側）。
> この付録は集計を**アプリ DB のテーブル**に置きます。利点は **再デプロイなしで数値を更新**できること（スクリプト再実行だけ）。
> ブラウザから Power BI API を直接叩くと **CORS** で失敗するため、いずれも「事前に集計を持ってくる」点は共通です。

---

## 10-1. UX 要件と設計システムを起こす（設計エージェント）★この付録の核

Rayfin はバックエンドのパターンしか与えません。**画面の良し悪し＝UX は作る人の責任**です。
通常の受講者は Lab 02〜08 で**データモデルを把握済み**なので、その理解を起点に「何を・どう見せるか」を先に決めます。

> 🗣️ **プロンプト**
> ```text
> NYC グリーンタクシーの分析データ（ゾーン別平均料金・ボロー別・時間帯別・
> ベンダー別・乗車種別の件数と平均料金）をデモ映えさせるダッシュボードの
> UX 要件をまとめて。そのうえで、ダークテーマの設計システム（カラーパレット・
> タイポグラフィ・コンポーネント仕様）を WCAG AA を満たす形で定義して。
> ```

🤖 **Copilot の動き**
- `se-ux-ui-designer` / `gem-designer` のような **UX/デザイン系エージェント**で、ユーザージャーニー → 情報設計 → コンポーネント設計 → 設計システムに落とし込みます。
- データの**粒度（グレイン）に正直**な設計にします（例: ボロー列を持つのはゾーン・スナップショットのみ → ボロー↔ゾーンのクロスフィルタは成立。時間帯/ベンダー/乗車種別は「全体（Overall）」表示）。

✅ **期待する結果** — 設計システム **"Midnight Dispatch"**（抜粋）

| 要素 | 値 |
|------|-----|
| 背景 / サーフェス | `#0A0E18` / `#121826` |
| ブランド（azure） | `#4C8DFF` |
| アクセント（taxi amber・**シグナル専用**） | `#FFB81C` |
| テキスト | `#EAF0FA` / `#9FB0CB` / `#8493B0` |
| ボーダー | `#2A3450`（装飾）/ `#566488`（操作系） |
| フォント | Space Grotesk（見出し）/ Manrope（本文）/ JetBrains Mono（数値） |

> 💡 設計エージェントは**ファイルを書きません**。要件・設計システムを**テキスト成果物**として受け取り、
> 10-4 の実装プロンプトの「入力」として渡します。

---

## 10-2. Rayfin アプリの土台を作る（Lab 08 の復習）

> 🗣️ **プロンプト**
> ```text
> Rayfin で taxi-insights という Fabric App プロジェクトを作って、
> student<番号> ワークスペース向けに初期化して。Fabric 認証（SSO のみ）にして。
> そのあと Rayfin にブラウザでサインインして（student<番号> アカウントで）。
> ```

🤖 **Copilot の動き**
- `npx rayfin init`（または `npm create @microsoft/rayfin@latest`）で React + Vite + Tailwind のプロジェクトを生成。
- `npx rayfin login` → ブラウザで `student<番号>` アカウントでサインイン。
- 可視化用に **Recharts** を追加（`npm i recharts`）。

✅ **期待する結果**
`taxi-insights/` プロジェクトが生成され、`Signed in` と表示される（Lab 08 と同じ流れ）。

---

## 10-3. データモデル: 業務（注釈）＋分析スナップショット

2 種類のエンティティを定義します。**業務（書き込み）**の `ZoneNote` と、**分析スナップショット（読み取り）** 6 種です。

> 🗣️ **プロンプト**
> ```text
> このアプリに次の Rayfin エンティティを追加して schema に登録して。
> - ZoneNote: location_id(number), zone_name(text?), tag(text), body(text?), user_id(text)
> - ZoneFareStat: location_id, zone, borough, avg_fare, trip_count
> - KpiOverview: trips, avg_fare, total_amount, avg_trip_distance
> - AggBorough: borough, avg_fare, trip_count
> - AggHour: hour, avg_fare, trip_count
> - AggVendor: vendor_name, trips, total_amount
> - AggTripType: trip_type_name, trips
> 全エンティティに refreshed_at(datetime?) を持たせて。
> ```

🤖 **Copilot の動き** — 生成されるエンティティ例

```typescript
// rayfin/data/ZoneNote.ts — 業務（書き込み）エンティティ
import { entity, id, text, number, datetime } from '@microsoft/rayfin-data';

@entity()
export class ZoneNote {
  @id() id!: string;
  @number() location_id!: number;
  @text({ max: 100, optional: true }) zone_name?: string;
  @text({ max: 50 }) tag!: string;
  @text({ max: 2000, optional: true }) body?: string;
  @text({ max: 200 }) user_id!: string;
  @datetime({ optional: true }) created_at?: Date;
}
```

```typescript
// rayfin/data/ZoneFareStat.ts — 分析スナップショット（読み取り）
@entity()
export class ZoneFareStat {
  @id() id!: string;
  @number() location_id!: number;
  @text({ max: 100 }) zone!: string;
  @text({ max: 50 }) borough!: string;
  @number() avg_fare!: number;
  @number() trip_count!: number;
  @datetime({ optional: true }) refreshed_at?: Date;
}
```

> 📝 **Rayfin の作法**（つまずきポイント）:
> - `@text()` には **`max` 指定が必須**（`NVARCHAR(MAX)` だと DAB / GraphQL で失敗）。
> - `@optional()` デコレータは無い → **`{ optional: true }`** をオプションで渡す。
> - ESM のため import は **`.js` 拡張子付き**（`import { ZoneNote } from './ZoneNote.js'`）。
> - テーブル名は **複数形**にマップ（`ZoneNote`→`ZoneNotes`、`AggBorough`→`AggBoroughs`）。

✅ **期待する結果**
`rayfin/data/schema.ts` に全 7 エンティティ（`ZoneNote` ＋スナップショット 6 種）が登録される。

---

## 10-4. 設計システムを適用したインタラクティブ・ダッシュボード（Recharts）

10-1 の設計システムを入力に、**Recharts ＋ Tailwind CSS v4** でダッシュボードを実装します。

> 🗣️ **プロンプト**
> ```text
> HomePage を「NYC Taxi Insights」ダッシュボードに作り替えて。設計システム "Midnight Dispatch"
> （背景 #0A0E18 / サーフェス #121826 / azure #4C8DFF / amber はシグナル専用）を適用し、
> Recharts で次を表示して:
> - KPI ストリップ（総乗車件数・平均料金・売上合計・平均距離）
> - ボロー別バー（クリックでゾーン一覧をクロスフィルタ）
> - 時間帯別 ComposedChart（件数バー＋平均料金ライン）
> - トップゾーン バー（選択でゾーン詳細＋注釈 CRUD を表示）
> - ベンダー別／乗車種別のドーナツ
> データは client.data.* から取得し、localhost ではサンプルにフォールバックして。
> ```

🤖 **Copilot の動き**
- `src/services/analytics.ts` が `client.data.KpiOverview` 等を読み出し（localhost ではサンプルにフォールバック）。
- `src/services/zoneNotes.ts` が `ZoneNote` の CRUD（作成・一覧・削除）を提供。
- `src/pages/HomePage.tsx` が設計システムのクラス文字列（Tailwind v4 任意値 `bg-[#0A0E18]` 等）でダッシュボードを描画。

✅ **完成アプリのビジュアル構成**

| # | ビジュアル | グラフ種別 | インタラクション |
|---|-----------|-----------|----------------|
| 1 | KPI ストリップ | 4 カード | 総件数 / 平均料金 / 売上合計 / 平均距離 |
| 2 | By Borough | 横棒（Bar） | **クリックでクロスフィルタ**（ゾーン一覧を絞り込み） |
| 3 | By Hour | ComposedChart | 件数（バー）＋平均料金（ライン）を 1 枚に |
| 4 | Top Zones | 縦棒（Bar） | **選択でゾーン詳細＋注釈 CRUD** を展開 |
| 5 | ゾーン注釈 | フォーム＋リスト | **タグ付きメモの追加・削除（書き込み）** |
| 6 | By Vendor | ドーナツ（Pie） | 全体のベンダー構成比 |
| 7 | By Trip Type | ドーナツ（Pie） | Street-hail / Dispatch の構成比 |

> 💡 **データ粒度の正直さ**: ボロー列を持つのはゾーン・スナップショットのみのため、ボロー↔ゾーンのクロスフィルタは実データで成立。
> 時間帯/ベンダー/乗車種別は「全体（Overall）」表示とし、過剰なドリルダウンを謳いません。

> 📦 ビルドメモ: Recharts 導入後の bundle は ~700KB（chunk-size 警告は**情報レベル**で問題なし。Fabric 上限 100MB に対し十分小さい）。
> `npm run build` / `tsc` / `npm test` がすべてグリーンであることを確認します。

---

## 10-5. Fabric へデプロイする

> 🗣️ **プロンプト**
> ```text
> この taxi-insights アプリを student<番号> ワークスペースにデプロイして、
> 公開 URL とポータルリンクを教えて。
> ```

🤖 **Copilot の動き** — `npx rayfin up --workspace student<番号>` を実行（ヘッドレスは環境変数で渡す）。

```bash
az account set --subscription e6c1292e-65b7-4e2d-9e1b-13f24e7753fd   # 有効アカウントを student<番号> に
export RAYFIN_TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com -o tsv)
export RAYFIN_WORKSPACE_ID=<あなたの workspace id>
export RAYFIN_TENANT_ID=e6c1292e-65b7-4e2d-9e1b-13f24e7753fd
export RAYFIN_ENCRYPTION_FALLBACK_ENABLED=true
npx rayfin up -y
```

✅ **期待する結果**
`student<番号>` ワークスペースに `taxi-insights`（AppBackend）が作成され、`*.webapp.fabricapps.net` の公開 URL が返る（HTTP 200）。
アプリ専用 SQL DB にエンティティどおりのテーブル（複数形）が作成される。

---

## 10-6. 分析スナップショットを投入して確認する（DAX → アプリ DB）

デプロイ直後はテーブルが空です。`sm_taxi_warehouse` から **DAX（Execute Queries）** で集計を取得し、
アプリ DB に **DELETE + INSERT** で取り込みます（`scripts/refresh-analytics.py` が一括で実行）。

> 🗣️ **プロンプト**
> ```text
> sm_taxi_warehouse から KPI・ゾーン別・ボロー別・時間帯別・ベンダー別・乗車種別の集計を
> DAX で取得して、デプロイ済み taxi-insights アプリの SQL DB にスナップショット投入するスクリプトを作って実行して。
> ```

🤖 **Copilot の動き** — DAX の要点（ASCII メジャー名で書く）

```python
# KPI（1 行）
EVALUATE ROW("trips",[# Trips],"avg_fare",[Avg Fare],
            "total_amount",[Total Amount],"avg_dist",[Avg Trip Distance])

# ゾーン別（平均料金＋件数）
EVALUATE SUMMARIZECOLUMNS(
  dimension_taxiZoneLookup[LocationID], dimension_taxiZoneLookup[Zone],
  dimension_taxiZoneLookup[Borough],
  "avg_fare",[Avg Fare], "trips",COUNTROWS(fact_greentrip_dates))
```

取得した行は `sqlcmd`（Entra ID 認証）で投入します:

```bash
sqlcmd -S <app-sql-server> -d <app-db> \
  --authentication-method=ActiveDirectoryDefault -C -i refresh.sql
```

✅ **期待する結果**（投入行数）

```
KpiOverviews    1
ZoneFareStats   265
AggBoroughs     7
AggHours        24
AggVendors      2
AggTripTypes    2
```

整合性チェック（すべて **37,948 件**に合算）:
- KPI: 37,948 件 / 平均料金 $11.92 / 売上合計 $687,602.60 / 平均距離 3.49 mi
- ベンダー: VeriFone 19,043 ＋ Creative Mobile 18,905 = **37,948** ✓
- 乗車種別: Street-hail 34,254 ＋ Dispatch 3,694 = **37,948** ✓
- ボロー: Queens 9,957 / Manhattan 9,937 / Brooklyn 8,702 / Bronx 6,151 / Staten Island 2,800 / Unknown 266 / EWR 135 = **37,948** ✓

公開 URL を開いて `student<番号>` でサインインすると、**ライブ数値のダッシュボード**が表示され、
ボロー別バーのクリックでゾーン一覧が絞り込まれ、ゾーンを選ぶと**注釈（メモ／タグ）を追加・削除**できます。

> 🔁 **再実行可能**: スクリプトは DELETE+INSERT のため、セマンティックモデルが更新されたら**再実行するだけ**で
> アプリのスナップショットが最新化されます（**再デプロイ不要**）。

> ⚠️ **DAX は ASCII のメジャー名で**（日本語メジャー名は Execute Queries で失敗しやすい）。
> `sqlcmd` は `-G` と `--authentication-method` を**同時指定しない**（排他）。

---

## ✅ チェックポイント

- [ ] **10-1**: UX 要件と設計システム "Midnight Dispatch" を定義できた
- [ ] **10-2**: Rayfin で `taxi-insights` を作り、`student<番号>` でサインインできた
- [ ] **10-3**: 業務（`ZoneNote`）＋分析スナップショット 6 種を定義し `schema.ts` に登録した
- [ ] **10-4**: 設計システムを適用した Recharts ダッシュボード（クロスフィルタ・注釈 CRUD）を実装した
- [ ] **10-5**: `rayfin up` で Fabric にデプロイ（公開 URL が HTTP 200）
- [ ] **10-6**: DAX → スナップショット投入（行数 1 / 265 / 7 / 24 / 2 / 2）し、ライブ数値を確認した

---

## 🧹 トラブルシュート（プロンプトで対処）

| 症状 | プロンプト例 / 対処 |
|------|---------------------|
| `@text()` で DAB/GraphQL エラー | `@text({ max: N })` のように **`max` を指定**（`NVARCHAR(MAX)` を避ける） |
| import 解決エラー | ESM のため import を **`.js` 拡張子付き**にする（`./ZoneNote.js`） |
| デプロイは成功するがダッシュボードが空 | **10-6 未実行**。`refresh-analytics.py` を実行してスナップショットを投入 |
| `Execute Queries` が 400/失敗 | DAX のメジャー名を **ASCII** にする（日本語メジャー名を使わない） |
| `rayfin up` が認証で失敗 | `az` の有効アカウントが `student<番号>` か確認 → `RAYFIN_TOKEN` を取り直す |
| ブラウザで開くと認証ループ | `student<番号>` の Fabric SSO で開く（InPrivate 推奨） |

---

## 🎉 おつかれさまでした！

Lab 08 の Fabric App に **設計システム（Midnight Dispatch）＋リッチなインタラクティブ可視化＋ゾーン注釈** を上乗せし、
**デモ映えするデータアプリ**を `student<番号>` ワークスペースにデプロイしました 🚀
Lab 09（Power BI のデザイン版）と合わせて、**BI レポートとデータアプリ、両方の「デザイン版」**が完成です。

> 📌 **参考実装**: [`shinyay/taxi-zone-notes-app`](https://github.com/shinyay/taxi-zone-notes-app)
> （`rayfin/data/` エンティティ / `src/pages/HomePage.tsx` ダッシュボード / `src/services/analytics.ts` / `scripts/refresh-analytics.py`）
