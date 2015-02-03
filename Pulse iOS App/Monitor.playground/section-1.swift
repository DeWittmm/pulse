// Playground - noun: a place where people can play

import Cocoa

//Free Standing Functions
protocol Summable: Equatable {
    func +(lhs: Self, rhs: Self) -> Self
}

extension Int: Summable {}
extension Double: Summable {}

func add <A:Summable, B:Summable> (p1: (A, B), p2: (A, B)) -> (A, B) {
    return (p1.0 + p2.0, p1.1 + p2.1)
}

func + <A:Summable, B:Summable> (p1: (A, B), p2: (A, B)) -> (A, B) {
    return add(p1, p2)
}

//Read in CSV
let file = "IR_1mod5.csv"

let dir = "\(NSHomeDirectory())/Documents/"
let path = dir.stringByAppendingPathComponent(file);

let csvFileContents = String(contentsOfFile:path, encoding: NSUTF8StringEncoding)
if csvFileContents == nil {
    abort()
}

let strValues = csvFileContents!.componentsSeparatedByString(",\n")

//Run Analysis
let values = strValues.map { NSString(string: $0).doubleValue }
println("Num values: \(values.count)")

let maxValue = values.reduce(0.0) { max($0, $1) }
maxValue

let maxValueTolerance = 0.95
var indicies = [(Int, Double)]()
for (index, value) in enumerate(values) {
    if value >= maxValue * maxValueTolerance {
        indicies.append((index, value))
    }
}

var peaks = [(Int, Double)]()
let HR_WIDTH = 25

func average(group: [(Int, Double)]) -> (Int, Double) {
    let count = group.count
    let total = group.reduce((0, 0.0)){ $0 + $1 }
    
    return (total.0 / count, total.1 / Double(count))
}

var cluster = [indicies.first!]
for (index, value) in indicies {
    index
    if cluster.first!.0 + HR_WIDTH > index {
        cluster.append(index, value)
    }
    else {
        let avg = average(cluster)
        peaks.append(avg)
        
        cluster.removeAll(keepCapacity: true)
        cluster.append(index, value)
    }
}
peaks.append(average(cluster))
peaks

let PRINT_BIN_TIME  = 727.0
let TIME_PER_POINT = 0.17
func millsBetweenPoints(p1: Double, p2: Double) -> Double {
//    println((p1, p2))
    let timePts = (p2 - p1) * TIME_PER_POINT
    let numBins = floor((p2 - p1) / 100)
    let spanWithPrint = PRINT_BIN_TIME * numBins
    return (timePts + spanWithPrint) / (numBins * 1000)
}

//Calculate BPM
var timeSpans = [Double]()
for var i=0; i < peaks.count - 1; i++ {
    let p1 = peaks[i].0
    let p2 = peaks[i+1].0
    
    let time = millsBetweenPoints(Double(p1), Double(p2))
    timeSpans.append(time)
}

var sum = 0.0
for time in timeSpans {
    sum += 60 / time
}
let avgBPM = sum/Double(timeSpans.count)
print("Average HR: \(avgBPM)")

//Baseline
let minValue = values.reduce(5.0) { min($0, $1) }
minValue

