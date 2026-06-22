# Lab 04 — Warehouse ディメンションテーブル＆ファクトテーブル作成（プロンプト駆動）

所要時間: 約 25 分  
前提: [Lab 03](03-adls-shortcut.md) 完了（`taxi_zone_lookup` テーブルが Lakehouse に存在すること）

このラボでは Fabric Data Warehouse を作成し、ディメンションテーブルとファクトテーブルを構築します。

```
Warehouse 作成  →  ディメンションテーブル 5 本作成  →  ファクトテーブル作成
```

> 🤖 **このラボはすべてプロンプト（Copilot）で完結します**

---

## 4-1. Fabric Warehouse を作成する

> 🗣️ **プロンプト**
> ```text
> student<番号> ワークスペースに taxi_warehouse という名前の
> Fabric Warehouse を作って。
> ```

🤖 **Copilot の動き**
- Fabric REST API `POST /v1/workspaces/{wsId}/warehouses` を実行
- 作成完了まで待機（約15秒）
- 接続文字列（FQDN）を取得

✅ **期待する結果**

```text
Warehouse ID:  c5a3812f-0390-4213-bddf-cb3063ea3a6f
Server:        xxxxxx.datawarehouse.fabric.microsoft.com
接続テスト:    Connected
```

---

## 4-2. ディメンションテーブルを作成してデータをロードする

> 🗣️ **プロンプト**
> ```text
> taxi_warehouse Warehouse に以下のディメンションテーブルを作って、データをロードして。
>
> - dimension_VendorID: VendorID(int), Description(varchar100)
>   1:'Creative Mobile Technologies, LLC', 2:'VeriFone Inc.'
>
> - dimension_TripType: Trip_type(int), Description(varchar100)
>   1:'Street-hail', 2:'Dispatch'
>
> - dimension_RatecodeID: RatecodeID(int), Description(varchar100)
>   1:'Standard rate', 2:'JFK', 3:'Newark', 4:'Nassau or Westchester',
>   5:'Negotiated fare', 6:'Group ride'
>
> - dimension_PaymentType: Payment_type(int), Description(varchar100)
>   1:'Credit card', 2:'Cash', 3:'No charge', 4:'Dispute',
>   5:'Unknown', 6:'Voided trip'
>
> - dimension_taxiZoneLookup: Lakehouse の taxi_zone_lookup からロード
> ```

🤖 **Copilot の動き** — `sqlcmd` で T-SQL を実行

```sql
-- dimension_VendorID
DROP TABLE IF EXISTS [dbo].[dimension_VendorID];
CREATE TABLE [dbo].[dimension_VendorID] (
    VendorID    [int] NULL,
    Description [VARCHAR](100) NULL
);
INSERT INTO dimension_VendorID (VendorID, Description) VALUES
    (1, 'Creative Mobile Technologies, LLC'),
    (2, 'VeriFone Inc.');

-- dimension_TripType
DROP TABLE IF EXISTS [dbo].[dimension_TripType];
CREATE TABLE [dbo].[dimension_TripType] (
    Trip_type   [int] NULL,
    Description [VARCHAR](100) NULL
);
INSERT INTO dimension_TripType (Trip_type, Description) VALUES
    (1, 'Street-hail'),
    (2, 'Dispatch');

-- dimension_RatecodeID
DROP TABLE IF EXISTS [dbo].[dimension_RatecodeID];
CREATE TABLE [dbo].[dimension_RatecodeID] (
    RatecodeID  [int] NULL,
    Description [VARCHAR](100) NULL
);
INSERT INTO dimension_RatecodeID (RatecodeID, Description) VALUES
    (1, 'Standard rate'), (2, 'JFK'), (3, 'Newark'),
    (4, 'Nassau or Westchester'), (5, 'Negotiated fare'), (6, 'Group ride');

-- dimension_PaymentType
DROP TABLE IF EXISTS [dbo].[dimension_PaymentType];
CREATE TABLE [dbo].[dimension_PaymentType] (
    Payment_type [int] NULL,
    Description  [VARCHAR](100) NULL
);
INSERT INTO dimension_PaymentType (Payment_type, Description) VALUES
    (1, 'Credit card'), (2, 'Cash'), (3, 'No charge'),
    (4, 'Dispute'), (5, 'Unknown'), (6, 'Voided trip');

-- dimension_taxiZoneLookup（Lakehouse からクロス DB クエリでロード）
DROP TABLE IF EXISTS [dbo].[dimension_taxiZoneLookup];
CREATE TABLE [dbo].[dimension_taxiZoneLookup] (
    LocationID   [int] NULL,
    Borough      [VARCHAR](50) NULL,
    Zone         [VARCHAR](50) NULL,
    service_zone [VARCHAR](50) NULL
);
INSERT INTO [dbo].[dimension_taxiZoneLookup]
SELECT * FROM [taxi_lakehouse].[dbo].[taxi_zone_lookup];
```

