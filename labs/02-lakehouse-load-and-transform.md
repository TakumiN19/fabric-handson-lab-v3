# Lab 02 — Lakehouse の作成・データ取り込み・変換（プロンプト駆動）

所要時間: 約 20〜25 分
前提: [Lab 01](01-login-and-connect.md) 完了（登録済みのワークスペースに接続済み）

> 💡 **作業指示だけで実行できます。** アカウント・ワークスペース・接続先 ID は Copilot が自動で補います。
> 各プロンプトはそのまま貼り付けてください。設定が見つからない場合は [Lab 00 の 0-7](00-prerequisites.md#0-7-自分の-student-番号を一度だけ登録する)を確認します。

このラボでは、**Lakehouse 作成 → ファイルのアップロード → 読み込み → 加工 → Delta 保存**を
**加工用の一つのプロンプト**でまとめて実行します。列削除・null〔欠損値〕除去に加え、
日付・時間帯・乗車時間・距離あたりの料金・乗客区分を作り、分析しやすいデータへ整えます。
最後に、**別の確認用プロンプト**で処理前後の件数・品質・固定レコードを確認します。
「加工する」と「確認する」を分けることで、依頼する目的と結果を整理できます。

> 🤖 裏側では Fabric REST API（Lakehouse 作成）・OneLake DFS API（アップロード）・
> **Livy API**（Spark セッション）が使われます。

> 📦 取り込むサンプルデータは、Lab 00 で用意したこのハンズオンリポジトリの
> `data/green_tripdata_2026-04.parquet`（NYC グリーンタクシー風のサンプル・約 1.3 MB）です。

<img width="1156" height="643" alt="image" src="https://github.com/user-attachments/assets/055979f9-7909-4694-98b1-e03a4ebe8489" />


---

> 📖 **分からない用語があれば** [用語集（Glossary）](glossary.md) で確認できます（Lakehouse・Delta・Livy・セマンティックモデル など）。

## 📐 全体像: なぜデータを「加工」するのか

> Lab 02 から、いよいよ **データの加工** が始まります。まず全体像を押さえましょう。

### 生データはそのままでは使えない — だから「加工」する

実務のデータは、欠損・重複・型の不整合などで、**そのままでは“汚くて”分析に使えない**ことがほとんどです。
そこで、生データを段階的に「**きれいで使いやすい形**」へ整えていく設計パターンが
**メダリオンアーキテクチャ**（`Bronze` → `Silver` → `Gold` ＝ Raw → Enrich → Curate）です。

![メダリオンアーキテクチャ（データ分析の階層化概念）](images/medallion-architecture.png)

| 層 | 役割 |
|----|------|
| 🥉 **Bronze**（Raw） | 生データをそのまま受け入れる（重複・品質不足を許容／公開前の状態） |
| 🥈 **Silver**（Enrich） | クレンジング・重複排除・結合で「信頼できる形」に整える（Single Source of Truth＝信頼できる唯一の情報源） |
| 🥇 **Gold**（Curate） | 分析・レポート用に集計・加工した「調整済みデータ」 |

### このハンズオンの進み方

本ハンズオンは、厳密なメダリオンアーキテクチャ（Bronze/Silver/Gold の層分け）**そのものではありません**。
ですが同じ考え方で、**生データを綺麗にし、結合し、表示に必要な形へ加工**していきます。
具体的には、以下の図のステップ（Lab 02〜06）で進みます。

![ハンズオンの全体像（Lab 02〜06 のデータの流れ）](images/handson-overview.png)

| ラボ | 何をするか |
|------|-----------|
| **Lab 02 / 03**（取り込み・加工） | Parquet の取り込み・クレンジング・派生列追加をまとめて実行（Lab 03 はショートカットで CSV を参照） |
| **Lab 04**（変換） | GitHub Copilot でデータを加工し、Warehouse にディメンション／ファクトを作成 |
| **Lab 05**（モデル） | 表示に必要な形へ整え、セマンティックモデルを構築 |
| **Lab 06**（表示） | Power BI ダッシュボードで可視化（Consume） |

> 💡 つまり「**生データ → 綺麗に整える → 結合・加工 → 表示**」という流れを、すべて **プロンプト駆動** で体験します
> （データの加工・変換は GitHub Copilot が自動で行います）。

---

## 2-1. 取り込みから加工・保存までまとめて実行する

「作成」「アップロード」「読み込み」はまとめて依頼し、**このステップでは加工・保存まで**行います。
細かい列名・計算方法は下の「加工ルール」に載せているので、プロンプトにはやりたいことを自然な言葉で書きます。
Copilot は教材の共通指示に従ってこの Lab を読み、詳細を補います。

> 🗣️ **加工用プロンプト**
> ```text
> taxi_lakehouse を作って、data/green_tripdata_2026-04.parquet を取り込んで。
> ehail_fee を削除して、乗客数が入っていない行を除いて。
> 乗車日・時間帯・年月、乗車時間、1マイルあたりの料金、乗客区分を追加して、
> green_tripdata_2026 という Delta テーブルに保存して。
> 元のファイルと、それ以外の列・値は残しておいて。
> ```

### 加工ルール（Copilot が参照する詳細）

| 対象 | ルール |
|------|--------|
| 取り込み先 | `taxi_lakehouse` の `Files/raw/green_tripdata_2026-04.parquet` |
| 削除する列 | `ehail_fee` |
| 除外する行 | `passenger_count` が null の行だけ。重複排除や追加の行削除はしない |
| `pickup_date` | `lpep_pickup_datetime` から日付を取り出す |
| `pickup_hour` | `lpep_pickup_datetime` から 0〜23 の時間帯を取り出す |
| `pickup_month` | `lpep_pickup_datetime` を `yyyy-MM` にする |
| `trip_duration_minutes` | 降車日時 − 乗車日時を分に換算し、小数2桁に丸める。日時が欠損、または降車が乗車より前なら null |
| `fare_per_mile` | `fare_amount / trip_distance` を小数2桁に丸める。距離が null・0以下、または料金が null なら null |
| `passenger_group` | `passenger_count` が 1 なら `single`、2以上なら `group`、0以下なら `unknown` |
| 保存先 | `green_tripdata_2026`。元ファイルと、削除対象以外の元の列・値を保持する |
| 再実行 | 既存の `taxi_lakehouse` を再利用し、指定ファイルとテーブルだけ更新する。派生列を含むスキーマで再保存し、他のアイテムは削除しない |

🤖 **Copilot の動き**
1. 登録済みの接続先とローカルファイルを確認し、`taxi_lakehouse` を作成または再利用します。
2. Parquet を OneLake にアップロードし、パス・ファイルサイズを確認します。
3. 対象 Lakehouse の Livy セッションで読み込み・加工・Delta 保存を実行します。元ファイルは保持します。
4. 保存の完了と処理件数を報告し、作成したセッションを閉じます。結果の答え合わせは次のステップで行います。

> 💡 **まとめるのは指示です。** 実際の処理は依存順に実行されます。途中で失敗したら処理を止め、
> 完了した段階と失敗理由を表示します。API 操作の承認が複数回必要になる場合もあります。

✅ **期待する結果**

```text
Lakehouse: taxi_lakehouse
File: Files/raw/green_tripdata_2026-04.parquet
Source: 44,238 rows / 21 columns
Removed null passenger_count: 6,290 rows
Dropped column: ehail_fee
Added columns: pickup_date, pickup_hour, pickup_month,
               trip_duration_minutes, fare_per_mile, passenger_group
Saved: green_tripdata_2026 — 37,948 rows / 26 columns
次は確認用プロンプトで、保存した結果を検証します。
```

### 今回増やす加工

| 処理 | 分析での使い道 |
|------|----------------|
| 不要列の削除・乗客数が欠損した行の除外 | 必要な項目を残し、欠損の影響を把握する |
| `pickup_date` / `pickup_hour` / `pickup_month` | 日別・時間帯別・月別に集計する |
| `trip_duration_minutes` | 乗車時間の長さや異常な日時を確認する |
| `fare_per_mile` | 距離あたりの料金を比較する |
| `passenger_group` | 1人乗車とグループ乗車を比較する |

> 📌 **後続 Lab との互換性**: テーブル名と元の日時・料金・距離・ID列は維持します。
> 行数は従来どおり **37,948 行**です。Lab 04 は従来の列を選んで Warehouse に取り込み、
> Lab 06 は元の乗車日時からレポート用テーブルを作るので、そのまま進められます。
> 派生列の計算で不正な値を null にする場合も、追加で行を削除しません。

---

## 2-2. 加工結果をまとめて確認・集計する

保存できたことだけでなく、**加工した列が分析に使えること**を確認します。
ここではデータを変更せず、品質チェックと簡単な集計をまとめて指示します。
WHERE 条件や期待値をプロンプトにすべて書く必要はありません。Copilot がこの節の確認条件を参照します。

> 🗣️ **確認用プロンプト**
> ```text
> green_tripdata_2026 が正しく加工できたか確認して。
> 件数・列・欠損値と、追加した列の計算結果を教材の期待値と比べて教えて。
> 教材で指定した2件を条件で絞って、元の値と加工した値を並べて見せて。
> 時間帯別と乗客区分別にも集計して、件数の合計を確認して。
> 確認だけで、データは変更しないで。
> ```

🤖 **Copilot の動き**
- 保存済みテーブルを読み直し、全件の件数・列構成・欠損・範囲と、派生列が元の値から正しく計算されているかを検証します。
- 下記の固定条件で 2 件を取得し、条件ごとの該当件数と期待値を照合します。`LIMIT` / `TOP` は使いません。
- 時間帯別・乗客区分別に集計し、合計件数と代表値を確認します。
- SQL Endpoint で使える列は SQL、元の日時列など SQL 非対応の列は PySpark で確認します。
  不一致は期待値・実測値・差異を報告し、このステップでは再加工や更新をしません。

✅ **期待する結果**

| 確認項目 | 配布サンプルでの結果 |
|----------|----------------------|
| 行数 / 列数 | 37,948 / 26 |
| `ehail_fee` | 存在しない |
| `passenger_count` の null | 0 件 |
| 追加した派生列 | 6 列すべて存在する |
| `pickup_hour` の範囲外・null | 0 件 |
| `pickup_month` | 全行 `2026-04` |
| 時間帯別・乗客区分別の件数合計 | それぞれ 37,948 件 |

### 固定レコードで答え合わせする

配布サンプルで**それぞれ 1 件だけ該当する条件**を使います。取得順に依存する `LIMIT` / `TOP` は使いません。
以下は Copilot が SQL Endpoint で実行する確認クエリの例です。元の日時列ではなく、
追加した日付・時間帯と元の ID 列で絞るため、SQL Endpoint でも確認できます。

```sql
SELECT
    VendorID, PULocationID, DOLocationID, passenger_count,
    trip_distance, fare_amount, pickup_date, pickup_hour, pickup_month,
    trip_duration_minutes, fare_per_mile, passenger_group
FROM dbo.green_tripdata_2026
WHERE pickup_date = '2026-04-01'
  AND pickup_hour = 0
  AND (
      (VendorID = 1 AND PULocationID = 206 AND DOLocationID = 89)
      OR (VendorID = 2 AND PULocationID = 243 AND DOLocationID = 108)
  )
ORDER BY VendorID, PULocationID, DOLocationID;
```

**期待する結果は次の 2 行です。** 両方とも `pickup_date = 2026-04-01`、`pickup_hour = 0`、`pickup_month = 2026-04` です。
各条件の該当件数も 1 件ずつ確認します。2 行表示されただけでは、同じ条件から 2 件取得していないか判断できないためです。

| VendorID | 乗車地 ID | 降車地 ID | 乗客数 | 距離 | 料金 | 乗車時間（分） | 料金 / マイル | 乗客区分 |
|----------|-----------|-----------|--------|------|------|----------------|---------------|----------|
| 1 | 206 | 89 | 1 | 5.94 | 15.83 | 36.00 | 2.66 | single |
| 2 | 243 | 108 | 5 | 6.64 | 23.07 | 34.00 | 3.47 | group |

PySpark で元の日時も照合する場合、VendorID=1 の乗車・降車は
`2026-04-01 00:01:51` / `2026-04-01 00:37:51`、VendorID=2 は
`2026-04-01 00:00:02` / `2026-04-01 00:34:02` です。

**集計の答え合わせ**は、全件から計算した結果で行います。
乗客区分は `single = 6,257 件`、`group = 31,691 件`、`unknown = 0 件`です。
時間帯別の `pickup_hour = 0` は **1,615 件 / 平均料金 11.94**（小数2桁に丸める）となります。
固定レコードが一致しても、全体の件数・null・範囲・集計チェックは省略しません。

> ⏳ **同期ラグ**: SQL Endpoint には反映まで数十秒〜数分かかることがあります。
> テーブルが見つからない場合は、Copilot がメタデータ更新・待機後の再確認を行います。
> `timestamp_ntz` の元の日時列は SQL Endpoint に公開されない場合があるため、PySpark で確認します。
> 取得できない列を推測したり、検証できていない項目を成功扱いしたりしません。

---

## 🔍 （参考）Copilot が実行する PySpark の加工と確認

対象 Lakehouse を既定として設定した Spark セッション内で実行するコード例です。
スキーマ有効の Lakehouse では保存先を `dbo.green_tripdata_2026`、
従来形式では `green_tripdata_2026` とし、Copilot が実際の設定を確認して生成します。
アップロードと API 操作は Copilot が別途実行するので、このコードを手で入力する必要はありません。

### 加工用コード例

```python
from pyspark.sql import functions as F

raw = spark.read.parquet("Files/raw/green_tripdata_2026-04.parquet")
df = raw.drop("ehail_fee").filter(F.col("passenger_count").isNotNull())

df = (
    df.withColumn("pickup_date", F.to_date("lpep_pickup_datetime"))
    .withColumn("pickup_hour", F.hour("lpep_pickup_datetime"))
    .withColumn("pickup_month", F.date_format("lpep_pickup_datetime", "yyyy-MM"))
    .withColumn(
        "trip_duration_minutes",
        F.when(
            F.col("lpep_dropoff_datetime") >= F.col("lpep_pickup_datetime"),
            F.round(
                F.expr(
                    "timestampdiff(SECOND, lpep_pickup_datetime, "
                    "lpep_dropoff_datetime) / 60.0"
                ).cast("double"),
                2,
            ),
        ),
    )
    .withColumn(
        "fare_per_mile",
        F.when(
            (F.col("trip_distance") > 0) & F.col("fare_amount").isNotNull(),
            F.round(F.col("fare_amount") / F.col("trip_distance"), 2),
        ),
    )
    .withColumn(
        "passenger_group",
        F.when(F.col("passenger_count") == 1, F.lit("single"))
        .when(F.col("passenger_count") >= 2, F.lit("group"))
        .otherwise(F.lit("unknown")),
    )
)

table_name = "green_tripdata_2026"
source_rows = raw.count()
result_rows = df.count()
df.write.format("delta").mode("overwrite").option(
    "overwriteSchema", "true"
).saveAsTable(table_name)

print(f"Source: {source_rows} rows / {len(raw.columns)} columns")
print(f"Removed null passenger_count: {source_rows - result_rows} rows")
print(f"Saved: {table_name} — {result_rows} rows / {len(df.columns)} columns")
```

> 📌 この例の `table_name` は従来形式の Lakehouse 用です。Copilot は対象のスキーマ設定に合わせて保存先を決定します。
> `overwriteSchema` は、このラボで指定したテーブルに派生列を追加して再保存するための指定です。
> 他のテーブルや元ファイルは削除しません。

### 確認用コード例（読み取りのみ）

別のセッションでも確認できるよう、保存済みテーブルと元ファイルを読み直します。
以下は件数・列構成と固定レコードの照合例です。全件の加工ルール検証・欠損チェック・集計も、2-2 に従って実行します。

```python
from pyspark.sql import functions as F

table_name = "green_tripdata_2026"
raw = spark.read.parquet("Files/raw/green_tripdata_2026-04.parquet")
saved = spark.table(table_name)
source_rows = raw.count()
saved_rows = saved.count()
if source_rows != 44238 or len(raw.columns) != 21 or saved_rows != 37948 or len(saved.columns) != 26:
    raise ValueError(
        f"Unexpected sample shape: source={source_rows}, source_columns={len(raw.columns)}, "
        f"saved={saved_rows}, saved_columns={len(saved.columns)}"
    )

expected_types = dict(raw.dtypes)
del expected_types["ehail_fee"]
expected_types.update({
    "pickup_date": "date", "pickup_hour": "int", "pickup_month": "string",
    "trip_duration_minutes": "double", "fare_per_mile": "double", "passenger_group": "string",
})
if dict(saved.dtypes) != expected_types:
    raise ValueError(f"Unexpected saved column types: {saved.dtypes}")

fixed = saved.filter(
    (F.col("pickup_date") == F.lit("2026-04-01").cast("date"))
    & (F.col("pickup_hour") == 0)
    & (
        ((F.col("VendorID") == 1) & (F.col("PULocationID") == 206) & (F.col("DOLocationID") == 89))
        | ((F.col("VendorID") == 2) & (F.col("PULocationID") == 243) & (F.col("DOLocationID") == 108))
    )
)
matches = {
    (row.VendorID, row.PULocationID, row.DOLocationID): row["count"]
    for row in fixed.groupBy("VendorID", "PULocationID", "DOLocationID").count().collect()
}
if matches != {(1, 206, 89): 1, (2, 243, 108): 1}:
    raise ValueError(f"Unexpected fixed-record matches: {matches}")

fixed.orderBy("VendorID", "PULocationID", "DOLocationID").select(
    "VendorID", "PULocationID", "DOLocationID", "passenger_count",
    "trip_distance", "fare_amount", "pickup_date", "pickup_hour", "pickup_month",
    "trip_duration_minutes", "fare_per_mile", "passenger_group",
).show(truncate=False)
```

---

## ✅ チェックポイント

- [ ] 一つのプロンプトで Lakehouse 準備・アップロード・加工・保存まで完了した
- [ ] サンプル parquet を `Files/raw/` にアップロードできた
- [ ] `ehail_fee` の削除と乗客数の null 行除外が完了した
- [ ] 日付・時間帯・月・乗車時間・距離あたり料金・乗客区分の 6 列を追加できた
- [ ] テーブル一覧に `green_tripdata_2026` が表示された
- [ ] 保存後に再読込して 37,948 行・26 列、`passenger_count` の null が 0 件と確認できた
- [ ] WHERE 条件で固定した 2 レコードが各 1 件だけ取得でき、期待する加工結果と一致した
- [ ] 時間帯別・乗客区分別に集計し、件数合計がそれぞれ 37,948 件と確認できた

---

## 🧹 トラブルシュート

| 症状 | プロンプト例 / 対処 |
|------|---------------------|
| アップロードが失敗する | 「data/green_tripdata_2026-04.parquet のパスを確認して、taxi_lakehouse の Files/raw にもう一度アップロードして」 |
| ファイルが見つからない | 「taxi_lakehouse の Files を再帰的に一覧して」でパスを再確認 |
| Livy セッション作成が失敗する | 「もう一度 Livy セッションを作り直して」 |
| セッションが `starting` のまま | 少し待ってから「セッションの状態を確認して」→ idle になってから再実行 |
| `ehail_fee` 列が存在しないエラー | 列名のスペルをファイルの実際の列名に合わせる（「カラム一覧を見せて」で確認） |
| 再保存でスキーマが一致しない | 「green_tripdata_2026 だけを、追加した派生列を含むスキーマで再保存して」 |
| 件数が配布サンプルと異なる | 「元ファイル・除外条件・処理前後の件数を確認して。追加の行削除や重複排除をしていないか調べて」 |
| 乗車時間や距離あたり料金が null | 「元の日時・距離・料金を確認して、null にした理由と件数を表示して」。0 埋めや追加の行削除はしない |
| テーブルが一覧に出ない | 「taxi_lakehouse の SQL Endpoint のメタデータを更新して」で同期 |

---

次は **Lab 03 — ADLS Gen2 + OneLake ショートカット**（[03-adls-shortcut.md](03-adls-shortcut.md)）に進みます。
