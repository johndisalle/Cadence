import Foundation

enum DeepLinkDestination {
    case event(UUID)
    case addEvent
    case quickLog
}

struct DeepLinkRouter {
    static func parse(url: URL) -> DeepLinkDestination? {
        guard url.scheme == "cadence" else { return nil }

        switch url.host {
        case "event":
            if let idString = url.pathComponents.dropFirst().first,
               let uuid = UUID(uuidString: idString) {
                return .event(uuid)
            }
        case "add":
            return .addEvent
        case "log":
            return .quickLog
        default:
            break
        }
        return nil
    }

    static func parse(shortcutType: String) -> DeepLinkDestination? {
        switch shortcutType {
        case "com.cadence.app.addEvent":
            return .addEvent
        case "com.cadence.app.quickLog":
            return .quickLog
        default:
            return nil
        }
    }
}
