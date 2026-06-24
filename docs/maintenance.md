# メンテナンスガイド

日常的な設定変更、トラブルシューティング、バックアップに関するガイド。

> このファイルは upstream（ryoppippi/dotfiles）に存在しない自分専用ファイル。
> 本体設定には手を入れず、運用メモはここに集約して sync 衝突を避ける。
> 関連: [cheatsheet.md](./cheatsheet.md)

---

## 設定変更の流れ

```
1. 設定ファイルを編集
2. git add .        ← Nix は staged ファイルしか認識しない
3. nix run .#switch ← ビルド & 適用
4. 動作確認
5. git commit（PR 経由。main へ直接 push しない）
```

---

## よくある設定変更

### パッケージを追加したい

| 種類                             | ファイル                                                                    |
| -------------------------------- | --------------------------------------------------------------------------- |
| Nix パッケージ（CLI 等・全環境） | `nix/modules/home/packages.nix`                                             |
| Nix パッケージ（macOS 限定）     | `nix/modules/darwin/packages.nix`                                           |
| Homebrew Cask（GUI アプリ）      | `nix/modules/darwin/system.nix` の `casks`                                  |
| Mac App Store                    | `nix/modules/darwin/system.nix` の `masApps`（`mas search` で ID を調べる） |
| AI ツール                        | `nix/modules/home/programs/ai-tools.nix`                                    |

### Fish エイリアスを追加したい

`fish/config/abbrs_aliases.fish` を編集:

```fish
abbr --add 短縮形 "展開後のコマンド"
# git サブコマンド用は: abbr -a -c git 短縮 展開 # コメント
```

### Neovim プラグインを追加したい

`nvim/lua/plugin/` 以下に Lazy.nvim 形式で追加。

### 設定ファイルの場所

| 設定                          | ファイル                                               |
| ----------------------------- | ------------------------------------------------------ |
| Fish エイリアス               | `fish/config/abbrs_aliases.fish`                       |
| Fish 関数                     | `fish/functions/`                                      |
| Fish キーバインド             | `fish/functions/fish_user_key_bindings.fish`           |
| Neovim キーマップ             | `nvim/lua/config/keymaps.lua`                          |
| cmux 設定                     | `nix/modules/home/programs/cmux.nix`                   |
| Ghostty 設定                  | `nix/modules/home/programs/ghostty.nix`                |
| Git 設定                      | `nix/modules/home/programs/git/`                       |
| Git エイリアス                | `nix/modules/home/programs/git/aliases`                |
| macOS システム設定 / Homebrew | `nix/modules/darwin/system.nix`                        |
| AI ツール                     | `nix/modules/home/programs/ai-tools.nix`               |
| Claude skills                 | `nix/modules/home/agent-skills.nix` / `agents/skills/` |

---

## upstream との同期（月次 sync 手順書）

ryoppippi/dotfiles の変更を取り込む定例作業。再fork で共通祖先を持つ状態から始めたので
`git merge upstream/main` が機能し、mergiraf + rerere が衝突を吸収する。

> **頻度の方針**: 週次〜隔週の軽いタスクで回す。upstream の churn は約7割が
> renovate/nix-updater の bot bump なので、追従の必要性は低い。重要なのは「頻度」より
> 「定期的に触ってドリフトを防ぐ」こと（478コミット遅れ → 再fork、の再発防止）。
>
> **稼働している仕組み**（Nix で設定済み・手で有効化不要）:
>
> - `mergiraf`: AST対応マージドライバ。`.gitattributes` の `* merge=mergiraf` で全ファイルに適用
> - `git rerere`: `enabled + autoupdate`。一度解決した衝突を次回自動再適用
> - `merge.ff = false` / `conflictstyle = zdiff3`（出典: `nix/modules/home/programs/git/default.nix`）

### 手順

