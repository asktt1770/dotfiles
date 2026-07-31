# Cheatsheet

このdotfilesで使えるエイリアス・キーバインド・コマンドの個人用チートシート（日本語・学習用）。

> **メンテ方針**: このファイルは upstream（ryoppippi/dotfiles）に存在しない自分専用ファイル。
> 本体の設定ファイル（`fish/config/abbrs_aliases.fish` 等）には手を入れず素のまま保ち、
> 学習メモはここに集約することで月次 upstream sync の衝突をゼロにする。
> 定義の出典は各セクションに記載。腐ったら定義ファイルと突き合わせて更新する。

---

## 📌 前回（archive版）からの変更点

| 変更          | 内容                                                                                                      |
| ------------- | --------------------------------------------------------------------------------------------------------- |
| ターミナル    | **WezTerm を廃止 → cmux に移行**（`nix/modules/home/programs/cmux.nix`）                                  |
| AI エイリアス | `cld`/`cldc` 廃止。`clc`（--continue）/ `cls1`（sonnet[1m]）追加。`clh` は skip-permissions 込みに        |
| Claude skills | 6個 → **19個** に拡張                                                                                     |
| git/gh        | worktree（`gwt`/`wtd`）、fzf連携、`gh-fork-sync`（fork一括同期）等を追加                                  |
| 新関数        | `nx`（nix shell ラッパ）, `gheye`（README閲覧）, `cppath`（パスをコピー）, `git_switch_branch`（fzf切替） |

---

## Nix 設定管理

| コマンド                        | 説明                                    |
| ------------------------------- | --------------------------------------- |
| `git add . && nix run .#switch` | 設定変更を適用（darwin + home-manager） |
| `nix run .#update`              | flake.lock の依存更新（macOS）          |
| `nix run .#update-ai-tools`     | llm-agents input だけ更新               |
| `nix run .#build`               | ビルドのみ（適用せず動作確認）          |

出典: `flake.nix` / `CLAUDE.md`

---

## Fish シェル

出典: `fish/config/abbrs_aliases.fish`（abbr/alias）, `fish/functions/`（関数）

### エイリアス（常に置換）

| エイリアス | 置換先  | 備考                                                                 |
| ---------- | ------- | -------------------------------------------------------------------- |
| `vim`      | `nvim`  |                                                                      |
| `ls`       | `eza`   | モダンな ls                                                          |
| `git`      | `bit`   | `bit` がある場合のみ                                                 |
| `rm`       | `trash` | 安全な削除（`fish/functions/rm.fish`。trash→なければ `bun x trash`） |

### エディタ・ナビゲーション

| 短縮            | 展開                  | 説明                              |
| --------------- | --------------------- | --------------------------------- |
| `v` / `nv`      | `nvim`                | Neovim 起動                       |
| `ll` / `la`     | `ls -hl` / `-hlA`     | 詳細 / 隠しファイル含む           |
| `lt` / `lg`     | `ls --tree` / `-hlFg` | ツリー / グループ表示             |
| `o`             | `open`                | ファイル/Finderで開く             |
| `vc`            | `code (pwd)`          | VS Code で開く                    |
| `cdr`           | `cd -- (git root)`    | **Gitルートへ一発移動**           |
| `cdf`           | `__fzf_cd`            | fzf でディレクトリ選択            |
| `pbc` / `pbp`   | `pbcopy` / `pbpaste`  | クリップボード                    |
| `sc`            | `source $FISH_CONFIG` | fish設定の再読込                  |
| `mkd` / `mkdir` | `mkdir -p`            | 親ごと作成（`mkdir`自体も上書き） |
| `rr` / `rf`     | `rm -r` / `rm -rf`    |                                   |
| `sed`           | `gsed`                | GNU sed                           |

### Git（トップレベル abbr）

