

import UIKit
import DDMEventBus

class SwiftEvent : NSObject, Event {
    let privateNum : Int
    static func eventClass() -> AnyClass {
        SwiftEvent.self
    }
    init(privateNum: Int) {
        self.privateNum = privateNum
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        subscriben(to: SwiftEvent.self).next { event in
            debugPrint("event num = \(event.privateNum)")
        }
    }
}

