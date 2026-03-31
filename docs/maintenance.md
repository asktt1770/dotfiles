# メンテナンスガイド

日常的な設定変更、トラブルシューティング、バックアップに関するガイド。

---

## 設定変更の流れ

```
1. 設定ファイルを編集
2. git add .        ← Nix は staged ファイルしか認識しない
3. nix run .#switch ← ビルド & 適用
4. 動作確認
5. git commit
```

---

## よくある設定変更

### パッケージを追加したい

| 種類                        | ファイル                                                                    |
| --------------------------- | --------------------------------------------------------------------------- |
| Nix パッケージ（CLI 等）    | `nix/modules/home/packages.nix`                                             |
| Homebrew Cask（GUI アプリ） | `nix/modules/darwin/system.nix` の `casks`                                  |
| Mac App Store               | `nix/modules/darwin/system.nix` の `masApps`（`mas search` で ID を調べる） |

### Fish エイリアスを追加したい

`fish/config/abbrs_aliases.fish` を編集:

```fish
abbr --add 短縮形 "展開後のコマンド"
```

### Neovim プラグインを追加したい

`nvim/lua/plugins/` 以下に Lazy.nvim 形式で追加。

### 設定ファイルの場所

| 設定               | ファイル                                 |
| ------------------ | ---------------------------------------- |
| Fish エイリアス    | `fish/config/abbrs_aliases.fish`         |
| Fish 関数          | `fish/functions/`                        |
| Neovim キーマップ  | `nvim/lua/config/keymaps.lua`            |
| Wezterm キーマップ | `wezterm/keymaps.lua`                    |
| Wezterm 設定       | `wezterm/wezterm.lua`                    |
| Git 設定           | `nix/modules/home/programs/git/`         |
| Ghostty 設定       | `nix/modules/home/programs/ghostty.nix`  |
| macOS システム設定 | `nix/modules/darwin/system.nix`          |
| Homebrew           | `nix/modules/darwin/system.nix`          |
| AI ツール          | `nix/modules/home/programs/ai-tools.nix` |

---

## upstream との同期

ryoppippiさんの最新変更を取り込む:

```bash
git fetch upstream
git merge upstream/main
```

### 衝突しやすい箇所と対処

| ファイル                           | 衝突箇所                                   | 対処           |
| ---------------------------------- | ------------------------------------------ | -------------- |
| `flake.nix`                        | `username`, `darwinHomedir`, `dotfilesDir` | 自分の値を残す |
| `nix/modules/lib/helpers/user.nix` | `githubId`                                 | 自分の値を残す |
| 各モジュールの `dotfilesDir`       | `ghq/github.com/ryoppippi/dotfiles`        | `asktt1770` に |

### 変更しないもの

- `nix/modules/home/programs/fish/default.nix` の `owner = "ryoppippi"` — プラグインの取得元なのでそのまま
- `nix/overlays/` 内の ryoppippi URL — 外部パッケージの参照なのでそのまま
- Cachix の設定 — ryoppippiさんのビルドキャッシュを利用するため

---

## トラブルシューティング

| 症状                     | 対処法                              |
| ------------------------ | ----------------------------------- |
| 設定が反映されない       | `git add . && nix run .#switch`     |
| Nix ビルドエラー         | `nix flake check` でエラー確認      |
| パッケージが見つからない | `nix run .#update` で依存関係を更新 |
| Fish の補完がおかしい    | `fish_update_completions`           |
| `command not found: nix` | ターミナルを開き直す                |
| Homebrew エラー          | `brew doctor && brew update`        |
| SSH 接続できない         | `ssh-add -l` で鍵を確認             |

### Nix キャッシュのクリア

ディスク容量が足りないとき:

```bash
nix-collect-garbage -d
```

---

## バックアップ

### バックアップ先

```text
~/Library/CloudStorage/GoogleDrive-<your-email>/マイドライブ/my_mac_backup/
```

### dotfiles で管理されているもの（バックアップ不要）

Git, Neovim, Fish, Wezterm, Karabiner, Ghostty の設定

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