| 短縮                 | 展開                                             | 説明                                  |
| -------------------- | ------------------------------------------------ | ------------------------------------- |
| `g`                  | `git`                                            |                                       |
| `ga` / `ga.` / `gaa` | `git add` / `add .` / `add --all`                | ステージング                          |
| `gc` / `gcn`         | `git commit` / `commit -n`                       | コミット（`-n`=hookスキップ）         |
| `gcm` / `gcnm`       | `git commit -m "%"` / `-n -m "%"`                | カーソルがメッセージ位置に入る        |
| `gcam` / `gcem`      | `commit --amend -m "%"` / `--allow-empty -m "%"` | 修正 / 空コミット                     |
| `gco`                | `git checkout`                                   |                                       |
| `gp` / `gpo`         | `git push` / `push origin`                       |                                       |
| `gpf` / `gpff`       | `push --force-with-lease` / `--force`            | **gpf=安全な**フォースプッシュ        |
| `gpl` / `gf`         | `git pull` / `git fetch`                         |                                       |
| `gsw` / `gswf`       | `git switch` / `switch feature/%`                | ブランチ切替                          |
| `gsm`                | `switch main \|\| switch master`                 | mainへ（master自動フォールバック）    |
| `gr` / `gpt`         | `git rebase` / `push --tags`                     |                                       |
| `gwt`                | `git wt`                                         | **worktree 管理**（カスタムコマンド） |
| `lzg` / `lzd`        | `lazygit` / `lazydocker`                         | TUIクライアント                       |

### forgit（fzf 対話 Git）

出典: `nix/modules/home/programs/fish/default.nix`（`pkgs.fishPlugins.forgit`）
上書き判定は `fish/config/abbrs_aliases.fish` との突き合わせ。

fzf + delta で Git 操作を対話的に選ぶプラグイン。abbr はプラグイン側が自動登録するので
`abbrs_aliases.fish` を読んでも出てこない = **上の表に載っていない Git 短縮がまだある**。

> **`git forgit <cmd>` は動かない。** 本体は fish 関数 `git-forgit` としてのみ定義され PATH に実体がないため、
> git サブコマンド経由は失敗する。abbr か `git-forgit <cmd>` を直接使う。

| 短縮                  | 対話操作                                            |
| --------------------- | --------------------------------------------------- |
| `gd`                  | **diff ビューア**（引数に revision を取れる。下記） |
| `glo` / `grl`         | log / reflog ビューア（`Ctrl-y` で SHA コピー）     |
| `gso`                 | show ビューア                                       |
| `gbl`                 | blame                                               |
| `grh` / `grs`         | `reset HEAD <file>` / `restore <file>` 選択         |
| `gcf` / `gcff`        | checkout file / checkout file from commit           |
| `gcb` / `gbd`         | checkout branch / `branch -D`                       |
| `gct` / `grc`         | checkout tag / revert commit                        |
| `gss` / `gsp`         | stash 表示 / stash push                             |
| `gcp`                 | cherry-pick                                         |
| `grb`                 | `rebase -i` 対象コミット選択                        |
| `gfu` / `gsq` / `grw` | fixup / squash / reword（いずれも autosquash 込み） |
| `gclean`              | `git clean` 対象選択                                |
| `gwa` / `gwd`         | worktree add / remove                               |
| `gi` / `gat`          | `.gitignore` / `.gitattributes` ジェネレータ        |

**自前 abbr が勝っていて forgit 版が呼べないもの**（フルで打つ必要あり）:

| 短縮  | 実際の展開     | 潰された forgit 版           |
| ----- | -------------- | ---------------------------- |
| `ga`  | `git add`      | `git-forgit add`             |
| `gco` | `git checkout` | `git-forgit checkout_commit` |
| `gsw` | `git switch`   | `git-forgit switch_branch`   |
| `gwt` | `git wt`       | `forgit::worktree`           |

#### fzf 画面内キーバインド

| キー                                   | 動作                                    |
| -------------------------------------- | --------------------------------------- |
| `Enter`                                | 選択項目を delta で全画面表示           |
| `?`                                    | プレビュー表示/非表示                   |
| `Alt-j` / `Alt-k`（`Alt-n` / `Alt-p`） | プレビューをスクロール                  |
| `Alt-w`                                | プレビューの折り返し切替                |
| `Alt-e`                                | `gd` でそのファイルをエディタで開く     |
| `Ctrl-s` / `Ctrl-r`                    | ソート切替 / 全選択トグル（複数選択時） |
| `Ctrl-y`                               | `glo` でコミット SHA をコピー           |
| `Esc` / `Ctrl-c`                       | 終了（exit 0 扱い）                     |

#### PR の差分を見る

`gd` は先頭 1〜2 引数を revision として解釈し（内部で `git rev-parse` 判定）、残りをパス扱いする。

```fish
gd main...                        # PRブランチ上で。GitHubの "Files changed" と一致
gd origin/main...HEAD             # リモート追跡ブランチ基準
gd @{u}...HEAD                    # 上流ブランチ基準
gd origin/main...HEAD nix/modules # パス絞り込み（`--` は付けない。パス扱いで壊れる）
glo main...HEAD                   # PRに含まれるコミットを一覧
```

