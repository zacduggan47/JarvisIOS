import Foundation
import EventKit

struct ReminderSuggestion: Identifiable, Equatable {
    enum Kind { case birthday, appointment, followUp, generic }
    let id = UUID()
    let text: String
    let kind: Kind
    let when: Date?
}

final class ReminderEngine {
    private let eventStore = EKEventStore()

    func suggestions(from messages: [ChatMessage], profile: UserProfile) -> [ReminderSuggestion] {
        guard let last = messages.last?.text.lowercased() else { return [] }
        var out: [ReminderSuggestion] = []
        // Heuristics: birthdays, doctor, follow-ups
        if last.contains("birthday") {
            out.append(ReminderSuggestion(text: "It's your mom's birthday next week—want me to set a reminder?", kind: .birthday, when: nil))
        }
        if last.contains("doctor") || last.contains("dentist") {
            out.append(ReminderSuggestion(text: "You have a dentist/doctor appointment soon. Add 'buy flowers' reminder?", kind: .appointment, when: nil))
        }
        if let person = profile.people.first, last.contains("call") || last.contains(person.lowercased()) {
            out.append(ReminderSuggestion(text: "You mentioned calling \(person) last week. Still planning to?", kind: .followUp, when: nil))
        }
        return out
    }

    func addToCalendar(text: String, date: Date?) async throws {
        let granted = try await requestCalendarAccess()
        guard granted else { return }
        let event = EKEvent(eventStore: eventStore)
        event.title = text
        let start = date ?? Date().addingTimeInterval(3600)
        event.startDate = start
        event.endDate = start.addingTimeInterval(1800)
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)
    }

    private func requestCalendarAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { cont in
            eventStore.requestAccess(to: .event) { granted, error in
                if let error { cont.resume(throwing: error) } else { cont.resume(returning: granted) }
            }
        }
    }
}
