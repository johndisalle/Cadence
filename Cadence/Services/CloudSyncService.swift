import Foundation
import SwiftData
import Combine

@Observable
final class CloudSyncService {
    static let shared = CloudSyncService()

    var isSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnabled")
            NotificationCenter.default.post(name: .iCloudSyncDidChange, object: nil)
        }
    }

    var syncStatus: SyncStatus = .idle
    var lastSyncDate: Date?

    enum SyncStatus: String {
        case idle = "Ready"
        case syncing = "Syncing..."
        case synced = "Up to date"
        case error = "Sync error"
        case disabled = "Off"
    }

    var syncStatusIcon: String {
        switch syncStatus {
        case .idle: return "arrow.triangle.2.circlepath"
        case .syncing: return "arrow.triangle.2.circlepath.circle.fill"
        case .synced: return "checkmark.icloud.fill"
        case .error: return "exclamationmark.icloud.fill"
        case .disabled: return "icloud.slash"
        }
    }

    private init() {
        if !isSyncEnabled {
            syncStatus = .disabled
        }
    }

    /// Creates the appropriate ModelConfiguration based on the current sync preference.
    func makeModelConfiguration(schema: Schema) -> ModelConfiguration {
        if isSyncEnabled {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        } else {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let iCloudSyncDidChange = Notification.Name("iCloudSyncDidChange")
}
