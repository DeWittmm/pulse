//
//  Array+Avg.swift
//  Pulse
//
//  Created by Michael DeWitt on 3/2/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

protocol Summable {
    func +(lhs: Self, rhs: Self) -> Self
}

extension Double: Summable {}

//MARK: Helpers

//extension Array {
//    
//    func avg<A : Summable>(start: A) -> Double {
//        return reduce(start) { $0 + ($1 as A } / Double(count)
//    }
//}

func avg(vals: [Double]) -> Double {
    return vals.reduce(0.0, combine: +) / Double(vals.count)
}
