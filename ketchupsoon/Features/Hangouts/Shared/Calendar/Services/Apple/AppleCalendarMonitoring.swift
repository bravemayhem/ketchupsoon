import EventKit
import Foundation

actor AppleCalendarMonitoring: AppleCalendarMonitoringProtocol {
    private let eventStore: EKEventStore
    private let auth: AppleCalendarAuthProtocol
    private weak var delegate: AppleCalendarServiceDelegate?
    private var observer: NSObjectProtocol?
    
    init(eventStore: EKEventStore, auth: AppleCalendarAuthProtocol, delegate: AppleCalendarServiceDelegate?) {
        self.eventStore = eventStore
        self.auth = auth
        self.delegate = delegate
    }
    
    func startEventMonitoring(notificationCenter: NotificationCenter = .default) async {
        guard await auth.isAuthorized else { return }
        
        let eventStore = self.eventStore
        let newObserver = await MainActor.run {
            notificationCenter.addObserver(
                forName: .EKEventStoreChanged,
                object: eventStore,
                queue: .main
            ) { [weak self] _ in
                Task { [weak self] in
                    await self?.handleCalendarChanged()
                }
            }
        }
        
        self.observer = newObserver
    }
    
    func stopEventMonitoring() async {
        if let currentObserver = observer {
            await MainActor.run {
                NotificationCenter.default.removeObserver(currentObserver)
            }
            self.observer = nil
        }
    }
    
    private func handleCalendarChanged() async {
        let currentDelegate = delegate
        await MainActor.run {
            currentDelegate?.calendarEventsDidChange()
        }
    }
    
    func setDelegate(_ delegate: AppleCalendarServiceDelegate?) {
        self.delegate = delegate
    }
    
    deinit {
        if let observer = observer {
            Task { @MainActor in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
} 