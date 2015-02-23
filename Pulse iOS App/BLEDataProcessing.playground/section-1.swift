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
let file = "RealDealArduino2" //"IR_1mod5FILTERED" //"RLED_3
let ext = file + "FILTERED.csv"
let dir = pathToFileInSharedSubfolder()
let path = dir + ext

let csvFileContents = String(contentsOfFile:path, encoding: NSUTF8StringEncoding)
if csvFileContents == nil {
    abort()
}

let strValues = csvFileContents!.componentsSeparatedByString(",")

let values = strValues.map { NSString(string: $0).doubleValue }
println("Num values: \(values.count)")

let dataCruncher = DataCruncher()

var packet = [UInt8]()
for num in values {
    if num < 0{
        let data = DataPacket(rawData: packet)!
        dataCruncher.addDataPacket(data)
        packet.removeAll(keepCapacity: true)
    }
    else {
        packet.append(UInt8(num))
    }
}

//MARK: Finding peaks