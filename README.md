# Microsoft Fabric × GitHub Copilot CLI ハンズオン

GitHub Copilot CLI と **skills-for-fabric** スキルを使って、Microsoft Fabric を
**自然言語のプロンプトだけで操作する**ハンズオンです。各ラボは独立した Markdown 手順書になっています。

> 🤖 **プロンプト駆動ハンズオン**
> コマンドを手で打つのではなく、「やりたいこと」を日本語で Copilot CLI に伝えるだけ。
> Copilot が `skills-for-fabric` スキルを使って `az` / REST API コマンドを自動生成・実行します。
> 各ステップは 🗣️ **プロンプト** → 🤖 **Copilot の動き** → ✅ **期待する結果** の3点セットで記載。
> （仕組みを知りたい人向けに、裏側のコマンドも参考として併記しています）

---

## 🎯 このハンズオンで学ぶこと

- GitHub Copilot CLI から Microsoft Fabric に接続する方法
- `skills-for-fabric` スキルを使った Lakehouse / Warehouse / SQL Endpoint の操作
- Fabric REST API・SQL Endpoint を使ったデータ探索と分析
- 自然言語プロンプトで Fabric ワークロードを動かす流れ

## 🧰 前提環境

| ツール | 用途 | 確認コマンド |
|--------|------|--------------|
| GitHub Copilot CLI | 本ハンズオンの実行環境 | `copilot --version` |
| Azure CLI (`az`) | Fabric への認証・トークン取得 | `az version` |
| `skills-for-fabric` プラグイン | Fabric スキル群 | `/plugin list` |
| Python 3 / `curl` | REST API 呼び出し・整形 | `python3 --version` |

> 💡 Azure CLI が未インストールの場合: macOS は `brew install azure-cli`。

## 🔐 接続に使うアカウント / 環境（本ハンズオン用）

| 項目 | 値 |
|------|-----|
| サインインユーザー | `student<番号>@M365x43914722.onmicrosoft.com`（各自に配布） |
| テナント ID | `e6c1292e-65b7-4e2d-9e1b-13f24e7753fd` |
| ワークスペース | `student<番号>`（自分に割り当てられた番号） |
| Workspace ID | 自分のワークスペース ID（Lab 01 で確認） |
| Lakehouse | `taxi_lakehouse`（Lab 02 で作成） |

> ⚠️ `student<番号>` は各受講者に割り当てられた番号（例: `student3`）に読み替えてください。
> Lakehouse・Warehouse などのアイテムは、各ラボで自分のワークスペースに作成します。

---

## 🔑 受講者向け: Fabric へのサインイン（最初に実施）

ハンズオンを始める前に、配布された `studentX` アカウントで Microsoft Fabric（Web ポータル）に
サインインします。手順は **[受講者向け — Microsoft Fabric へのサインイン手順](labs/fabric-portal-login.md)** を参照してください。

> 💡 すでに会社・個人アカウントでサインインしている場合は、Profile パネルの **Sign out** で
> サインアウトしてから `studentX` アカウントに切り替えます（シークレット / InPrivate ウィンドウ推奨）。
>
> 🎫 **Lab 05・06（Power BI）を行う場合**は、サインイン後に Profile パネルの **Start Fabric trial**（60 日・PPU 相当）を開始してください。**Fabric (Free) ではレポート / セマンティックモデルを作成できません**。

---

## 📚 ラボ一覧

| # | ラボ | 内容 | 状態 |
|---|------|------|------|
| — | [Fabric へのサインイン（受講者向け）](labs/fabric-portal-login.md) | 配布された `studentX` アカウントで Fabric Web ポータルにサインイン | ✅ |
| 00 | [前提条件のセットアップ](labs/00-prerequisites.md) | ツール確認・プラグイン導入 | ✅ |
| 01 | [サインインとワークスペース接続](labs/01-login-and-connect.md) | ブラウザ認証で `az login`、自分の `student<番号>` に接続 | ✅ |
| 02 | [Lakehouse 作成・データ取り込み・変換](labs/02-lakehouse-load-and-transform.md) | Lakehouse 作成 → Parquet アップロード → Delta 変換（列削除・null 除去） | ✅ |
| 03 | [ADLS Gen2 + OneLake ショートカット](labs/03-adls-shortcut.md) | ADLS Gen2 作成 → CSV アップロード → Fabric 接続 → ショートカット作成 | ✅ |
| 04 | [Warehouse ディメンション＆ファクトテーブル作成](labs/04-warehouse-dimensions.md) | Warehouse 作成 → ディメンション 5 本 → fact_greentrip_copilot (CTAS) | ✅ |
| 05 | [セマンティックモデル作成](labs/05-semantic-model.md) | Warehouse テーブルからセマンティックモデル構築・リレーションシップ定義 | ✅ |
| 06 | [Power BI レポート作成](labs/06-powerbi-report.md) | セマンティックモデルを使った多角分析レポート（5ビジュアル）を Fabric に公開 | ✅ |

---

## ▶️ 進め方

1. [Lab 00](labs/00-prerequisites.md) で環境を整える（ツール確認・プラグイン導入）
2. [Fabric へのサインイン](labs/fabric-portal-login.md) で、配布された `studentX` アカウントで Fabric にサインインする
3. [Lab 01](labs/01-login-and-connect.md) で **プロンプトで**サインインしてワークスペースに接続する
4. 以降のラボも、すべて **プロンプトで指示** して進める

各ステップは 🗣️ プロンプト → 🤖 Copilot の動き → ✅ 期待する結果 で構成。
ラボの末尾には **✅ チェックポイント**（完了確認）と
**🧹 トラブルシュート**（プロンプトでの対処）を用意しています。

> 💡 Copilot がコマンド実行の許可を求めたら、内容を確認して承認してください。
