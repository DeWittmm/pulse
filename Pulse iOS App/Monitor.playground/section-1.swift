// Playground - noun: a place where people can play

import Cocoa

//Read in CSV
let file = "IR_1mod5.csv"


let dir = "\(NSHomeDirectory())/Documents/"
let path = dir.stringByAppendingPathComponent(file);

if let csvFileContents = String(contentsOfFile:path, encoding: NSUTF8StringEncoding) {

    let strValues = csvFileContents.componentsSeparatedByString(",\n")

    //Run Analysis
    let values = strValues.map { NSString(string: $0).doubleValue  }

    let maxValue = values.reduce(0.0) { max($0, $1) }
    maxValue

    let tolerance = 0.95

    var indicies = [(Int, Double)]()
    for (index, value) in enumerate(values) {
        if value >= maxValue * tolerance {
            indicies.append((index, value))
        }
    }
    indicies
        
    let minValue = values.reduce(5.0) { min($0, $1) }
    minValue
    
}

