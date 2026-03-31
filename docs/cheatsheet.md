# Cheatsheet

ryoppippiさんのdotfilesで使えるエイリアス・キーバインド・コマンドのチートシート。

---

## Nix 設定管理

| コマンド                        | 説明                     |
| ------------------------------- | ------------------------ |
| `git add . && nix run .#switch` | 設定変更を適用           |
| `nix run .#update`              | 依存関係を更新           |
| `nix run .#build`               | ビルドテスト（適用せず） |

---

## Fish シェル

### エディタ・ナビゲーション

| 短縮形        | 展開                 | 説明                   |
| ------------- | -------------------- | ---------------------- |
| `v` / `nv`    | `nvim`               | Neovim 起動            |
| `ll`          | `ls -hl`             | 詳細リスト             |
| `la`          | `ls -hlA`            | 隠しファイル含む       |
| `lt`          | `ls --tree`          | ツリー表示             |
| `cdr`         | `cd (git root)`      | Git ルートへ移動       |
| `cdf`         | `__fzf_cd`           | fzf でディレクトリ選択 |
| `o`           | `open`               | ファイルを開く         |
| `vc`          | `code (pwd)`         | VS Code で開く         |
| `pbc` / `pbp` | `pbcopy` / `pbpaste` | クリップボード         |

### エイリアス（自動置換）

| エイリアス | 置換先  | 備考           |
| ---------- | ------- | -------------- |
| `vim`      | `nvim`  |                |
| `ls`       | `eza`   | モダンな ls    |
| `git`      | `bit`   | bit がある場合 |
| `rm`       | `trash` | 安全な削除     |

### Git

#### 基本操作

| 短縮形 | 展開                                     | 説明                   |
| ------ | ---------------------------------------- | ---------------------- |
| `g`    | `git`                                    |                        |
| `ga`   | `git add`                                | ステージング           |
| `ga.`  | `git add .`                              | 全てステージ           |
| `gc`   | `git commit`                             | コミット               |
| `gcm`  | `git commit -m "%"`                      | メッセージ付き         |
| `gp`   | `git push`                               | プッシュ               |
| `gpf`  | `git push --force-with-lease`            | 安全なフォースプッシュ |
| `gpl`  | `git pull`                               | プル                   |
| `gf`   | `git fetch`                              | フェッチ               |
| `gsw`  | `git switch`                             | ブランチ切替           |
| `gsm`  | `git switch main \|\| git switch master` | main へ切替            |
| `lzg`  | `lazygit`                                | TUI Git クライアント   |

#### git サブコマンド短縮（`git` の後に入力）

| 短縮    | 展開                                          | 説明                   |
| ------- | --------------------------------------------- | ---------------------- |
| `a`     | `add`                                         | ステージング           |
| `ap`    | `add -p`                                      | パッチモード           |
| `cm`    | `commit -m`                                   | メッセージ付きコミット |
| `sw`    | `switch`                                      | ブランチ切替           |
| `swc`   | `switch -c`                                   | 新規ブランチ           |
| `pf`    | `push --force-with-lease --force-if-includes` | 安全なフォースプッシュ |
| `st`    | `stash`                                       | スタッシュ             |
| `co`    | `checkout`                                    | チェックアウト         |
| `pl`    | `pull`                                        | プル                   |
| `difff` | `diff --word-diff`                            | 単語レベルの差分       |
| `clb`   | `clean-local-branches`                        | マージ済みブランチ削除 |

### GitHub CLI

| 短縮形 | 展開      | 説明           |
| ------ | --------- | -------------- |
| `ghp`  | `gh poi`  | PR 一覧        |
| `gg`   | `ghq get` | リポジトリ取得 |

`gh` の後: `pco` = `pr checkout`, `pcr` = `pr create`

### Docker

| 短縮形 | 展開                        |
| ------ | --------------------------- |
| `dc`   | `docker compose`            |
| `dcu`  | `docker compose up`         |
| `dcd`  | `docker compose down`       |
| `dor`  | `docker container run --rm` |

### AI ツール

