import AppKit
import Foundation

final class OffsetClockApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu?
    private var timer: Timer?
    private var pendingSingleClickAction: DispatchWorkItem?
    private var lastRenderedClockTitle: String?
    private static let offsetDefaultsKey = "offsetMinutes"
    private let allowedOffsetRange = -1440...1440
    private let presetOffsets = [0, 5, 10, 15, 30, 60]
    private let defaultOffsetMinutes: Int
    private let promptOnLaunch: Bool
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

    init(defaultOffsetMinutes: Int, promptOnLaunch: Bool) {
        self.defaultOffsetMinutes = defaultOffsetMinutes
        self.promptOnLaunch = promptOnLaunch
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
        configureStatusItemButton()
        buildMenu()
        updateClock()
        startClockTimer()

        if promptOnLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.promptCustomOffset()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        pendingSingleClickAction?.cancel()
        pendingSingleClickAction = nil
        timer?.invalidate()
        timer = nil
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        promptCustomOffset()
        return true
    }

    @objc private func updateClock() {
        guard let button = statusItem?.button else {
            return
        }
        let offsetSeconds = TimeInterval(offsetMinutes * 60)
        let shifted = Date().addingTimeInterval(offsetSeconds)
        let nextTitle = formatter.string(from: shifted)
        guard nextTitle != lastRenderedClockTitle || button.title != nextTitle else {
            return
        }
        button.title = nextTitle
        lastRenderedClockTitle = nextTitle
    }

    @objc private func selectPreset(_ sender: NSMenuItem) {
        setOffsetMinutes(sender.tag)
    }

    @objc private func selectDefaultOffset() {
        setOffsetMinutes(defaultOffsetMinutes)
    }

    @objc private func promptCustomOffset() {
        pendingSingleClickAction?.cancel()
        pendingSingleClickAction = nil
        runWithForegroundInteraction {
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
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func setOffsetMinutes(_ value: Int) {
        guard allowedOffsetRange.contains(value) else {
            return
        }
        guard value != offsetMinutes else {
            return
        }
        offsetMinutes = value
    }

    private func startClockTimer() {
        timer?.invalidate()
        let clockTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateClock()
        }
        clockTimer.tolerance = 0.2
        timer = clockTimer
        RunLoop.main.add(clockTimer, forMode: .common)
    }

    private func buildMenu() {
        let statusMenu = NSMenu()
        let offsetItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        offsetItem.isEnabled = false
        statusMenu.addItem(offsetItem)
        currentOffsetItem = offsetItem

        statusMenu.addItem(NSMenuItem.separator())

        for minutes in presetOffsets {
            let item = NSMenuItem(title: formattedMenuTitle(for: minutes),
                                  action: #selector(selectPreset(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.tag = minutes
            statusMenu.addItem(item)
            presetItems[minutes] = item
        }

        let customItem = NSMenuItem(title: "Custom...", action: #selector(promptCustomOffset), keyEquivalent: "")
        customItem.target = self
        statusMenu.addItem(customItem)

        let defaultItem = NSMenuItem(title: "Use Default (\(formattedOffset(defaultOffsetMinutes)) min)",
                                     action: #selector(selectDefaultOffset),
                                     keyEquivalent: "")
        defaultItem.target = self
        statusMenu.addItem(defaultItem)

        statusMenu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit Offset Clock", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)

        menu = statusMenu
        refreshMenuState()
    }

    private func configureStatusItemButton() {
        guard let button = statusItem.button else {
            return
        }
        button.target = self
        button.action = #selector(handleStatusItemClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else {
            popUpMenu()
            return
        }

        if event.type == .rightMouseUp {
            cancelPendingSingleClick()
            promptCustomOffset()
            return
        }

        if event.clickCount >= 2 {
            cancelPendingSingleClick()
            promptCustomOffset()
            return
        }

        scheduleSingleClickMenu()
    }

    private func scheduleSingleClickMenu() {
        cancelPendingSingleClick()
        let workItem = DispatchWorkItem { [weak self] in
            self?.popUpMenu()
        }
        pendingSingleClickAction = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + NSEvent.doubleClickInterval, execute: workItem)
    }

    private func cancelPendingSingleClick() {
        pendingSingleClickAction?.cancel()
        pendingSingleClickAction = nil
    }

    private func popUpMenu() {
        cancelPendingSingleClick()
        guard let menu, let button = statusItem.button else {
            return
        }
        let origin = NSPoint(x: 0, y: button.bounds.maxY + 2)
        menu.popUp(positioning: nil, at: origin, in: button)
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
        runWithForegroundInteraction {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Invalid offset"
            alert.informativeText = "Please enter an integer between -1440 and 1440."
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
        }
    }

    private func runWithForegroundInteraction(_ block: () -> Void) {
        let previousPolicy = NSApp.activationPolicy()
        let switchedToRegular = previousPolicy != .regular
        if switchedToRegular {
            _ = NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
        block()
        if switchedToRegular {
            _ = NSApp.setActivationPolicy(previousPolicy)
        }
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

func readPromptOnLaunch(from args: [String]) -> Bool {
    if args.contains("--prompt-on-launch") {
        return true
    }
    if args.contains("--no-prompt-on-launch") {
        return false
    }

    // Show the prompt by default when launched as an app bundle.
    let packageType = Bundle.main.object(forInfoDictionaryKey: "CFBundlePackageType") as? String
    return packageType == "APPL"
}

let app = NSApplication.shared
let offsetMinutes = readDefaultOffsetMinutes(from: CommandLine.arguments)
let promptOnLaunch = readPromptOnLaunch(from: CommandLine.arguments)
let delegate = OffsetClockApp(defaultOffsetMinutes: offsetMinutes, promptOnLaunch: promptOnLaunch)
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
