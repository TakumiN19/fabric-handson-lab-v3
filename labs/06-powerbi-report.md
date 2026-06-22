# Lab 06: Power BI レポート作成

## 概要

セマンティックモデル `sm_taxi_warehouse` を使い、乗車時刻・乗車場所・料金を多角的に分析する Power BI レポートを GitHub Copilot CLI で作成して Fabric に公開します。

このラボでは **2種類のレポート** を作成することで、**カスタムスキルの有無による成果物の違い**を体感します：

| | スキルなし版 | スキルあり版（デジ庁形式） |
|--|------------|----------------------|
| **キャンバス** | 1920×1080（Power BI デフォルト） | 1280×720（デジ庁ガイドブック準拠） |
| **レイアウト** | 4ビジュアルを縦2段配置 | ヘッダー / KPI ストリップ / 2×2 グリッド / フッター |
| **カラー** | Power BI デフォルト（青紫） | Digital Agency Blue（#3460FB / #0017C1） |
| **KPI 表示** | なし | KPI バナー（pivotTable・平均料金/件数/最大料金） |
| **読み取り動線** | なし | 左上（全体）→ 右下（詳細）の視線誘導 |
| **デザイン要素** | なし | ヘッダーバンド・左アクセント・青ヘッダーKPIバナー |

---

## 前提条件

- **ライセンス**: `studentX` で **Fabric トライアル（PPU 相当）または Power BI Pro / PPU** が有効であること。
  **Fabric (Free) では Power BI レポートを作成・発行できません**（容量が F64 でも、作成には Pro / PPU が必要）。
  開始手順は [Fabric サインイン手順](fabric-portal-login.md) の「手順 5」を参照。
- Lab 05 完了（セマンティックモデル `sm_taxi_warehouse` が公開済みであること）
- `powerbi-report-authoring` スキルが利用可能であること
- `powerbi-report-author` CLI がインストール済みであること

```bash
npm install -g @microsoft/powerbi-report-authoring-cli
powerbi-report-author --version
```

---

## ステップ 1: 日付関連テーブルの追加（Lakehouse）

Warehouse の `fact_greentrip_copilot` には datetime 型の列がないため、Lakehouse に日付情報テーブルを追加します。

### プロンプト例

```
Livy セッションを使って、Lakehouse の green_tripdata_2026 テーブルから
lpep_pickup_datetime を DATE/INT/STRING 型に変換した
fact_greentrip_dates テーブルを作成して
```

### 実行イメージ（PySpark）

```python
from pyspark.sql.functions import col, to_date, hour, date_format

df = spark.table("green_tripdata_2026")
df_dates = df.select(
    col("lpep_pickup_datetime").cast("timestamp").cast("date").alias("pickup_date"),
    hour(col("lpep_pickup_datetime").cast("timestamp")).alias("pickup_hour"),
    date_format(col("lpep_pickup_datetime").cast("timestamp"), "yyyy-MM").alias("pickup_month"),
    col("fare_amount"),
    col("PULocationID")
)
df_dates.write.format("delta").mode("overwrite").saveAsTable("fact_greentrip_dates")
```

---

## ステップ 2: セマンティックモデルの更新

`fact_greentrip_dates` テーブルをセマンティックモデルに追加します。

### プロンプト例

```
セマンティックモデル sm_taxi_warehouse に
fact_greentrip_dates テーブルを追加して、
Avg Fare メジャーと dimension_taxiZoneLookup へのリレーションシップも設定して
```

追加する TMDL（table/fact_greentrip_dates.tmdl の例）:

```tmdl
table fact_greentrip_dates
    partition fact_greentrip_dates = m
        mode: import
        source =
            let
                Source = Sql.Database("<SQL_ENDPOINT_SERVER>", "taxi_lakehouse"),
                Data = Source{[Schema="dbo",Item="fact_greentrip_dates"]}[Data]
            in Data

    column pickup_date
        dataType: dateTime
        formatString: Short Date

    column pickup_hour
        dataType: int64

    column pickup_month
        dataType: text

    column fare_amount
        dataType: decimal

    column PULocationID
        dataType: int64

    measure 'Avg Fare' = AVERAGE(fact_greentrip_dates[fare_amount])
        formatString: \$#,0.00

    // --- KPI バナー（pivotTable）用メジャー ---
    measure '平均料金 ($)' = AVERAGE(fact_greentrip_dates[fare_amount])
        formatString: \$#,##0.00
    measure '総乗車件数' = COUNTROWS(fact_greentrip_dates)
        formatString: #,##0
    measure '最大料金 ($)' = MAX(fact_greentrip_dates[fare_amount])
        formatString: \$#,##0.00

relationship fact_greentrip_dates_to_zone
    fromColumn: fact_greentrip_dates[PULocationID]
    toColumn: dimension_taxiZoneLookup[LocationID]
```

---

## ステップ 3: PBIR レポートファイルの作成

### プロンプト例

```
powerbi-report-authoring スキルを使って、以下の内容でレポートを作成して。
レポート名は "Power BI Copilot Report"

・タイトル: 乗車時刻・乗車場所・料金の分析
・日別平均料金の折れ線グラフ（pickup_date × Avg Fare）
・時間帯別平均料金の折れ線グラフ（pickup_hour × Avg Fare）
・Zone別平均料金の横棒グラフ（Zone × Avg Fare、降順）
・Borough別平均料金の横棒グラフ（Borough × Avg Fare）
・Zone × pickup_month の平均料金マトリックス
```

### ディレクトリ構成

```
/tmp/pbir/Power BI Copilot Report.Report/
├── .platform
├── definition.pbir
└── definition/
    ├── version.json
    ├── report.json
    └── pages/
        ├── pages.json
        └── <pageId>/
            ├── page.json
            └── visuals/
                ├── <id>/visual.json  ← textbox (タイトル)
                ├── <id>/visual.json  ← lineChart (日別)
                ├── <id>/visual.json  ← lineChart (時間帯別)
                ├── <id>/visual.json  ← clusteredBarChart (Zone別)
                ├── <id>/visual.json  ← clusteredBarChart (Borough別)
                └── <id>/visual.json  ← pivotTable (マトリックス)
```

---

## ステップ 3.5: KPI バナーの実装（pivotTable）⭐ 重要

> **このラボで最もハマるポイント。** 上部のKPI（平均料金・件数・最大料金）は、直感的には `cardVisual`（カードビジュアル）を使いたくなりますが、**Fabric の Power BI サービス環境では `cardVisual` が描画されず空白の箱になる**現象が発生しました（コンテナ枠だけ表示され、value/label/accentBar など中身が一切出ない）。さらに、描画に失敗する `cardVisual` は **PDF エクスポート（ExportTo）処理も 0% で停止**させます。

### ✅ うまくいく方法: `pivotTable` で KPI バナーを作る

