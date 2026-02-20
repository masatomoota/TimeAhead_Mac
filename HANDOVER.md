# TimeAhead 引き継ぎメモ

最終更新: 2026-02-20

## 1. 目的
- macOS のシステム時刻を変更せず、メニューバー上に「現在時刻 + 任意分」の時計を表示する。
- 右上時計で「何分進めるか」を UI から変更可能にする。

## 2. 実装済み成果物

### 2.1 ソースコード
- `/Users/masatomo/_git_repository/TimeAhead/OffsetClock.swift`

### 2.2 実行バイナリ
- `/Users/masatomo/_git_repository/TimeAhead/offset-clock`

### 2.3 自動起動設定 (LaunchAgent)
- `/Users/masatomo/Library/LaunchAgents/local.offsetclock.plist`
- `ProgramArguments` は以下:
  - `/Users/masatomo/_git_repository/TimeAhead/offset-clock`
  - `--offset-minutes`
  - `10`

## 3. 現在の動作仕様

### 3.1 メニューバー表示
- `NSStatusBar` に常駐し、表示文字列は `Date() + offsetMinutes * 60` の時刻。
- 1 秒ごとに更新。

### 3.2 オフセット変更 UI
メニューバーのアプリをクリックすると以下が出る:
- 現在オフセット表示 (`Offset: +10 min` など)
- プリセット選択:
  - `0 min (real time)`
  - `+5 min`
  - `+10 min`
  - `+15 min`
  - `+30 min`
  - `+60 min`
- `Custom...`:
  - 任意分入力ダイアログ
  - 範囲: `-1440` 〜 `1440`
- `Use Default (+10 min)`
- `Quit Offset Clock`

### 3.3 設定保持
- 選択したオフセット分は `UserDefaults` (`offsetMinutes`) に保存。
- 再起動後も保存値を優先して復元。
- 保存値がなければ `--offset-minutes` 引数値 (現在は `10`) を初期値として使用。

## 4. 実行・管理コマンド

### 4.1 ビルド
```bash
swiftc "/Users/masatomo/_git_repository/TimeAhead/OffsetClock.swift" -o "/Users/masatomo/_git_repository/TimeAhead/offset-clock"
```

### 4.2 LaunchAgent 再読込
```bash
uid=$(id -u)
launchctl bootout gui/$uid/local.offsetclock 2>/dev/null || true
launchctl bootstrap gui/$uid "/Users/masatomo/Library/LaunchAgents/local.offsetclock.plist"
launchctl kickstart -kp gui/$uid/local.offsetclock
```

### 4.3 状態確認
```bash
uid=$(id -u)
launchctl print gui/$uid/local.offsetclock | rg "state =|pid =|job state"
pgrep -fl "offset-clock"
```

## 5. 既知制約 (重要)
- macOS 26.2 環境で、標準の右上時計 (`ControlCenter` 側) を `defaults` で非表示化しても、`ControlCenter` 再起動時に表示フラグが戻る挙動を確認。
- そのため現時点では「標準時計の完全置換」ではなく「追加のオフセット時計表示」として成立させている。

補足:
- 一時的に標準時計表示を崩す目的で以下を試行済み:
```bash
defaults write com.apple.menuextra.clock DateFormat -string "   "
killall ControlCenter
```
- 効果は環境依存。

## 6. これまでの変更履歴 (要点)
1. `OffsetClock.swift` を作成し、+10分固定の常駐時計を実装。
2. `local.offsetclock.plist` を作成し、ログイン時起動を設定。
3. UI 改修:
   - プリセット + カスタム入力 + デフォルト復帰 + 選択状態表示。
   - UserDefaults 保存を追加。
4. 成果物を以下へ移動:
   - 旧: `/Users/masatomo/Library/Application Support/OffsetClock/`
   - 新: `/Users/masatomo/_git_repository/TimeAhead/`
5. LaunchAgent の実行パスを新ディレクトリへ更新。

## 7. 他チャットへ渡すときに伝えるべきポイント
- 目的: システム時刻変更なしでメニューバーに時間オフセット表示。
- 主ファイル:
  - `/Users/masatomo/_git_repository/TimeAhead/OffsetClock.swift`
  - `/Users/masatomo/Library/LaunchAgents/local.offsetclock.plist`
- 既知制約: macOS 26.2 で標準時計は強制再表示される可能性が高い。
- 優先タスク候補:
  1. 標準時計との見た目干渉を減らす UI 改善。
  2. 設定画面化 (オフセット・時刻フォーマット・表示位置)。
  3. コードをアプリパッケージ化 (署名/常駐管理) して保守性を上げる。

## 8. 完全停止/削除手順
```bash
uid=$(id -u)
launchctl bootout gui/$uid/local.offsetclock 2>/dev/null || true
rm -f "/Users/masatomo/Library/LaunchAgents/local.offsetclock.plist"
rm -f "/Users/masatomo/_git_repository/TimeAhead/offset-clock"
# ソースも不要なら
rm -f "/Users/masatomo/_git_repository/TimeAhead/OffsetClock.swift"
```

## 9. 復旧手順 (最短)
1. `OffsetClock.swift` をビルド。
2. `local.offsetclock.plist` のパスが正しいことを確認。
3. `launchctl bootstrap` + `kickstart` で再起動。

