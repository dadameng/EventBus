import Foundation

// MARK: Protocol

@objc public protocol Event {
    static func eventClass() -> AnyClass
    func subtypeOfEvent() -> String?
}

@objc public protocol EventSubscribeToken {
    func dispose()
}

@objc public protocol EventBusSubscribable {
    var eventLifeCycleTracker: EventLifeCycleTracker? { get }
    func subscribe(to eventClass: Event.Type) -> EventBus.EventSubscriberMaker
    func subscribeOnBus(to eventClass: Event.Type, on bus: EventBus) -> EventBus.EventSubscriberMaker
    func subscribeToJSON(name: String) -> EventBus.EventSubscriberMaker
    func subscribeToNotification(name: String) -> EventBus.EventSubscriberMaker
}

protocol EventBusContainerValue {
    func valueUniqueId() -> String
}

// MARK: Content Type

public final class EventBus: NSObject {
    public final class EventSubscriberMaker: NSObject {
        var eventClass: Event.Type
        private unowned var eventBus: EventBus
        
        var eventSubTypes: [String] = []
        var queue: DispatchQueue?
        weak var lifeTimeTracker: EventLifeCycleTracker?
        var handler: ((Event) -> Void)?
        
        init(eventBus: EventBus, eventClass: Event.Type) {
            self.eventBus = eventBus
            self.eventClass = eventClass
        }
        
        @discardableResult
        @objc public func next(_ handler: @escaping (Event) -> Void) -> EventSubscribeToken {
            self.handler = handler
            return eventBus.createNewSubscriber(with: self)
        }
        
        @objc public func atQueue(_ queue: DispatchQueue) -> EventSubscriberMaker {
            self.queue = queue
            return self
        }
        
        @objc public func autoDisposeTokenWith(_ object: EventLifeCycleTracker) -> EventSubscriberMaker {
            lifeTimeTracker = object
            return self
        }
        
        @objc public func ofSubType(_ eventType: String) -> EventSubscriberMaker {
            eventSubTypes.append(eventType)
            return self
        }
        
        // Closure properties to support fluent APIs using closures
        @objc public var atQueueClosure: (DispatchQueue) -> EventSubscriberMaker {
            return { queue in
                self.queue = queue
                return self
            }
        }
        
        @objc public var ofSubTypeClosure: (String) -> EventSubscriberMaker {
            return { eventType in
                self.eventSubTypes.append(eventType)
                return self
            }
        }
        
        @objc public var autoDisposeTokenWithClosure: (EventLifeCycleTracker) -> EventSubscriberMaker {
            return { lifeTimeTracker in
                self.lifeTimeTracker = lifeTimeTracker
                return self
            }
        }
        
        fileprivate func make(uniqueId: String) -> EventSubscriber {
            let subsriber: EventSubscriber = EventSubscriber(eventClass: eventClass, uniqueId: uniqueId)
            subsriber.subscriberQueue = queue
            subsriber.handler = handler
            subsriber.eventSubTypes = eventSubTypes
            if let lifeTimeTracker = lifeTimeTracker {
                subsriber.eventLifeCycleTracker = lifeTimeTracker
            }
            return subsriber
        }
    }
    
    final class EventSubscriber: EventBusContainerValue {
        var eventClass: Event.Type
        let uniqueId: String
        var subscriberQueue: DispatchQueue?
        
        weak var eventLifeCycleTracker: EventLifeCycleTracker?
        var handler: ((Event) -> Void)?
        var eventSubTypes: [String] = []
        
        init(eventClass: Event.Type, uniqueId: String) {
            self.eventClass = eventClass
            self.uniqueId = uniqueId
        }
        
        func valueUniqueId() -> String {
            uniqueId
        }
    }
    
    final class EventToken: EventSubscribeToken {
        var uniqueId: String
        var onDispose: ((String) -> Void)?
        var isDisposed: Bool = false
        
        init(uniqueId: String) {
            self.uniqueId = uniqueId
        }
        
        public func dispose() {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            
            guard !isDisposed else { return }
            isDisposed = true
            onDispose?(uniqueId)
        }
    }
    
    final class ComposeToken: EventSubscribeToken {
        var isDisposed: Bool = false
        var tokens: [EventToken]
        
        init(tokens: [EventToken]) {
            self.tokens = tokens
        }
        
        func dispose() {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            
            guard !isDisposed else { return }
            isDisposed = true
            
            tokens.forEach { $0.dispose() }
        }
    }
    
    @objc public static let shared = EventBus()
    private var prefix: String
    private var publishQueue: DispatchQueue
    private var notificationTracker = [String: Int]()
    private var subscribers = EventBusCollection<EventSubscriber>()
    
