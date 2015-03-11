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
let file = "BLEData5" //"IR_1mod5" //
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
var points = [DataPoint]()
for packet in allDataPackets {
    points += packet.dataPoints
}

//FIXME: Slicing for speed
//let reasonableValues = someValues.filter { $0 < 1000.0 && $0 > 200 }
let conversionFactor = 1.0 //4.0 / 1023.0
let voltageValues = points.map { $0.value * conversionFactor }.filter { $0 > 0.0 }

let mapVs = voltageValues.map { $0 }

/// MARK: Filtering

//Finite Impulse Response (FIR) filter
// http://www.arc.id.au/FilterDesign.html
public struct FIRFilter {
    static let FIR_coeff = [0.4, 0.8, 1, 0.8, 0.4]
    
    var queue: [Double]
    var data: [Double]
    
    public init?(inputData: [Double]) {
        let order = FIRFilter.FIR_coeff.count
        if order > inputData.count {
            return nil
        }
        
        data = inputData
        queue = Array(inputData[0..<order])
    }
    
    public mutating func filter() -> [Double] {
        return data.map { value in
            self.queue.insert(value, atIndex: 0)
            self.queue.removeLast()
            
            var output = 0.0
            for (index,value) in enumerate(self.queue) {
                output += value * FIRFilter.FIR_coeff[index]
            }
            return output
        }
    }
}

var lowpass = FIRFilter(inputData: voltageValues)! //mutating
let filValues = lowpass.filter()
let vilVs = filValues.map { $0 }
filValues.count
voltageValues.count

func writeValueAsCSV(value: String, toFilePath filePath: String) {
    
        let writePath = dir.stringByAppendingPathComponent(filePath);
        
        //writing
        value.writeToFile(writePath, atomically: false, encoding: NSUTF8StringEncoding, error: nil);
        
        //reading
        //        let text2 = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
}

let filStrValues = filValues.map { "\($0)" }
writeValueAsCSV(join(",", filStrValues), toFilePath: "\(file)FILTERED.csv")
