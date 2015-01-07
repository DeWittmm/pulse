//
//  InterfaceController.swift
//  Pulse WatchKit Extension
//
//  Created by Michael DeWitt on 11/22/14.
//  Copyright (c) 2014 Biomedical Engineering Design. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    override init(context: AnyObject?) {
        // Initialize variables here.
        super.init(context: context)
        
        // Configure interface objects here.
        NSLog("%@ init", self)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("%@ will activate", self)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        NSLog("%@ did deactivate", self)
        super.didDeactivate()
    }
    
    
    //Use for responding to Glance interaction
    override func actionForUserActivity(userActivity: [NSObject : AnyObject]?, context: AutoreleasingUnsafeMutablePointer<AnyObject?>) -> String? {
        
        // The object you provide is passed to the new interface controller’s initWithContext: method.
        
        return nil;
    }
}
