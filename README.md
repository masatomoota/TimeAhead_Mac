# TimeAhead

macOS のシステム時刻を変更せず、メニューバーに「現在時刻 + 任意分」の時計を表示する小さな常駐アプリです。

## 概要
- `NSStatusBar` 常駐アプリとして動作
- 表示時刻は `Date() + offsetMinutes * 60`
- オフセット分はメニュー UI から変更可能
- ログイン時自動起動 (LaunchAgent)

## ファイル構成
- ソース: `/Users/masatomo/_git_repository/TimeAhead/OffsetClock.swift`
- バイナリ: `/Users/masatomo/_git_repository/TimeAhead/offset-clock`
- LaunchAgent: `/Users/masatomo/Library/LaunchAgents/local.offsetclock.plist`
- 引き継ぎ詳細: `/Users/masatomo/_git_repository/TimeAhead/HANDOVER.md`

## 使い方
メニューバーの TimeAhead をクリックしてオフセットを変更します。

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
swiftc "/Users/masatomo/_git_repository/TimeAhead/OffsetClock.swift" -o "/Users/masatomo/_git_repository/TimeAhead/offset-clock"
```

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
rm -f "/Users/masatomo/_git_repository/TimeAhead/offset-clock"
```