KPI は **`pivotTable`（マトリックス）の Values ロールに複数メジャーを並べる**ことで、確実に表示できます（折れ線・棒グラフと同じ描画エンジンのため信頼性が高い）。

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.9.0/schema.json",
  "name": "<20桁hex>",
  "position": { "x": 0, "y": 64, "z": 2000, "height": 92, "width": 1272, "tabOrder": 2000 },
  "visual": {
    "visualType": "pivotTable",
    "query": {
      "queryState": {
        "Values": {
          "projections": [
            { "field": { "Measure": { "Expression": { "SourceRef": { "Entity": "fact_greentrip_dates" } }, "Property": "平均料金 ($)" } }, "queryRef": "fact_greentrip_dates.平均料金 ($)", "nativeQueryRef": "平均料金 ($)" },
            { "field": { "Measure": { "Expression": { "SourceRef": { "Entity": "fact_greentrip_dates" } }, "Property": "総乗車件数" } }, "queryRef": "fact_greentrip_dates.総乗車件数", "nativeQueryRef": "総乗車件数" },
            { "field": { "Measure": { "Expression": { "SourceRef": { "Entity": "fact_greentrip_dates" } }, "Property": "最大料金 ($)" } }, "queryRef": "fact_greentrip_dates.最大料金 ($)", "nativeQueryRef": "最大料金 ($)" }
          ]
        }
      }
    },
    "objects": {
      "columnHeaders": [{ "properties": {
        "backColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#0017C1'" } } } } },
        "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#FFFFFF'" } } } } },
        "bold": { "expr": { "Literal": { "Value": "true" } } },
        "fontSize": { "expr": { "Literal": { "Value": "12D" } } },
        "alignment": { "expr": { "Literal": { "Value": "'Center'" } } },
        "autoSizeColumnWidth": { "expr": { "Literal": { "Value": "true" } } },
        "columnAdjustment": { "expr": { "Literal": { "Value": "'growToFit'" } } }
      }}],
      "values": [{ "properties": {
        "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#0017C1'" } } } } },
        "fontSize": { "expr": { "Literal": { "Value": "24D" } } },
        "bold": { "expr": { "Literal": { "Value": "true" } } }
      }}]
    },
    "visualContainerObjects": {
      "stylePreset": [{ "properties": { "name": { "expr": { "Literal": { "Value": "'None'" } } } } }],
      "border": [{ "properties": { "show": { "expr": { "Literal": { "Value": "false" } } } } }]
    }
  }
}
```

### ポイント

- **`Values` ロールに3メジャーを並べる** → 横並びの KPI バナー（ヘッダー行＝メジャー名、値行＝数値）として描画される。
- **日本語ヘッダーにするには**、メジャー名を日本語にする（`平均料金 ($)` など）。pivotTable のカラムヘッダーはメジャー名がそのまま表示されるため。
- **`stylePreset` を `None`** にしないと、既定スタイルが `backColor`/`fontColor` を上書きしてしまう（table.md の注意点）。
- 色（fill 型）は `{ "solid": { "color": { ... } } }` ラッパーで囲む。`alignment` は `columnHeaders` にはあるが `values` には**ない**（バリデーションエラーになるので注意）。

---


## ステップ 4: 重要なファイルの修正ポイント

### definition.pbir（Fabric 公開に必須）

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json",
  "version": "4.0",
  "datasetReference": {
    "byConnection": {
      "connectionString": "semanticmodelid=<セマンティックモデルのID>"
    }
  }
}
```

> ⚠️ **注意**: `byPath` ではなく `byConnection` を使用すること。`definitionProperties/2.0.0` が正しいスキーマパス。

### definition/version.json

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/versionMetadata/1.0.0/schema.json",
  "version": "2.0.0"
}
```

> ⚠️ **注意**: `version` ではなく `versionMetadata` がスキーマパス中の正しいキーワード。

### definition/pages/pages.json

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/pagesMetadata/1.0.0/schema.json",
  "pageOrder": ["<pageId>"],
  "activePageName": "<pageId>"
}
```

> ⚠️ **注意**: `pages` ではなく `pagesMetadata` がスキーマパス中の正しいキーワード。

---

## ステップ 5: バリデーション

```bash
powerbi-report-author validate "/tmp/pbir/Power BI Copilot Report.Report" --pretty
```

`result: "succeeded"` または `"succeededWithWarnings"` で errors が 0 であることを確認します。

---

## ステップ 6: Fabric へ公開

### プロンプト例

```
powerbi-report-management スキルを使って、
/tmp/pbir/Power BI Copilot Report.Report を
student<番号> ワークスペースに公開して
```

### az rest による公開スクリプト