> **`...`（三点）を使う。** `gd origin/main HEAD` のような2引数指定は `git diff A B` の二点 diff になり、
> 分岐後に main 側へ入ったコミットまで差分に混ざる。GitHub の PR ビューはマージベース基準の三点 diff。

未チェックアウトの PR は worktree を切ってから見る:

```fish
git wtpr <PR番号 or URL>  # PR用 worktree を作って移動
gd main...
```

### Git サブコマンド短縮（`git ` の後に入力 / fish 4.0+ `-c`）

| 短縮                    | 展開                                                             | 説明                           |
| ----------------------- | ---------------------------------------------------------------- | ------------------------------ |
| `a` / `aa` / `ap`       | `add` / `add -a` / `add -p`                                      | ap=パッチモード                |
| `cm` / `cma`            | `commit -m` / `commit --amend -m`                                |                                |
| `sw` / `swc`            | `switch` / `switch -c`                                           | swc=新規ブランチ作成切替       |
| `co` / `cob`            | `checkout` / `checkout -b`                                       |                                |
| `b` / `bm` / `bv`       | `branch` / `branch -m` / `branch -vv`                            | bv=追跡情報付き一覧            |
| `bu`                    | `rev-parse --abbrev-ref ...@{u}`                                 | upstream ブランチ表示          |
| `br`                    | `browse`                                                         | リポジトリをブラウザで開く     |
| `f` / `p` / `pl` / `po` | `fetch` / `push` / `pull` / `push origin`                        |                                |
| `pf` / `pushf`          | `push --force-with-lease --force-if-includes`                    | 安全なフォースプッシュ         |
| `rbm`                   | `rebase origin/main`                                             |                                |
| `rst` / `rs`            | `reset` / `restore`                                              |                                |
| `st` / `sts`            | `stash` / `status -s -uno`                                       | sts=短縮＋untracked非表示      |
| `cp` / `cpn`            | `cherry-pick` / `cherry-pick -n`                                 |                                |
| `difff`                 | `diff --word-diff`                                               | 単語レベル差分                 |
| `clb`                   | `clean-local-branches`                                           | マージ済みローカルブランチ削除 |
| `sha` / `id` / `cid`    | `rev-parse HEAD` / `show -s --format=%H` / `log -n1 --format=%H` | コミットID系                   |
| `sm` / `smu` / `sma`    | `submodule` / `update --remote --init --recursive` / `add`       | サブモジュール                 |
| `wtd`                   | `wt -D`                                                          | worktree 削除                  |
| `pbr`                   | `browse-pr`                                                      | PRをブラウザで開く             |

### Git エイリアス（`~/.gitconfig` / `;`コメント付き）

出典: `nix/modules/home/programs/git/aliases`（このファイル自体が説明付きで読める）

| エイリアス                 | 説明                                                 |
| -------------------------- | ---------------------------------------------------- |
| `git apf`                  | fzf + delta プレビューで対話的に `add -p`            |
| `git swf` / `swor`         | fzf でブランチ（全 / リモート）を選んで switch       |
| `git fixit`                | `commit --amend --no-edit`（メッセージそのまま修正） |
| `git browse` / `browse-pr` | リポジトリ / PR をブラウザで開く（`gh`使用）         |
| `git brc`                  | 現在HEADのコミットURLを取得                          |
| `git rb`                   | reflogから最近触ったブランチ一覧                     |
| `git today-numstat`        | 今日の追加/削除行数の統計                            |
| `git isv` / `prv`          | fzf-tmux で issue / PR をプレビューしながら選択      |
| `git com`                  | main/master を自動判定して checkout                  |
| `git dlr <branch>`         | ローカル削除＋リモート削除を一括                     |
| `git pr-setup`             | GitHub PR をローカルブランチとして fetch する設定    |
| `git root`                 | リポジトリのルートを表示                             |

### GitHub CLI / ghq

| 短縮             | 展開                                      | 説明                 |
| ---------------- | ----------------------------------------- | -------------------- |
| `ghp`            | `gh poi`                                  | PR一覧（gh拡張）     |
| `gg`             | `ghq get`                                 | リポジトリ取得       |
| `gh pco` / `pcr` | `pr checkout` / `pr create`               | `gh ` の後に入力     |
| `gh-fork-sync`   | fork全部（最大200）を upstream に一括同期 | **再fork運用で便利** |

### Docker

