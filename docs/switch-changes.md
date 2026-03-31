# `nix run .#switch` で変わること

このドキュメントは、素の macOS 状態から `nix run .#switch` を実行した際に適用される変更の一覧です。

## 1. シェル

| 項目           | 適用前 (デフォルト) | 適用後                              |
| -------------- | ------------------- | ----------------------------------- |
| ログインシェル | zsh                 | Fish                                |
| プロンプト     | デフォルト zsh      | Hydro (Fish プロンプト)             |
| プラグイン     | なし                | fzf, autopair, zoxide 連携など 13個 |

Fish プラグインは Nix で管理され、`~/.local/share/fish/nix-plugins/` に配置されます。

## 2. ターミナル

| 項目    | 適用前         | 適用後                                                    |
| ------- | -------------- | --------------------------------------------------------- |
| WezTerm | デフォルト設定 | dotfiles の Lua 設定 (`wezterm/`) がリンク                |
| Ghostty | 設定なし       | Kanagawa Dragon テーマ、背景透過70%、UDEV Gothic フォント |

## 3. キーボード (Karabiner)

**注意: 適用前のルールは完全に上書きされます。必要なルールは事前に `karabiner/karabiner.ts` に取り込んでください。**

### Complex Modifications

| ルール                                    | 内容                                                  | 対象                           |
| ----------------------------------------- | ----------------------------------------------------- | ------------------------------ |
| Tap Ctrl -> japanese_eisuu + ESC          | 左Ctrl 単押しで英数+ESC、押しっぱなしは通常の Ctrl    | 全キーボード                   |
| Tap ESC -> japanese_eisuu + esc           | ESC 押下時に英数切り替え + ESC                        | 全キーボード                   |
| Quit application by holding command-q     | Cmd+Q 長押しで終了 (誤爆防止)                         | 全キーボード                   |
| Swap Enter/Shift+Enter on Discord/ChatGPT | Enter と Shift+Enter を入れ替え                       | Discord, ChatGPT               |
| Tap CMD to toggle Kana/Eisuu              | 左Cmd 単押し→英語、右Cmd 単押し→かな                  | MacBook / 外付け (claw44 以外) |
| Hold tab to super key                     | Tab 長押し→Hyper Key (Cmd+Opt+Shift+Ctrl)、単押し→Tab | MacBook / 外付け (claw44 以外) |
| fn + h/j/k/l to arrow keys                | Vim 風矢印キー                                        | MacBook / 外付け (claw44 以外) |
| Right option to super key                 | 右Option→Hyper Key                                    | MacBook / 外付け (claw44 以外) |

### Simple Modifications

| 項目               | 内容                               |
| ------------------ | ---------------------------------- |
| CapsLock           | 左 Control に変更 (全プロファイル) |
| Backslash / Delete | 入れ替え (Apple キーボード)        |

## 4. Git

| 項目                  | 適用前           | 適用後                                         |
| --------------------- | ---------------- | ---------------------------------------------- |
| .gitconfig            | なし             | フル設定 (SSH 署名、delta、エイリアス等)       |
| エディタ              | デフォルト (vim) | Neovim                                         |
| diff ビューア         | 通常の diff      | delta (シンタックスハイライト、side-by-side)   |
| グローバル .gitignore | なし             | .DS_Store, **pycache**, .env 等を無視          |
| push                  | デフォルト       | autoSetupRemote 有効、force-if-includes        |
| rebase                | デフォルト       | autoStash, autoSquash, updateRefs 有効         |
| merge                 | デフォルト       | fast-forward 無効、zdiff3 コンフリクトスタイル |

## 5. エディタ

| 項目    | 適用前   | 適用後                                                              |
| ------- | -------- | ------------------------------------------------------------------- |
| Neovim  | 設定なし | dotfiles の Lua 設定 (`nvim/`) がリンク、Lazy.nvim でプラグイン管理 |
| IdeaVim | 設定なし | `~/.ideavimrc` がリンク                                             |

## 6. macOS システム設定 (defaults)

### Dock

| 設定             | 値              |
| ---------------- | --------------- |
| 自動非表示       | 有効            |
| アイコンサイズ   | 45px            |
| ピン留めアプリ   | 全削除 (空配列) |
| 最近使ったアプリ | 非表示          |
| 位置             | 下              |

### Finder

| 設定             | 値         |
| ---------------- | ---------- |
| 隠しファイル表示 | 有効       |
| 拡張子表示       | 有効       |
| パスバー         | 表示       |
| ステータスバー   | 表示       |
| デフォルト表示   | リスト表示 |
| 拡張子変更警告   | 無効       |

### グローバル設定

