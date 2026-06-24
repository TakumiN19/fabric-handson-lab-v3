# 用語集（Glossary）— Fabric ハンズオン

このハンズオンの Lab 02〜10 に登場する **Fabric / データ基盤の専門用語** を、
**短い定義** ＋ **本ハンズオンでの使われ方** ＋ **公式ドキュメント** でまとめた早見表です。
分からない用語が出てきたら、ここで確認してください。

> 💡 各ラボは「プロンプト駆動」なので、用語の意味を完全に理解していなくても進められます。
> ここは「もっと知りたい」「言葉の意味を確認したい」ときの参照用です。

**カテゴリ**

1. Fabric の構成要素（アイテム）
2. ストレージとファイル形式
3. 処理基盤と API
4. データモデリングの概念
5. データ連携・移行
6. 認証・ライセンス
7. ツール・フレームワーク

---

## 1. Fabric の構成要素（アイテム）

Fabric の「ワークスペース」の中に作る部品（アイテム）です。

### ワークスペース（Workspace）
Fabric でアイテム（Lakehouse・Warehouse・レポートなど）をまとめて置く**作業領域**。受講者ごとに `student<番号>` が割り当てられます。
- **本ハンズオン**: Lab 01 で自分の `student<番号>` ワークスペースに接続し、以降すべての成果物をこの中に作ります。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/fundamentals/workspaces)

### Lakehouse（レイクハウス）
**ファイル（Files）とテーブル（Tables）を1か所で扱える**データ保管場所。生ファイルも、SQL で問い合わせできるテーブルも同居できます（データレイク＋データウェアハウスの“いいとこ取り”）。
- **本ハンズオン**: Lab 02 で `taxi_lakehouse` を作成し、Parquet を取り込んで Delta テーブル化します。Lab 03 ではショートカットで外部データも参照。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-engineering/lakehouse-overview)

### Warehouse（ウェアハウス）
**T-SQL で扱う本格的なデータウェアハウス**。集計・結合・ディメンション/ファクト設計などに向きます。
- **本ハンズオン**: Lab 04 で `taxi_warehouse` を作り、ディメンション5本とファクトテーブルを構築します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-warehouse/data-warehousing)

### SQL Endpoint（SQL 分析エンドポイント）
Lakehouse のテーブルを **読み取り専用の T-SQL で問い合わせる**ための接続口。Lakehouse を作ると自動で付いてきます。
- **本ハンズオン**: Lab 02 の 2-6 で行数や null 件数を SQL で確認するときに使います。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-engineering/lakehouse-sql-analytics-endpoint)

### SQL Database（Fabric SQL Database）
Fabric 上で動く**書き込み可能なマネージド SQL データベース**。アプリのデータ保存先になります。
- **本ハンズオン**: Lab 08・10 の Fabric App（Rayfin）が、入力フォームや注釈の保存先として使います（OneLake に自動ミラー）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/database/sql/overview)

### セマンティックモデル（Semantic Model）
テーブル間の**リレーションシップ**や**メジャー（集計式）**を定義した、レポートの土台となる**データモデル**（旧称: データセット）。
- **本ハンズオン**: Lab 05 で `sm_taxi_warehouse` を構築し、Lab 06 のレポートや Lab 07 の Data Agent がこれを参照します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/power-bi/connect-data/service-datasets-understand)

### Power BI レポート（Report）
セマンティックモデルのデータを**グラフや表で可視化**した成果物。
- **本ハンズオン**: Lab 06 で多角分析レポートを作成・公開します（Lab 09 でデザインを作り直し）。
- 📖 [Microsoft Learn（PBIR 形式）](https://learn.microsoft.com/power-bi/developer/projects/projects-report)

### Data Agent（データエージェント）
セマンティックモデル等のデータに**自然言語で質問できる会話型 AI**（Fabric の Copilot/AI 機能）。
- **本ハンズオン**: Lab 07 で `taxi_ride_agent` を作成し、Lab 08 のアプリにチャットとして組み込みます。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-science/concept-data-agent)

