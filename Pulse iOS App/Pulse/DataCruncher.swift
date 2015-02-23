//
//  DataCruncher.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/9/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import CoreBluetooth

// Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V)
let ArudinoVoltageConversionFactor = 1.0 //4.0 / 1023.0
let binCapacity = 800 / 20 //PacketCount

public protocol DataAnalysisDelegate: class {
    func analysingData(InfaredData: [Double], RedLEDData: [Double])
    func analysisFoundHeartRate(hr: Double)
}

public class DataCruncher {
    
    //MARK: Private Properties

    //MARK: Properties
    var IRDataBin = [DataPacket]()
    var LEDDataBin = [DataPacket]()
    
    var timesBtwPackets = [Int]()
    var timePerPoint: Double = 0.0
    
    public weak var delegate: DataAnalysisDelegate?
    
    public var binPercentage: Double {
        return Double(self.IRDataBin.count)/Double(binCapacity)
    }
    
    public init() {
    }
    
    //MARK: Build filteredDataBin
    
    public func addDataPacket(packet: DataPacket) {
        
        switch packet.lightSource {
        case .IR:
            IRDataBin += [packet]
        case .RedLED:
            LEDDataBin += [packet]
        }
        
        if LEDDataBin.count > binCapacity {
            var values: [DataPoint]
            (values, timePerPoint, timesBtwPackets) = processBin(LEDDataBin)!
            let hr = calculateHeartRate(values)
            
            let ledData = values.map { $0.value }
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.analysingData([], RedLEDData: ledData)
                self.delegate?.analysisFoundHeartRate(hr)
            }
            
            totalTime()
            clear()
        }
        
        if IRDataBin.count > binCapacity {
            var values: [DataPoint]
            (values, timePerPoint, timesBtwPackets) = processBin(LEDDataBin)!
            let hr = calculateHeartRate(values)
            
            let irData = values.map { $0.value }
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.analysingData(irData, RedLEDData:[])
                self.delegate?.analysisFoundHeartRate(hr)
            }
            
            clear()
        }
    }
    
    func clear() {
        LEDDataBin.removeAll(keepCapacity: true)
        IRDataBin.removeAll(keepCapacity: true)

        timesBtwPackets.removeAll(keepCapacity: true)
    }
    
    func totalTime() {
        let totalTimeBtw = timesBtwPackets.reduce(0){ $0 + $1 }
        let totalTimeIn = timePerPoint * Double(timesBtwPackets.count)
        let total = Double(totalTimeBtw) + totalTimeIn
        println("TimeBtw: \(totalTimeBtw) TimeIn: \(totalTimeIn)")
        println("Total TimeGraphs: \(total)")
    }
    
    //MARK: Processing
    
    func processBin(bin: [DataPacket]) -> (filteredPoints: [DataPoint], avgTimeInPackets: Double, timeBtwPackets: [Int])? {
        
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
            if secondPacket.startTime > firstPacket.endTime {
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
            
            assert(filteredPoints.count == ltimesBtwPackets.count, "Data Mismatch")
            
            return (filteredPoints, avgTimePerPoint, ltimesBtwPackets)
        }
        return nil
    }
    
    //MARK: Calculations
    
    let MIN_TIME_SPAN = 100.0
    let MILLS_PER_MIN = 60000.0
    func calculateHeartRate(dataPoints: [DataPoint]) -> Double {
        
        let peaks = findPeaks(dataPoints)
        
        var timeSpans = [Double]()
        for var i=1; i < peaks.count; i++ {
            let p1 = peaks[i-1].point
            let p2 = peaks[i].point
            
            //FIXME?
            let time = millsBetweenPoints(p1, p2: p2)
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
    
    //Original values
//    let BIN_PRINT_TIME  = 727.0
//    let TIME_PER_POINT = 0.17
    private func millsBetweenPoints(p1: Int, p2: Int) -> Double {
        let timePts = Double(p2 - p1) * self.timePerPoint
        let numPrintBins = (p2 - p1) / DATA_SIZE
        let startingIndex = p1 / DATA_SIZE
        
        var spanWithPrint = 0
        for var i = 0; i < numPrintBins; i++ {
            spanWithPrint += self.timesBtwPackets[startingIndex + i]
        }
        
        return timePts + Double(spanWithPrint)
    }
    
    let MaxValueTolerance = 0.75
    let HR_WIDTH = 100
    private func findPeaks(data: [DataPoint]) -> [DataPoint] {
        
        let values = data.map { $0.value }
        let maxValue = values.reduce(0.0) { max($0, $1) }
        
        let indicies = data.filter {
            $0.value >= maxValue * self.MaxValueTolerance
        }
        println("Max threshold: \(maxValue * MaxValueTolerance)")
        
        //Clustering
        var peaks = [DataPoint]()
        
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
        
        println("Found \(peaks.count) Peaks")
        return peaks
    }
}

func average(group: [DataPoint]) -> DataPoint {
    let count = group.count
    let total = group.reduce(DataPoint.Zero()){ $0 + $1 }
    
    return DataPoint(point: total.point / count, value: total.value / Double(count))
}

//Finite Impulse Response (FIR) filter
// http://www.arc.id.au/FilterDesign.html
struct FIRFilter {
    //    static let FIR_coeff = [0.1, 0.2, 1, 0.2, 0.1]
    static let FIR_coeff = [0.4, 0.8, 1, 0.8, 0.4]
    
    var queue = [Double]()
    var data: [Double]
    
    init?(inputData: [Double]) {
        let count = FIRFilter.FIR_coeff.count
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
                output += value * FIRFilter.FIR_coeff[index]
            }
            return output
        }
    }
}