| 短縮形 | 展開                                    | 説明           |
| ------ | --------------------------------------- | -------------- |
| `cl`   | `claude`                                | Claude Code    |
| `cld`  | `claude --dangerously-skip-permissions` | 許可スキップ   |
| `cldc` | 上記 + `--continue`                     | 前回の続き     |
| `clh`  | 上記 + `--model haiku`                  | 高速モデル     |
| `clo`  | 上記 + `--model opus`                   | 高性能モデル   |
| `cls`  | 上記 + `--model sonnet`                 | バランスモデル |
| `cx`   | `codex`                                 | Codex          |
| `ca`   | `cursor-agent`                          | Cursor Agent   |
| `oc`   | `opencode`                              | OpenCode       |

### Nix

| 短縮形 | 展開                  |
| ------ | --------------------- |
| `ns`   | `nix-shell`           |
| `ngc`  | `nix-collect-garbage` |
| `dv`   | `devenv`              |

### その他

| 短縮形 | 展開                                        |
| ------ | ------------------------------------------- |
| `br`   | `brew`                                      |
| `py`   | `python`                                    |
| `n`    | `_na`（bun/deno/pnpm/npm 自動判定ランナー） |

### Fish キーバインド

| キー            | 動作                   |
| --------------- | ---------------------- |
| `Ctrl+F`        | fzf ファイル検索       |
| `Ctrl+R`        | fzf 履歴検索           |
| `Ctrl+B`        | fzf ブランチ切替       |
| `Ctrl+G`        | ghq プロジェクト選択   |
| `Alt+D`         | fzf ディレクトリ移動   |
| `Ctrl+X Ctrl+K` | fkill（プロセス kill） |

### カスタム関数

| 関数                    | 説明                                       |
| ----------------------- | ------------------------------------------ |
| `mkcd`                  | mkdir + cd                                 |
| `fkill`                 | fzf でプロセス選択して kill                |
| `gh-q`                  | GitHub リポジトリを fzf で選んで ghq clone |
| `gip` / `lip`           | グローバル / ローカル IP 表示              |
| `clean`                 | パッケージキャッシュの一括削除             |
| `dotfiles-pull`         | dotfiles を最新に更新                      |
| `npkill`                | node_modules を一括削除                    |
| `nvbench` / `nvprofile` | Neovim ベンチマーク / プロファイル         |
| `pathclean`             | PATH の重複削除                            |
| `ss`                    | 前回のコマンドを sudo で再実行             |
| `tree`                  | ディレクトリツリー表示                     |

---

## Neovim

### 設計思想

- `;` と `:` を入れ替え（Shift なしでコマンドモード）
- `s` を無効化してウィンドウ操作に再利用
- ヤンク・ペーストのレジスタ汚染を防止

### 基本移動

| キー            | 動作                            |
| --------------- | ------------------------------- |
| `h` `j` `k` `l` | 左下上右                        |
| `0`             | 行頭 / 最初の非空白文字をトグル |
| `M`             | 対応する括弧へジャンプ（`%`）   |
| `U`             | Redo（`Ctrl+r`）                |

### ウィンドウ操作

| キー                | 動作             |
| ------------------- | ---------------- |
| `ss`                | 水平分割         |
| `sv`                | 垂直分割         |
| `sh` `sj` `sk` `sl` | ウィンドウ間移動 |

### タブ操作

| キー                | 動作              |
| ------------------- | ----------------- |
| `Tab` / `Shift+Tab` | 次 / 前のタブ     |
| `tt`                | 新しいタブ        |
| `tq`                | タブを閉じる      |
| `th` / `tl`         | 最初 / 最後のタブ |

### 編集

| キー      | モード         | 動作                         |
| --------- | -------------- | ---------------------------- |
| `x`       | Normal, Visual | 削除（ヤンクしない）         |
| `X`       | Normal, Visual | 行末まで削除（ヤンクしない） |
| `p`       | Visual         | ペースト（ヤンクしない）     |
| `y`       | Visual         | ヤンク（カーソル位置維持）   |
| `S`       | Normal         | カーソル下の単語を検索置換   |
| `S`       | Visual         | 選択範囲を検索置換           |
| `<` / `>` | Visual         | インデント（選択維持）       |
| `gq`      | Normal         | 検索ハイライト解除           |
| `Ctrl+K`  | Insert         | 左の単語を大文字化           |

### コマンドモード（Emacs 風）

| キー                | 動作    |
| ------------------- | ------- |
| `Ctrl+A`            | 行頭    |
| `Ctrl+E`            | 行末    |
| `Ctrl+F` / `Ctrl+B` | 右 / 左 |

