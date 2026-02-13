import Foundation
import SwiftUI
import CoreLocation
import EventKit
import Contacts
import AVFoundation
import Speech
import HealthKit
import HomeKit
import MediaPlayer
import UserNotifications
import Photos
import UIKit

@MainActor
final class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()

    enum PermissionType: CaseIterable, Hashable {
        case locationWhenInUse
        case locationAlways
        case calendar
        case contacts
        case microphone
        case speech
        case health
        case home
        case mediaLibrary
        case notifications
        case camera
        case photos
    }

    enum Status: Equatable {
        case notDetermined
        case denied
        case restricted
        case limited // photos
        case granted
        case unknown

        var color: Color {
            switch self {
            case .granted: return .green
            case .denied, .restricted: return .red
            case .limited: return .orange
            case .notDetermined, .unknown: return .gray
            }
        }

        var text: String {
            switch self {
            case .granted: return "Granted"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .limited: return "Limited"
            case .notDetermined: return "Not Determined"
            case .unknown: return "Unknown"
            }
        }
    }

    @Published var statuses: [PermissionType: Status] = [:]

    private var locationProxy: LocationProxy?
    private var homeManager: HMHomeManager?
    private let eventStore = EKEventStore()
    private let contactStore = CNContactStore()
    private let healthStore = HKHealthStore()

    override init() {
        super.init()
        refreshAll()
    }

    func refreshAll() {
        for type in PermissionType.allCases {
            statuses[type] = status(for: type)
        }
    }

    func status(for type: PermissionType) -> Status {
        switch type {
        case .locationWhenInUse, .locationAlways:
            let auth = CLLocationManager.authorizationStatus()
            switch auth {
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .denied: return .denied
            case .authorizedAlways: return .granted
            case .authorizedWhenInUse:
                return type == .locationWhenInUse ? .granted : .notDetermined
            @unknown default: return .unknown
            }
        case .calendar:
            switch EKEventStore.authorizationStatus(for: .event) {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .restricted: return .restricted
            case .authorized: return .granted
            @unknown default: return .unknown
            }
        case .contacts:
            switch CNContactStore.authorizationStatus(for: .contacts) {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .restricted: return .restricted
            case .authorized: return .granted
            @unknown default: return .unknown
            }
        case .microphone:
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined: return .notDetermined
            case .denied: return .denied
            case .granted: return .granted
            @unknown default: return .unknown
            }
        case .speech:
            switch SFSpeechRecognizer.authorizationStatus() {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .restricted: return .restricted
            case .authorized: return .granted
            @unknown default: return .unknown
            }
        case .health:
            if HKHealthStore.isHealthDataAvailable() {
                let types: [HKObjectType] = requestedHealthTypes()
                var anyNotDetermined = false
                var anyDenied = false
                for t in types {
                    let s = healthStore.authorizationStatus(for: t)
                    switch s {
                    case .notDetermined: anyNotDetermined = true
                    case .sharingDenied: anyDenied = true
                    case .sharingAuthorized: break
                    @unknown default: break
                    }
                }
                if anyNotDetermined { return .notDetermined }
                if anyDenied { return .denied }
                return .granted
            } else {
                return .restricted
            }
        case .home:
            if #available(iOS 13.0, *) {
                let s = HMHomeManager.authorizationStatus()
                switch s {
                case .determined: return .granted // treat as usable
                case .restricted: return .restricted
                @unknown default: return .unknown
                }
            } else {
                return .unknown
            }
        case .mediaLibrary:
            switch MPMediaLibrary.authorizationStatus() {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .restricted: return .restricted
            case .authorized: return .granted
            @unknown default: return .unknown
            }
        case .notifications:
            var result: Status = .unknown
            let group = DispatchGroup()
            group.enter()
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .notDetermined: result = .notDetermined
                case .denied: result = .denied
                case .authorized, .provisional, .ephemeral: result = .granted
                @unknown default: result = .unknown
                }
                group.leave()
            }
            group.wait()
            return result
        case .camera:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .restricted: return .restricted
            case .authorized: return .granted
            @unknown default: return .unknown
            }
        case .photos:
            if #available(iOS 14, *) {
                switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
                case .notDetermined: return .notDetermined
                case .denied: return .denied
                case .restricted: return .restricted
                case .authorized: return .granted
                case .limited: return .limited
                @unknown default: return .unknown
                }
            } else {
                switch PHPhotoLibrary.authorizationStatus() {
                case .notDetermined: return .notDetermined
                case .denied: return .denied
                case .restricted: return .restricted
                case .authorized: return .granted
                @unknown default: return .unknown
                }
            }
        }
    }

    func request(_ type: PermissionType) {
        switch type {
        case .locationWhenInUse:
            locationProxy = LocationProxy { [weak self] in
                self?.refreshLocationStatus()
            }
            locationProxy?.manager.requestWhenInUseAuthorization()
        case .locationAlways:
            locationProxy = LocationProxy { [weak self] in
                self?.refreshLocationStatus()
            }
            locationProxy?.manager.requestAlwaysAuthorization()
        case .calendar:
            eventStore.requestAccess(to: .event) { [weak self] _, _ in
                DispatchQueue.main.async { self?.statuses[.calendar] = self?.status(for: .calendar) }
            }
        case .contacts:
            contactStore.requestAccess(for: .contacts) { [weak self] _, _ in
                DispatchQueue.main.async { self?.statuses[.contacts] = self?.status(for: .contacts) }
            }
        case .microphone:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] _ in
                DispatchQueue.main.async { self?.statuses[.microphone] = self?.status(for: .microphone) }
            }
        case .speech:
            SFSpeechRecognizer.requestAuthorization { [weak self] _ in
                DispatchQueue.main.async { self?.statuses[.speech] = self?.status(for: .speech) }
            }
        case .health:
            let read = Set(requestedHealthTypes())
            healthStore.requestAuthorization(toShare: nil, read: read) { [weak self] _, _ in
                DispatchQueue.main.async { self?.statuses[.health] = self?.status(for: .health) }
            }
        case .home:
            homeManager = HMHomeManager()
            // Status will become determined; refresh after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.statuses[.home] = self?.status(for: .home)
            }
        case .mediaLibrary:
            MPMediaLibrary.requestAuthorization { [weak self] _ in
                DispatchQueue.main.async { self?.statuses[.mediaLibrary] = self?.status(for: .mediaLibrary) }
            }
        case .notifications:
            PushNotificationManager.shared.requestAuthorization { [weak self] _ in
                DispatchQueue.main.async { self?.statuses[.notifications] = self?.status(for: .notifications) }
            }
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async { self?.statuses[.camera] = self?.status(for: .camera) }
            }
        case .photos:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] _ in
                    DispatchQueue.main.async { self?.statuses[.photos] = self?.status(for: .photos) }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { [weak self] _ in
                    DispatchQueue.main.async { self?.statuses[.photos] = self?.status(for: .photos) }
                }
            }
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func refreshLocationStatus() {
        statuses[.locationWhenInUse] = status(for: .locationWhenInUse)
        statuses[.locationAlways] = status(for: .locationAlways)
    }

    private func requestedHealthTypes() -> [HKObjectType] {
        var types: [HKObjectType] = []
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.append(steps) }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { types.append(distance) }
        if let heart = HKObjectType.quantityType(forIdentifier: .heartRate) { types.append(heart) }
        types.append(HKObjectType.workoutType())
        return types
    }
}

private final class LocationProxy: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        super.init()
        manager.delegate = self
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onChange()
    }
}