```bash
WS_ID="<自分のワークスペース ID>"
REPORT_DIR="/tmp/pbir/Power BI Copilot Report.Report"

# 全ファイルをbase64エンコードしてペイロード作成
python3 << 'EOF'
import json, base64, os

report_dir = "/tmp/pbir/Power BI Copilot Report.Report"
parts = []
for root, dirs, files in os.walk(report_dir):
    dirs[:] = sorted([d for d in dirs if not d.startswith('.')])
    for fname in sorted(files):
        fpath = os.path.join(root, fname)
        rel = os.path.relpath(fpath, report_dir)
        with open(fpath, 'rb') as f:
            content = f.read()
        parts.append({
            "path": rel,
            "payload": base64.b64encode(content).decode(),
            "payloadType": "InlineBase64"
        })

payload = {
    "displayName": "Power BI Copilot Report",
    "definition": {"parts": parts}
}
with open("/tmp/report_publish_payload.json", "w") as f:
    json.dump(payload, f)
EOF

# LRO でポーリング
az rest --method post \
  --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces/$WS_ID/reports" \
  --body @/tmp/report_publish_payload.json \
  --verbose 2>/tmp/post_resp.txt

OP_ID=$(grep "x-ms-operation-id" /tmp/post_resp.txt | grep -oE "[0-9a-f-]{36}" | head -1)

# ステータスポーリング
for i in {1..12}; do
  sleep 5
  STATUS=$(az rest --method get --resource "https://api.fabric.microsoft.com" \
    --url "https://api.fabric.microsoft.com/v1/operations/$OP_ID")
  ST=$(echo "$STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))")
  echo "Status: $ST"
  if [[ "$ST" == "Succeeded" || "$ST" == "Failed" ]]; then break; fi
done
```

---

## ステップ 7: 確認

```bash
az rest --method get \
  --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces/$WS_ID/reports" \
  --query "value[].{name:displayName,id:id}" -o table
```

### Fabric Portal での確認

