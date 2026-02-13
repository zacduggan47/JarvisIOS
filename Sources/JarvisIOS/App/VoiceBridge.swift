import Foundation

public struct VoiceBridge {
    public static let transcriptionReady = Notification.Name("VoiceBridgeTranscriptionReady")
    public static func postTranscription(_ text: String) {
        NotificationCenter.default.post(name: transcriptionReady, object: nil, userInfo: ["text": text])
    }
}