✅ **期待する結果**

```text
テーブル                  行数
------------------------  ----
dimension_VendorID           2
dimension_TripType           2
dimension_RatecodeID         6
dimension_PaymentType        6
dimension_taxiZoneLookup   265
```

> 💡 **ポイント**: `[taxi_lakehouse].[dbo].[taxi_zone_lookup]` のように
> **3パート名（アイテム名.dbo.テーブル名）** で同一ワークスペース内の Lakehouse を参照できます。

---

## 4-3. ファクトテーブルを作成する

`green_tripdata_2026`（Lakehouse）から以下の変換を適用して `fact_greentrip_copilot` テーブルを作成します。

**変換内容:**

| 変換 | 対象列 |
|------|--------|
| 削除 | `store_and_fwd_flag`, `extra`, `mta_tax`, `improvement_surcharge`, `congestion_surcharge` |
| null → 0 に置換 | `trip_type` |
| 整数型（INT）にキャスト | `VendorID`, `RatecodeID`, `PULocationID`, `DOLocationID`, `payment_type`, `trip_type` |

> 🗣️ **プロンプト**
> ```text
> fact_greentrip_copilot というテーブルを Warehouse に作って。
> taxi_lakehouse の green_tripdata_2026 テーブルを使って、
> 以下の処理をしてから書き込んで：
> - store_and_fwd_flag, extra, mta_tax, improvement_surcharge, congestion_surcharge を削除
> - trip_type の null を 0 に置換
> - VendorID, PULocationID, RatecodeID, payment_type, trip_type を整数型にキャスト
> ```

🤖 **Copilot の動き** — CTAS（CREATE TABLE AS SELECT）で一括変換・書き込み

```sql
DROP TABLE IF EXISTS [dbo].[fact_greentrip_copilot];

CREATE TABLE [dbo].[fact_greentrip_copilot]
AS
SELECT
    CAST(VendorID     AS INT)             AS VendorID,
    CAST(RatecodeID   AS INT)             AS RatecodeID,
    CAST(PULocationID AS INT)             AS PULocationID,
    CAST(DOLocationID AS INT)             AS DOLocationID,
    passenger_count,
    trip_distance,
    fare_amount,
    tip_amount,
    tolls_amount,
    total_amount,
    CAST(payment_type AS INT)             AS payment_type,
    CAST(COALESCE(trip_type, 0) AS INT)   AS trip_type,
    cbd_congestion_fee
FROM [taxi_lakehouse].[dbo].[green_tripdata_2026];
```

✅ **期待する結果**

```text
row_count
---------
37948
```

スキーマ確認:

```text
column_name        data_type
-----------------  ---------
VendorID           int          ← キャスト済み
RatecodeID         int          ← bigint から変換
PULocationID       int          ← キャスト済み
DOLocationID       int          ← キャスト済み
passenger_count    bigint
trip_distance      float
fare_amount        float
tip_amount         float
tolls_amount       float
total_amount       float
payment_type       int          ← bigint から変換
trip_type          int          ← null→0、bigint から変換
cbd_congestion_fee float
```

