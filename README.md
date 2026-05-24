# TimeAhead

macOS のシステム時刻を変更せず、メニューバーに「現在時刻 + 任意分」の時計を表示する小さな常駐アプリです。

## 概要
- `NSStatusBar` 常駐アプリとして動作
- 表示時刻は `Date() + offsetMinutes * 60`
- オフセット分はメニュー UI から変更可能
- ログイン時自動起動 (LaunchAgent)

## 動作環境
- OS: macOS 13.0 以上
- CPU: Apple Silicon (`arm64`)
- 配布済みバイナリ (`offset-clock` / `build/TimeAhead.app` / `dist/*.zip`) は `arm64` 向け
- Intel Mac で使う場合は、対象Mac上でソースからビルドして実行
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
swiftc "OffsetClock.swift" -o "offset-clock"
```

## `.app` 形式でビルド
```bash
./scripts/build_app.sh
```

- 生成物: `build/TimeAhead.app`
- アイコン: `assets/TimeAhead.icns` が存在する場合、`Contents/Resources/TimeAhead.icns` として組み込まれます。
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

PDF を再生成する場合:
```bash
python3 /Users/masatomo/.codex/plugins/cache/openai-bundled/latex/0.2.0/scripts/compile_latex.py \
  "$PWD/docs/TimeAhead_User_Manual.tex" \
  --compiler tectonic
```

## 他のMacへのインストール
1. `TimeAhead.dmg` を対象Macにコピーして開く
2. `TimeAhead.app` を `Applications` にドラッグ
3. `Applications/TimeAhead.app` を起動
4. 初回は Gatekeeper 警告が出る場合があるため、右クリック→「開く」で許可

## 起動・再起動
```bash
uid=$(id -u)
launchctl bootout gui/$uid/local.offsetclock 2>/dev/null || true
launchctl bootstrap gui/$uid "/Users/masatomo/Library/LaunchAgents/local.offsetclock.plist"
launchctl kickstart -kp gui/$uid/local.offsetclock
```

## 状態確認
```bash
uid=$(id -u)
launchctl print gui/$uid/local.offsetclock | rg "state =|pid =|job state"
pgrep -fl "offset-clock"
```

## 停止
```bash
uid=$(id -u)
launchctl bootout gui/$uid/local.offsetclock
```

## 既知制約
- macOS 26.2 環境では、標準の右上時計 (`ControlCenter` 側) を `defaults` で非表示化しても再表示される挙動を確認しています。
- そのため現状は「標準時計を完全置換」ではなく「追加のオフセット時計表示」として運用します。

## 削除
```bash
uid=$(id -u)
launchctl bootout gui/$uid/local.offsetclock 2>/dev/null || true
rm -f "/Users/masatomo/Library/LaunchAgents/local.offsetclock.plist"
rm -f "offset-clock"
```
