# Lab 06 — Power BI レポート作成（プロンプト駆動）

所要時間: 約 25 分
前提: [Lab 05](05-semantic-model.md) 完了（セマンティックモデル `sm_taxi_warehouse` が公開済み）

> 🎫 **ライセンス注意**: Power BI レポートの作成には **Pro / PPU 相当**が必要です。
> `studentX` は [Fabric サインイン手順](fabric-portal-login.md) の「手順 5」で **60 日トライアル**を
> 開始してください（Fabric Free では作成できません）。

このラボでは、Lab 05 で作ったセマンティックモデル `sm_taxi_warehouse` を使って、
**乗車時刻・乗車場所・料金を多角的に分析する Power BI レポート**を作成し、Fabric に公開します。
レポートのコードは Copilot CLI が自動生成するので、あなたがやるのは**プロンプトで指示するだけ**です。

> 🤖 裏側では Copilot が `powerbi-report-authoring` スキルで Power BI レポート（PBIR）を生成・検証し、
> Fabric REST API で自分のワークスペースへ公開します。

---

> 📖 **分からない用語があれば** [用語集（Glossary）](glossary.md) で確認できます（Lakehouse・Delta・Livy・セマンティックモデル など）。

## 📊 このラボで作るレポート

| # | ビジュアル | 内容 |
|---|-----------|------|
| 1 | KPI（平均料金・総乗車件数・最大料金） | 主要指標を上部にまとめて表示 |
| 2 | 折れ線グラフ | 日別の平均料金の推移 |
| 3 | 折れ線グラフ | 時間帯別の平均料金 |
| 4 | 横棒グラフ | ゾーン（Zone）別の平均料金（上位） |
| 5 | 横棒グラフ | 区（Borough）別の平均料金 |

---

## 6-1. レポート用の日付データを準備する

Warehouse（`taxi_warehouse`）の `fact_greentrip_copilot` には日時列が含まれていないため、
`taxi_lakehouse`（Lakehouse）に「日付・時間・月」の列を持つテーブルを用意します。

> 🗣️ **プロンプト**
> ```text
> Livy セッションを使って、taxi_lakehouse の green_tripdata_2026 から
> 乗車日時を変換した fact_greentrip_dates テーブルを作って。
> 列は次のとおり:
> - pickup_date（乗車日）
> - pickup_hour（乗車時間帯）
> - pickup_month（年月）
> - fare_amount（料金）
> - PULocationID（乗車ゾーンID）
> ```

🤖 **Copilot の動き**
- Livy セッションを作成し、PySpark で `lpep_pickup_datetime` から日付/時間/月を抽出して
  Delta テーブル `fact_greentrip_dates` として保存します。

✅ **期待する結果**

```text
Table fact_greentrip_dates created. Rows: 37,948
columns: pickup_date, pickup_hour, pickup_month, fare_amount, PULocationID
```

---

## 6-2. セマンティックモデルにメジャーを追加する

レポートで使う集計（メジャー）と、ゾーン名を引くためのリレーションシップをモデルに追加します。

> 🗣️ **プロンプト**
> ```text
> セマンティックモデル sm_taxi_warehouse に fact_greentrip_dates テーブルを追加して、
> 次のメジャーを作って:
> - 平均料金 = fare_amount の平均
> - 総乗車件数 = 行数
> - 最大料金 = fare_amount の最大
> あわせて fact_greentrip_dates.PULocationID → dimension_taxiZoneLookup.LocationID の
> リレーションシップも設定して。
> ```

🤖 **Copilot の動き**
- TMDL を更新してテーブル・メジャー・リレーションシップを追加し、
  Fabric REST API で再デプロイします（非同期処理を完了まで待機）。

✅ **期待する結果**

```text
Status: Succeeded
sm_taxi_warehouse に fact_greentrip_dates と 3 つのメジャーを追加
```

---

## 6-3. Power BI レポートを作成する