| 短縮                  | 展開                                   |
| --------------------- | -------------------------------------- |
| `do` / `dop`          | `docker container` / `... ps`          |
| `dob` / `dor` / `dox` | `... build` / `run --rm` / `exec -it`  |
| `dc` / `dcu` / `dcub` | `docker compose` / `up` / `up --build` |
| `dcd` / `dcr`         | `compose down` / `restart`             |

### Nix / Deno / その他

| 短縮                 | 展開                                   | 説明                               |
| -------------------- | -------------------------------------- | ---------------------------------- |
| `ns` / `ngc`         | `nix-shell` / `nix-collect-garbage`    |                                    |
| `nrn`                | `nix run nixpkgs#%`                    | 展開後カーソルが `#` 直後に入る    |
| `dv`                 | `devenv`                               |                                    |
| `dr` / `dt`          | `deno run -A --unstable` / `deno task` |                                    |
| `bunb` / `bunbx`     | `bun --bun` / `bunx --bun`             |                                    |
| `br` / `bri`         | `brew` / `brew install`                |                                    |
| `py`                 | `python`                               |                                    |
| `lc` / `lce` / `lct` | `leetcode` / `e` / `t`                 | LeetCode CLI                       |
| `n`                  | `_na`                                  | bun/deno/pnpm/npm 自動判定ランナー |

### AI ツール

| 短縮               | 展開                                                  | 説明                   |
| ------------------ | ----------------------------------------------------- | ---------------------- |
| `cl`               | `claude`                                              | Claude Code            |
| `clc`              | `claude --continue`                                   | **前回セッション再開** |
| `clo` / `cls`      | `claude --model opus` / `sonnet`                      | モデル指定             |
| `cls1`             | `claude --model sonnet[1m]`                           | **1Mコンテキスト**     |
| `clh`              | `claude --dangerously-skip-permissions --model haiku` | 雑用を爆速で           |
| `oc` / `cx` / `ca` | `opencode` / `codex` / `cursor-agent`                 | 他エージェント         |

### Fish キーバインド

出典: `fish/functions/fish_user_key_bindings.fish`, `fish/config/key_bindings.fish`
（fzf は legacy バインドがデフォルト = `Ctrl+T` / `Alt+C`）

| キー            | 動作                                      |
| --------------- | ----------------------------------------- |
| `Ctrl+T`        | fzf ファイル検索                          |
| `Ctrl+R`        | fzf 履歴検索                              |
| `Alt+C`         | fzf ディレクトリ移動                      |
| `Ctrl+B`        | fzf でブランチ切替（`git_switch_branch`） |
| `Ctrl+G`        | ghq プロジェクト選択（`__ghq_roots`）     |
| `Ctrl+X Ctrl+K` | fkill（プロセス選択 kill）                |
| `Alt+Y`         | カレントディレクトリのパスをコピー        |

### カスタム関数

出典: `fish/functions/`

| 関数                    | 説明                                                               |
| ----------------------- | ------------------------------------------------------------------ |
| `nx <pkg> -- <cmd>`     | nixpkgs のパッケージを一時的に使ってコマンド実行（**NEW**）        |
| `gheye <owner/repo>`    | GitHub の README を取得して glow で表示（**NEW**）                 |
| `cppath [path]`         | ファイル/ディレクトリの絶対パスを表示＋クリップボードへ（**NEW**） |
| `git_switch_branch`     | fzf でブランチ切替（`Ctrl+B` に割当、**NEW**）                     |
| `mkcd`                  | mkdir + cd                                                         |
| `fkill`                 | fzf でプロセス選択して kill                                        |
| `gh-q`                  | GitHubリポジトリを fzf で選んで ghq clone                          |
| `gip` / `lip`           | グローバル / ローカル IP 表示                                      |
| `clean`                 | パッケージキャッシュの一括削除                                     |
| `dotfiles-pull`         | dotfiles を最新に更新                                              |
| `npkill`                | node_modules を一括削除                                            |
| `nvbench` / `nvprofile` | Neovim ベンチマーク / プロファイル                                 |
| `pathclean`             | PATH の重複削除                                                    |
| `ss`                    | 直前のコマンドを sudo で再実行                                     |
| `tree`                  | ディレクトリツリー表示                                             |

---

## Neovim

出典: `nvim/lua/config/keymaps.lua`

### 設計思想

- `;` と `:` を入れ替え（Shiftなしでコマンドモード）
- `S` を無効化して検索置換に再利用
- ヤンク・ペーストのレジスタ汚染を防止

### 移動・基本

