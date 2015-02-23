// Playground - noun: a place where people can play

import Foundation
import BLEDataProcessing
import XCPlayground


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

public func processBin(bin: [DataPacket]) -> (filteredPoints: [DataPoint], avgTimeInPackets: Double, timeBtwPackets: [Int])? {
    
    var data = [DataPoint]()
    for packet in bin {
        data += packet.dataPoints
    }
    
    //Reorder the DataPoint Indexs to be continuous
    for var i = 0; i < data.count; i++ {
        let point = data[i]
        data[i] = DataPoint(point: i, value: point.value)
    }
    
    let timesPerPoint = bin.map { packet in
        return packet.timePerPoint // * Double(packet.dataPoints.count)
    }
    let totalTimeInPacket = timesPerPoint.reduce(0.0) { $0 + $1 }
    let avgTimePerPoint = totalTimeInPacket / Double(timesPerPoint.count)
    
    var ltimesBtwPackets = [Int]()
    for var i=1; i < bin.count; i++ {
        let firstPacket = bin[i-1]
        let secondPacket = bin[i]
        
        var startTime = secondPacket.startTime
        if secondPacket.startTime < firstPacket.endTime {
            startTime += MAX_ARDUINO_TIME
        }
        ltimesBtwPackets += [startTime - firstPacket.endTime]
    }
    
    //Filtering
    let voltageValues = data.map { $0.value * ArudinoVoltageConversionFactor }
    if var lowPass =  FIRFilter(inputData: voltageValues) {
        let filteredValues = lowPass.filter()
        
        var filteredPoints = [DataPoint]()
        for var i=0; i < data.count; i++ {
            filteredPoints += [DataPoint(point: data[i].point, value: filteredValues[i])]
        }
        
        return (filteredPoints, avgTimePerPoint, ltimesBtwPackets)
    }
    return nil
}

var filteredVals: [DataPoint]
var avgTime: Double
var timeBtw: [Int]
(filteredVals, avgTime, timeBtw) = processBin(allDataPackets)!


func writeValueAsCSV(value: String, toFilePath filePath: String) {
    
    let writePath = dir.stringByAppendingPathComponent(filePath);
    
    //writing
    value.writeToFile(writePath, atomically: false, encoding: NSUTF8StringEncoding, error: nil);
}

let vals = filteredVals.map { $0.value }
let filStrValues = vals.map { "\($0)" }
writeValueAsCSV(join(",", filStrValues), toFilePath: "\(file)FILTERED.csv")
