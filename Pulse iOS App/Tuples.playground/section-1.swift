// Playground - noun: a place where people can play

import Cocoa

//Free Standing Functions
protocol Summable: Equatable {
    func +(lhs: Self, rhs: Self) -> Self
}

extension Int: Summable {}
extension Double: Summable {}
//extension Float: Summable {}

func add <A:Summable, B:Summable> (p1: (A, B), p2: (A, B)) -> (A, B) {
    return (p1.0 + p2.0, p1.1 + p2.1)
}

func + <A:Summable, B:Summable> (p1: (A, B), p2: (A, B)) -> (A, B) {
    return add(p1, p2)
}

struct DataPoint {
    let point: Int
    let value: Double
}

add((1, 5.0), (2, 1.7))

(1, 5.0) + (2, 1.7)

var dataPoint: (point: Int, value: Double)

DataPoint(point: 1, value: 5.0)