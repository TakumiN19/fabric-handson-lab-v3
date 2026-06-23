# Lab 01 — サインインとワークスペース接続（プロンプト駆動）

所要時間: 約 15 分
前提: [Lab 00](00-prerequisites.md) 完了

このラボでは、まず **Fabric ポータル（Web）** にサインインし、続いて
**コマンドを手で打つのではなく** GitHub Copilot CLI に **自然言語のプロンプトで指示**して
**Azure CLI** でもサインインし、自分の Microsoft Fabric ワークスペース（`student<番号>`）に接続します。

> 🤖 **プロンプト駆動とは？**
> あなたは「やりたいこと」を日本語で伝えるだけ。Copilot CLI が
> `skills-for-fabric` スキルを使い、必要な `az` / REST API コマンドを
> 自動で組み立てて実行します。実行前に内容を確認して **承認 (approve)** すればOKです。

---

## 📖 このラボの読み方

各ステップは次の3点セットで書かれています。

- 🗣️ **プロンプト** … Copilot CLI にそのまま貼り付けて送る文
- 🤖 **Copilot の動き** … 裏側でスキルが何をするか
- ✅ **期待する結果** … これが出れば成功

> 💡 Copilot がコマンド実行の許可を求めてきたら、内容を確認して
> 「Yes / 許可」を選びます。`az login` などサインイン系も同様です。

---

## 1-1. Fabric ポータル（Web）にサインインする

このあとの Power BI / Data Agent ラボでは、ブラウザの **Fabric ポータル**も使います。
まず、配布された `studentX` アカウントで Fabric ポータルにサインインしておきましょう
（このステップはブラウザ操作です。1-2 以降は Copilot へのプロンプトで進めます）。

> 📘 **詳しい手順は [受講者向け — Microsoft Fabric へのサインイン手順](fabric-portal-login.md) を参照してください。**

ざっくりの流れ:

1. ブラウザ（**シークレット / InPrivate ウィンドウ推奨**）で `https://app.fabric.microsoft.com` を開く
2. 別アカウントでログイン済みなら 右上プロフィール → **Sign out** してから、
   配布された `studentX@M365x43914722.onmicrosoft.com` でサインイン
3. 右上プロフィールが `studentX` になり、自分の `studentX` ワークスペースが見えれば OK
4. **Power BI ラボ（Lab 05・06）を行う場合**は、続けて **Start Fabric trial**（60 日・PPU〔Power BI のユーザー単位ライセンス〕相当）も開始
   （[サインイン手順](fabric-portal-login.md) の「手順 5」参照）

✅ ポータルに自分の `studentX` ワークスペースが表示されれば成功です。
このあとは **CLI** でもサインインして、プロンプト駆動でワークスペースを操作していきます。

---

## 1-2. Azure CLI にサインインする

> 🗣️ **プロンプト**（`student<番号>` は自分に割り当てられた番号に置き換えてください）
> ```text
> Azure CLI にブラウザ認証でサインインして。
> ユーザーは student<番号>@M365x43914722.onmicrosoft.com を使いたい。
> ```
>
> 例: 自分の番号が 3 なら `student3@M365x43914722.onmicrosoft.com` を指定します。

🤖 **Copilot の動き**
- `az login`（ブラウザ認証）を実行し、既定のブラウザを開きます。
- ユーザー名/パスワード直渡しは **MFA（多要素認証）で失敗する**ため使いません。

操作:
1. 開いたブラウザで自分の `student<番号>@M365x43914722.onmicrosoft.com` を選択（無ければ「別のアカウント」で入力）
2. パスワード / MFA を入力
3. 「サインインが完了しました」と出たらタブを閉じる

✅ **期待する結果**
ターミナルにサインインしたテナント / ユーザーが表示される。受講者アカウントは
**サブスクリプションを持たないテナントレベル**のため、サブスクリプション名は
`N/A(tenant level account)` と表示されます（環境によっては `No subscriptions found` と出ますが、どちらも正常です）。

```text
Name                       TenantId                              User
-------------------------  ------------------------------------  ----------------------------------
N/A(tenant level account)  e6c1292e-65b7-4e2d-9e1b-13f24e7753fd  student<番号>@M365x43914722.onmicrosoft.com
```

> 💡 `No subscriptions found` でサインインが止まる場合は、**サブスクリプション無しのテナント**としてサインインします。
> Copilot に「サブスクリプション無しのテナントとしてサインインして」と伝えるか、ターミナルで
> `az login --allow-no-subscriptions` を実行します。

> 💡 すでに別アカウントでサインイン済みのときは、
> 「別のユーザーでログインし直して」と伝えれば切り替えてくれます。

> 🛟 **Copilot 経由でサインインできないとき**（ブラウザが自動で開かない・リモート接続など）は、
> ターミナルで次を**直接実行**する **デバイスコード方式** が確実です。
>
> ```bash
> az login --use-device-code
> # サブスクリプションを持たない受講者アカウントでは次を使います
> az login --use-device-code --allow-no-subscriptions
> ```
>
> 表示された URL（`https://microsoft.com/devicelogin`）をブラウザで開き、ターミナルに出たコードを入力して、
> `student<番号>@M365x43914722.onmicrosoft.com` でサインインします。

---

## 1-3. サインイン状態を確認する

