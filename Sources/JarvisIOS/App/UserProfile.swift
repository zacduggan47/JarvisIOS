import Foundation

struct UserProfile: Equatable {
    var name: String
    var goals: [String]
    var struggles: [String]
    var people: [String]
    var tone: String
    var humor: String
    var energy: String

    static func current() -> UserProfile {
        let defaults = UserDefaults.standard
        let memory = defaults.array(forKey: "memoryAnswers") as? [String] ?? Array(repeating: "", count: 7)
        let soul = defaults.array(forKey: "soulAnswers") as? [String] ?? Array(repeating: "", count: 7)

        let name = memory.indices.contains(0) ? memory[0].trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let goals = splitList(memory.indices.contains(2) ? memory[2] : "")
        let struggles = splitList(memory.indices.contains(3) ? memory[3] : "")
        let people = splitList(memory.indices.contains(6) ? memory[6] : "")

        let tone = soul.indices.contains(0) ? soul[0] : ""
        let humor = soul.indices.contains(1) ? soul[1] : ""
        let energy = soul.indices.contains(2) ? soul[2] : ""

        return UserProfile(
            name: name.isEmpty ? (defaults.string(forKey: "accountName") ?? "") : name,
            goals: goals,
            struggles: struggles,
            people: people,
            tone: tone,
            humor: humor,
            energy: energy
        )
    }

    private static func splitList(_ s: String) -> [String] {
        let seps: CharacterSet = [",", ";", "\n"]
        return s
            .components(separatedBy: seps)
            .flatMap { $0.components(separatedBy: " and ") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