> 🗣️ **プロンプト**
> ```text
> sm_taxi_warehouse を使って「乗車分析レポート」という Power BI レポートを作って。
> 入れたいビジュアル:
> - 上部に KPI: 平均料金・総乗車件数・最大料金
> - 日別の平均料金の折れ線グラフ
> - 時間帯別の平均料金の折れ線グラフ
> - ゾーン（Zone）別の平均料金の横棒グラフ（降順）
> - 区（Borough）別の平均料金の横棒グラフ
> タイトルも付けて。
> ```

🤖 **Copilot の動き**
1. セマンティックモデルの列・メジャーを確認します。
2. `powerbi-report-authoring` スキルでレポート定義（PBIR）を生成します。
3. バリデーションを実行し、エラーが 0 であることを確認します。

✅ **期待する結果**

```text
レポート「乗車分析レポート」を作成
validate: succeeded（errors: 0）
ビジュアル: KPI / 折れ線 ×2 / 横棒 ×2
```

> 💡 上部の KPI は、**カード**ではなく**テーブル（マトリックス）**で表示すると、
> この Fabric 環境で確実に描画されます（カードが空白の箱になる場合の回避策）。Copilot が自動で対応します。

---

## 6-4. レポートを Fabric に公開する

> 🗣️ **プロンプト**
> ```text
> 作った「乗車分析レポート」を、自分の studentX ワークスペースに公開して。
> ```

🤖 **Copilot の動き**
- Fabric REST API `POST /v1/workspaces/{wsId}/reports` でレポート定義を公開します
  （非同期処理を完了まで待機）。

✅ **期待する結果**

```text
Status: Succeeded
Report published: 乗車分析レポート
```

---

## 6-5. レポートを確認する

> 🗣️ **プロンプト**
> ```text
> 自分の studentX ワークスペースのレポート一覧を表示して。
> ```

✅ **期待する結果**

```text
## Report
  - 乗車分析レポート
```

**Fabric Portal で開いて確認:**

1. [Fabric Portal](https://app.fabric.microsoft.com) を開く
2. `studentX` ワークスペース → `乗車分析レポート` をクリック
3. KPI・折れ線・横棒の各ビジュアルにデータが表示されることを確認

ここまで表示されれば、レポートの作成・公開は成功です 🎉

---

## 🔍 （参考）裏側で実行される処理

プロンプト駆動でも、内部では次の流れが走っています（手で打つ必要はありません）。

```text
1. Livy + PySpark           … 日付テーブル fact_greentrip_dates を作成
2. TMDL 更新 + REST API      … セマンティックモデルにメジャー / リレーションを追加
3. powerbi-report-authoring … PBIR レポート定義を生成・バリデーション
4. REST API /reports        … Fabric ワークスペースへ公開（非同期処理をポーリング）
```

---

## ✅ チェックポイント

- [ ] `fact_greentrip_dates` テーブルを作成できた（37,948 行）
- [ ] セマンティックモデルにメジャー（平均料金・総乗車件数・最大料金）を追加できた
- [ ] 「乗車分析レポート」を作成し、バリデーションが成功した
- [ ] レポートを自分の `studentX` ワークスペースに公開できた
- [ ] Portal で各ビジュアルにデータが表示された

---

## 🧹 トラブルシュート

| 症状 | 対処 |
|------|------|
| レポート作成 / 公開でライセンスエラー | [サインイン手順](fabric-portal-login.md) の「手順 5」で Fabric トライアル（PPU 相当）を開始 |
| KPI が空白の箱になる | カードビジュアルではなく**テーブル / マトリックス**で表示するよう Copilot に伝える |
| ビジュアルにデータが出ない | DirectQuery になっているか確認。または Portal でセマンティックモデルのデータソース認証（組織アカウント）を設定 |
| 公開が `Failed` になる | 「エラーの詳細を表示して」で原因を確認し、もう一度公開 |
| `green_tripdata_2026` が無い | [Lab 02](02-lakehouse-load-and-transform.md) を先に完了しているか確認 |

---

## ➡️ 次は

データ基盤〜レポート（Lab 02〜06）が完成しました。
最後に **[Lab 07 — Data Agent 作成](07-data-agent.md)** で、作ったセマンティックモデルに
**自然言語で質問できる会話型 AI（Data Agent）** を構築します 🤖