> 🗣️ **プロンプト**
> ```text
> 今 Azure にサインインしているユーザー名とテナントを教えて。
> ```

🤖 **Copilot の動き** … `az account show` を実行して整形表示します。

✅ **期待する結果**
ユーザーが自分の `student<番号>@M365x43914722.onmicrosoft.com`、テナントが
`e6c1292e-65b7-4e2d-9e1b-13f24e7753fd` になっている。

> 別ユーザーになっていたら 1-2 のプロンプトでサインインし直します。

---

## 1-4. ワークスペースに接続してアイテムを確認する

> 🗣️ **プロンプト**（`student<番号>` は自分のワークスペース名に置き換えてください）
> ```text
> student<番号> という Fabric ワークスペースに接続して、
> 含まれているアイテム（Lakehouse や SQL Endpoint など）を一覧して。
> ```

🤖 **Copilot の動き**
- `fabric-consumption`（または `fabric-skills`）スキルが起動。
- Fabric トークンを取得 → ワークスペース一覧から `student<番号>` を名前で特定 →
  その Workspace ID でアイテムを一覧します。

✅ **期待する結果**
自分の `student<番号>` ワークスペースが名前で特定でき、その Workspace ID が表示される。

このハンズオンを始めたばかりの段階では、ワークスペースは **まだ空** です。
Lakehouse やテーブルは **これから各ラボで作成していく** ので、この時点ではアイテムは表示されません。

```text
ワークスペース: student<番号> | <Workspace ID>
（アイテムはまだありません — Lab 02 以降で作成します）
```

ワークスペースを名前で特定できていれば、接続は成功です 🎉

> 💡 すでに Lakehouse やテーブルを作成済みの場合は、それらが種類ごとに一覧表示されます。

---

## 1-5. （応用）そのまま深掘りプロンプト

接続できたら、続けて自然言語で指示するだけで探索できます。例:

```text
student<番号> のワークスペース ID を覚えておいて。今後この中で作業するよ。
```

```text
このワークスペースに今あるアイテムを種類ごとに一覧して。
```

> 📌 Lakehouse やテーブルを作成したあと（Lab 02 以降）は、次のように深掘りできます。

```text
作成した Lakehouse にどんなテーブルがあるか一覧して。
```

```text
このワークスペースの SQL Endpoint の接続情報（サーバー名）を教えて。
```

> 📌 Copilot はワークスペース ID やアイテム ID を会話の中で覚えてくれるので、
> 一度特定すれば以降は「あのワークスペースの〜」で通じます。

---

## 🔍 （参考）裏側で実行されるコマンド

プロンプト駆動でも、内部では次のような `az` / REST 呼び出しが走っています。
仕組みを理解したい人向けの参考です（手で打つ必要はありません）。

```bash
# サインイン（ブラウザ認証）
az login

# サインイン確認
az account show --query "{user:user.name, tenant:tenantId}" -o json

# Fabric トークン取得 → ワークスペースを名前で特定
TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)
curl -s -H "Authorization: Bearer $TOKEN" "https://api.fabric.microsoft.com/v1/workspaces" \
  | python3 -c "import sys,json; [print(w['displayName'], w['id']) for w in json.load(sys.stdin)['value'] if w['displayName'].lower()=='student<番号>']"  # ← 自分のワークスペース名に置き換え

# Workspace ID でアイテム一覧
curl -s -H "Authorization: Bearer $TOKEN" "https://api.fabric.microsoft.com/v1/workspaces/<WS_ID>/items"
```

---

## ✅ チェックポイント

- [ ] Fabric ポータル（Web）に `studentX` でサインインし、自分のワークスペースが見えた
- [ ] プロンプトで Azure CLI にサインインできた（ブラウザ認証）
- [ ] サインインユーザーが目的のアカウントになっている
- [ ] プロンプトで自分の `student<番号>` ワークスペースに接続できた
- [ ] ワークスペースのアイテム一覧を確認できた（この時点では空でOK / 作成済みなら表示される）

---

## 🧹 トラブルシュート（プロンプトで対処）

| 症状 | プロンプト例 / 対処 |
|------|---------------------|
| 別のアカウントでサインインしている | 「別のユーザー `student<番号>@M365x43914722.onmicrosoft.com` でサインインし直して」 |
| ブラウザが開かない（SSH / リモート） | 「デバイスコード方式でサインインして」→ Copilot が `az login --use-device-code` を実行 |
| `No subscriptions found` と出る | 「サブスクリプション無しのテナントとしてサインインして」→ `az login --allow-no-subscriptions` |
| ワークスペースが見つからない | 「今アクセスできるワークスペースを全部一覧して」で確認 → 正しいテナント/名前か再確認 |
| API が 401 になる | 「Fabric のトークンを取り直して、もう一度試して」 |

> 🛟 プロンプトでうまくいかないときは、[Lab 01 付録のコマンド](#-参考裏側で実行されるコマンド)を
> 手動で実行して切り分けられます。

---

次は **Lab 02 — Lakehouse 作成・データ取り込み・変換**（[02-lakehouse-load-and-transform.md](02-lakehouse-load-and-transform.md)）に進みます。
そこでも「テーブルを一覧して」「行数を数えて」のように、**プロンプトだけ**で進めます。
