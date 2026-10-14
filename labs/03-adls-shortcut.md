# Lab 03 — ADLS Gen2 + OneLake ショートカット（プロンプト駆動）

所要時間: 約 15 分
前提: [Lab 02](02-lakehouse-load-and-transform.md) 完了（登録済みのワークスペース／Lakehouse に接続済み）

> 💡 **作業指示だけで実行できます。** アカウント・ワークスペース・接続先 ID は Copilot が自動で補います。
> 各プロンプトはそのまま貼り付けてください。設定が見つからない場合は [Lab 00 の 0-7](00-prerequisites.md#0-7-自分の-student-番号を一度だけ登録する)を確認します。

このラボでは、**講師が用意した共有の ADLS Gen2**〔Azure Data Lake Storage Gen2＝大容量データ向けストレージ〕 に対して、各受講者が **OneLake ショートカット**を
張り、Fabric から直接データを参照します。

```
（講師が事前準備済み）              （受講者が実施）
ADLS Gen2 + CSV + 共有接続  ──→   共有接続でショートカット作成  →  Lakehouse から参照・テーブル化
```

> ✅ **このラボに Azure の権限（サブスクリプションの RBAC〔ロールベースのアクセス権〕）は不要です。**
> ADLS Gen2 ストレージ・Service Principal〔アプリ/サービス用の ID〕・Fabric 接続（Connection＝データ源への到達情報と資格情報をまとめた設定）は **講師が 1 か所にまとめて作成・共有済み**です。
> 受講者は **Fabric 側でショートカットを作るだけ**。`az storage account create` などの Azure 操作は行いません。

---

> 📖 **分からない用語があれば** [用語集（Glossary）](glossary.md) で確認できます（Lakehouse・Delta・Livy・セマンティックモデル など）。

## ショートカットとは？

OneLake ショートカットは、**データをコピーせず**に別のストレージ（Azure・AWS・GCS 等）を
Lakehouse に仮想マウントする機能です。

```
Lakehouse
└── Files/
    └── taxi_zone/ ─── (Shortcut) ──→ 共有 ADLS Gen2 のコンテナ/パス
```

データは元の場所（講師の共有 ADLS）に残ったまま、各受講者の Fabric から直接読み取れます。

> 💡 **「取り込み（Lab 02）」と「ショートカット（Lab 03）」の違い**
> - **Lab 02**: ローカルのファイルを OneLake に **アップロード＝コピー**して取り込みました。
> - **Lab 03**: 外部に置いたままのデータを **ショートカットで“その場参照”**（コピーしない）します。
>
> **OneLake 自体は Fabric に自動で備わる**ため、ADLS Gen2 は不要です（Lab 02 がその例）。
> また、ショートカットの**参照先は ADLS Gen2 に限りません**——Amazon S3・Google Cloud Storage・別の OneLake なども指定できます。
> このラボは、その参照先の一例として共有 ADLS Gen2 を使っているだけです。

---

## 🔗 受講者が使う共有接続の情報

ショートカット作成時に、以下の**共有接続**を指定します（講師から共有済み・全受講者が利用可）。

| 項目 | 値 |
|------|-----|
| 接続名 | `adls-handson-sp-v3` |
| 接続 ID | `e580afe8-376d-43b2-8e03-192d031e782e` |
| ADLS Gen2 URL | `https://st0taxihandson0616.dfs.core.windows.net` |
| コンテナ / パス | `taxi-data` |
| 認証 | Service Principal（接続に格納済み・受講者は資格情報不要） |

> 💡 この接続は受講者全員に **User 権限で共有**されています。各受講者は自分のトークンで
> この接続 ID を使ってショートカットを作成できます（ADLS への直接アクセス権は不要）。

---

## 3-1. 共有接続を使って OneLake ショートカットを作成する

> 🗣️ **プロンプト**
> ```text
> 自分の Lakehouse（taxi_lakehouse）に、共有接続を使って
> ADLS Gen2 のショートカットを作って。
>
> - 接続名: adls-handson-sp-v3
> - 接続ID: e580afe8-376d-43b2-8e03-192d031e782e
> - ADLS Gen2 の URL: https://st0taxihandson0616.dfs.core.windows.net
> - コンテナとパス: /taxi-data
> - ショートカット名: taxi_zone
> - 配置場所: Files/taxi_zone
> ```

🤖 **Copilot の動き**
- Fabric REST API `POST /v1/workspaces/{wsId}/items/{lhId}/shortcuts` を実行
- 既存の共有接続 ID を `connectionId` に指定（接続は作成済みなので、受講者は接続を作る必要なし）

```json
{
  "path": "Files",
  "name": "taxi_zone",
  "target": {
    "adlsGen2": {
      "location": "https://st0taxihandson0616.dfs.core.windows.net",
      "subpath": "/taxi-data",
      "connectionId": "e580afe8-376d-43b2-8e03-192d031e782e"
    }
  }
}
```

✅ **期待する結果**

```json
{
  "path": "Files",
  "name": "taxi_zone",
  "target": {
    "type": "AdlsGen2",
    "adlsGen2": {
      "location": "https://st0taxihandson0616.dfs.core.windows.net",
      "subpath": "/taxi-data",
      "connectionId": "e580afe8-376d-43b2-8e03-192d031e782e"
    }
  }
}
```

> 📌 `subpath` はコンテナ名（`/taxi-data`）から始めます。

---

## 3-2. ショートカット一覧で確認する

> 🗣️ **プロンプト**
> ```text
> taxi_lakehouse のショートカット一覧を表示して。
> ```

✅ **期待する結果**

```text
- taxi_zone | Files | type: AdlsGen2
```

---

## 3-3. ショートカット経由でファイルを確認する

> 🗣️ **プロンプト**
> ```text
> Livy セッションを使って、自分の Lakehouse の
> Files/taxi_zone/Taxi_zone_lookup.csv を読み込んで、
> LocationID が1・2・3・4・5のレコードを条件指定で表示して。
> 各IDが1件ずつあることを確認し、LocationID の昇順で並べて。
> ```

🤖 **Copilot の動き** — PySpark で CSV を読み込み、DataFrame を表示

```python
from pyspark.sql import functions as F

df = spark.read.option("header", "true").csv("Files/taxi_zone/Taxi_zone_lookup.csv")
df.filter(F.col("LocationID").cast("int").isin(1, 2, 3, 4, 5)).orderBy(
    F.col("LocationID").cast("int")
).show(truncate=False)
```

✅ **期待する結果**

| LocationID | Borough | Zone | service_zone |
|------------|---------|------|--------------|
| 1 | EWR | Newark Airport | EWR |
| 2 | Queens | Jamaica Bay | Boro Zone |
| 3 | Bronx | Allerton/Pelham Gardens | Boro Zone |
| 4 | Manhattan | Alphabet City | Yellow Zone |
| 5 | Staten Island | Arden Heights | Boro Zone |

取得順ではなく **LocationID で 5 件を固定**するため、何度確認しても同じレコードになります。

---

## 3-4. ショートカットから Delta テーブルを作成する

ショートカット経由で CSV を読み込み、Lakehouse の管理テーブルとして登録します。

> 🗣️ **プロンプト**
> ```text
> taxi_zone_lookup というテーブル名で、
> taxi_zone のショートカットからテーブルを作って。
> ```

🤖 **Copilot の動き** — Livy セッションで PySpark を実行

```python
df = spark.read.csv("Files/taxi_zone/Taxi_zone_lookup.csv", header=True, inferSchema=True)
df.write.format("delta").mode("overwrite").saveAsTable("taxi_zone_lookup")
print("Done. Rows:", df.count())
df.printSchema()
```

✅ **期待する結果**

```text
Done. Rows: 265
root
 |-- LocationID: integer (nullable = true)
 |-- Borough: string (nullable = true)
 |-- Zone: string (nullable = true)
 |-- service_zone: string (nullable = true)
```

> 📌 Lakehouse の **Tables** セクションに `taxi_zone_lookup` が Delta テーブルとして登録されます。
> SQL Endpoint からも `SELECT * FROM taxi_zone_lookup` でクエリできるようになります。

---

## 3-5. テーブルをクエリして確認する

> 🗣️ **プロンプト**
> ```text
> taxi_zone_lookup の LocationID が1・2・3・4・5のレコードを WHERE 条件でクエリして。
> 各IDが1件ずつあること、CSVで確認した値と一致することを確認して。
> LocationID の昇順で並べて。全体の行数と LocationID の重複・null 件数も確認して。
> ```

🤖 **Copilot の動き**

```python
spark.sql("""
SELECT * FROM taxi_zone_lookup
WHERE LocationID IN (1, 2, 3, 4, 5)
ORDER BY LocationID
""").show(truncate=False)
```

✅ **期待する結果**

```
+----------+-------------+-----------------------+------------+
|LocationID|Borough      |Zone                   |service_zone|
+----------+-------------+-----------------------+------------+
|1         |EWR          |Newark Airport         |EWR         |
|2         |Queens       |Jamaica Bay            |Boro Zone   |
|3         |Bronx        |Allerton/Pelham Gardens|Boro Zone   |
|4         |Manhattan    |Alphabet City          |Yellow Zone |
|5         |Staten Island|Arden Heights          |Boro Zone   |
+----------+-------------+-----------------------+------------+
```

各 ID が 1 件ずつで、3-3 と同じ値になります。全体は **265 行**、LocationID の重複・null は **0 件**です。

---

## 3-6. 乗車データと地区テーブルを JOIN する

`green_tripdata_2026` の乗車・降車ロケーション ID（`PULocationID` / `DOLocationID`）と
`taxi_zone_lookup.LocationID` を JOIN して、ゾーン名・区名を付与できます。

```
green_tripdata_2026.PULocationID ─┐
                                   ├─ JOIN ─ taxi_zone_lookup.LocationID → Zone, Borough
green_tripdata_2026.DOLocationID ─┘
```

> 🗣️ **プロンプト**
> ```text
> green_tripdata_2026 と taxi_zone_lookup を JOIN して、
> Lab 02と同じ固定レコードに、乗車・降車のゾーン名と区名を付けて表示して。
> pickup_date=2026-04-01・pickup_hour=0かつ、
> VendorID=1・PULocationID=206・DOLocationID=89と、
> VendorID=2・PULocationID=243・DOLocationID=108を WHERE 条件で選んで。
> JOIN前後とも各条件が1件ずつであることを確認し、VendorID の昇順で並べて。
> 全件をJOINした件数も37,948から増減しないことを確認して。
> ```

🤖 **Copilot の動き**

```python
spark.sql("""
SELECT
  t.VendorID,
  t.lpep_pickup_datetime,
  t.trip_distance,
  t.total_amount,
  pu.Zone    AS pickup_zone,
  pu.Borough AS pickup_borough,
  do_.Zone   AS dropoff_zone,
  do_.Borough AS dropoff_borough
FROM green_tripdata_2026 t
JOIN taxi_zone_lookup pu  ON t.PULocationID = pu.LocationID
JOIN taxi_zone_lookup do_ ON t.DOLocationID = do_.LocationID
WHERE t.pickup_date = '2026-04-01'
  AND t.pickup_hour = 0
  AND (
    (t.VendorID = 1 AND t.PULocationID = 206 AND t.DOLocationID = 89)
    OR (t.VendorID = 2 AND t.PULocationID = 243 AND t.DOLocationID = 108)
  )
ORDER BY t.VendorID, t.PULocationID, t.DOLocationID
""").show(truncate=False)
```

✅ **期待する結果**

| VendorID | 乗車日時 | 距離 | 合計料金 | 乗車ゾーン | 乗車区 | 降車ゾーン | 降車区 |
|----------|----------|------|----------|------------|--------|------------|--------|
| 1 | 2026-04-01 00:01:51 | 5.94 | 19.38 | Saint George/New Brighton | Staten Island | Flatbush/Ditmas Park | Brooklyn |
| 2 | 2026-04-01 00:00:02 | 6.64 | 35.41 | Washington Heights North | Manhattan | Gravesend | Brooklyn |

地区名は [NYC TLC の地区マスター](https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv)に基づきます。
共有 CSV の内容が異なる場合は、不一致として報告して講師に確認します。
固定レコードだけでなく全件の JOIN 前後も確認し、未一致による行の欠落やキー重複による行の増加を検出します。

> 💡 **同じテーブルを2回 JOIN するポイント**
> `taxi_zone_lookup` を別名（`pu` / `do_`）で2回 JOIN することで、
> 乗車地と降車地のゾーン情報を同時に取得できます。

---

## 🔍 （参考）裏側で実行されるコマンド

以下は仕組みを示す参考です。ワークスペース・Lakehouse の ID は Copilot が API で特定して補うため、手入力は不要です。

```bash
# ショートカット作成（共有接続IDを使用）
# WS_ID / LH_ID は Copilot が登録済み設定と API の確認結果から設定済み
CONN_ID="e580afe8-376d-43b2-8e03-192d031e782e"   # 共有接続 adls-handson-sp-v3
TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)

curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://api.fabric.microsoft.com/v1/workspaces/$WS_ID/items/$LH_ID/shortcuts" \
  -d '{
    "path": "Files",
    "name": "taxi_zone",
    "target": {
      "adlsGen2": {
        "location": "https://st0taxihandson0616.dfs.core.windows.net",
        "subpath": "/taxi-data",
        "connectionId": "'"$CONN_ID"'"
      }
    }
  }'

# ショートカット一覧
az rest --method get \
  --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces/$WS_ID/items/$LH_ID/shortcuts"
```

---

## ✅ チェックポイント

- [ ] 共有接続（`adls-handson-sp-v3`）の情報を確認した（**Azure 権限は不要**）
- [ ] `taxi_zone` ショートカットを作成できた
- [ ] ショートカット経由で CSV が読み込めた
- [ ] `taxi_zone_lookup` Delta テーブルを作成できた（265行）
- [ ] `green_tripdata_2026` と `taxi_zone_lookup` を JOIN してゾーン名・区名を取得できた

---

## 🧹 トラブルシュート

| 症状 | 対処 |
|------|------|
| ショートカット作成で 401 | 「Fabric トークンを更新してもう一度試して」 |
| ショートカット作成で 403 `InsufficientPrivileges`（接続が storage に到達できない） | **講師対応**: 共有 ADLS `st0taxihandson0616` の `publicNetworkAccess` が **Enabled** か確認（`az storage account update -n st0taxihandson0616 -g rg-fabric-handson --public-network-access Enabled`）。SP には `Storage Blob Data Reader` 付与済み |
| ショートカット作成で `connectionId not found` / 接続が使えない | 共有接続 ID が正しいか確認。表示されない場合は**接続が自分に共有されているか講師に確認**（接続 → 共有 → User 権限） |
| CSV が読めない / ファイルが見えない | ショートカットの `subpath` がコンテナ名から始まっているか確認（`/taxi-data`） |
| `green_tripdata_2026` が無い | Lab 02 を先に完了しているか確認 |
| 自分の Lakehouse / ワークスペース ID が分からない | 「自分のワークスペースのアイテムと ID を一覧して」 |

> ℹ️ ストレージ作成・SP 作成・接続作成は**講師が実施済み**のため、受講者がそれらでエラーになることはありません。
> もし「ストレージを作って」等の Azure 操作を促された場合は、このラボでは不要です（共有接続を使ってください）。

---

次は **Lab 04 — Warehouse ディメンション＆ファクトテーブル作成**（[04-warehouse-dimensions.md](04-warehouse-dimensions.md)）に進みます。
