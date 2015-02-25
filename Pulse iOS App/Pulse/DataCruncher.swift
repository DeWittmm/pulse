//
//  DataCruncher.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/9/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import CoreBluetooth

let binCapacity = 800 / 20 //PacketCount

public protocol DataAnalysisDelegate: class {
    func analysingIRData(InfaredData: [Double])
    func analysingLEDData(redLEDData: [Double])
    
    func currentProgress(irDataProg: Double, ledDataProg: Double)
    
    func analysisFoundHeartRate(hr: Double)
    func analysisFoundSP02(sp02: Double)
}

public class DataCruncher {
    
    //MARK: Private Properties
    private var rawData = [UInt8]()

    //MARK: Properties
    var IRDataBin = [DataPacket]()
    var LEDDataBin = [DataPacket]()
    
    var IRPeaks = [DataPoint]()
    var LEDPeaks = [DataPoint]()
    
    public weak var delegate: DataAnalysisDelegate?
    
    public init() {}
    
    //MARK: Build filteredDataBin
    public func addDataForCrunching(data: [UInt8]) {
        rawData += data
        
        if let data = DataPacket(rawData: data) {
            crunchPacket(data)
            
            dispatch_async(dispatch_get_main_queue()) {
                
                let irProg = Double(self.IRDataBin.count)/Double(binCapacity)
                let ledProg = Double(self.LEDDataBin.count)/Double(binCapacity)
                
                self.delegate?.currentProgress(irProg, ledDataProg: ledProg)
            }
        }
    }
    
    func crunchPacket(packet: DataPacket) {
        
        switch packet.lightSource {
        case .IR:
            IRDataBin += [packet]
        case .RedLED:
            LEDDataBin += [packet]
        }
        
        if LEDDataBin.count > binCapacity {
            println("LED \(rawData)")

            var values: [DataPoint]
            if let info = processBin(LEDDataBin) {
                let peaks = findPeaks(info.0)
                LEDPeaks = peaks
                let hr = calculateHeartRate(peaks, avgTimeBtwPackets: info.2, avgTimePerPoint: info.1)
                
                let ledData = info.0.map { $0.value }
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.analysingLEDData(ledData)
                    self.delegate?.analysisFoundHeartRate(hr)
                }                
            }
            clear()
        }
        
        if IRDataBin.count > binCapacity {
            println("IR \(rawData)")

            var values: [DataPoint]
            if let info = processBin(IRDataBin) {
                let peaks = findPeaks(info.0)
                IRPeaks = peaks
                let hr = calculateHeartRate(info.0, avgTimeBtwPackets: info.2, avgTimePerPoint: info.1)
                
                let irData = info.0.map { $0.value }
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.analysingIRData(irData)
                    self.delegate?.analysisFoundHeartRate(hr)
                }
            }
            clear()
        }
        
        if !IRPeaks.isEmpty && !LEDPeaks.isEmpty {
//            println("Calculate SP02")
        }
    }
    
    func clear() {
        rawData.removeAll(keepCapacity: true)
        LEDDataBin.removeAll(keepCapacity: true)
        IRDataBin.removeAll(keepCapacity: true)
    }
    
    //MARK: Processing
    
    public func processBin(bin: [DataPacket]) -> (data: [DataPoint], avgTimeInPackets: Double, timeBtwPackets: Double)? {
        
        var data = [DataPoint]()
        for packet in bin {
            data += packet.dataPoints
        }
        
        //Reorder the DataPoint Indexs to be continuous
        var pointsDict = [Int:Double]()
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
        let totalTimeBtwBins = ltimesBtwPackets.reduce(0) { $0 + $1 }
        let avgTimeBtw = Double(totalTimeBtwBins) / Double(ltimesBtwPackets.count)
        
        return (data, avgTimePerPoint, avgTimeBtw)
    }
    
    public func filter(points: [DataPoint]) -> [DataPoint]? {
        
        let voltageValues = points.map { $0.value * ArudinoVoltageConversionFactor }
        
        if var lowPass =  FIRFilter(inputData: voltageValues) {
            let filteredValues = lowPass.filter()
            
            var filteredPoints = [DataPoint]()
            for var i=0; i < points.count; i++ {
                filteredPoints += [DataPoint(point: points[i].point, value: filteredValues[i])]
            }
            
            return filteredPoints
        }
        return nil
    }
    
    public func findPeaks(data: [DataPoint]) -> [DataPoint] {
        
        let dataDict = data.reduce([Int:Double]()) { (var dict, dataPt) in
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
        
        var peaks = [DataPoint]()
        
        for var i=0; i < slopes.count; i++ {
            let slopePoint = slopes[i]
            
            if slopePoint.value > MINIMUM_SLOPE {
                //Traverse Up
                let startIndex = i
                while i+1 < slopes.count {
                    if slopes[++i].value < 0 {
                        break
                    }
                }
                
                if startIndex + MINIMUM_SLOPE_LENGTH > i {
                    continue
                }
                
                //Potential Peak
                let pPeakIndex = slopes[i].point
                let endIndex = i
                
                //Traverse Down
                while i+1 < slopes.count &&
                    slopes[++i].value <= MINIMUM_DECLINE  {}
                
                if i < endIndex + MINIMUM_SLOPE_LENGTH {
                    continue
                }
                
                if let value = dataDict[pPeakIndex] {
                    peaks.append(DataPoint(point: pPeakIndex, value: value))
                }
            }
        }
        
        println("Found \(peaks.count) Peaks")
        return peaks
    }
    
    //MARK: Calculations (Should be private)
    public func calculateHeartRate(peaks: [DataPoint], avgTimeBtwPackets: Double, avgTimePerPoint: Double) -> Double {
        
        func millsBetweenPoints(p1: Int, p2: Int) -> Double {
            let timePts = Double(p2 - p1) * avgTimePerPoint
            let numPrintBins = (p2 - p1) / PACKET_DATA_SIZE
            let timeSpanBtwPrints = Double(numPrintBins) * avgTimeBtwPackets
            
            return timePts + timeSpanBtwPrints
        }
        
        var timeSpans = [Double]()
        for var i=1; i < peaks.count; i++ {
            let p1 = peaks[i-1].point
            let p2 = peaks[i].point
            
            let time = millsBetweenPoints(p1, p2)
            timeSpans.append(time)
        }
        
        timeSpans = timeSpans.filter { $0 > MINIMUM_TIME_SPAN }
        timeSpans = timeSpans.map { MILLS_PER_MIN/$0 }
        
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
    
    public func calcuateSPO2Ratio(avgTimeBtwPackets: Double, avgTimePerPoint: Double) -> Double {
        
//        let avgIR = IRPeaks.reduce(DataPoint.Zero()) { $0.value + $1.value }
        return 0.0
    }
}

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