| 設定                 | 値                          |
| -------------------- | --------------------------- |
| 外観                 | ダークモード                |
| キーリピート速度     | 2 (高速)                    |
| キーリピート開始遅延 | 25                          |
| トラックパッド速度   | 1.3                         |
| 自動大文字化         | 無効                        |
| 自動ダッシュ置換     | 無効                        |
| 自動ピリオド挿入     | 無効                        |
| 自動引用符置換       | 無効                        |
| スペル自動修正       | 無効                        |
| メニューバー間隔     | 狭め (spacing=2, padding=2) |

### スクリーンショット

| 設定         | 値                     |
| ------------ | ---------------------- |
| 保存先       | ~/Pictures/Screenshots |
| フォーマット | PNG                    |

### トラックパッド

| 設定               | 値                           |
| ------------------ | ---------------------------- |
| タップでクリック   | 無効                         |
| 二本指で右クリック | 有効                         |
| 三本指ドラッグ     | 無効                         |
| クリック感度       | 軽い (FirstClickThreshold=0) |
| Force Click        | 有効                         |
| 触覚フィードバック | 有効                         |

### セキュリティ

| 設定             | 値                     |
| ---------------- | ---------------------- |
| Touch ID で sudo | 有効 (tmux 内でも動作) |

## 7. Homebrew パッケージ

**注意: `onActivation.cleanup = "uninstall"` が設定されているため、dotfiles に定義されていない Homebrew パッケージはアンインストールされます。**

### Casks (GUI アプリ)

1Password, Alfred, Aqua Voice, Arc, BlackHole, Brave Browser, Claude, Cloudflare WARP, Discord, Google Chrome, Google Drive, ImageOptim, Karabiner Elements, Ollama, OpenVPN Connect, OrbStack, SD Formatter, Secretive, Dia

### Mac App Store

Accelerate, AdGuard for Safari, Amphetamine, Blackmagic Disk Speed Test, CotEditor, DevCleaner, Document Generator, FocusRecorder, Gifski, Hex Fiend, Hush, Keynote, LanguageTranslator, Leftovers, Microsoft Excel/Word, Microsoft Remote Desktop, NamingTranslator, Pages, Seashore, Shareful, Slack, TabifyIndents, TestFlight, The Unarchiver, Xcode

### Nix パッケージ (brew-nix 経由の cask)

Alt-Tab, AppCleaner, Beekeeper Studio, Bluesnooze, ChatGPT, Cursor, DeskPad, Figma, Glance, Homerow, IsThereNet, Kap, Maestral, Marta, OBS, Postman, Processing, QLVideo, Raycast, Shottr, Signal, Stats, VLC, Yaak, Zed, Zoom

### Nix パッケージ (直接)

Audacity, Cyberduck, Ghostty, KeyCastr, MonitorControl, Obsidian, Telegram, VS Code, WezTerm

## 8. dotfiles シンボリンク

### 共通 (全プラットフォーム)

| リンク先                   | ソース               |
| -------------------------- | -------------------- |
| `~/.config/fish`           | `fish/`              |
| `~/.config/wezterm`        | `wezterm/`           |
| `~/.config/aquaproj-aqua`  | `aqua/`              |
| `~/.config/efm-langserver` | `efm-langserver/`    |
| `~/.ideavimrc`             | `ideavimrc`          |
| `~/.zshenv`                | `zshenv`             |
| `~/.zshrc`                 | `zsh/zshrc`          |
| `~/.bash_profile`          | `bash/.bash_profile` |
| `~/.bashrc`                | `bash/.bashrc`       |
| `~/.scripts`               | `my_scripts/`        |
| `~/.pip/pip.conf`          | `pip/pip.conf`       |

### macOS のみ

| リンク先                                     | ソース                         |
| -------------------------------------------- | ------------------------------ |
| `~/.config/karabiner`                        | `karabiner/`                   |
| `~/.Brewfile`                                | `Brewfile`                     |
| `~/.finicky.js`                              | `finicky.js`                   |
| `~/.config/yabai`                            | `yabai/`                       |
| `~/.config/skhd`                             | `skhd/`                        |
| Xcode キーバインド                           | `xcode/Default.idekeybindings` |
| `~/Library/Application Support/pip/pip.conf` | `pip/pip.conf`                 |

## 特に注意が必要なポイント

1. **Karabiner のルールが完全に入れ替わる** - 現在の設定を残したい場合は `karabiner/karabiner.ts` に事前に移植すること
2. **Homebrew の cleanup** - dotfiles に定義されていない cask/brew はアンインストールされる。事前に `brew list` で確認推奨
3. **Dock のピン留めが全消去** - `persistent-apps = [ ]` により空になる
4. **ログインシェルが Fish に変更** - zsh 固有の設定がある場合は注意
