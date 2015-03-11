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
let file = "BLEData5"
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
var count = BLE_PACKET_SIZE - 1
for num in partValues {
    data.append(UInt8(num))
    
    if count-- <= 0 {
        data.count
        if let packet = DataPacket(rawData: data) {
            allDataPackets.append(packet)
            data.removeAll(keepCapacity: true)
        }
        count = BLE_PACKET_SIZE - 1
    }
}
allDataPackets

var filteredVals: [DataPoint]
var avgTimePerPoint: Double
var avgtimeBtwBins: Double
(filteredVals, avgTimePerPoint, avgtimeBtwBins) = dataCruncher.processBin(allDataPackets)!

avgTimePerPoint
avgtimeBtwBins

//FIXME: Constant Times
avgTimePerPoint = 2.0
avgtimeBtwBins = 30

filteredVals.map { $0.value }

//MARK:Peak Detection
let STEP = 5
let DECLINE_CUTTOFF: Double = -1.0
let MINIMUM_SLOPE_LENGTH: Int = 10
let MINIMUM_SLOPE: Double = 1.0
public func findPeaks(data: [DataPoint]) -> [DataPoint] {
    
    let valueDict = data.reduce([Int:Double]()) { (var dict, dataPt) in
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
    slopes.count
    
    for var i=0; i < slopes.count; i++ {
        let slopePoint = slopes[i]
        
        //Find slope increase
        if slopePoint.value > minimumSlope {

            var peakVal = valueDict[slopePoint.point]
            while slopes[i-1].value < slopes[i++].value {
                peakVal = valueDict[slopes[i-1].point]
            }
            
            //Traverse Down
            var runIndex = i
            while runIndex+1 < slopes.count {
                let slo = slopes[++runIndex]
                if let val = valueDict[slo.point] where val >= peakVal {
                    peakVal = val
                }
                else if slo.value < DECLINE_CUTTOFF { //Only break when back in significant decrease (slope < 0)
                    break
                }
            }
            
            runIndex
            peakVal
            
            if runIndex < i + MINIMUM_SLOPE_LENGTH {
                continue
            }
            i = runIndex //Skip index past found peak
            
            let peakIndex = slopes[runIndex].point
            if let value = valueDict[peakIndex] {
                peaks.append(DataPoint(point: peakIndex, value: value))
            }
        }
    }
    
    println("Found \(peaks.count) Peaks")
    return peaks
}

let peaks = findPeaks(filteredVals)
//Typically 
// ~200 points between peaks
// ~690 for peak values

//Based off values from BLEData3
let testPeaks = [DataPoint(point: 150, value: 697), DataPoint(point: 249, value: 697)]

let bpm = dataCruncher.calculateHeartRate(peaks, avgTimeBtwPackets: avgtimeBtwBins, avgTimePerPoint: avgTimePerPoint)
println("HR: \(bpm)")
