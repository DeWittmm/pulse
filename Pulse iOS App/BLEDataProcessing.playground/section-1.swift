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
var count = 19
for num in partValues {
    data.append(UInt8(num))
    
    if count-- <= 0 {
        if let packet = DataPacket(rawData: data) {
            allDataPackets.append(packet)
            data.removeAll(keepCapacity: true)
        }
        else {
            abort()
        }
        count = 19
    }
}

var filteredVals: [DataPoint]
var avgTime: Double
var avgtimeBtw: Double
(filteredVals, avgTime, avgtimeBtw) = dataCruncher.processBin(allDataPackets)!

let vals = filteredVals.map { $0.value }
avgTime
avgtimeBtw

//MARK:Peak Detection
let MaxValueTolerance = 0.75
let MINIMUM_SLOPE = 30.0
let STEP = 5
let MINIMUM_SLOPE_LENGTH = 5
public func findPeaks(data: [DataPoint]) -> [DataPoint] {
    
    var slopes = [DataPoint]()
    for var i=0; i + STEP < data.count; i++ {
        let dp = data[i]
        let sdp = data[i+STEP]
        let slope = (sdp.value - dp.value) / Double(STEP)
        
        slopes += [DataPoint(point: dp.point, value: slope)]
    }
    
    var peaks = [DataPoint]()

    for var i=0; i < slopes.count; i++ {
        let slopePoint = slopes[i]
        
        if slopePoint.value > MINIMUM_SLOPE {
            //Traverse Up
            while i+1 < slopes.count &&
                slopes[++i].value > 0  {}
            
            //Potential Peak
            let index = slopes[i].point
            let potentialPeak = data.filter { $0.point == index }.first
            let testi = i
            
            //Traverse Down
            while i+1 < slopes.count &&
                slopes[++i].value < 0  {}
            
            if testi < i + MINIMUM_SLOPE_LENGTH {
                if let peak = potentialPeak {
                    peaks.append(peak)
                }
            }
        }
    }
    
    println("Found \(peaks.count) Peaks")
    return peaks
}

//MARK: Calculate HR
let MIN_TIME_SPAN = 100.0
let MILLS_PER_MIN = 60000.0

public func calculateHeartRate(dataPoints: [DataPoint], avgTimeBtwPackets: Double, avgTimePerPoint: Double) -> Double {
    
    let peaks = findPeaks(dataPoints)
    
    func millsBetweenPoints(p1: Int, p2: Int) -> Double {
        let timePts = Double(p2 - p1) * avgTimePerPoint
        let numPrintBins = (p2 - p1) / PACKET_DATA_SIZE
        let timeSpanBtwPrints = Double(numPrintBins) * avgTimeBtwPackets
        
        return timePts + Double(timeSpanBtwPrints)
    }
    
    var timeSpans = [Double]()
    for var i=1; i < peaks.count; i++ {
        let p1 = peaks[i-1].point
        let p2 = peaks[i].point
        
        let time = millsBetweenPoints(p1, p2)
        timeSpans.append(time)
    }
    
    timeSpans = timeSpans.filter { $0 > MIN_TIME_SPAN }
    timeSpans = timeSpans.map { MILLS_PER_MIN/$0 }
    
    var avgMap = [Double]()
    for var i=0; i < timeSpans.count - 1; i++ {
        let t1 = timeSpans[i].0
        let t2 = timeSpans[i+1].0
        let avg = (t1 + t2) / 2
        avgMap.append(avg)
    }
    
    var sum = timeSpans.reduce(0.0) { $0 + $1 }
    let avgBPM = sum/Double(timeSpans.count)
    
    return avgBPM
}


let bpm = calculateHeartRate(filteredVals, avgtimeBtw, avgTime)
println("HR: \(bpm)")