### Fabric App / AppBackend
**Fabric 上にホストする Web アプリ**（preview）。`*.webapp.fabricapps.net` で公開され、作成すると AppBackend というアイテムになります。
- **本ハンズオン**: Lab 08・10 で Rayfin CLI を使って作成・デプロイします。
- 📖 [Rayfin（アプリビルダー）](https://github.com/microsoft/rayfin)

### MirroredWarehouse（ミラー）
Fabric SQL Database の中身が **OneLake に自動でコピー（ミラー）**され、SQL 分析エンドポイントとして参照できる仕組み。
- **本ハンズオン**: Lab 08 で入力フォームのデータが手動 ETL なしで分析側に流れることを確認します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/database/mirrored-database/overview)

### ショートカット（Shortcut）
データを**コピーせずに**、別の場所（ADLS Gen2 など）のデータを Lakehouse から**参照**する仕組み（リンクのようなもの）。
- **本ハンズオン**: Lab 03 で ADLS Gen2 上の CSV を Lakehouse にショートカットとして取り込みます。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/onelake/onelake-shortcuts)

---

## 2. ストレージとファイル形式

### OneLake
Fabric 全体で共有される**唯一のデータレイク**（“データの OneDrive”）。すべてのワークスペース・アイテムのデータがここに格納されます。
- **本ハンズオン**: Lakehouse の Files/Tables も、アプリ DB のミラーも、実体は OneLake 上にあります。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/onelake/onelake-overview)

### Files / Tables（Lakehouse の2領域）
Lakehouse は2つの領域を持ちます。**Files** は生ファイル置き場（Parquet・CSV など）、**Tables** は SQL で問い合わせできる Delta テーブル置き場。
- **本ハンズオン**: Lab 02 で Parquet を `Files/raw/` に置き、変換して `Tables` に Delta テーブルとして保存します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-engineering/lakehouse-overview)

### Parquet（パーケット）
**列指向の圧縮ファイル形式**。CSV より小さく・速く、分析用データの受け渡しに広く使われます。
- **本ハンズオン**: 取り込むサンプル `green_tripdata_2026-04.parquet`（約 1.3MB）がこの形式です。
- 📖 [Apache Parquet](https://parquet.apache.org/)

### Delta（Delta Lake / Delta テーブル）
Parquet に**トランザクションログ**を足した、**更新・追記・履歴（タイムトラベル）に強いオープンなテーブル形式**。Fabric のテーブルの標準形式です。
- **本ハンズオン**: Lab 02 で変換後のデータを Delta テーブルとして保存します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-engineering/lakehouse-and-delta-tables)

### ADLS Gen2（Azure Data Lake Storage Gen2）
Azure の**大容量データ向けストレージ**。階層フォルダーと大規模分析に対応します。
- **本ハンズオン**: Lab 03 で CSV を置き、Fabric からショートカットで参照します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction)

### timestamp_ntz（タイムゾーンなしの日時型）
Spark / Delta の**タイムゾーン情報を持たない日時型**（timestamp without time zone）。
- **本ハンズオン**: Lab 04 で、Lakehouse の `timestamp_ntz` 列は Warehouse の SQL Endpoint 経由では公開されないため、Warehouse のファクトには日時列を含めません（日時が必要な Lab 06 では Livy/PySpark で別途用意）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/azure/databricks/sql/language-manual/data-types/timestamp-ntz-type)

---

## 3. 処理基盤と API

### Spark / PySpark
**Spark** は大規模データを分散処理するエンジン。**PySpark** はその Python 版 API です。
- **本ハンズオン**: Lab 02 でデータの読み込み・列削除・null 除去・Delta 保存を PySpark で実行します（Copilot がコード生成）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-engineering/spark-compute)

### Livy API
Fabric の Lakehouse に対して **Spark セッションを作り、コードを送って実行する** REST API。
- **本ハンズオン**: Lab 02 の変換処理は、裏側で Livy セッションを作って PySpark を実行しています。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-engineering/get-started-api-livy)

### Fabric REST API
Fabric のアイテム（Lakehouse/Warehouse 等）を**作成・操作するための REST API**。
- **本ハンズオン**: Lakehouse 作成やアイテム一覧などで使われます（Copilot が自動で呼び出し）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/rest/api/fabric/articles/using-fabric-apis)

