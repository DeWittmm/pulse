// Playground - noun: a place where people can play

import Cocoa
import XCPlayground

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

func pathToFileInSharedSubfolder() -> String {
    return XCPSharedDataDirectoryPath +
        "/" +
        NSProcessInfo.processInfo().processName +
    "/"
}

//MARK: Read in CSV
let file = "IR_1mod5FILTERED" //"RLED_3
let ext = file + ".csv"
let dir = pathToFileInSharedSubfolder()
let path = dir + ext

let csvFileContents = String(contentsOfFile:path, encoding: NSUTF8StringEncoding)
if csvFileContents == nil {
    abort()
}

let strValues = csvFileContents!.componentsSeparatedByString(",")

let values = strValues.map { NSString(string: $0).doubleValue }
println("Num values: \(values.count)")

//MARK: Finding peaks
let maxValue = values.reduce(0.0) { max($0, $1) }
maxValue

let maxValueTolerance = 0.75
println("Max threshold: \(maxValue * maxValueTolerance)")
var indicies = [(Int, Double)]()
for (index, value) in enumerate(values) {
    if value >= maxValue * maxValueTolerance {
        indicies.append((index, value))
    }
}

//MARK: Clustering
let HR_WIDTH = 100
var peaks = [(Int, Double)]()
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
println("Number of peaks found: \(peaks.count)")

//MARK: Calculate BPM

let BIN_PRINT_TIME  = 727.0
let TIME_PER_POINT = 0.17
func millsBetweenPoints(p1: Double, p2: Double) -> Double {
//    println((p1, p2))
    let timePts = (p2 - p1) * TIME_PER_POINT
    let numPrintBins = floor((p2 - p1) / 100)
    let spanWithPrint = BIN_PRINT_TIME * numPrintBins
    let milis = (timePts + spanWithPrint)
    
    //FIXME
    let 💩 = ((numPrintBins != 0 ? numPrintBins : 1) * 1000)
    return milis
}

let MIN_TIME_SPAN = 100.0
var timeSpans = [Double]()
for var i=0; i < peaks.count - 1; i++ {
    let p1 = peaks[i].0
    let p2 = peaks[i+1].0
    
    let time = millsBetweenPoints(Double(p1), Double(p2))
    timeSpans.append(time)
}

let MILLS_PER_MIN = 60000.0
timeSpans = timeSpans.filter { $0 > MIN_TIME_SPAN }
timeSpans = timeSpans.map { MILLS_PER_MIN/$0 }

var avgMap = [Double]()
for var i=0; i < timeSpans.count - 1; i++ {
    let t1 = timeSpans[i].0
    let t2 = timeSpans[i+1].0
    let avg = (t1 + t2) / 2
    avgMap.append(avg)
}

avgMap
var sum = timeSpans.reduce(0.0) { $0 + $1 }
let avgBPM = sum/Double(timeSpans.count)
print("Average HR: \(avgBPM) BPM")

//Baseline
let minValue = values.reduce(maxValue) { min($0, $1) }
minValue

