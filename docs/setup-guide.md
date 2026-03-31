# Mac セットアップガイド

Mac を初期化して、ryoppippiさんの dotfiles（フォーク版）を導入するための手順書。

---

## Phase 1: 初期化前の準備

### 確認事項

- [ ] 1Password にログインできる（別デバイス or Web）
- [ ] SSH 鍵が 1Password に保存されている
- [ ] iCloud / Google Drive の同期が完了している
- [ ] このリポジトリが GitHub に push 済み
- [ ] Wi-Fi パスワード、Apple ID を控えている

### バックアップ

バックアップ先: `~/Library/CloudStorage/GoogleDrive-<your-email>/マイドライブ/my_mac_backup/`

重要度の高いもの:

- [ ] 1Password: マスターパスワード / Secret Key を確認
- [ ] Raycast: Settings > Advanced > Export
- [ ] Cursor: 設定同期の確認
- [ ] SSH/GPG 鍵: `~/.ssh/` のバックアップ（1Password 管理なら不要）

dotfiles で管理されるため不要:

- Git 設定、Neovim 設定、Wezterm 設定、Karabiner 設定、Fish 設定

---

## Phase 2: Mac の初期化

1. 電源ボタン長押しでリカバリーモード起動
2. ディスクユーティリティで内蔵ドライブを消去（APFS）
3. macOS を再インストール

---

## Phase 3: 初期セットアップ

### 3.1 macOS 初期設定

1. 言語・地域、Wi-Fi を設定
2. Apple ID でサインイン
3. ユーザーアカウント作成（ユーザー名: `asktt1770`）

### 3.2 1Password をセットアップ

App Store からインストールしてログイン。

### 3.3 Xcode Command Line Tools

```bash
xcode-select --install
```

---

## Phase 4: Nix のインストール

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

ターミナルを再起動:

```bash
exec $SHELL
```

確認:

```bash
nix --version
```

---

## Phase 5: dotfiles のクローン

### 5.1 SSH 接続設定

1Password SSH Agent を使用:

```bash
mkdir -p ~/.ssh
cat << 'EOF' > ~/.ssh/config
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
```

接続テスト:

```bash
ssh -T git@github.com
```

### 5.2 リポジトリをクローン

```bash
mkdir -p ~/ghq/github.com/asktt1770
git clone git@github.com:asktt1770/dotfiles.git ~/ghq/github.com/asktt1770/dotfiles
cd ~/ghq/github.com/asktt1770/dotfiles
```

---

## Phase 6: 自分用にカスタマイズ（初回のみ）

フォーク時に書き換え済みならスキップ。

### 変更が必要なファイル

| ファイル                           | 変更内容                              |
| ---------------------------------- | ------------------------------------- |
| `flake.nix`                        | `username = "asktt1770"`              |
| `flake.nix`                        | `dotfilesDir` のパスを `asktt1770` に |
| `nix/modules/lib/helpers/user.nix` | `githubId` を自分の ID に             |

### dotfilesDir の一括置換

```bash
find . -name "*.nix" -exec sed -i '' 's|github.com/ryoppippi/dotfiles|github.com/asktt1770/dotfiles|g' {} \;
```

### GitHub ユーザー ID の確認

```bash
curl -s https://api.github.com/users/asktt1770 | grep '"id"'
```

---

## Phase 7: 設定の適用

### 初回（nix-darwin が未インストール）

```bash
cd ~/ghq/github.com/asktt1770/dotfiles
sudo nix run nix-darwin -- switch --flake .#asktt1770
```

初回は 10〜30 分程度かかる。

### シェルを Fish に切り替え

```bash
exec fish
```

### 2 回目以降

```bash
git add . && nix run .#switch
```

---

## Phase 8: 追加セットアップ

- [ ] `gh auth login` — GitHub CLI ログイン
- [ ] Arc / Chrome — Google アカウントでログイン
- [ ] Slack / Discord — 各アカウントでログイン
- [ ] Obsidian — iCloud / Google Drive 同期を有効化
- [ ] Raycast — バックアップから設定を復元

---

## 完了チェックリスト

- [ ] Fish シェルが起動する
- [ ] Neovim が起動する（`v`）
- [ ] Git が動作する（`gs`）
- [ ] `gh` コマンドが使える
- [ ] 1Password が動作する
- [ ] Wezterm / Ghostty が起動する
- [ ] フォント（UDEV Gothic）が表示される

---

## upstream（ryoppippiさん）の更新を取り込む

```bash
# 初回のみ
git remote add upstream https://github.com/ryoppippi/dotfiles.git

# 更新を取り込む
git fetch upstream
git merge upstream/main
```

衝突した場合: `username` / `dotfilesDir` / `githubId` は **自分の値を残す**。

```bash
# 衝突を解決後
git add <ファイル>
git commit
git push origin main
```