### OneLake DFS API
OneLake のファイルを**アップロード・一覧・ダウンロード**するための API（ADLS Gen2 互換の DFS エンドポイント）。
- **本ハンズオン**: Lab 02 で Parquet を「作成→追記→フラッシュ」の3手順でアップロードするのに使います。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/onelake/onelake-overview)

### アクセストークン（Token）
API を呼ぶときに本人確認として渡す**一時的な認証キー**。`az account get-access-token` で取得します。
- **本ハンズオン**: Fabric 用・ストレージ用など、用途ごとにトークンを取得して API を呼びます。
- 📖 [Microsoft Entra ID](https://learn.microsoft.com/entra/fundamentals/whatis)

### DAB（Data API Builder）
データベースのテーブルから **REST / GraphQL API を自動生成**するツール。
- **本ハンズオン**: Lab 08・10 の Rayfin アプリが、エンティティ定義から DAB 経由でデータ API を生成します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/azure/data-api-builder/overview)

### GraphQL
**必要なデータだけを問い合わせできる** API のクエリ言語。
- **本ハンズオン**: Rayfin（DAB）が生成するデータ API の一形態として登場します。
- 📖 [GraphQL 公式](https://graphql.org/)

### executeQueries（DAX クエリ API）
セマンティックモデルに対して **DAX クエリを実行して結果を取得する** Power BI REST API。
- **本ハンズオン**: Lab 10 でセマンティックモデルから集計値を取り出し、アプリ DB にスナップショットするのに使います。
- 📖 [Microsoft Learn](https://learn.microsoft.com/rest/api/power-bi/datasets/execute-queries)

### T-SQL（Transact-SQL）
Microsoft の SQL 方言（Transact-SQL）。標準 SQL に変数・制御構文などの拡張を加えたもの。
- **本ハンズオン**: Lab 04・05 で Warehouse のテーブル作成・データ投入・クエリに使います。
- 📖 [Microsoft Learn](https://learn.microsoft.com/sql/t-sql/language-reference)

### クロス DB クエリ / 3 パート名
`アイテム名.スキーマ.テーブル名`（例 `taxi_lakehouse.dbo.taxi_zone_lookup`）の **3 パート名**で、**同一ワークスペース内の別アイテム（Lakehouse など）を横断参照**する Fabric の機能。
- **本ハンズオン**: Lab 04 で Warehouse から Lakehouse の `taxi_zone_lookup` を参照してディメンションをロードします。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-warehouse/query-warehouse)

### FQDN / 接続文字列
**FQDN**（Fully Qualified Domain Name）はサーバーの完全なアドレス（例 `xxx.datawarehouse.fabric.microsoft.com`）。**接続文字列**は接続先（サーバー・DB 等）をまとめた文字列。
- **本ハンズオン**: Warehouse / SQL Endpoint へ `sqlcmd` で接続する際のサーバー指定に使います（Lab 04〜06・10）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-warehouse/connectivity)

---

## 4. データモデリングの概念

### メダリオンアーキテクチャ（Bronze / Silver / Gold）
生データを段階的にきれいにする設計パターン。**Bronze**（生のまま）→ **Silver**（クレンジング・結合で信頼できる形）→ **Gold**（分析・レポート用に集計）。
- **本ハンズオン**: 厳密な層分けはしませんが、「生データ→綺麗に→加工→表示」という同じ考え方で Lab 02〜06 を進めます。
- 📖 [Microsoft Learn](https://learn.microsoft.com/azure/databricks/lakehouse/medallion)

### データ変換（クレンジング）
生データを使える形に整える処理。**列削除**（不要な列を捨てる）、**null（欠損値）除去**（値が無い行を捨てる）、型変換、結合などを指します。
- **本ハンズオン**: Lab 02 で `ehail_fee` 列の削除と `passenger_count` が null の行の削除を行います。
- 📖 [Microsoft Learn（Lakehouse）](https://learn.microsoft.com/fabric/data-engineering/lakehouse-overview)

### ディメンション / ファクト（Dimension / Fact）
分析用のテーブル設計。**ファクト**は数値（売上・件数など）と外部キーを持つ“出来事”の表、**ディメンション**は「いつ・どこ・誰・何」を説明する“属性”の表。
- **本ハンズオン**: Lab 04 で `dimension_*`（5本）と `fact_greentrip_copilot` を作ります。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-warehouse/dimensional-modeling-overview)

### スタースキーマ（Star Schema）
1つのファクトを複数のディメンションが星形に囲む、分析で定番のテーブル配置。
- **本ハンズオン**: Lab 04〜05 のファクト＋ディメンション＋リレーションシップがこの形です。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-warehouse/dimensional-modeling-overview)

### CTAS（CREATE TABLE AS SELECT）
**SELECT の結果からそのまま新しいテーブルを作る** T-SQL の書き方。
- **本ハンズオン**: Lab 04 でファクトテーブル `fact_greentrip_copilot` を CTAS で作成します。
- 📖 [Microsoft Learn（ディメンショナルモデリング）](https://learn.microsoft.com/fabric/data-warehouse/dimensional-modeling-overview)

### リレーションシップ（Relationship）
セマンティックモデルで、ファクトとディメンションを**キーで結びつける**定義。これがあると横断的に集計できます。
- **本ハンズオン**: Lab 05 でファクトと各ディメンションの間に4本のリレーションシップを定義します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/power-bi/transform-model/desktop-relationships-understand)

### メジャー（Measure）/ DAX
**メジャー**は「合計金額」「平均運賃」などの**集計式**。**DAX** はその式を書く言語（Excel の関数に近い）。
- **本ハンズオン**: Lab 05 で `# Trips`・`Avg Fare`・`Total Amount` などのメジャーを DAX で定義します。
- 📖 [Microsoft Learn（DAX）](https://learn.microsoft.com/dax/data-analysis-expressions-dax-reference)

### DirectQuery / Import モード
セマンティックモデルのデータ取得方式。**DirectQuery** は表示のたびに元データへライブ問い合わせ（リフレッシュ不要）、**Import** は事前にデータを取り込んでキャッシュ。
- **本ハンズオン**: Lab 05 のモデルは DirectQuery で構成します（SSO で自動認証・リフレッシュ不要）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/power-bi/connect-data/desktop-directquery-about)

### TMDL（Tabular Model Definition Language）
セマンティックモデルの構造（テーブル・メジャー・リレーション）を**テキストで記述する形式**。
- **本ハンズオン**: Lab 05・06 でモデルを TMDL で定義・更新します（Copilot が生成）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/power-bi/transform-model/desktop-tmdl-view)

