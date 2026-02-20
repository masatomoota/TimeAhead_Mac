import AppKit
import Foundation

final class OffsetClockApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private static let offsetDefaultsKey = "offsetMinutes"
    private let allowedOffsetRange = -1440...1440
    private let presetOffsets = [0, 5, 10, 15, 30, 60]
    private let defaultOffsetMinutes: Int
    private var currentOffsetItem: NSMenuItem?
    private var presetItems: [Int: NSMenuItem] = [:]
    private var offsetMinutes: Int {
        didSet {
            UserDefaults.standard.set(offsetMinutes, forKey: Self.offsetDefaultsKey)
            updateClock()
            refreshMenuState()
        }
    }
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.autoupdatingCurrent
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    init(defaultOffsetMinutes: Int) {
        self.defaultOffsetMinutes = defaultOffsetMinutes
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.offsetDefaultsKey) != nil {
            self.offsetMinutes = defaults.integer(forKey: Self.offsetDefaultsKey)
        } else {
            self.offsetMinutes = defaultOffsetMinutes
        }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        buildMenu()
        updateClock()

        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(updateClock),
                                     userInfo: nil,
                                     repeats: true)
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
    }

    @objc private func updateClock() {
        let offsetSeconds = TimeInterval(offsetMinutes * 60)
        let shifted = Date().addingTimeInterval(offsetSeconds)
        statusItem.button?.title = formatter.string(from: shifted)
    }

    @objc private func selectPreset(_ sender: NSMenuItem) {
        setOffsetMinutes(sender.tag)
    }

    @objc private func selectDefaultOffset() {
        setOffsetMinutes(defaultOffsetMinutes)
    }

    @objc private func promptCustomOffset() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Set Clock Offset (minutes)"
        alert.informativeText = "Positive advances time, negative delays it. Range: -1440 to 1440."
        let input = NSTextField(string: String(offsetMinutes))
        input.placeholderString = "e.g. 10"
        input.frame = NSRect(x: 0, y: 0, width: 220, height: 24)
        alert.accessoryView = input
        alert.addButton(withTitle: "Apply")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let trimmed = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let minutes = Int(trimmed), allowedOffsetRange.contains(minutes) else {
            showValidationError()
            return
        }
        setOffsetMinutes(minutes)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func setOffsetMinutes(_ value: Int) {
        guard allowedOffsetRange.contains(value) else {
            return
        }
        offsetMinutes = value
    }

    private func buildMenu() {
        let menu = NSMenu()
        let offsetItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        offsetItem.isEnabled = false
        menu.addItem(offsetItem)
        currentOffsetItem = offsetItem

        menu.addItem(NSMenuItem.separator())

        for minutes in presetOffsets {
            let item = NSMenuItem(title: formattedMenuTitle(for: minutes),
                                  action: #selector(selectPreset(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.tag = minutes
            menu.addItem(item)
            presetItems[minutes] = item
        }

        let customItem = NSMenuItem(title: "Custom...", action: #selector(promptCustomOffset), keyEquivalent: "")
        customItem.target = self
        menu.addItem(customItem)

        let defaultItem = NSMenuItem(title: "Use Default (\(formattedOffset(defaultOffsetMinutes)) min)",
                                     action: #selector(selectDefaultOffset),
                                     keyEquivalent: "")
        defaultItem.target = self
        menu.addItem(defaultItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit Offset Clock", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        refreshMenuState()
    }

    private func refreshMenuState() {
        currentOffsetItem?.title = "Offset: \(formattedOffset(offsetMinutes)) min"
        for (value, item) in presetItems {
            item.state = value == offsetMinutes ? .on : .off
        }
    }

    private func formattedOffset(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    private func formattedMenuTitle(for value: Int) -> String {
        if value == 0 {
            return "0 min (real time)"
        }
        return "\(formattedOffset(value)) min"
    }

    private func showValidationError() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Invalid offset"
        alert.informativeText = "Please enter an integer between -1440 and 1440."
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
    }
}

func readDefaultOffsetMinutes(from args: [String]) -> Int {
    let defaultValue = 10
    guard let index = args.firstIndex(of: "--offset-minutes"), index + 1 < args.count else {
        return defaultValue
    }
    guard let value = Int(args[index + 1]) else {
        return defaultValue
    }
    return min(1440, max(-1440, value))
}

let app = NSApplication.shared
let offsetMinutes = readDefaultOffsetMinutes(from: CommandLine.arguments)
let delegate = OffsetClockApp(defaultOffsetMinutes: offsetMinutes)
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