> ⚠️ **補足**: `lpep_pickup_datetime` / `lpep_dropoff_datetime` は Lakehouse の `timestamp_ntz` 型が
> Lakehouse SQL Endpoint 経由では公開されないため、Warehouse テーブルには含まれません。
> datetime 列が必要な場合は、Livy + PySpark で Parquet に変換してから COPY INTO するか、
> Dataflow Gen2 を使用してください。

---

## 4-4. テーブル一覧を確認する

> 🗣️ **プロンプト**
> ```text
> taxi_warehouse のテーブル一覧と行数を表示して。
> ```

🤖 **Copilot の動き**

```sql
SELECT 'dimension_VendorID'     AS tbl, COUNT(*) AS rows FROM dimension_VendorID    UNION ALL
SELECT 'dimension_TripType',           COUNT(*) FROM dimension_TripType             UNION ALL
SELECT 'dimension_RatecodeID',         COUNT(*) FROM dimension_RatecodeID           UNION ALL
SELECT 'dimension_PaymentType',        COUNT(*) FROM dimension_PaymentType          UNION ALL
SELECT 'dimension_taxiZoneLookup',     COUNT(*) FROM dimension_taxiZoneLookup       UNION ALL
SELECT 'fact_greentrip_copilot',       COUNT(*) FROM fact_greentrip_copilot;
```

✅ **期待する結果**

```text
tbl                       rows
------------------------  ------
dimension_VendorID             2
dimension_TripType             2
dimension_RatecodeID           6
dimension_PaymentType          6
dimension_taxiZoneLookup     265
fact_greentrip_copilot     37948
```

---

## 🔍 （参考）裏側で実行されるコマンド

```bash
WS_ID="<自分のワークスペース ID>"
TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)

# Warehouse 作成
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://api.fabric.microsoft.com/v1/workspaces/$WS_ID/warehouses" \
  -d '{"displayName":"taxi_warehouse"}'

# 接続文字列取得
DW_SERVER=$(az rest --method get \
  --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces/$WS_ID/warehouses/<DW_ID>" \
  --query "properties.connectionString" -o tsv)

# SQL 実行
sqlcmd -S "$DW_SERVER" -d "taxi_warehouse" -G -i create_dimensions.sql -W
```

---

## ✅ チェックポイント

- [ ] `taxi_warehouse` Warehouse を作成できた
- [ ] `sqlcmd` で Warehouse に接続できた
- [ ] ディメンションテーブル 5 本を作成できた
  - [ ] `dimension_VendorID`（2行）
  - [ ] `dimension_TripType`（2行）
  - [ ] `dimension_RatecodeID`（6行）
  - [ ] `dimension_PaymentType`（6行）
  - [ ] `dimension_taxiZoneLookup`（265行・Lakehouse からロード）
- [ ] `fact_greentrip_copilot`（37,948行）を CTAS で作成できた
- [ ] 変換（列削除・null 置換・型キャスト）が正しく適用されていることを確認できた

---

## 🧹 トラブルシュート

| 症状 | 対処 |
|------|------|
| Warehouse 作成で `EntityNotFound` | `az account set` で正しいサブスクリプションに切り替え後、再度ログイン |
| `sqlcmd: command not found` | `brew install sqlcmd`（Mac）または `winget install sqlcmd`（Windows） |
| `Invalid column name 'lpep_pickup_datetime'` | `timestamp_ntz` 型は SQL Endpoint 非対応。その列を除外するか Livy 経由で変換する |
| Lakehouse クロス DB クエリが失敗 | Lakehouse 名が正確か確認。同一ワークスペース内のみ参照可 |
| `Login failed` | `az login --tenant <tenantId>` で再認証後、`sqlcmd -G` で試す |
| CTAS が遅い | Warehouse は初回実行時に分散実行環境を起動するため、2〜3分かかることがある |

---

次は **Lab 05 — セマンティックモデル作成**（準備中）に進みます。
