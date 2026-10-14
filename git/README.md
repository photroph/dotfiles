# Git 設定

`~/.gitconfig` は `~/dotfiles/.gitconfig` への symlink を使う。
共通設定は `.gitconfig`、仕事・私物などマシン固有の設定は
`.gitconfig.local` に置く。`.gitconfig.local` は Git 管理外で、
共通設定の最後で読み込まれるため、同じ単一値の設定を上書きできる。

## 新しいマシンでの設定

リポジトリを `~/dotfiles` に置き、以下を実行する。
既存の `~/.gitconfig` が通常のファイルの場合は、内容を移してからリンクする。

```sh
ln -s ~/dotfiles/.gitconfig ~/.gitconfig
cp -n ~/dotfiles/.gitconfig.local.example ~/dotfiles/.gitconfig.local
git config --file ~/dotfiles/.gitconfig.local user.name "自分の名前"
git config --file ~/dotfiles/.gitconfig.local user.email "マシンで使うメールアドレス"
```

すでに symlink があるマシンでは `ln -s` は不要。
`.gitconfig.local` がなくても、共通設定は読み込まれる。

## 日々の変更

固有設定は `.gitconfig.local` を直接編集するか、上記の `--file` で変更する。
`git config --global` は symlink 先の共通設定を変更するため、
名前やメールアドレスの変更には使わない。

読み込み元は以下で確認できる。

```sh
git config --global --includes --show-origin --get-regexp '^user\.'
```

## 将来 mise を導入するとき

設定ファイルの分離は Git の include で完結しており、mise には依存しない。
mise bootstrap には `~/dotfiles/.gitconfig` → `~/.gitconfig` のリンクを管理させればよい。
`~/dotfiles` にリポジトリを置く構成では、include と `.gitconfig.local` はそのまま使える。
マシン固有のファイルは各マシンで保持する。リポジトリの配置を変える場合は、
テーマ設定とローカル設定の include パスも変更する。
