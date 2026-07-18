# dotfiles

Nix、nix-darwin、Home Manager で macOS と Linux の環境を管理する。

## macOS

Apple Silicon Mac を対象としている。

| 構成名 | 端末 | macOS アカウント名 |
| --- | --- | --- |
| `macbook-pro` | MacBook Pro | `katsumi.kobayashi` |
| `macbook-air` | MacBook Air | `katsumikobayashi` |

### 初回セットアップ

手動でインストールするものは Determinate Nix だけでよい。nix-darwin は初回の
`nix run` で導入され、Homebrew は `nix-homebrew` が導入する。Git は macOS の
Command Line Tools に含まれる。

1. Command Line Tools をインストールする。

   ```sh
   xcode-select --install
   ```

2. Determinate Nix をインストールし、ターミナルを再起動する。

   ```sh
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   ```

   Determinate Nix は Flakes が最初から有効で、macOS アップデート後の復旧や
   アンインストールにも対応している。この構成では Determinate Nix と競合しないよう
   nix-darwin 側の Nix 管理を `nix.enable = false` にしている。

3. このリポジトリを取得する。

   ```sh
   mkdir -p ~/git
   git clone https://github.com/TakabayaP/dotfiles.git ~/git/dotfiles
   cd ~/git/dotfiles
   ```

4. Flake の依存関係をロックする。

   ```sh
   nix flake lock
   ```

5. 対象端末の構成を適用する。

   LiveWallpaper のソースは private repository なので、先にログインユーザーの
   SSH 鍵で Flake inputs を Nix store へ取得する。

   ```sh
   nix flake archive --no-update-lock-file .
   ```

   MacBook Air:

   ```sh
   sudo nix run nix-darwin/master#darwin-rebuild -- \
     switch --flake .#macbook-air
   ```

   MacBook Pro:

   ```sh
   sudo nix run nix-darwin/master#darwin-rebuild -- \
     switch --flake .#macbook-pro
   ```

2回目以降は次のコマンドで適用する。

```sh
nix flake archive --no-update-lock-file .
sudo darwin-rebuild switch --flake .#macbook-air
```

既存の Homebrew がある場合は、初回適用時に `nix-homebrew` が移行する。

### macOS の管理方針

- GUI アプリケーション本体は Homebrew cask で管理する。
- GUI アプリケーションの設定ファイルは Home Manager で管理する。
- Home Manager の `programs.<name>.package` は、Homebrew cask とアプリ本体が
  重複しないよう `null` にする。
- GUI アプリケーションを Nix package と Homebrew cask の両方から導入しない。

Keykun だけは個人用の SwiftPM アプリなので、fork の `main` を Flake input として
Nix package にしている。`flake.lock` に取得時のコミットが固定されるため、別の Mac
でも同じソースから再現できる。

Keykun の package だけを先にビルドする場合:

```sh
nix build .#keykun
```

通常は darwin-rebuild が必要な package build と Home Manager のインストールをまとめて
行う。

```sh
nix flake archive --no-update-lock-file .
sudo darwin-rebuild switch --flake .#macbook-pro
```

これにより `~/Applications/Keykun.app`、現在の入力切り替え/Slack Esc 設定、ログイン時の
起動設定が用意される。Nix のビルド自体は通常の Nix ビルダーで行われ、`sudo` は
darwin-rebuild のシステム適用にだけ使う。

macOS の Accessibility 権限は TCC の仕様上、通常の Nix 設定からユーザー許可を直接
付与できない。初回だけ次を実行し、システム設定の「プライバシーとセキュリティ」>
「アクセシビリティ」で `~/Applications/Keykun.app` を許可する。

```sh
open "$HOME/Applications/Keykun.app"
```

## `.env` ファイル

`settings.env` と `secrets.env` は旧 `Makefile` の Linux 向け設定であり、
現在の macOS/Nix セットアップでは使用しない。`*.env` は Git の管理対象外なので、
端末固有の秘密情報をリポジトリへコミットしないこと。
