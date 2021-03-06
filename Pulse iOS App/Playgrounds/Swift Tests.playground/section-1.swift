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

let refreshDate = NSDate(timeIntervalSince1970: 1000)
let interval = NSDate.timeIntervalSinceDate(refreshDate)

interval(refreshDate)

let date = NSDate(timeInterval: 100, sinceDate: NSDate())
date.timeIntervalSinceNow

var intArr = [Int](count: 100, repeatedValue: 2)
intArr.count

let strArr = intArr.map { "\($0*$0)" }

intArr.removeAll(keepCapacity: true)
intArr.count

UInt8(random() % 255)

let u1: UInt = 1
let u2: UInt = 2

u2 - u1
//Int(u1) - u2
//Int(u1 - u2)

func test() {
    var i = 10;
    while i > 0 {
        while --i > 0 {
            continue
        }
        println("Break")
    }
}

let opt1: Int? = nil
let opt2: Int = 0
opt1 < opt2 //nil < 0

test()