1. [Fabric Portal](https://app.fabric.microsoft.com) にアクセス
2. `student<番号>` ワークスペースを選択
3. `Power BI Copilot Report` をクリック
4. 各ビジュアルにデータが表示されることを確認

---

## ステップ 7.5: レンダリングの自動検証（macOS / Power BI Desktop なし）⭐

> Power BI Desktop は Windows 専用のため、**macOS では `powerbi-desktop` スキルのスクリーンショット検証が使えません**。代わりに **Power BI ExportTo API で PDF 出力 → 画像化** すれば、実際のレンダリング結果を CLI から確認できます。

```bash
WS_ID="<自分のワークスペース ID>"
REPORT_ID="<自分のレポート ID>"
# Japan West テナントはリダイレクト先エンドポイントを使う
BASE="https://wabi-japan-west-a-primary-redirect.analysis.windows.net/v1.0/myorg"
TOKEN=$(az account get-access-token --resource "https://analysis.windows.net/powerbi/api" --query accessToken -o tsv)

# 1) エクスポート開始（PDF）
EXPORT_ID=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/groups/$WS_ID/reports/$REPORT_ID/ExportTo" -d '{"format":"PDF"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")

# 2) 完了までポーリング
for i in {1..18}; do
  sleep 7
  ST=$(curl -s -H "Authorization: Bearer $TOKEN" \
    "$BASE/groups/$WS_ID/reports/$REPORT_ID/exports/$EXPORT_ID" \
    | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['status'],d.get('percentComplete'))")
  echo "$ST"; echo "$ST" | grep -q Succeeded && break
done

# 3) ダウンロードして PNG 化（poppler の pdftoppm）
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/groups/$WS_ID/reports/$REPORT_ID/exports/$EXPORT_ID/file" -o report.pdf
pdftoppm -png -r 100 report.pdf report   # → report-1.png
```

> 💡 **副次効果**: `cardVisual` のように描画に失敗するビジュアルがあると ExportTo は 0% で停止します。**ExportTo が完走するかどうか自体が、レポートが正しく描画できているかの判定**にもなります（実際にこのラボでは cardVisual を pivotTable に置き換えたら ExportTo が成功するようになりました）。

---

## 完成レポートのビジュアル構成

| # | ビジュアル | 説明 |
|---|-----------|------|
| 1 | テキストボックス | タイトル（青ヘッダーバンド上に白字） |
| 2 | **pivotTable（KPIバナー）** | **平均料金・総乗車件数・最大料金の3KPI（最上段）** |
| 3 | 折れ線グラフ | 日別平均料金の推移 |
| 4 | 折れ線グラフ | 時間帯別平均料金の推移 |
| 5 | 横棒グラフ | Zone別平均料金（降順ソート） |
| 6 | 横棒グラフ | Borough別平均料金 |
| - | シェイプ | ヘッダーバンド・左アクセントライン・フッター区切り |

> KPI バナーは **`cardVisual` ではなく `pivotTable`** で実装（この環境では cardVisual が描画されないため。ステップ 3.5 参照）。

---

## セマンティックモデルのデータ接続モード

セマンティックモデルのテーブルは **DirectQuery** モードで設定します。

| モード | 説明 | Fabric 推奨 |
|--------|------|------------|
| **DirectQuery** | レポート表示時に毎回ライブクエリ。リフレッシュ不要。ユーザーの Entra ID (SSO) で自動認証 | ✅ |
| Import | データを事前にキャッシュ。リフレッシュが必要。Warehouse/Lakehouse SQL endpoint では **明示的な OAuth2 認証情報の設定が必須** | ⚠️ |

Import モードを使う場合は、Fabric Portal の「セマンティックモデルの設定」→「データソースの資格情報」→「資格情報の編集」で **組織アカウント** を設定する必要があります。

### TMDL でのDirectQuery 設定方法

```tmdl
partition fact_greentrip_copilot = m
    mode: directQuery   ← "import" ではなくこちら
    source = ...
```

---

## トラブルシューティング

| エラー | 原因 | 対処 |
|--------|------|------|
| `Can't find '$schema' property in 'version.json'` | `$schema` なし | `versionMetadata/1.0.0/schema.json` を追加 |
| `Can't resolve schema '1.0.0' in 'version.json'` | `version` パスが誤り | `versionMetadata` に変更 |
| `Can't resolve schema '1.0.0' in 'pages/pages.json'` | `pages` パスが誤り | `pagesMetadata` に変更 |
| `Can't resolve schema '2.0.0' in 'version.json'` | バージョンが新しすぎる | `versionMetadata/1.0.0` に変更 |
| セマンティックモデルにデータが表示されない | Import モードで認証情報未設定 | DirectQuery モードに変更するか、Portal で組織アカウントを設定 |
| **KPI カードが空白の箱になる（中身が出ない）** | **この環境で `cardVisual` が描画されない** | **`pivotTable`（Values に複数メジャー）で KPI バナーを作る（ステップ 3.5）** |
| ExportTo が 0% で止まる | 描画に失敗するビジュアル（cardVisual 等）がある | 問題のビジュアルを pivotTable 等に置き換える |
| `Unknown property "alignment" in formatting object "values"` | `values` に `alignment` は無い | `alignment` は `columnHeaders` のみ。`values` からは削除 |

---

---

## Lab 06B: スキルなし版レポートの作成（比較用）

### 目的

カスタムスキル（`powerbi-dashboard-layout`）なしでレポートを作成し、スキルあり版と比較することで、スキルがもたらす設計上の価値を体感します。

### プロンプト例（スキルなし）

```
powerbi-report-authoring スキルを使って、
セマンティックモデル sm_taxi_warehouse のデータを使い、
基本的なレポートを作って：
・タイトルテキストボックス（1920×1080 キャンバス）
・日別平均料金の折れ線グラフ（左上）
・時間帯別平均料金の折れ線グラフ（右上）
・Zone別平均料金の横棒グラフ（左下）
・Borough別平均料金の横棒グラフ（右下）
特別なデザインルールは不要。
```

### スキルなし版レイアウト構成

| # | 位置 | サイズ | ビジュアル |
|---|------|--------|-----------|
| 1 | 上部全体 | 1920×60 | タイトルテキストボックス |
| 2 | 左上 | 940×480 | 折れ線グラフ（日別） |
| 3 | 右上 | 940×480 | 折れ線グラフ（時間帯別） |
| 4 | 左下 | 940×480 | 横棒グラフ（Zone別） |
| 5 | 右下 | 940×480 | 横棒グラフ（Borough別） |

---

## Lab 06C: デジ庁スキルを使ったリッチなレポートの作成

### 目的

`powerbi-dashboard-layout` スキルのガイドブック準拠メソッドを使い、読み取り動線・KPI ストリップ・カラーパレットを適用した高品質ダッシュボードを作成します。

### プロンプト例（スキルあり）

```
powerbi-dashboard-layout スキルを使って、
グリーンタクシー乗車データのダッシュボードをデジ庁ガイドブック形式でデザインして。
スキルなし版 (1920×1080) との違いを最大化して、
Blue ファミリーのカラーパレットを使い、
KPI ストリップ・ヘッダーバンド・読み取り動線を含めて。
```

### デジ庁スキルが適用する設計原則

| 原則 | スキルなし | スキルあり（デジ庁） |
|------|-----------|------------------|
| キャンバス | 1920×1080（デフォルト） | 1280×720（ガイドブック準拠 16:9） |
| 読み取り動線 | なし（ランダム配置） | 左上（全体 / 概要）→ 右下（詳細） |
| KPI | なし | KPI バナー（pivotTable）で重要指標を最上段に |
| カラー | Power BI デフォルト | Digital Agency 7 Hue（Blue #3460FB） |
| ヘッダー | テキストのみ | 全幅バンド（#0017C1） + アクセント |
| KPI バナー | なし | 青ヘッダー + 大きな数値（pivotTable, stylePreset None） |
| フッター | なし | データソース + 更新情報 |
| アクセシビリティ | 考慮なし | コントラスト ≥ 3:1、カラー非依存 |

> ⚠️ **KPI は `cardVisual` ではなく `pivotTable` で実装**します。この Fabric 環境では cardVisual が空白になるためです（ステップ 3.5 とトラブルシューティング参照）。

### デジ庁フォーマット レイアウト詳細

```
+----------------------------------------------------------+  y=0
| [Blue900バンド全幅]  タイトル（白字）                    |  y=0..56
+----------------------------------------------------------+  y=56
| [KPI バナー: pivotTable]                                 |  y=64..156
|   平均料金 ($) | 総乗車件数 | 最大料金 ($)               |  ← 青ヘッダー+大きな数値
+----------------------------------------------------------+  y=174
| ●日別平均料金推移(折れ線)  | ●Zone別平均料金(横棒)      |  y=176..424
|   740×248                  |   524×248                  |
+----------------------------------------------------------+  y=440
| ●時間帯別平均料金(折れ線)  | ●Borough別平均料金(横棒)  |  y=440..672
|   740×232                  |   524×232                  |
+----------------------------------------------------------+  y=676
| データソース                          DirectQuery 表記   |  y=676..720
+----------------------------------------------------------+

● = 左アクセントライン (Blue600 #3460FB, 4px幅)
※ KPI は cardVisual ではなく pivotTable で実装（ステップ 3.5 参照）
```

---

## 参考情報

### 作成したレポート（講師作成の参考例）

> 📌 下記リンクは **講師が作成した見本レポート**（`student0` デモワークスペース）です。
> 受講者自身のレポートは自分の `student<番号>` ワークスペースに作成され、URL / ID は異なります。

| レポート | URL | 特徴 |
|---------|-----|------|
| **スキルなし版** | [Power BI Copilot Report (スキルなし)](https://app.fabric.microsoft.com/groups/7a430330-5e50-4d60-a9fc-fd787832b907/reports/4ccb7268-169e-456b-8cd4-bc3c2ccebbcd) | 1920×1080、デフォルトスタイル、4ビジュアル |
| **スキルあり版（デジ庁）** | [Power BI Copilot Report](https://app.fabric.microsoft.com/groups/7a430330-5e50-4d60-a9fc-fd787832b907/reports/40ca1ab7-418b-4059-a725-ec6d226eba66) | 1280×720、Blue パレット、KPI+4チャート+ヘッダー/フッター |

### ID 情報

- セマンティックモデル ID: `921b90fa-c16c-4145-b054-13fcd70449e2`
- デジ庁スキルあり レポート ID: `40ca1ab7-418b-4059-a725-ec6d226eba66`
- スキルなし レポート ID: `4ccb7268-169e-456b-8cd4-bc3c2ccebbcd`
