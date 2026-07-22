import Foundation

/// The six alarm sounds. Ship six, no more.
struct AlarmSound: Identifiable, Hashable {
    let id: String          // bundle resource name, no extension
    let displayName: String
    let character: String

    static let all: [AlarmSound] = [
        AlarmSound(id: "Dawn", displayName: "Dawn", character: "Soft rising bell"),
        AlarmSound(id: "Chapel", displayName: "Chapel", character: "Distant church bells"),
        AlarmSound(id: "MorningLight", displayName: "Morning Light", character: "Gentle piano"),
        AlarmSound(id: "Rise", displayName: "Rise", character: "Firm, for heavy sleepers"),
        AlarmSound(id: "Choir", displayName: "Choir", character: "Wordless vocal swell"),
        AlarmSound(id: "Classic", displayName: "Classic", character: "Standard alarm"),
    ]

    static let `default` = all[0]

    static func named(_ id: String) -> AlarmSound {
        all.first { $0.id == id } ?? .default
    }

    var fileURL: URL? {
        Bundle.main.url(forResource: id, withExtension: "caf")
    }
}