    private var attr = pthread_mutexattr_t()
    private var accessLock = pthread_mutex_t()
    
    override init() {
        prefix = "\(Date().timeIntervalSince1970)"
        publishQueue = DispatchQueue(label: "com.eventbus.publish.queue")
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&accessLock, &attr)
    }
    
    @objc public func dispatchOnPublishQueue(_ event: any Event) {
        publishQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dispatch(event)
        }
    }
    
    @objc public func dispatchOnMain(_ event: any Event) {
        DispatchQueue.main.async {
            self.dispatch(event)
        }
    }
    
    @objc public func on(eventType: Event.Type) -> EventSubscriberMaker {
        return EventSubscriberMaker(eventBus: self, eventClass: eventType)
    }
    
    fileprivate func createNewSubscriber(with maker: EventSubscriberMaker) -> EventSubscribeToken {
        // Assert to ensure the handler exists. This will crash in debug mode if handler is nil.
        assert(maker.handler != nil, "EventSubscriberMaker must have a handler.")
        
        var tokens = [EventToken]()
        
        guard !maker.eventSubTypes.isEmpty else { // Handle primary event
            return addSubscriber(with: maker, eventType: nil)
        }
        
        // Handle subtypes
        for eventType in maker.eventSubTypes {
            let token = addSubscriber(with: maker, eventType: eventType)
            tokens.append(token)
        }
        
        return ComposeToken(tokens: tokens)
    }
    
    private func addSubscriber(with maker: EventSubscriberMaker, eventType: String?) -> EventToken {
        let eventKey = generateEventKey(for: maker.eventClass, subeventName: eventType)
        let groupId = generateGroupID(eventKey)
        let uniqueId = generateUniqueID(groupId)
        let token = EventToken(uniqueId: uniqueId)
        let isNotification = maker.eventClass is NSNotification.Type
        
        if let eventType = eventType, isNotification {
            addNotificationObserverIfNeeded(eventType)
        }
        
        token.onDispose = { [weak self, groupId] uniqueId in
            guard let strongSelf = self else { return }
            strongSelf.subscribers.remove(uniqueId: uniqueId, fromKey: groupId)
            let isEmptyList = strongSelf.subscribers.isEmptyList(for: groupId)
            guard let eventType = eventType, isEmptyList && isNotification else {
                return
            }
            strongSelf.removeNotificationObserver(eventType)
        }
        
        let subscriber = maker.make(uniqueId: uniqueId)
        if let eventLifeCycleTracker = subscriber.eventLifeCycleTracker {
            eventLifeCycleTracker.addToken(token)
        }
        subscribers.add(value: subscriber, forKey: groupId)
        return token
    }
    
    private func addNotificationObserverIfNeeded(_ eventType: String) {
        lockAndDo {
            if notificationTracker[eventType] == nil {
                notificationTracker[eventType] = 1
                NotificationCenter.default.addObserver(self, selector: #selector(receiveNotification(_:)), name: NSNotification.Name(eventType), object: nil)
            }
        }
    }
    
    private func removeNotificationObserver(_ eventType: String) {
        lockAndDo {
            notificationTracker.removeValue(forKey: eventType)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(eventType), object: nil)
        }
    }
    
    @objc private func receiveNotification(_ notification: NSNotification) {
        dispatchOnMain(notification)
    }
    
    private func dispatch(_ event: Event) {
        if let subtypeOfEvent = event.subtypeOfEvent() {
            let eventKey = generateEventKey(for: type(of: event), subeventName: subtypeOfEvent)
            publish(for: eventKey, event: event)
        }
        let eventKey = generateEventKey(for: type(of: event), subeventName: nil)
        publish(for: eventKey, event: event)
    }
    
    private func publish(for eventKey: String, event: Event) {
        let groupId = generateGroupID(eventKey)
        let subscribersForEvent = subscribers.values(for: groupId)
        guard !subscribersForEvent.isEmpty else { return }
        subscribersForEvent.forEach { subscriber in
            if let subscriberQueue = subscriber.subscriberQueue {
                subscriberQueue.async {
                    subscriber.handler?(event)
                }
            } else {
                subscriber.handler?(event)
            }
        }
    }
    
    private func generateGroupID(_ eventKey: String) -> String {
        return prefix + eventKey
    }
    
    private func generateUniqueID(_ groupId: String) -> String {
        return groupId + "\(Date().timeIntervalSince1970)"
    }
    
    private func generateEventKey(for type: Event.Type, subeventName: String?) -> String {
        let targetClass: AnyClass = type.eventClass()
        if targetClass is NSObject.Type {
            let className = NSStringFromClass(targetClass)
            if let eventType = subeventName {
                return "\(eventType)_of_\(className)"
            } else {
                return className
            }
        } else {
            let className = String(describing: targetClass)
            let finalClassName = className.components(separatedBy: ".").last ?? className
            if let eventType = subeventName {
                return "\(eventType)_of_\(finalClassName)"
            } else {
                return finalClassName
            }
        }
    }
    
    private func lockAndDo(_ block: () -> Void) {
        pthread_mutex_lock(&accessLock)
        defer { pthread_mutex_unlock(&accessLock) }
        block()
    }
    
    deinit {
        pthread_mutex_destroy(&accessLock)
        pthread_mutexattr_destroy(&attr)
    }
}

