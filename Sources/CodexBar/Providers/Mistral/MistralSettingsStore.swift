import CodexBarCore
import Foundation

extension SettingsStore {
    var mistralAPIToken: String {
        get { self.configSnapshot.providerConfig(for: .mistral)?.sanitizedAPIKey ?? "" }
        set {
            self.updateProviderConfig(provider: .mistral) { entry in
                entry.apiKey = self.normalizedConfigValue(newValue)
            }
            self.logSecretUpdate(provider: .mistral, field: "apiKey", value: newValue)
        }
    }
}
