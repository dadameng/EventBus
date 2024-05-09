@testable import EventBus
import XCTest
class EventBusTests: XCTestCase {
    var eventBus: EventBus!
    var subscriber: NSObject!

    override func setUp() {
        super.setUp()
        eventBus = EventBus.shared
        subscriber = NSObject()
    }

    override func tearDown() {
        eventBus = nil
        subscriber = nil
        super.tearDown()
    }

    func testSubscriptionAndEventHandling() {
        let expectation = self.expectation(description: "Event should be handled")
        var eventHandled = false

        // Subscribe to a custom event
        let token = subscriber.subscribe(to: TestEvent.self).next { _ in
            eventHandled = true
            expectation.fulfill()
        }

        // Dispatch an event
        let event = TestEvent(uniqueId: "testEvent1")
        eventBus.dispatchOnPublishQueue(event)

        waitForExpectations(timeout: 1) { _ in
            XCTAssertTrue(eventHandled, "Event was not handled as expected")
            token.dispose() // Clean up the subscription
        }
    }

    func testEventSubtypeHandling() {
        let expectation = self.expectation(description: "Event subtype should be handled")
        var eventHandled = false

        // Subscribe to a specific subtype of an event
        let token = subscriber.subscribe(to: TestEvent.self).ofSubType("subtype1").next { event in
            if event.subtypeOfEvent() == "subtype1" {
                eventHandled = true
            }
            expectation.fulfill()
        }

        // Dispatch an event with subtype
        let event = TestEvent(uniqueId: "subtype1")
        eventBus.dispatchOnPublishQueue(event)

        waitForExpectations(timeout: 1) { _ in
            XCTAssertTrue(eventHandled, "Event subtype was not handled as expected")
            token.dispose()
        }
    }

    func testAutomaticDisposalByDeallocatingSubscriber() {
        var temporarySubscriber: NSObject? = NSObject()
        let expectation = self.expectation(description: "Event should not be handled after subscriber is deallocated")

        temporarySubscriber?.subscribe(to: TestEvent.self).next { _ in
            XCTFail("Event handler should not be called after subscriber is deallocated")
        }

        if let tracker = temporarySubscriber?.eventLifeCycleTracker {
            XCTAssertEqual(tracker.tokens.count, 1, "Should have one token")
        } else {
            XCTFail("EventLifeCycleTracker should exist")
        }

        temporarySubscriber = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let event = TestEvent(uniqueId: "test")
            self.eventBus.dispatchOnMain(event)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error, "The event should not be handled, indicating the subscriber was properly deallocated and unsubscribed")
        }
    }

    func testEventHandlingContinuesAfterObjectDeallocatedUntilTokenDisposed() {
        let expectationHandledAfterDealloc = self.expectation(description: "Event should be handled after object is deallocated but before disposal")

        var eventHandled = false
        var handler: ((Event) -> Void)? = { event in
            eventHandled = true
            expectationHandledAfterDealloc.fulfill()
        }
        
        let token = EventBus.shared.on(eventType: TestEvent.self).next(handler!)

        handler = nil

        let event = TestEvent(uniqueId: "testEvent1")
        EventBus.shared.dispatchOnPublishQueue(event)

        waitForExpectations(timeout: 1) { error in
            XCTAssertTrue(eventHandled, "Event should still be handled because the token has not been disposed")

            eventHandled = false

            token.dispose()

            let newEvent = TestEvent(uniqueId: "testEvent2")
            EventBus.shared.dispatchOnPublishQueue(newEvent)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertFalse(eventHandled, "Event should not be handled after token is disposed")
            }
        }
    }
}

class TestEvent: NSObject, Event {
    let uniqueId: String

    init(uniqueId: String) {
        self.uniqueId = uniqueId
    }

    static func eventClass() -> AnyClass {
        return TestEvent.self
    }

    func subtypeOfEvent() -> String? {
        return uniqueId
    }
}
