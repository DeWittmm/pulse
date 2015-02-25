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
let file = "BLEData4"
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

let partValues = Array(values[0..<values.count])

//MARK: Processing
let dataCruncher = DataCruncher()

var data = [UInt8]()
var allDataPackets = [DataPacket]()
var count = 19
for num in partValues {
    data.append(UInt8(num))
    
    if count-- <= 0 {
        data
        if let packet = DataPacket(rawData: data) {
            allDataPackets.append(packet)
            data.removeAll(keepCapacity: true)
        }
        count = 19
    }
}
allDataPackets

var vals: [DataPoint]
var avgTimePerPoint: Double
var avgtimeBtwBins: Double
(vals, avgTimePerPoint, avgtimeBtwBins) = dataCruncher.processBin(allDataPackets)!

avgTimePerPoint
avgtimeBtwBins

//avgTimePerPoint = 4.5
//avgtimeBtwBins = 52

let rawVals = vals.map { $0.value }

vals = vals.filter { $0.value > 20 }
let filteredVals = dataCruncher.filter(vals)!
filteredVals.map { $0.value }

//MARK:Peak Detection
let STEP = 5
let MINIMUM_DECLINE = 10.0
let MINIMUM_SLOPE_LENGTH = 10
let MINIMUM_SLOPE = 2.0
public func findPeaks(data: [DataPoint]) -> [DataPoint] {
    
    let dataDict = data.reduce([Int:Double]()) { (var dict, dataPt) in
        dict[dataPt.point] = dataPt.value
        return dict
    }
    
    var slopes = [DataPoint]()
    for var i=0; i + STEP < data.count; i++ {
        let dp = data[i]
        let sdp = data[i+STEP]
        let slope = (sdp.value - dp.value) / Double(STEP)
        
        slopes += [DataPoint(point: dp.point, value: slope)]
    }
    let sVals = slopes.map { $0.value }.filter{ $0 > MINIMUM_SLOPE }
    let minimumSlope = sVals.reduce(0.0) { $0 + $1 } / Double(sVals.count)
    minimumSlope
    
    var peaks = [DataPoint]()
    for var i=0; i < slopes.count; i++ {
        let slopePoint = slopes[i]
        
        if slopePoint.value > minimumSlope {
            //Traverse Up
            let startIndex = i
            while i+1 < slopes.count {
                if slopes[++i].value < 0 {
                    break
                }
            }
            
            if startIndex + MINIMUM_SLOPE_LENGTH > i {
                continue
            }
            
            //Potential Peak
            let pPeakIndex = slopes[i].point
            let endIndex = i
            
            //Traverse Down
            while i+1 < slopes.count {
                if slopes[++i].value > MINIMUM_DECLINE {
                    break
                }
            }
            i
            if i < endIndex + MINIMUM_SLOPE_LENGTH {
                continue
            }

            if let value = dataDict[pPeakIndex] {
                peaks.append(DataPoint(point: pPeakIndex, value: value))
            }
        }
    }
    
    println("Found \(peaks.count) Peaks")
    return peaks
}

//MARK: Calculate HR
let MINIMUM_HR_TIME_SPAN = 100.0
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
    
    timeSpans = timeSpans.filter { $0 > MINIMUM_HR_TIME_SPAN }
    timeSpans = timeSpans.map { MILLS_PER_MIN/$0 }
    
    timeSpans
    
    var avgMap = [Double]()
    for var i=0; i < timeSpans.count - 1; i++ {
        let t1 = timeSpans[i].0
        let t2 = timeSpans[i+1].0
        let avg = (t1 + t2) / 2
        avgMap.append(avg)
    }
    
    let avgBPM = timeSpans.reduce(0.0) { $0 + $1 } / Double(timeSpans.count)
    
    return avgBPM
}

let bpm = calculateHeartRate(filteredVals, avgtimeBtwBins, avgTimePerPoint)
println("HR: \(bpm)")
