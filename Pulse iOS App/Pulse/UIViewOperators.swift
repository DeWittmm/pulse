//
//  UIViewOperators.swift
//  Pulse
//
//  Created by Michael DeWitt on 1/21/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit

//infix operator + { associativity left precedence 100 }
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x:left.x + right.x, y: left.y + right.y)
}

//infix operator - { associativity left precedence 100 }
func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x:left.x - right.x, y: left.y - right.y)
}