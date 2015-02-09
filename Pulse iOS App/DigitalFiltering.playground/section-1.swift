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
let file = "RLED_4mod10" //"IR_1mod5" //
let ext = file + ".csv"
let dir = pathToFileInSharedSubfolder()
let path = dir + ext

let csvFileContents = String(contentsOfFile:path, encoding: NSUTF8StringEncoding)
if csvFileContents == nil {
    abort()
}

let strValues = csvFileContents!.componentsSeparatedByString(",\n")

let values = strValues.map { NSString(string: $0).doubleValue }
println("Num values: \(values.count)")

/// MARK: Filtering

//Finite Impulse Response (FIR) filter
// http://www.arc.id.au/FilterDesign.html
struct FIRFilter {
//    let FIR_coeff = [0.1, 0.2, 1, 0.2, 0.1]
    let FIR_coeff = [0.4, 0.8, 1, 0.8, 0.4]

    var queue = [Double]()
    var data: [Double]
    
    init(inputData: [Double]) {
        let count = FIR_coeff.count
        data = Array(inputData[count..<inputData.count])
        queue += inputData[0..<count]
    }
    
    mutating func filter() -> [Double] {
        return data.map { value in
            self.queue.insert(value, atIndex: 0)
            self.queue.removeLast()
            
            var output = 0.0
            for (index,value) in enumerate(self.queue) {
                output += value * self.FIR_coeff[index]
            }
            return output
        }
    }
}


//FIXME: Slicing for speed
let someValues = Array(values[0..<800])
var lowpass = FIRFilter(inputData: someValues) //mutating
let filValues = lowpass.filter()

func writeValueAsCSV(value: String, toFilePath filePath: String) {
    
        let writePath = dir.stringByAppendingPathComponent(filePath);
        
        //writing
        value.writeToFile(writePath, atomically: false, encoding: NSUTF8StringEncoding, error: nil);
        
        //reading
        //        let text2 = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
}

let filStrValues = filValues.map { "\($0)" }
writeValueAsCSV(join(",", filStrValues), toFilePath: "\(file)FILTERED.csv")
