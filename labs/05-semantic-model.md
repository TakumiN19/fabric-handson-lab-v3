# Lab 05 — セマンティックモデル作成（プロンプト駆動）

所要時間: 約 20 分  
前提: [Lab 04](04-warehouse-dimensions.md) 完了（`taxi_warehouse` に 6 テーブルが存在すること）

> 🎫 **ライセンス注意**: セマンティックモデルの作成には **Pro / PPU 相当**が必要です。
> `studentX` は [Fabric サインイン手順](fabric-portal-login.md) の「手順 5」で **60 日トライアル**を開始してください（Fabric Free では作成不可）。

このラボでは Fabric Warehouse のテーブルを使って Power BI セマンティックモデルを作成し、
ディメンションテーブルとファクトテーブルのリレーションシップを定義します。

```
TMDL ファイル作成  →  Fabric REST API でデプロイ  →  リレーションシップ確認
```

> 🤖 **このラボはすべてプロンプト（Copilot）で完結します**

---

## セマンティックモデルとは？

セマンティックモデルは Power BI のデータモデルです。
テーブル・リレーションシップ・メジャー（集計式）を定義することで、
レポートや Copilot がデータを正しく解釈できるようになります。

```
dimension_VendorID ────┐
dimension_RatecodeID ──┤
dimension_TripType ────┼──→ fact_greentrip_copilot
dimension_taxiZoneLookup ─┘
dimension_PaymentType（将来用）
```

---

## 5-1. セマンティックモデルを作成する

> 🗣️ **プロンプト**
> ```text
> taxi_warehouse の以下のテーブルを使って、
> sm_taxi_warehouse という名前のセマンティックモデルを student<番号> ワークスペースに作って。
>
> テーブル:
> - fact_greentrip_copilot（ファクト）
> - dimension_VendorID
> - dimension_TripType
> - dimension_RatecodeID
> - dimension_PaymentType
> - dimension_taxiZoneLookup
>
> リレーションシップ（多 → 一）:
> - fact_greentrip_copilot.VendorID → dimension_VendorID.VendorID
> - fact_greentrip_copilot.RatecodeID → dimension_RatecodeID.RatecodeID
> - fact_greentrip_copilot.trip_type → dimension_TripType.Trip_type
> - fact_greentrip_copilot.PULocationID → dimension_taxiZoneLookup.LocationID
> ```

🤖 **Copilot の動き**
1. Warehouse のカラム情報を確認（`INFORMATION_SCHEMA.COLUMNS`）
2. TMDL ファイルを生成（テーブル定義・リレーションシップ・メジャー）
3. Fabric REST API `POST /v1/workspaces/{wsId}/semanticModels` でデプロイ
4. LRO（非同期処理）をポーリングして完了確認

✅ **期待する結果**

```text
Status: Succeeded
SemanticModel: sm_taxi_warehouse
```

---

## 5-2. 作成されたモデルを確認する

> 🗣️ **プロンプト**
> ```text
> student<番号> ワークスペースのセマンティックモデル一覧を表示して。
> ```

🤖 **Copilot の動き**

```bash
az rest --method get \
  --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces/{wsId}/semanticModels" \
  --query "value[].{name:displayName, id:id}" -o table
```

✅ **期待する結果**

```text
Name
-----------------
sm_taxi_warehouse
```

---

## 🔍 （参考）Copilot が生成する TMDL

Copilot は以下のような TMDL ファイルを生成して REST API 経由でデプロイします。

### フォルダー構成

```
definition.pbism
definition/
  database.tmdl
  model.tmdl
  relationships.tmdl
  tables/
    fact_greentrip_copilot.tmdl
    dimension_VendorID.tmdl
    dimension_TripType.tmdl
    dimension_RatecodeID.tmdl
    dimension_PaymentType.tmdl
    dimension_taxiZoneLookup.tmdl
```

### model.tmdl（テーブル参照）

```tmdl
model Model
	culture: en-US
	defaultPowerBIDataSourceVersion: powerBI_V3

ref table fact_greentrip_copilot
ref table dimension_VendorID
ref table dimension_TripType
ref table dimension_RatecodeID
ref table dimension_PaymentType
ref table dimension_taxiZoneLookup
```

### relationships.tmdl（リレーションシップ定義）

