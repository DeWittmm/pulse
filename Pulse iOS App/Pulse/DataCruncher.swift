//
//  DataCruncher.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/9/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

//Finite Impulse Response (FIR) filter
// http://www.arc.id.au/FilterDesign.html
struct FIRFilter {
    //    let FIR_coeff = [0.1, 0.2, 1, 0.2, 0.1]
    let FIR_coeff = [0.4, 0.8, 1, 0.8, 0.4]
    
    var queue = [Double]()
    var data: [Double]
    
    init?(inputData: [Double]) {
        let count = FIR_coeff.count
        if count > inputData.count {
            return nil
        }
        
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

struct DataPoint {
    let point: Int
    let value: Double
    
    static func Zero() -> DataPoint {
        return DataPoint(point: 0, value: 0.0)
    }
}

func + (p1: DataPoint, p2: DataPoint) -> DataPoint {
    return DataPoint(point: p1.point + p2.point, value: p1.value + p2.value)
}

class DataCruncher {
    
    //MARK: Private Properties
    
    private let conversionFactor = 1024/5.0
    
    //MARK: Properties

    let filteredValues: [Double]
    
    init?(rawData: [UInt8]) {
        
        let voltageValues = rawData.map { Double($0) * 1024/5.0 }
        
        //Filtering
        if var lowPass =  FIRFilter(inputData: voltageValues) {
            filteredValues = lowPass.filter()
        }
        else {
            filteredValues = [0.0]
            return nil
        }
    }
    
    let MIN_TIME_SPAN = 100.0
    let MILLS_PER_MIN = 60000.0

    func calculateHeartRate() -> Double {
        
        let peaks = findPeaks()
        
        var timeSpans = [Double]()
        for var i=0; i < peaks.count - 1; i++ {
            let p1 = peaks[i].point
            let p2 = peaks[i+1].point
            
            let time = millsBetweenPoints(Double(p1), p2: Double(p2))
            timeSpans.append(time)
        }
        
        timeSpans = timeSpans.filter { $0 > self.MIN_TIME_SPAN }
        timeSpans = timeSpans.map { self.MILLS_PER_MIN/$0 }
        
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
    
    let BIN_PRINT_TIME  = 727.0
    let TIME_PER_POINT = 0.17
    private func millsBetweenPoints(p1: Double, p2: Double) -> Double {
        let timePts = (p2 - p1) * TIME_PER_POINT
        let numPrintBins = floor((p2 - p1) / 100)
        let spanWithPrint = BIN_PRINT_TIME * numPrintBins
        let milis = (timePts + spanWithPrint)
        
        return milis
    }
    
    private func findPeaks() -> [DataPoint] {
        let maxValue = filteredValues.reduce(0.0) { max($0, $1) }
        maxValue
        
        let maxValueTolerance = 0.75
        println("Max threshold: \(maxValue * maxValueTolerance)")
        var indicies = [DataPoint]()
        for (index, value) in enumerate(filteredValues) {
            if value >= maxValue * maxValueTolerance {
                indicies.append(DataPoint(point: index, value: value))
            }
        }
        
        //MARK: Clustering
        let HR_WIDTH = 100
        var peaks = [DataPoint]()
        func average(group: [DataPoint]) -> DataPoint {
            let count = group.count
            let total = group.reduce(DataPoint.Zero()){ $0 + $1 }
            
            return DataPoint(point: total.point / count, value: total.value / Double(count))
        }
        
        var cluster = [indicies.first!]
        for dataPoint in indicies {
            let width = cluster.first!.point + HR_WIDTH

            if  width > dataPoint.point {
                cluster.append(dataPoint)
            }
            else {
                let avg = average(cluster)
                peaks.append(avg)
                
                cluster.removeAll(keepCapacity: true)
                cluster.append(dataPoint)
            }
        }
        peaks.append(average(cluster))
        
        return peaks
    }
}
