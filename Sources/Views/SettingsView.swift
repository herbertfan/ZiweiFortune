import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var settings = SettingsStore.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L(StringKey.settings))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(L(StringKey.close)) {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            Form {
                Section(L(StringKey.language)) {
                    Picker(L(StringKey.language), selection: $localization.storedLanguage) {
                        Text(AppLanguage.system.displayName).tag(AppLanguage.system.rawValue)
                        Text(AppLanguage.traditionalChinese.displayName).tag(AppLanguage.traditionalChinese.rawValue)
                        Text(AppLanguage.simplifiedChinese.displayName).tag(AppLanguage.simplifiedChinese.rawValue)
                        Text(AppLanguage.japanese.displayName).tag(AppLanguage.japanese.rawValue)
                    }
                    .pickerStyle(.radioGroup)
                }

                Section(L("appearance")) {
                    Toggle(L("dark_mode"), isOn: $settings.darkModeEnabled)
                }
            }
            .formStyle(.grouped)
            .padding()

            Spacer()
        }
        .frame(width: 400, height: 350)
    }
}