---

## ターミナル使い分け

|      | WezTerm            | Ghostty                   |
| ---- | ------------------ | ------------------------- |
| 役割 | 日常開発（メイン） | SSH接続・軽量作業（サブ） |

詳細: `docs/terminal-usage.md`

---

## Wezterm

### 基本設定

| 項目         | 値                                                    |
| ------------ | ----------------------------------------------------- |
| フォント     | UDEV Gothic 35LG (13.0)                               |
| 背景透明度   | 0%（不透明）                                          |
| テーマ       | 自動（Dark: Woodland / Light: Atelier Estuary Light） |
| リーダーキー | `Ctrl+;`                                              |

### ペイン操作

| キー                | 動作             |
| ------------------- | ---------------- |
| `Cmd+d`             | 水平分割         |
| `Cmd+Shift+d`       | 垂直分割         |
| `Cmd+w`             | ペインを閉じる   |
| `Cmd+z`             | ペインをズーム   |
| `Cmd+h/j/k/l`       | ペイン間移動     |
| `Cmd+Shift+H/J/K/L` | ペインサイズ調整 |

### タブ操作

| キー                | 動作                |
| ------------------- | ------------------- |
| `Cmd+t`             | 新規タブ            |
| `Cmd+Shift+W`       | タブを閉じる        |
| `Cmd+Shift+(` / `)` | タブを左 / 右に移動 |
| `Leader+1`〜`9`     | タブ番号で切替      |

### ワークスペース

| キー            | 動作                             |
| --------------- | -------------------------------- |
| `Cmd+s`         | ワークスペース一覧（fzf 風選択） |
| `Cmd+Shift+S`   | 新規ワークスペース作成           |
| `Cmd+Shift+n/p` | 前後のワークスペースへ           |
| `Leader+s`      | ワークスペース名変更             |

### その他

| キー           | 動作                |
| -------------- | ------------------- |
| `Leader+Space` | Quick Select モード |
| `Leader+;`     | フルスクリーン切替  |
| `Cmd+Shift+f`  | 背景ぼかし切替      |

---

## Ghostty

### 基本設定

| 項目       | 値                                           |
| ---------- | -------------------------------------------- |
| フォント   | UDEV Gothic 35LG (13)                        |
| 背景透明度 | 0%（不透明）                                 |
| テーマ     | 自動（Dark: One Double Dark / Light: Novel） |

### キーバインド（macOS デフォルト）

#### タブ操作

| キー          | 動作           |
| ------------- | -------------- |
| `Cmd+t`       | 新規タブ       |
| `Cmd+w`       | タブを閉じる   |
| `Cmd+Shift+]` | 次のタブ       |
| `Cmd+Shift+[` | 前のタブ       |
| `Cmd+1`〜`9`  | タブ番号で切替 |

#### 分割操作

| キー                     | 動作           |
| ------------------------ | -------------- |
| `Cmd+d`                  | 右に分割       |
| `Cmd+Shift+d`            | 下に分割       |
| `Cmd+Shift+Enter`        | 分割をズーム   |
| `Cmd+Alt+Arrow` / `hjkl` | 分割間移動     |
| `Cmd+Shift+Arrow`        | 分割サイズ調整 |

#### その他

| キー          | 動作               |
| ------------- | ------------------ |
| `Cmd+Shift+,` | 設定ファイルを開く |
| `Cmd+Enter`   | フルスクリーン     |
| `Cmd+n`       | 新規ウィンドウ     |

---

## Claude Code スキル

| スキル                      | 用途                                |
| --------------------------- | ----------------------------------- |
| `/commit`                   | Conventional Commits でコミット作成 |
| `/create-pr`                | ブランチ作成 → コミット → PR 作成   |
| `/fix-ci`                   | CI 失敗を自動診断・修正             |
| `/merge-main`               | main ブランチをマージ               |
| `/pr-apply-review`          | PR レビュー指摘を適用               |
| `/session-summary-japanese` | セッションを日本語で要約            |

---

## 日常ワークフロー

```
1. Wezterm 起動
2. ghq + fzf でリポジトリ選択 (Ctrl+G)
3. Neovim 起動 (v)
4. 作業
5. lazygit でコミット (lzg) または Claude Code (/commit)
```
