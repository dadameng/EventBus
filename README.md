# EventBus

`EventBus` is a lightweight, protocol-oriented event bus framework for Swift. It facilitates communication between components in an application without requiring the components to have direct references to each other, which helps in reducing coupling and enhancing modularity.

## Features

- **Decoupled Communication:** Allows components to communicate with each other without direct references.
- **Type Safety:** Uses Swift's strong typing to ensure that events are handled appropriately.
- **Asynchronous Options:** Supports dispatching events on different queues.
- **Lifecycle Management:** Automatic management of subscriptions using `EventLifeCycleTracker`.

## Installation

### Swift Package Manager

To integrate `EventBus` into your Swift project using Swift Package Manager, add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dadameng/EventBus", .upToNextMajor(from: "1.0.0"))
]
```

### CocoaPods

To integrate `EventBus` into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'EventBus', '~> 1.0'
```

Make sure to replace `1.0` with the latest version of `EventBus`.

## Usage

### Defining Events

Create a custom event by conforming to the `Event` protocol:

```swift
class CustomEvent: NSObject, Event {
    static func eventClass() -> AnyClass {
        return CustomEvent.self
    }

    func subtypeOfEvent() -> String? {
        return "SomeSubtype"
    }
}
```

### Subscribing to Events

Subscribe to events wherever you need to listen for them:

```swift
let subscriber = NSObject()
subscriber.subscribe(to: CustomEvent.self).next { event in
    print("Received an event: \(event)")
}
```

### Publishing Events

Dispatch events to all subscribers:

```swift
let event = CustomEvent()
EventBus.shared.dispatchOnMain(event)
```

## License

EventBus is released under the MIT license. 
