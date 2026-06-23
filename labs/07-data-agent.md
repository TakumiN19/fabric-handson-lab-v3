# Lab 07 — 付録：Data Agent 作成（プロンプト駆動）

所要時間: 約 20 分
前提: [Lab 05](05-semantic-model.md) 完了（`sm_taxi_warehouse` セマンティックモデルが自分の `student<番号>` ワークスペースに存在すること）

> 🎫 **機能 / ライセンス注意**: Data Agent は Fabric の **Copilot / AI 機能**です。テナントで AI 機能が有効になっており、Fabric 容量（**トライアル可**）が必要です。作成できない場合は講師に確認してください。

このラボでは、Lab 05 で作った **セマンティックモデルに自然言語で質問できる会話型 AI**（Fabric **Data Agent**）を作成します。
`taxi_ride_agent` という Data Agent を `sm_taxi_warehouse` に接続し、**指示（instructions）と代表的な質問 5 つ**を整備して公開、最後に実際に質問してみます。

```
Data Agent 作成  →  セマンティックモデル接続  →  指示＋例題整備  →  公開  →  質問してみる
```

> 🤖 **裏側では何が動く？**
> Data Agent は Fabric の **AI Skill ワークロード**です。Copilot CLI は **Fabric ノートブック / Livy セッション**を起動して
> `fabric-data-agent-sdk` を実行し、作成・設定・公開を行います（セッション起動を含め数分かかります）。

> 💡 ポータル UI（`student<番号>` ワークスペース → **新規** → **Data Agent**）でも作成できますが、本ラボは **プロンプト駆動**で進めます。

---

> 📖 **分からない用語があれば** [用語集（Glossary）](glossary.md) で確認できます（Lakehouse・Delta・Livy・セマンティックモデル など）。

## 7-1. Data Agent を作成してセマンティックモデルに接続する

> 🗣️ **プロンプト**（`student<番号>` は自分のワークスペース名）
> ```text
> student<番号> ワークスペースに taxi_ride_agent という Data Agent を作って、
> sm_taxi_warehouse セマンティックモデルをデータソースとして接続して。
> テーブルは全部選択した状態にして。
> ```

🤖 **Copilot の動き**
- Fabric ノートブック / Livy セッションで `fabric-data-agent-sdk` を実行します。
- `create_data_agent("taxi_ride_agent")` → Data Agent アイテムを作成。
- `agent.add_datasource("sm_taxi_warehouse")` → セマンティックモデル（`semantic_model`）として接続。
- `ds.select()` → 全テーブルを選択（**選択しないと Agent がクエリせず、推測で誤答する**ため必須）。

✅ **期待する結果**
`taxi_ride_agent`（種類: DataAgent）が作成され、データソースに `sm_taxi_warehouse` が表示される。

```text
DataAgent: taxi_ride_agent
  datasource: sm_taxi_warehouse  (tables: selected)
```

---

## 7-2. 指示（instructions）を整備する

データの意味とルールを教えると、Agent の回答精度が大きく上がります。

> 🗣️ **プロンプト**
> ```text
> taxi_ride_agent に次の指示（instructions）を設定して：
> - 対象は NYC グリーンタクシー 2026年4月・約 37,948 トリップ
> - メジャー [# Trips] / [Total Amount](USD) / [Avg Trip Distance] を優先して使う
> - 時系列は fact_greentrip_dates の pickup_month / pickup_hour と [Avg Fare] / [# Trips (Dates)]
> - 集計に使える結合済みディメンション: VendorID, RatecodeID, TripType,
>   taxiZoneLookup（Borough = 乗車地）
> - dimension_PaymentType は fact と未結合なので、支払方法で集計しない
> - 降車地（DOLocationID）も未結合。金額は USD で一部マイナス有 → 収益は [Total Amount] を使う
> - 4月のデータのみ。回答は簡潔に、実際の数値を含める
> ```

🤖 **Copilot の動き** … `agent.update_configuration(instructions=...)` を実行。

✅ **期待する結果**
Agent の instructions が設定される（ドメイン説明・使うメジャー・結合ルールが反映される）。

> 💡 **設計ポイント**: `dimension_PaymentType` はモデルに存在しても **fact と未結合**です。
> 支払方法で集計するよう求められても正しくフィルタされないため、指示で明示的に避けさせます。

---

## 7-3. 代表的な質問（例題）を 5 つ用意する

例題を与えると、Agent が想定質問にどんな DAX で答えるべきかを学習し、回答が安定します。

> ⚠️ **Fabric の仕様**: セマンティックモデルのデータソースは **few-shot 例題 API が非対応**
> （`Few shots not supported for semantic model`）。そのため例題は **instructions に DAX 付きで埋め込みます**。

> 🗣️ **プロンプト**
> ```text
> taxi_ride_agent の instructions に、代表的な質問 5 つを DAX 付きの例として追記して：
> 1. 総トリップ数は？
> 2. 総収益と平均乗車距離は？
> 3. 乗車地の borough 別トリップ数・収益（多い順）
> 4. ベンダー別のトリップ数・収益の比較
> 5. 月別の平均運賃とトリップ数
> ```

🤖 **Copilot の動き** … 各質問と DAX を instructions に追記して `update_configuration` で保存。

埋め込まれる DAX の例:

```dax
-- 1. 総トリップ数
EVALUATE ROW("Total Trips", [# Trips])

-- 2. 総収益と平均乗車距離
EVALUATE ROW("Total Amount", [Total Amount], "Avg Trip Distance", [Avg Trip Distance])

-- 3. 乗車地の borough 別（多い順）
EVALUATE
SUMMARIZECOLUMNS(
    dimension_taxiZoneLookup[Borough],
    "Trips", [# Trips],
    "Total Amount", [Total Amount]
)
ORDER BY [Trips] DESC

-- 4. ベンダー別の比較
EVALUATE
SUMMARIZECOLUMNS(
    dimension_VendorID[Description],
    "Trips", [# Trips],
    "Total Amount", [Total Amount]
)
ORDER BY [Trips] DESC

-- 5. 月別の平均運賃とトリップ数
EVALUATE
SUMMARIZECOLUMNS(
    fact_greentrip_dates[pickup_month],
    "Trips", [# Trips (Dates)],
    "Avg Fare", [Avg Fare]
)
ORDER BY fact_greentrip_dates[pickup_month]
```

✅ **期待する結果**
5 つの代表質問が DAX 付きで instructions に含まれる。

---

## 7-4. 公開する

> 🗣️ **プロンプト**
> ```text
> taxi_ride_agent を公開して。
> ```

🤖 **Copilot の動き** … `agent.publish()` で設定（sandbox → production）を公開。

✅ **期待する結果**
`published` 状態になり、チャットや API から利用可能になる。

---

## 7-5. Data Agent に質問してみる

> 🗣️ **プロンプト**
> ```text
> taxi_ride_agent に「総トリップ数と総収益は？」と聞いて、回答を見せて。
> ```

🤖 **Copilot の動き** … 発行済みエージェント（`FabricOpenAI(artifact_name="taxi_ride_agent")`）に問い合わせ、セマンティックモデルへ実クエリした結果を返します。

✅ **期待する結果**（例 / 数値や文面は多少変わります）

```text
There were about 37,948 NYC green taxi trips in total for April 2026,
with total revenue of about $931,663.
```

> 📌 セマンティックモデルに実際にクエリした **接地（grounded）回答**が返れば成功です 🎉
> 続けて「borough 別のトリップ数を多い順に」「ベンダー別の収益は？」のように自然言語で深掘りできます。

---

## 🔍 （参考）裏側の仕組み（`fabric-data-agent-sdk`）

Data Agent の作成・設定は SDK で行います。SDK は **Fabric ランタイム専用**（`sempy` + `synapse.ml` が必要）なため、
**Fabric ノートブック / Livy セッション**の中で実行します（ローカル PC では動きません）。

```python
from fabric.dataagent.client import create_data_agent

agent = create_data_agent("taxi_ride_agent")           # Data Agent 作成
ds = agent.add_datasource("sm_taxi_warehouse")          # semantic_model として接続
ds.select()                                             # 全テーブル選択（重要）
agent.update_configuration(instructions=INSTRUCTIONS)   # 指示＋例題（DAX）を設定
agent.publish()                                         # 公開
```

**ハマりどころ（Copilot が自動対処します）**
- `pip install fabric-data-agent-sdk` が `pydantic-core` を更新し、`cannot import name 'Sentinel' from 'typing_extensions'` で落ちる
  → `pip install -U "typing_extensions>=4.14"` 後、`typing_extensions` / `pydantic` を再読込してから import。
- セマンティックモデルのデータソースは **few-shot** も **データソース単位の instructions** も非対応（lakehouse / warehouse / kusto のみ）
  → 例題・指示は **agent レベルの instructions** に集約。
- Agent を削除した直後に同名で作り直すと `409 ItemDisplayNameNotAvailableYet`（リトライ可）
  → 数分待って再試行。

---

## ✅ チェックポイント

- [ ] プロンプトで `taxi_ride_agent`（DataAgent）を作成できた
- [ ] `sm_taxi_warehouse` をデータソースに接続し、全テーブルを選択できた
- [ ] instructions（ドメイン / メジャー / 結合ルール）を設定できた
- [ ] 代表的な質問 5 つを DAX 付きで instructions に含められた
- [ ] Data Agent を **公開（published）** できた
- [ ] 質問に対して、セマンティックモデルへ実クエリした **接地回答**が返った

---

## 🧹 トラブルシュート（プロンプトで対処）

| 症状 | プロンプト例 / 対処 |
|------|---------------------|
| 作成でライセンス / 機能エラー | テナントで Copilot / AI 機能が有効か、Fabric 容量（トライアル）かを確認（講師に連絡） |
| `cannot import name 'Sentinel'` | 「typing_extensions を 4.14 以上に更新して、import 前にモジュールを再読込して」 |
| `Few shots not supported for semantic model` | 例題は few-shot ではなく **instructions に DAX 付きで**入れる（7-3 の方法） |
| 削除直後に同名で作れない（`409`） | 「数分待ってから taxi_ride_agent を作り直して」（名前予約の解放待ち・リトライ） |
| 回答が的外れ / 数値が出ない | 「taxi_ride_agent の全テーブルを選択し直して」→ `ds.select()`。instructions を見直す |
| 公開後すぐ応答しない | 数十秒待ってから再質問。`student<番号>` の正しい Agent か確認 |

---

## 🎉 おつかれさまでした！

ここまでで Lab 00〜07 が完了です。
GitHub Copilot CLI と `skills-for-fabric` を使い、**自然言語プロンプトだけ**で
Lakehouse へのデータロード → ショートカット → Warehouse → セマンティックモデル →
Power BI レポート → そして **会話型 AI（Data Agent）** までを一気通貫で構築しました 🚀

> ➡️ 続いて **[Lab 08](08-fabric-app.md)** で、この Data Agent を組み込んだ
> **Fabric App（ダッシュボード＋入力フォーム＋チャットボット）** を作ってデプロイします。