### PBIR（Power BI Enhanced Report format）
Power BI レポートを**フォルダー＋ JSON のテキスト**で表す保存形式。差分管理や自動生成に向きます。
- **本ハンズオン**: Lab 06 でレポートを PBIR で組み立てて Fabric に公開します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/power-bi/developer/projects/projects-report)

---

## 5. データ連携・移行

### ミラーリング（Mirroring）
あるデータストアの中身を、**ほぼリアルタイムで別の場所に複製**し続ける仕組み。手動の ETL（取り出し・変換・書き込み）が不要になります。
- **本ハンズオン**: Lab 08 で Fabric SQL Database への書き込みが OneLake（MirroredWarehouse）に自動ミラーされることを確認します。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/database/mirrored-database/overview)

### ショートカット（再掲）
データをコピーせず別の場所のデータを参照する仕組み → 「1. アイテム」の[ショートカット](#ショートカットshortcut)を参照。

---

## 6. 認証・ライセンス

### Microsoft Entra ID（旧 Azure AD）
Microsoft のクラウド**ID 管理サービス**。サインインや権限の基盤です。
- **本ハンズオン**: `studentX` アカウントや SSO の認証基盤として使われます。
- 📖 [Microsoft Learn](https://learn.microsoft.com/entra/fundamentals/whatis)

### テナント（Tenant）
組織ごとに割り当てられる Entra ID の**まとまり（組織の境界）**。テナント ID で識別します。
- **本ハンズオン**: テナント ID は `e6c1292e-...`。受講者アカウントはこのテナントの**テナントレベル（サブスクリプション無し）**です。
- 📖 [Microsoft Learn](https://learn.microsoft.com/entra/fundamentals/whatis)

### SSO（シングルサインオン）
一度サインインすれば、関連サービスに**追加のサインインなしでアクセス**できる仕組み。
- **本ハンズオン**: DirectQuery のセマンティックモデルや Fabric App は、ユーザーの Entra ID で SSO 認証されます。
- 📖 [Microsoft Entra ID](https://learn.microsoft.com/entra/fundamentals/whatis)

### MFA（多要素認証）
パスワードに加えて**スマホ承認やコード**など2つ目の本人確認を求める方式。
- **本ハンズオン**: `az login` はブラウザ認証＋MFA で行います（ユーザー名/パスワード直渡しは MFA で失敗）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/entra/identity/authentication/concept-mfa-howitworks)

### PPU / Fabric トライアル
**PPU**（Power BI Premium Per User）はユーザー単位の上位ライセンス。**Fabric トライアル**は 60 日間 PPU 相当の機能を試せる無料体験です。
- **本ハンズオン**: Lab 05・06（Power BI）はトライアル（PPU 相当）が必要です。Fabric (Free) では作成できません。
- 📖 [Microsoft Learn（Fabric トライアル）](https://learn.microsoft.com/fabric/fundamentals/fabric-trial)

### サービスプリンシパル（Service Principal）
人ではなく**アプリやサービスが認証に使う ID**。バックグラウンド処理が、ユーザーの手を借りずにリソースへアクセスするために使います。
- **本ハンズオン**: Lab 03 の共有 ADLS 接続に、SP の資格情報があらかじめ格納されています（受講者は資格情報不要）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/entra/identity-platform/app-objects-and-service-principals)

### RBAC（ロールベースアクセス制御）
「**誰に・何の権限を**」を**ロール（役割）の割り当て**で管理する仕組み。
- **本ハンズオン**: Lab 03 は受講者にサブスクリプションの RBAC は不要です（必要な権限は講師が SP に付与済み）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/azure/role-based-access-control/overview)

### 接続（Connection）
外部データ源への**到達情報（URL など）と資格情報をひとまとめにした Fabric の設定**。共有でき、ショートカットやデータ取り込みで使い回せます。
- **本ハンズオン**: Lab 03 で共有接続 `adls-handson-sp-v3` を指定してショートカットを作成します（Lab 08 でも使用）。
- 📖 [Microsoft Learn](https://learn.microsoft.com/fabric/data-factory/data-source-management)

---

## 7. ツール・フレームワーク

### GitHub Copilot CLI
ターミナルで動く **AI コーディングアシスタント**（`copilot` コマンド）。本ハンズオンの実行環境です。
- **本ハンズオン**: 自然言語のプロンプトを受けて `az` / REST / PySpark などを自動生成・実行します。
- 📖 [GitHub Docs](https://docs.github.com/copilot/how-tos/set-up/install-copilot-cli)

### skills-for-fabric（プラグイン）
Copilot CLI に Fabric 操作のスキルを追加する**プラグイン群**。
- **本ハンズオン**: Lab 00 で導入し、Lakehouse 作成やクエリなど Fabric 操作のプロンプトを実現します。
- 📖 [GitHub: microsoft/skills-for-fabric](https://github.com/microsoft/skills-for-fabric)

### Rayfin
データモデル（エンティティ）を書くと **SQL スキーマ＋データ API＋型付きクライアントを生成**する、Microsoft の**コードファースト**アプリビルダー。
- **本ハンズオン**: Lab 08・10 で Fabric App を作るのに使います。
- 📖 [GitHub: microsoft/rayfin](https://github.com/microsoft/rayfin)

### Azure CLI（`az`）
Azure / Fabric を**コマンドで操作・認証**するツール。
- **本ハンズオン**: `az login` でのサインインや、API 用トークンの取得に使います。
- 📖 [Microsoft Learn](https://learn.microsoft.com/cli/azure/install-azure-cli)

### sqlcmd
Warehouse・SQL Endpoint・SQL Database に**コマンドラインから SQL を実行**する CLI ツール（本ハンズオンは新しい go-sqlcmd を使用）。
- **本ハンズオン**: Lab 04・05・06・10 で T-SQL の実行やデータ確認に使います（Entra ID 認証）。
- 📖 [Microsoft Learn（go-sqlcmd）](https://learn.microsoft.com/sql/tools/sqlcmd/go-sqlcmd-utility)

---

> 🔗 ハンズオンのトップに戻る → [README](../README.md) ／ 最初のラボ → [Lab 00](00-prerequisites.md)
