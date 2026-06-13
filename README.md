# TimeAhead

**日本語** | [English](README.en.md)

macOS のシステム時刻を変更せず、メニューバーに「現在時刻 + 任意分」の時計を表示する小さな常駐アプリです。

![TimeAhead をメニューバーに表示した様子](assets/screenshot-menubar.png)

## 概要
- `NSStatusBar` 常駐アプリとして動作
- 表示時刻は `Date() + offsetMinutes * 60`
- オフセット分はメニュー UI から変更可能
- ログイン時自動起動 (LaunchAgent)

## 動作環境
- OS: macOS 13.0 以上
- CPU: Apple Silicon (`arm64`) / Intel (`x86_64`) 両対応
- 配布バイナリ（[Releases](https://github.com/masatomoota/TimeAhead_Mac/releases) の `*.zip`）は **ユニバーサルバイナリ**（`arm64` + `x86_64`）
- ソースビルドに必要: Xcode Command Line Tools (`swiftc` が利用可能なこと)
- メニューバー常駐アプリのため、GUI セッション (Aqua) での実行が前提

## ファイル構成
- ソース: `OffsetClock.swift`
- 旧式の単体バイナリ: `offset-clock`
- `.app` ビルドスクリプト: `scripts/build_app.sh`
- `.dmg` ビルドスクリプト: `scripts/build_dmg.sh`
- アプリアイコン元画像: `assets/TimeAheadIcon.png`
- macOS アイコン: `assets/TimeAhead.icns`
- 人間向けマニュアル: `docs/TimeAhead_User_Manual.pdf`
- 開発引き継ぎ詳細: `HANDOVER.md`

## 使い方
メニューバーの TimeAhead をクリックしてオフセットを変更します。
- `Applications/TimeAhead.app` を開いて起動した場合は、起動直後にオフセット入力ポップアップを表示
- 起動中に `Applications/TimeAhead.app` を再度開いた場合も、オフセット入力ポップアップを表示
- 左クリック: メニューを開く
- 右クリック: オフセット入力ポップアップを直接開く
- 左ダブルクリック: オフセット入力ポップアップを直接開く

### プリセット
- `0 min (real time)`
- `+5 min`
- `+10 min`
- `+15 min`
- `+30 min`
- `+60 min`

### カスタム入力
- `Custom...` から任意分を入力
- 許容範囲: `-1440` 〜 `1440`

### デフォルトへ戻す
- `Use Default (+10 min)`

## ビルド
```bash
# 現在のアーキ向けの簡易ビルド
swiftc "OffsetClock.swift" -o "offset-clock"
```

ユニバーサルバイナリ（`arm64` + `x86_64`）を手動でビルドする場合:
```bash
swiftc OffsetClock.swift -target arm64-apple-macosx13.0  -o offset-clock-arm64
swiftc OffsetClock.swift -target x86_64-apple-macosx13.0 -o offset-clock-x86_64
lipo -create offset-clock-arm64 offset-clock-x86_64 -output offset-clock
```

## `.app` 形式でビルド
```bash
./scripts/build_app.sh
```

- 生成物: `build/TimeAhead.app`（既定で **ユニバーサルバイナリ** `arm64` + `x86_64`）
- アイコン: `assets/TimeAhead.icns` が存在する場合、`Contents/Resources/TimeAhead.icns` として組み込まれます。
- 特定アーキのみでビルドする場合は `ARCHS` を指定:
```bash
ARCHS="arm64" ./scripts/build_app.sh
```
- 署名IDを指定する場合:
```bash
SIGN_IDENTITY="Developer ID Application: YOUR_NAME (TEAM_ID)" ./scripts/build_app.sh
```

## `.dmg` 形式で配布用にビルド
```bash
./scripts/build_dmg.sh
```

- 生成物: `build/TimeAhead.dmg`
- DMGには `TimeAhead.app` と `Applications` へのショートカットが入ります。

## マニュアル
人間向けの図解マニュアルは以下です。

- PDF: `docs/TimeAhead_User_Manual.pdf`
- LaTeX ソース: `docs/TimeAhead_User_Manual.tex`

PDF を再生成する場合（[Tectonic](https://tectonic-typesetting.github.io/) を使用）:
```bash
tectonic docs/TimeAhead_User_Manual.tex
```

## ダウンロード（ビルド済みバイナリ）
ビルド済みのユニバーサルバイナリ（`arm64` + `x86_64`）は [Releases](https://github.com/masatomoota/TimeAhead_Mac/releases) ページから入手できます。Apple Silicon / Intel どちらの Mac でも動作します。

- `TimeAhead-app-universal.zip` … メニューバー常駐アプリ (`TimeAhead.app`)
- `offset-clock-universal.zip` … 旧式の単体 CLI バイナリ

> **注意:** 配布バイナリは Apple Developer ID 署名・notarization を行っていない（ad-hoc 署名）ため、初回起動時に Gatekeeper の警告が出ます。下記「Gatekeeper 警告の回避」を参照してください。

## 他のMacへのインストール
1. [Releases](https://github.com/masatomoota/TimeAhead_Mac/releases) から `TimeAhead-app-universal.zip` をダウンロードして展開
2. `TimeAhead.app` を `Applications` にドラッグ
3. `Applications/TimeAhead.app` を起動

### Gatekeeper 警告の回避
未署名アプリのため、ダブルクリックすると「開発元を検証できないため開けません」と表示されます。以下のいずれかで許可してください。

**方法A: 右クリックで開く（推奨・初回のみ）**
1. `Applications/TimeAhead.app` を **右クリック（Control+クリック）→「開く」**
2. 確認ダイアログで再度「開く」を選択

**方法B: システム設定から許可**
1. 一度ダブルクリックして警告を閉じる
2. 「システム設定 → プライバシーとセキュリティ」を開く
3. 下部の「"TimeAhead" は開発元を確認できないため…」の横の **「このまま開く」** をクリック

**方法C: 隔離属性をターミナルで除去**
```bash
xattr -dr com.apple.quarantine /Applications/TimeAhead.app
```

## 起動・再起動
```bash
uid=$(id -u)
launchctl bootout gui/$uid/com.masatomoota.timeahead 2>/dev/null || true
launchctl bootstrap gui/$uid "$HOME/Library/LaunchAgents/com.masatomoota.timeahead.plist"
launchctl kickstart -kp gui/$uid/com.masatomoota.timeahead
```

## 状態確認
```bash
uid=$(id -u)
launchctl print gui/$uid/com.masatomoota.timeahead | rg "state =|pid =|program =|arguments ="
pgrep -fl "TimeAhead.app/Contents/MacOS/TimeAhead"
```

## 停止
```bash
uid=$(id -u)
launchctl bootout gui/$uid/com.masatomoota.timeahead
```

## 既知制約
- macOS 26.2 環境では、標準の右上時計 (`ControlCenter` 側) を `defaults` で非表示化しても再表示される挙動を確認しています。
- そのため現状は「標準時計を完全置換」ではなく「追加のオフセット時計表示」として運用します。

## 削除
```bash
uid=$(id -u)
launchctl bootout gui/$uid/com.masatomoota.timeahead 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.masatomoota.timeahead.plist"
rm -rf "/Applications/TimeAhead.app"
rm -f "offset-clock"
```