@objc public final class EventLifeCycleTracker: NSObject {
    var tokens = [EventSubscribeToken]()
    private var mutex = pthread_mutex_t()
    private var attr = pthread_mutexattr_t()
    
    override init() {
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
    }
    
    deinit {
        pthread_mutex_lock(&mutex)
        defer {
            pthread_mutex_unlock(&mutex)
            pthread_mutex_destroy(&mutex)
            pthread_mutexattr_destroy(&attr)
        }
        tokens.forEach { $0.dispose() }
    }
    
    func addToken(_ token: EventSubscribeToken) {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        tokens.append(token)
    }
}

final class EventBusLinkNode<Value> {
    weak var previous: EventBusLinkNode?
    var next: EventBusLinkNode?
    var value: Value
    let uniqueId: String
    
    init(value: Value, uniqueId: String) {
        self.value = value
        self.uniqueId = uniqueId
    }
}
final class EventBusLinkList<Value> {
    var head: EventBusLinkNode<Value>?
    var tail: EventBusLinkNode<Value>?
    private var nodeMap: [String: EventBusLinkNode<Value>] = [:]

    private let queue = DispatchQueue(label: "com.eventbus.linklist", attributes: .concurrent)

    func appendNode(_ node: EventBusLinkNode<Value>) {
        queue.async(flags: .barrier) {
            if let existingNode = self.nodeMap[node.uniqueId] {
                // replace current existing node
                if let prev = existingNode.previous {
                    prev.next = node
                    node.previous = prev
                } else {
                    // existingNode is head node
                    self.head = node
                }

                if let next = existingNode.next {
                    next.previous = node
                    node.next = next
                } else {
                    // existingNode is tail node
                    self.tail = node
                }

                self.nodeMap[node.uniqueId] = node
            } else {
                // append new node to tail
                if let tail = self.tail {
                    tail.next = node
                    node.previous = tail
                    self.tail = node
                } else {
                    // list is empty
                    self.head = node
                    self.tail = node
                }
                self.nodeMap[node.uniqueId] = node
            }
        }
    }

    func removeNode(for uniqueId: String) {
        queue.async(flags: .barrier) {
            guard let node = self.nodeMap[uniqueId] else { return }
            if let prev = node.previous {
                prev.next = node.next
            }
            if let next = node.next {
                next.previous = node.previous
            }
            if node === self.head {
                self.head = node.next
            }
            if node === self.tail {
                self.tail = node.previous
            }
            self.nodeMap.removeValue(forKey: uniqueId)
        }
    }

    func getNode(with uniqueId: String) -> EventBusLinkNode<Value>? {
        return queue.sync {
            return self.nodeMap[uniqueId]
        }
    }

    func isEmpty() -> Bool {
        return queue.sync {
            return self.nodeMap.isEmpty
        }
    }
}

final class EventBusCollection<Value: EventBusContainerValue> {
    private var lists: [String: EventBusLinkList<Value>] = [:]
    private let queue = DispatchQueue(label: "com.eventbus.collection", attributes: .concurrent)

    func add(value: Value, forKey key: String) {
        let uniqueId = value.valueUniqueId()
        let node = EventBusLinkNode(value: value, uniqueId: uniqueId)
        queue.async(flags: .barrier) {
            let list = self.lists[key, default: EventBusLinkList<Value>()]
            list.appendNode(node)
            self.lists[key] = list
        }
    }

    func remove(uniqueId: String, fromKey key: String) {
        queue.async(flags: .barrier) {
            self.lists[key]?.removeNode(for: uniqueId)
        }
    }

    func values(for key: String) -> [Value] {
        return queue.sync {
            guard let list = self.lists[key] else { return [] }

            var values: [Value] = []
            var currentNode = list.head
            while let node = currentNode {
                values.append(node.value)
                currentNode = node.next
            }

            return values
        }
    }

