// Playground - noun: a place where people can play

import Cocoa

//MARK: Read in CSV
let file = "~/RLED_3.csv" //
let expandedPath = file.stringByExpandingTildeInPath

let csvFileContents = String(contentsOfFile:expandedPath, encoding: NSUTF8StringEncoding)
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
    let FIR_coeff = [0.0, 0.2, 0.5, 0.2, 0.0]
    var queue = [Double]()
    var data: [Double]
    
    init(inputData: [Double]) {
        data = Array(inputData[5..<inputData.count])
        queue += inputData[0..<5]
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