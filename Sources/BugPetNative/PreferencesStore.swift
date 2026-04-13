import Foundation

@MainActor
final class PreferencesStore {
    private let defaults = UserDefaults.standard
    private let languageKey = "bugpet.native.language"
    private let selectedPetKey = "bugpet.native.selected-pet"
    private let panelThemeKey = "bugpet.native.panel-theme"
    private let showsStatusBarKey = "bugpet.native.show-status-bar"
    private let petDisplaySizeKey = "bugpet.native.pet-display-size"
    private let todoItemsKey = "bugpet.native.todo-items.v1"
    private let selectedWhitelistIDsKey = "bugpet.native.selected-whitelist-ids.v1"
    private let customWhitelistAppsKey = "bugpet.native.custom-whitelist-apps.v1"

    static let presetWhitelistApps: [WhitelistApp] = [
        WhitelistApp(name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", isPreset: true),
        WhitelistApp(name: "Visual Studio Code", bundleIdentifier: "com.microsoft.VSCode", isPreset: true),
        WhitelistApp(name: "Cursor", isPreset: true),
        WhitelistApp(name: "TRAE", isPreset: true),
        WhitelistApp(name: "Codex", isPreset: true),
        WhitelistApp(name: "Zed", isPreset: true),
        WhitelistApp(name: "Android Studio", isPreset: true),
        WhitelistApp(name: "IntelliJ IDEA", isPreset: true),
        WhitelistApp(name: "WebStorm", isPreset: true),
        WhitelistApp(name: "Sublime Text", isPreset: true),
        WhitelistApp(name: "Terminal", bundleIdentifier: "com.apple.Terminal", isPreset: true),
        WhitelistApp(name: "iTerm2", bundleIdentifier: "com.googlecode.iterm2", isPreset: true),
        WhitelistApp(name: "Ghostty", isPreset: true),
        WhitelistApp(name: "Warp", isPreset: true),
        WhitelistApp(name: "WezTerm", isPreset: true),
        WhitelistApp(name: "Alacritty", isPreset: true),
        WhitelistApp(name: "Kitty", isPreset: true),
        WhitelistApp(name: "Hyper", isPreset: true),
    ]

    var language: AppLanguage {
        get {
            guard let rawValue = defaults.string(forKey: languageKey), let language = AppLanguage(rawValue: rawValue) else {
                return .zh
            }

            return language
        }
        set {
            defaults.set(newValue.rawValue, forKey: languageKey)
        }
    }

    var selectedPet: PetKind {
        get {
            guard let rawValue = defaults.string(forKey: selectedPetKey), let pet = PetKind(rawValue: rawValue) else {
                return .bugcat
            }

            return pet
        }
        set {
            defaults.set(newValue.rawValue, forKey: selectedPetKey)
        }
    }

    var panelTheme: PanelTheme {
        get {
            guard let rawValue = defaults.string(forKey: panelThemeKey), let theme = PanelTheme(rawValue: rawValue) else {
                return .system
            }

            return theme
        }
        set {
            defaults.set(newValue.rawValue, forKey: panelThemeKey)
        }
    }

    var systemResolvedTheme: PanelTheme {
        let globalDefaults = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        if let style = globalDefaults?["AppleInterfaceStyle"] as? String,
           style.caseInsensitiveCompare("dark") == .orderedSame {
            return .dark
        }

        return .light
    }

    var showsStatusBar: Bool {
        get {
            if defaults.object(forKey: showsStatusBarKey) == nil {
                return true
            }

            return defaults.bool(forKey: showsStatusBarKey)
        }
        set {
            defaults.set(newValue, forKey: showsStatusBarKey)
        }
    }

    var petDisplaySize: PetDisplaySize {
        get {
            guard let rawValue = defaults.string(forKey: petDisplaySizeKey),
                  let size = PetDisplaySize(rawValue: rawValue) else {
                return .medium
            }

            return size
        }
        set {
            defaults.set(newValue.rawValue, forKey: petDisplaySizeKey)
        }
    }

    var todos: [TodoItem] {
        get {
            decode([TodoItem].self, forKey: todoItemsKey) ?? []
        }
        set {
            encode(newValue, forKey: todoItemsKey)
        }
    }

    var customWhitelistApps: [WhitelistApp] {
        get {
            decode([WhitelistApp].self, forKey: customWhitelistAppsKey) ?? []
        }
        set {
            encode(newValue, forKey: customWhitelistAppsKey)
        }
    }

    var selectedWhitelistIDs: Set<String> {
        get {
            if let ids = decode([String].self, forKey: selectedWhitelistIDsKey) {
                return Set(ids)
            }

            return Set(Self.presetWhitelistApps.map(\.id))
        }
        set {
            encode(Array(newValue).sorted(), forKey: selectedWhitelistIDsKey)
        }
    }

    var availableWhitelistApps: [WhitelistApp] {
        let combined = Self.presetWhitelistApps + customWhitelistApps
        var seen: Set<String> = []
        return combined.filter { app in
            seen.insert(app.id).inserted
        }
    }

    var selectedWhitelistApps: [WhitelistApp] {
        let selectedIDs = selectedWhitelistIDs
        return availableWhitelistApps.filter { selectedIDs.contains($0.id) }
    }

    func setWhitelistSelection(_ ids: Set<String>) {
        selectedWhitelistIDs = ids
    }

    func addCustomWhitelistApp(_ app: WhitelistApp) {
        if let preset = Self.presetWhitelistApps.first(where: { $0.id == app.id }) {
            var ids = selectedWhitelistIDs
            ids.insert(preset.id)
            selectedWhitelistIDs = ids
            return
        }

        var apps = customWhitelistApps
        if !apps.contains(where: { $0.id == app.id }) {
            apps.append(WhitelistApp(name: app.name, bundleIdentifier: app.bundleIdentifier, isPreset: false))
            customWhitelistApps = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        var ids = selectedWhitelistIDs
        ids.insert(app.id)
        selectedWhitelistIDs = ids
    }

    func removeCustomWhitelistApp(id: String) {
        customWhitelistApps.removeAll { $0.id == id }
        var ids = selectedWhitelistIDs
        ids.remove(id)
        selectedWhitelistIDs = ids
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
        } catch {
            NSLog("Failed to persist preferences for key \(key): \(error.localizedDescription)")
        }
    }
}