    func isEmptyList(for key: String) -> Bool {
        return queue.sync {
            guard let list = self.lists[key] else { return false }
            return list.isEmpty()
        }
    }

    func isEmpty() -> Bool {
        return queue.sync {
            return self.lists.isEmpty
        }
    }
}



@objcMembers
public final class JSONEvent: NSObject, Event {
    let uniqueId: String
    let data: Any
    
    init?(uniqueId: String, data: Any) {
        if !JSONEvent.isValidData(data) {
            return nil
        }
        self.uniqueId = uniqueId
        self.data = data
        super.init()
    }
    
    public static func eventClass() -> AnyClass {
        return JSONEvent.self
    }
    
    public func subtypeOfEvent() -> String? {
        uniqueId
    }
    
    private static func isValidData(_ data: Any) -> Bool {
        return data is [Any] || data is [String: Any]
    }
    
    var eventType: String {
        return uniqueId
    }
}

// MARK: extension

extension NSObject: EventBusSubscribable {
    private struct AssociatedKeys {
        static var lifeCycleTracker: UInt8 = 0
    }
    
    @objc public var eventLifeCycleTracker: EventLifeCycleTracker? {
        if let lifeCycleTracker = objc_getAssociatedObject(self, &AssociatedKeys.lifeCycleTracker) as? EventLifeCycleTracker {
            return lifeCycleTracker
        } else {
            let lifeCycleTracker = EventLifeCycleTracker()
            objc_setAssociatedObject(self, &AssociatedKeys.lifeCycleTracker, lifeCycleTracker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return lifeCycleTracker
        }
    }
    
    @objc public func subscribe(to eventClass: Event.Type) -> EventBus.EventSubscriberMaker {
        let maker = EventBus.shared.on(eventType: eventClass)
        guard let eventLifeCycleTracker = eventLifeCycleTracker else { return maker }
        return maker.autoDisposeTokenWith(eventLifeCycleTracker)
    }
    
    @objc public func subscribeOnBus(to eventClass: Event.Type, on bus: EventBus) -> EventBus.EventSubscriberMaker {
        let maker = bus.on(eventType: eventClass)
        guard let eventLifeCycleTracker = eventLifeCycleTracker else { return maker }
        return maker.autoDisposeTokenWith(eventLifeCycleTracker)
    }
    
    @objc public func subscribeToJSON(name: String) -> EventBus.EventSubscriberMaker {
        let maker = EventBus.shared.on(eventType: JSONEvent.self).ofSubType(name)
        guard let eventLifeCycleTracker = eventLifeCycleTracker else { return maker }
        return maker.autoDisposeTokenWith(eventLifeCycleTracker)
    }
    
    @objc public func subscribeToNotification(name: String) -> EventBus.EventSubscriberMaker {
        let maker = EventBus.shared.on(eventType: NSNotification.self).ofSubType(name)
        guard let eventLifeCycleTracker = eventLifeCycleTracker else { return maker }
        return maker.autoDisposeTokenWith(eventLifeCycleTracker)
    }
}

extension EventBusSubscribable {
    public func subscribe(to eventClass: Event.Type) -> EventBus.EventSubscriberMaker {
        let maker = EventBus.shared.on(eventType: eventClass)
        guard let eventLifeCycleTracker = eventLifeCycleTracker else { return maker }
        return maker.autoDisposeTokenWith(eventLifeCycleTracker)
    }
    
    public func subscribeOnBus(to eventClass: Event.Type, on bus: EventBus) -> EventBus.EventSubscriberMaker {
        let maker = bus.on(eventType: eventClass)
        guard let eventLifeCycleTracker = eventLifeCycleTracker else { return maker }
        return maker.autoDisposeTokenWith(eventLifeCycleTracker)
    }
    
    public func subscribeToJSON(name: String) -> EventBus.EventSubscriberMaker {
        let maker = EventBus.shared.on(eventType: JSONEvent.self).ofSubType(name)
        guard let eventLifeCycleTracker = eventLifeCycleTracker else { return maker }
        return maker.autoDisposeTokenWith(eventLifeCycleTracker)
    }
    
    public func subscribeToNotification(name: String) -> EventBus.EventSubscriberMaker {
        let maker = EventBus.shared.on(eventType: NSNotification.self).ofSubType(name)
        guard let eventLifeCycleTracker = eventLifeCycleTracker else { return maker }
        return maker.autoDisposeTokenWith(eventLifeCycleTracker)
    }
}

extension NSNotification: Event {
    public static func eventClass() -> AnyClass {
        return NSNotification.self
    }
    
    public func subtypeOfEvent() -> String? {
        return name.rawValue
    }
}
