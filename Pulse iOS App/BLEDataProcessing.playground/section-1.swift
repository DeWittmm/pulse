// Playground - noun: a place where people can play

import Foundation
import XCPlayground
import BLEDataProcessing

func pathToFileInSharedSubfolder() -> String {
    return XCPSharedDataDirectoryPath +
        "/" +
        NSProcessInfo.processInfo().processName +
    "/"
}

//MARK: Read in CSV
let file = "BLEData" //"IR_1mod5FILTERED" //"RLED_3
let ext = file + ".csv"
let dir = pathToFileInSharedSubfolder()
let path = dir + ext

let csvFileContents = String(contentsOfFile:path, encoding: NSUTF8StringEncoding)
if csvFileContents == nil {
    abort()
}

let strValues = csvFileContents!.componentsSeparatedByString(",")
strValues

let values = strValues.map { NSString(string: $0).doubleValue }
println("Num values: \(values.count)")

let partValues = Array(values[0..<values.count/2])

//MARK: Callback

//MARK: Processing
let dataCruncher = DataCruncher()

var data = [UInt8]()
var allDataPackets = [DataPacket]()
var count = 20
for num in partValues {
    if count-- <= 0 {
        if let packet = DataPacket(rawData: data) {
            allDataPackets.append(packet)
            data.removeAll(keepCapacity: true)
        }
        count = 20
    }
    else {
        data.append(UInt8(num))
    }
}

var filteredVals: [DataPoint]
var avgTime: Double
var timeBtw: [Int]
(filteredVals, avgTime, timeBtw) = dataCruncher.processBin(allDataPackets)!

let vals = filteredVals.map { $0.value }
avgTime
timeBtw

//MARK: Calculate HR
func millsBetweenPoints(p1: Int, p2: Int) -> Double {
    p2 - p1
    let timePts = Double(p2 - p1) * avgTime
    let numPrintBins = (p2 - p1) / PACKET_DATA_SIZE
    let startingIndex = p1 / PACKET_DATA_SIZE
    
    var spanWithPrint = 0
    for var i = 0; i < numPrintBins && startingIndex + i < timeBtw.count; i++ {
        spanWithPrint += timeBtw[startingIndex + i]
    }
    spanWithPrint
    
    return timePts + Double(spanWithPrint)
}

let MINIMUM_TIME_SPAN = 100.0
let MILLS_PER_MIN = 60000.0
let peaks = dataCruncher.findPeaks(filteredVals)

var timeSpans = [Double]()
for var i=1; i < peaks.count; i++ {
    let p1 = peaks[i-1].point
    p1
    let p2 = peaks[i].point
    p2
    
    //FIXME?
    let time = millsBetweenPoints(p1, p2)
    time
    timeSpans.append(time)
}

timeSpans = timeSpans.filter { $0 > MINIMUM_TIME_SPAN }
timeSpans = timeSpans.map { $0/MILLS_PER_MIN }

var avgMap = [Double]()
for var i=0; i < timeSpans.count - 1; i++ {
    let t1 = timeSpans[i].0
    let t2 = timeSpans[i+1].0
    let avg = (t1 + t2) / 2
    avgMap.append(avg)
}

var sum = timeSpans.reduce(0.0) { $0 + $1 }
let avgBPM = sum/Double(timeSpans.count)

println("HR: \(avgBPM)")


millsBetweenPoints(3414, 3529)



