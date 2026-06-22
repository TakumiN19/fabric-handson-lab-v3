# Lab 03 — ADLS Gen2 + OneLake ショートカット（プロンプト駆動）

所要時間: 約 15 分
前提: [Lab 02](02-lakehouse-load-and-transform.md) 完了（自分の `studentX` ワークスペース／Lakehouse に接続済み）

このラボでは、**講師が用意した共有の ADLS Gen2** に対して、各受講者が **OneLake ショートカット**を
張り、Fabric から直接データを参照します。

```
（講師が事前準備済み）              （受講者が実施）
ADLS Gen2 + CSV + 共有接続  ──→   共有接続でショートカット作成  →  Lakehouse から参照・テーブル化
```

> ✅ **このラボに Azure の権限（サブスクリプションの RBAC）は不要です。**
> ADLS Gen2 ストレージ・Service Principal・Fabric 接続（Connection）は **講師が 1 か所にまとめて作成・共有済み**です。
> 受講者は **Fabric 側でショートカットを作るだけ**。`az storage account create` などの Azure 操作は行いません。
>
> （講師がどう準備したかは末尾の [📦 付録: 講師による事前準備](#-付録-講師による事前準備実施済み) を参照）

---

## ショートカットとは？

OneLake ショートカットは、**データをコピーせず**に別のストレージ（Azure・AWS・GCS 等）を
Lakehouse に仮想マウントする機能です。

```
Lakehouse
└── Files/
    └── taxi_zone/ ─── (Shortcut) ──→ 共有 ADLS Gen2 のコンテナ/パス
```

データは元の場所（講師の共有 ADLS）に残ったまま、各受講者の Fabric から直接読み取れます。

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
> Files/taxi_zone/Taxi_zone_lookup.csv を読み込んで、先頭 5 行を表示して。
> ```

🤖 **Copilot の動き** — PySpark で CSV を読み込み、DataFrame を表示

```python
df = spark.read.option("header", "true").csv("Files/taxi_zone/Taxi_zone_lookup.csv")
df.show(5)
```

✅ **期待する結果**

```
+----------+-------+--------------------+------------+
|LocationID|Borough|                Zone|service_zone|
+----------+-------+--------------------+------------+
|         1|    EWR|Newark Airport  ...|         EWR|
|         2| Queens|Jamaica Bay         |  Boro Zone |
...
```

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
> taxi_zone_lookup テーブルを10行クエリして。
> ```

🤖 **Copilot の動き**

```python
spark.sql("SELECT * FROM taxi_zone_lookup LIMIT 10").show(truncate=False)
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
...
```

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
> 乗車・降車のゾーン名と区名を含めた結果を10行表示して。
> ```

🤖 **Copilot の動き**

```python
spark.sql("""
SELECT
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
LIMIT 10
""").show(truncate=False)
```

✅ **期待する結果**

```
+--------------------+-------------+------------+------------------------+--------------+---------------------------------+---------------+
|lpep_pickup_datetime|trip_distance|total_amount|pickup_zone             |pickup_borough|dropoff_zone                     |dropoff_borough|
+--------------------+-------------+------------+------------------------+--------------+---------------------------------+---------------+
|2026-04-01 00:29:09 |6.56         |48.1        |DUMBO/Vinegar Hill      |Brooklyn      |Clinton East                     |Manhattan      |
|2026-04-01 00:19:13 |0.0          |27.0        |Jackson Heights         |Queens        |Jackson Heights                  |Queens         |
...
```

> 💡 **同じテーブルを2回 JOIN するポイント**
> `taxi_zone_lookup` を別名（`pu` / `do_`）で2回 JOIN することで、
> 乗車地と降車地のゾーン情報を同時に取得できます。

---

## 3-7. （クリーンアップ）ショートカットを削除する

不要になったショートカットを削除できます（**ショートカットを消しても元の共有 ADLS のデータは残ります**）。

> 🗣️ **プロンプト**
> ```text
> taxi_lakehouse にある taxi_zone ショートカットを削除して。
> ```

---

## 🔍 （参考）裏側で実行されるコマンド

```bash
# ショートカット作成（共有接続IDを使用）
WS_ID="<自分のワークスペースID>"
LH_ID="<自分のLakehouseID>"
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

# ショートカット削除
az rest --method delete \
  --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces/$WS_ID/items/$LH_ID/shortcuts/Files/taxi_zone"
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
| 自分の Lakehouse / ワークスペース ID が分からない | 「自分の studentX ワークスペースのアイテムと ID を一覧して」 |

> ℹ️ ストレージ作成・SP 作成・接続作成は**講師が実施済み**のため、受講者がそれらでエラーになることはありません。
> もし「ストレージを作って」等の Azure 操作を促された場合は、このラボでは不要です（共有接続を使ってください）。

---

## 📦 付録: 講師による事前準備（実施済み）

> 受講者は実施不要です。**講師が 1 回だけ**以下を作成し、接続を全受講者に共有しています。
> 受講者に Azure サブスクリプションの RBAC を配らずに済むため、権限管理がシンプルになります。

### A. ADLS Gen2 ストレージアカウント作成（HNS 有効）

```bash
az storage account create \
  --name st0taxihandson0616 --resource-group rg-fabric-handson \
  --location japaneast --sku Standard_LRS --kind StorageV2 \
  --enable-hierarchical-namespace true
```

### B. コンテナ作成と CSV アップロード

> サブスクリプションのポリシーで `allowSharedKeyAccess=false`（キー認証禁止）のため、
> **`--auth-mode login`（Entra 認証）**でアップロードします。事前に自分へ
> `Storage Blob Data Contributor` ロールを付与しておきます。

```bash
az storage fs create --name taxi-data \
  --account-name st0taxihandson0616 --auth-mode login

az storage fs file upload \
  --account-name st0taxihandson0616 --auth-mode login \
  --file-system taxi-data --source ~/Downloads/Taxi_zone_lookup.csv \
  --path Taxi_zone_lookup.csv
```

### C. Service Principal 作成 + ADLS 読み取り権限付与

```bash
az ad sp create-for-rbac --name sp-fabric-adls-handson \
  --role "Storage Blob Data Reader" \
  --scopes "/subscriptions/<SUB>/resourceGroups/rg-fabric-handson/providers/Microsoft.Storage/storageAccounts/st0taxihandson0616"
# 出力の appId / password / tenant を控える
```

### D. Fabric 接続（Connection）を作成

```json
POST /v1/connections
{
  "connectivityType": "ShareableCloud",
  "displayName": "adls-handson-sp-v3",
  "connectionDetails": {
    "type": "AzureDataLakeStorage",
    "creationMethod": "AzureDataLakeStorage",
    "parameters": [
      { "dataType": "Text", "name": "server", "value": "https://st0taxihandson0616.dfs.core.windows.net" },
      { "dataType": "Text", "name": "path",   "value": "taxi-data" }
    ]
  },
  "credentialDetails": {
    "singleSignOnType": "None",
    "connectionEncryption": "NotEncrypted",
    "credentials": {
      "credentialType": "ServicePrincipal",
      "servicePrincipalClientId": "<AppId>",
      "servicePrincipalSecret": "<Secret>",
      "tenantId": "<TenantId>"
    }
  }
}
```

> 💡 **ポイント**: `creationMethod` は `connectionDetails` の**中**に入れます（外側は `InvalidParameter`）。
> `connectivityType: ShareableCloud` にすることで、後から他ユーザーへ共有できます。

### E. 接続を全受講者へ共有（User 権限）

```bash
# 各 studentX の AAD オブジェクトID に対して User ロールを付与
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://api.fabric.microsoft.com/v1/connections/e580afe8-376d-43b2-8e03-192d031e782e/roleAssignments" \
  -d '{"principal":{"id":"<studentXのoid>","type":"User"},"role":"User"}'
```

> これにより、各受講者は **ADLS への直接アクセス権なしで**、共有接続を使って
> ショートカットを作成できます（接続が SP の資格情報を保持しているため）。

---

次は **Lab 04 — Warehouse ディメンション＆ファクトテーブル作成**（[04-warehouse-dimensions.md](04-warehouse-dimensions.md)）に進みます。
