import Foundation
import SwiftData

@Model
final class LogEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var notes: String?
    var photoData: Data?
    var event: Event?

    init(
        timestamp: Date = Date(),
        notes: String? = nil,
        photoData: Data? = nil,
        event: Event? = nil
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.notes = notes
        self.photoData = photoData
        self.event = event
    }
}