| キー | 動作                          |
| ---- | ----------------------------- |
| `U`  | Redo（`Ctrl+r`）              |
| `M`  | 対応する括弧へジャンプ（`%`） |
| `gM` | 画面中央へ（本来の `M`）      |

### ウィンドウ操作

| キー                | 動作                |
| ------------------- | ------------------- |
| `ss` / `sv`         | 水平分割 / 垂直分割 |
| `sh` `sj` `sk` `sl` | ウィンドウ間移動    |

### タブ操作

| キー        | 動作                    |
| ----------- | ----------------------- |
| `tt` / `tq` | 新規タブ / タブを閉じる |
| `th` / `tl` | 最初 / 最後のタブ       |

### 編集

| キー      | モード        | 動作                               |
| --------- | ------------- | ---------------------------------- |
| `x` / `X` | Normal,Visual | 削除（ヤンクしない）/ 行末まで削除 |
| `p`       | Visual        | ペースト（レジスタ汚染なし）       |
| `y`       | Visual        | ヤンク（カーソル位置維持）         |
| `S`       | Normal        | カーソル下の単語を検索置換         |
| `S`       | Visual        | 選択範囲を検索置換                 |
| `<` / `>` | Visual        | インデント（選択維持）             |

---

## ターミナル使い分け

|      | cmux（メイン）               | Ghostty（サブ）   |
| ---- | ---------------------------- | ----------------- |
| 役割 | 日常開発・AIエージェント統合 | SSH接続・軽量作業 |

出典: `nix/modules/home/programs/cmux.nix`, `ghostty.nix`

### cmux キーバインド

出典: `cmux.nix` の `shortcuts.bindings`

| キー                          | 動作                     |
| ----------------------------- | ------------------------ |
| `Cmd+Shift+H/J/K/L`           | ペイン間フォーカス移動   |
| `Cmd+z`                       | 分割ズームのトグル       |
| `Cmd+s`                       | ワークスペースへ移動     |
| `Cmd+Shift+F` / `Cmd+Shift+B` | サイドバータブ 次 / 前   |
| `Cmd+L`                       | ブラウザのアドレスバーへ |
| `Cmd+Shift+O`                 | ブラウザを開く           |
| `Cmd+Ctrl+H`                  | フラッシュ（ペイン点滅） |

cmux の特徴: Claude Code 統合（`claudeCodeIntegration`）、サイドバーに PR/ポート/進捗/SSH 表示、内蔵ブラウザでリンクを開く。

### Ghostty キーバインド（macOSデフォルト）

| キー                     | 動作                    |
| ------------------------ | ----------------------- |
| `Cmd+t` / `Cmd+w`        | 新規タブ / タブを閉じる |
| `Cmd+Shift+]` / `[`      | 次 / 前のタブ           |
| `Cmd+d` / `Cmd+Shift+d`  | 右に分割 / 下に分割     |
| `Cmd+Alt+矢印` or `hjkl` | 分割間移動              |
| `Cmd+Enter`              | フルスクリーン          |

---

## Claude Code スキル

出典: `agents/skills/`（agent-skills-nix 経由で管理）

| スキル                         | 用途                                |
| ------------------------------ | ----------------------------------- |
| `commit`                       | Conventional Commits でコミット作成 |
| `create-commits-and-push`      | コミット作成 → push                 |
| `create-pr`                    | ブランチ作成 → コミット → PR作成    |
| `fix-ci`                       | CI失敗を自動診断・修正              |
| `merge-main`                   | main ブランチをマージ               |
| `pr-apply-review`              | PRレビュー指摘を適用                |
| `session-summary-japanese`     | セッションを日本語で要約            |
| `ask-codex` / `codex-review`   | Codex に質問 / レビュー依頼         |
| `council`                      | 複数視点で議論                      |
| `cmux-debug`                   | cmux のデバッグ                     |
| `missing-tools`                | 不足ツールの検出                    |
| `nix-github-rate-limit`        | Nix の GitHub レート制限対処        |
| `react-server-components`      | RSC ガイド                          |
| `tdd`                          | テスト駆動開発                      |
| `typescript-style`             | TypeScript スタイル                 |
| `vitest-testing`               | Vitest テスト                       |
| `you-might-not-need-an-effect` | React useEffect 削減                |
| `skill-creator`                | 新スキル作成                        |

---

## 日常ワークフロー

```
1. cmux 起動
2. ghq + fzf でリポジトリ選択 (Ctrl+G)
3. Neovim 起動 (v)
4. 作業（cmux 内で Claude Code 統合を活用）
5. lazygit でコミット (lzg) または Claude Code (/commit)
```