```bash
# 0. 前提: 作業ツリーをクリーンに、main を最新化
git switch main && git pull
git status                      # 未コミット変更がないこと

# 1. sync 用ブランチを切る（main へ直接マージしない）
git switch -c chore/upstream-sync-YYYY-MM-DD

# 2. upstream を取得して、どれだけ遅れているか確認
git fetch upstream
git rev-list --count main..upstream/main          # 遅れているコミット数
git log --oneline --no-merges main..upstream/main # 中身をざっと確認（7割は bot bump）

# 3. マージ実行（mergiraf が自動で効く / rerere が既知の衝突を再適用）
git merge upstream/main

# 4. 残った衝突を手で解決
#    - 個人化ポイント（下表）は必ずこちら側を残す
#    - 解決は rerere が autoupdate で記録 → 次回以降は自動化される
git status                      # 衝突ファイルを確認
# 解決後:
git add -A

# 5. ビルド検証（適用せず）→ OK なら適用してスモークテスト
git add . && nix run .#build
nix run .#switch                # fish / nvim / cmux が起動するか軽く確認

# 6. コミット & PR（fork なので --repo を明示）
git commit                      # マージコミット
git push -u origin HEAD
gh pr create --repo asktt1770/dotfiles --fill
```

> mergiraf が構造的衝突を吸収できないケース（同一行を両者が別内容に変更等）だけ手作業になる。
> 解決を一度すれば rerere が次回同じ衝突を再生するので、回を追うごとに手作業は減る。

### 衝突しやすい箇所と対処

### 衝突しやすい箇所と対処

個人化の値はこちら側を残す:

| ファイル                           | 箇所               | 自分の値                            |
| ---------------------------------- | ------------------ | ----------------------------------- |
| `flake.nix`                        | `username`         | `asktt1770`                         |
| `flake.nix`                        | `dotfilesDir` 各所 | `ghq/github.com/asktt1770/dotfiles` |
| `nix/modules/lib/helpers/user.nix` | `githubId`         | 自分の GitHub 数値 ID               |

### 変更しないもの（ryoppippi のまま）

- `flake.nix` の `description` / Cachix 設定 — ryoppippiさんのビルドキャッシュを利用するため
- fish プラグインの取得元 `owner = "ryoppippi"` — プラグイン参照元
- `nix/overlays/` 内の ryoppippi URL — 外部パッケージ参照

---

## トラブルシューティング

| 症状                     | 対処法                                                    |
| ------------------------ | --------------------------------------------------------- |
| 設定が反映されない       | `git add . && nix run .#switch`                           |
| Nix ビルドエラー         | `nix flake check` でエラー確認                            |
| パッケージが見つからない | `nix run .#update` で依存関係を更新                       |
| Fish の補完がおかしい    | `fish_update_completions`                                 |
| `command not found: nix` | ターミナルを開き直す                                      |
| Homebrew エラー          | `brew doctor && brew update`                              |
| SSH 接続できない         | `ssh-add -l` で鍵を確認                                   |
| ディスク容量不足         | `nix-collect-garbage -d`（または `/nix-gc-direnv` skill） |

---

## バックアップ

### バックアップ先

```text
~/Library/CloudStorage/GoogleDrive-<your-email>/マイドライブ/my_mac_backup/
```

### dotfiles で管理されているもの（バックアップ不要）

Git, Neovim, Fish, cmux, Karabiner, Ghostty の設定

### バックアップが必要なもの

| アプリ    | 重要度 | 方法                                          |
| --------- | ------ | --------------------------------------------- |
| 1Password | 高     | マスターパスワード / Secret Key を控える      |
| Raycast   | 中     | Settings > Advanced > Export                  |
| Cursor    | 中     | Settings Sync を確認                          |
| Obsidian  | 中     | Vault が iCloud/Google Drive にあることを確認 |
| SSH 鍵    | 高     | 1Password 管理 or `~/.ssh/` をコピー          |

### Raycast クリップボード履歴の復元

公式エクスポートではクリップボード履歴は移行されない。手動で復元:

1. 新 Mac で Raycast を終了
2. データベースを復元:
   ```bash
   cp -r /path/to/backup/clipboard_history/* ~/Library/Application\ Support/com.raycast.macos/
   ```
3. 画像キャッシュを復元:
   ```bash
   cp -r /path/to/backup/clipboard_cache/* ~/Library/Caches/com.raycast.macos/
   ```
4. Keychain に `database_key` を登録:
   ```bash
   security add-generic-password -a "Raycast" -s "database_key" -w "$(cat /path/to/backup/database_key.txt)" -T /Applications/Raycast.app
   ```
5. Raycast を起動
