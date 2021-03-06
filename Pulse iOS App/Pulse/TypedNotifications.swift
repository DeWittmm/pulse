//Originally found at: http://www.objc.io/snippets/16.html
//MODIFIED: 2/2/2015 Michael DeWitt

import Foundation

class Box<T> {
    let unbox: T
    init(_ value: T) { self.unbox = value }
}

struct Notification<A> {
    let name: String
}

func postNotification<A>(note: Notification<A>, value: A) {
   
    let userInfo = ["value": Box(value)]
    NSNotificationCenter.defaultCenter().postNotificationName(note.name, object: nil, userInfo: userInfo)
}

class NotificationObserver {
    let observer: NSObjectProtocol
    
    init<A>(notification: Notification<A>, block aBlock: A -> (), opQueue: NSOperationQueue = NSOperationQueue.mainQueue()) {
        observer = NSNotificationCenter.defaultCenter().addObserverForName(notification.name, object: nil, queue: opQueue) { note in
            if let value = (note.userInfo?["value"] as? Box<A>)?.unbox {
                aBlock(value)
            } else {
                assert(false, "Couldn't understand user info")
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
    
}