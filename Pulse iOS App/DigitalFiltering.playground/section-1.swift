// Playground - noun: a place where people can play

import Foundation
import XCPlayground

func pathToFileInSharedSubfolder() -> String {
    return XCPSharedDataDirectoryPath +
        "/" +
        NSProcessInfo.processInfo().processName +
        "/"
}

//MARK: Read in CSV
let file = "RealDealArduino2"//"RLED_4mod10" //"IR_1mod5" //
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

/// MARK: Filtering

//Finite Impulse Response (FIR) filter
// http://www.arc.id.au/FilterDesign.html
public struct FIRFilter {
    //    static let FIR_coeff = [0.1, 0.2, 1, 0.2, 0.1]
    static let FIR_coeff = [0.4, 0.8, 1, 0.8, 0.4]
    
    var queue: [Double]
    var data: [Double]
    
    public init?(inputData: [Double]) {
        let order = FIRFilter.FIR_coeff.count
        if order > inputData.count {
            return nil
        }
        
        data = inputData
        queue = [Double](count: order, repeatedValue: 1.0)
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


//FIXME: Slicing for speed
let someValues = Array(values[0..<values.count/2])
//let reasonableValues = someValues.filter { $0 < 1000.0 && $0 > 200 }
let conversionFactor = 4.0 / 1023.0
let voltageValues = someValues.map { Double($0) * conversionFactor }

var lowpass = FIRFilter(inputData: voltageValues)! //mutating
let filValues = lowpass.filter()
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