```tmdl
relationship 'fact-dimension_VendorID'
	fromColumn: fact_greentrip_copilot.VendorID
	toColumn: dimension_VendorID.VendorID

relationship 'fact-dimension_RatecodeID'
	fromColumn: fact_greentrip_copilot.RatecodeID
	toColumn: dimension_RatecodeID.RatecodeID

relationship 'fact-dimension_TripType'
	fromColumn: fact_greentrip_copilot.trip_type
	toColumn: dimension_TripType.Trip_type

relationship 'fact-dimension_taxiZoneLookup'
	fromColumn: fact_greentrip_copilot.PULocationID
	toColumn: dimension_taxiZoneLookup.LocationID
```

### ファクトテーブル（fact_greentrip_copilot.tmdl）

```tmdl
table fact_greentrip_copilot

	measure '# Trips' = COUNTROWS(fact_greentrip_copilot)
		formatString: #,##0

	measure 'Total Amount' = SUM(fact_greentrip_copilot[total_amount])
		formatString: $#,##0.00

	measure 'Avg Trip Distance' = AVERAGE(fact_greentrip_copilot[trip_distance])
		formatString: #,##0.00

	column VendorID
		dataType: int64
		isHidden          ← FK 列は非表示
		summarizeBy: none
		sourceColumn: VendorID

	column total_amount
		dataType: double
		summarizeBy: sum
		sourceColumn: total_amount

	... （他の列も同様）

	partition fact_greentrip_copilot = m
		mode: import
		source =
			let
				Source = Sql.Database("<DW_SERVER>", "taxi_warehouse"),
				Data = Source{[Schema="dbo",Item="fact_greentrip_copilot"]}[Data]
			in
				Data
```

> 💡 **設計ポイント**
> - `fromColumn` = 多側（ファクト）、`toColumn` = 一側（ディメンション）
> - ファクトテーブルの FK 列（VendorID 等）は `isHidden` で非表示
> - ディメンションのキー列は `summarizeBy: none`
> - メジャーには `formatString` が必須

---

## 5-3. Fabric Portal でモデルを確認する（任意）

1. [Fabric Portal](https://app.fabric.microsoft.com) を開く
2. `student<番号>` ワークスペース → `sm_taxi_warehouse` を選択
3. **「データモデルを開く」** をクリック
4. リレーションシップビューでテーブル間の接続を確認

✅ **期待する画面**: 4 本のリレーションシップ線がファクトテーブルとディメンションを結んでいる

---

## 5-4. データを更新する（任意）

モデルを更新するには Fabric Portal でデータソース接続の認証が必要です。

> 🗣️ **プロンプト**
> ```text
> sm_taxi_warehouse セマンティックモデルの更新をトリガーして。
> ```

> ⚠️ **初回は Portal での認証が必要な場合があります**
> Fabric Portal → `sm_taxi_warehouse` → 設定 → データソース認証情報 → 資格情報の編集
> → 「組織アカウント」でサインイン → 更新を実行

---

## ✅ チェックポイント

- [ ] TMDL ファイルが正しく生成された
- [ ] `sm_taxi_warehouse` が student<番号> ワークスペースに作成された
- [ ] 4 本のリレーションシップが定義されている
  - [ ] `fact.VendorID` → `dimension_VendorID.VendorID`
  - [ ] `fact.RatecodeID` → `dimension_RatecodeID.RatecodeID`
  - [ ] `fact.trip_type` → `dimension_TripType.Trip_type`
  - [ ] `fact.PULocationID` → `dimension_taxiZoneLookup.LocationID`
- [ ] ファクトテーブルに 3 本のメジャーが含まれている（`# Trips`, `Total Amount`, `Avg Trip Distance`）

---

## 🧹 トラブルシュート

| 症状 | 対処 |
|------|------|
| `202` だが `Failed` になる | エラー詳細を「LRO のエラー内容を表示して」で確認 |
| TMDL バリデーションエラー | `InvalidLineType: Property!` → `database.tmdl` が `database` 宣言から始まっているか確認 |
| テーブルが見つからない | Warehouse の接続文字列が正しいか `az rest` で再確認 |
| データ更新で認証エラー | Portal でデータソース認証情報を「組織アカウント」で設定 |
| セマンティックモデルが消えた | 再デプロイ：「sm_taxi_warehouse セマンティックモデルを再作成して」 |

---

次は **Lab 06 — Power BI レポート作成**（準備中）に進みます。
