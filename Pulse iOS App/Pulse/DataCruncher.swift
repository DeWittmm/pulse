//
//  DataCruncher.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/9/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import CoreBluetooth

public protocol DataAnalysisDelegate: class {
    func analysingIRData(InfaredData: [Double], foundPeaks: Int)
    func analysingLEDData(redLEDData: [Double], foundPeaks: Int)
    
    func currentProgress(irDataProg: Double, ledDataProg: Double)
    
    func analysisFoundHeartRate(hr: Double)
    func analysisFoundSP02(sp02: Double)
}

public class DataCruncher {
    
    //MARK: Private Properties
//    private var rawData = [UInt8]()

    //MARK: Properties
    var IRDataBin = [DataPacket]()
    var LEDDataBin = [DataPacket]()
    
    var peaks = [LightSource: [DataPoint]]()
    
    public weak var delegate: DataAnalysisDelegate?
    
    public init() {}
    
    //MARK: Build filteredDataBin
    public func addDataForCrunching(data: [UInt8]) {
        
        if let data = DataPacket(rawData: data) {
            
            let irProg = Double(self.IRDataBin.count)/Double(binCapacity)
            let ledProg = Double(self.LEDDataBin.count)/Double(binCapacity)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.currentProgress(irProg, ledDataProg: ledProg)
            }
            
            crunchPacket(data)
        }
    }
    
    func crunchPacket(packet: DataPacket) {
        
        switch packet.lightSource {
        case .IR:
            IRDataBin += [packet]
        case .RedLED:
            LEDDataBin += [packet]
        }
        
        if LEDDataBin.count >= binCapacity {
//            println("LED \(rawData)")
            analyzeBinForLightSource(packet.lightSource)
        }
        
        if IRDataBin.count >= binCapacity {
//            println("IR \(rawData)")
            analyzeBinForLightSource(packet.lightSource)
        }
    }
    
    func clear() {
        LEDDataBin.removeAll(keepCapacity: true)
        IRDataBin.removeAll(keepCapacity: true)
    }
    
    //MARK: Analysis
    
    func analyzeBinForLightSource(source: LightSource) {
        
        var values: [DataPoint]
        let bin = source == .IR ? IRDataBin : LEDDataBin
        clear() //clear immediatly to allow bins to continue building
        
        if let info = processBin(bin) {
            let newPeaks = findPeaks(info.0)
            peaks.updateValue(newPeaks, forKey:source)
            
            let hr = calculateHeartRate(newPeaks, avgTimeBtwPackets: info.2, avgTimePerPoint: info.1)
            
            let data = info.0.map { $0.value }
            dispatch_async(dispatch_get_main_queue()) {
                switch source {
                case .IR:
                    self.delegate?.analysingIRData(data, foundPeaks: newPeaks.count)
                    self.delegate?.analysisFoundHeartRate(hr)
                case .RedLED:
                    self.delegate?.analysingLEDData(data, foundPeaks: newPeaks.count)
                }
            }
        }
        
        if let irPeaks = peaks[.IR], let ledPeaks = peaks[.IR] where irPeaks.count > 2 && ledPeaks.count > 2 {
            let spO2 = calculateBloodOxygenSaturation(ledPeaks, irPeaks: irPeaks)
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.analysisFoundSP02(spO2)
            }
        }
    }
    
    //MARK: Processing
    public func processBin(bin: [DataPacket]) -> (data: [DataPoint], avgTimeInPackets: Double, timeBtwPackets: Double)? {
        
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
            return packet.timePerPoint
        }
        
        let totalTimeInPacket = timesPerPoint.reduce(0.0) { $0 + $1 }
        var avgTimePerPoint = totalTimeInPacket / Double(timesPerPoint.count)
        
        var ltimesBtwPackets = [Int]()
        for var i=1; i < bin.count; i++ {
            let firstPacket = bin[i-1]
            let secondPacket = bin[i]
            
//            var startTime = secondPacket.startTime
//            if secondPacket.startTime < firstPacket.endTime {
//                startTime += MAX_ARDUINO_TIME
//            }
//            ltimesBtwPackets += [startTime - firstPacket.endTime]
        }
        let totalTimeBtwBins = ltimesBtwPackets.reduce(0) { $0 + $1 }
        var avgtimeBtwPaks = Double(totalTimeBtwBins) / Double(ltimesBtwPackets.count)
        
//        println("AvgTimePerPt: \(avgTimePerPoint), AvgTimeBtwPak: \(avgtimeBtwPaks)")
        
        //FIXME: Constant Times
        avgTimePerPoint = 2.0
        avgtimeBtwPaks = 40
        
        if let filetedPts = filter(data) {
            return (filetedPts, avgTimePerPoint, avgtimeBtwPaks)
        }
        return nil
    }
    
    func filter(var points: [DataPoint]) -> [DataPoint]? {
        
        points = points.filter { $0.value > VALUE_CUTTOFF }
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
        
        let valueDict = data.reduce([Int:Double]()) { (var dict, dataPt) in
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
        let sVals = slopes.map { $0.value }.filter{ $0 > MINIMUM_SLOPE }
        let minimumSlope = sVals.reduce(0.0) { $0 + $1 } / Double(sVals.count)
        minimumSlope
        
        var peaks = [DataPoint]()
        slopes.count
        
        for var i=0; i < slopes.count; i++ {
            let slopePoint = slopes[i]
            
            //Find slope increase
            if slopePoint.value > minimumSlope {
                
                var peakVal = valueDict[slopePoint.point]
                while i < slopes.count &&
                    slopes[i-1].value < slopes[i++].value {
                    peakVal = valueDict[slopes[i-1].point]
                }
                
                //Traverse Down
                var runIndex = i
                while runIndex + 1 < slopes.count {
                    let slo = slopes[++runIndex]
                    if let val = valueDict[slo.point] where val >= peakVal {
                        peakVal = val
                    }
                    else if slo.value < DECLINE_CUTTOFF { //Only break when back in significant decrease (slope < 0)
                        break
                    }
                }
                
                if runIndex < i + MINIMUM_SLOPE_LENGTH {
                    continue
                }
                i = runIndex //Skip index past found peak
                
                let peakIndex = slopes[runIndex].point
                if let value = valueDict[peakIndex] {
                    peaks.append(DataPoint(point: peakIndex, value: value))
                }
            }
        }
        
//        println("Found \(peaks.count) Peaks")
        return peaks
    }
    
    //MARK: Calculations (Should be private - exposed for playground)
    public func calculateHeartRate(peaks: [DataPoint], avgTimeBtwPackets: Double, avgTimePerPoint: Double) -> Double {
        
        
        func millsBetweenPoints(p1: Int, p2: Int) -> Double {
            let timePts = Double(p2 - p1) * avgTimePerPoint
            let numPrintBins = (p2 - p1) / PACKET_DATA_SIZE
            let timeSpanBtwPrints = Double(numPrintBins) * avgTimeBtwPackets
            
            return timePts + Double(timeSpanBtwPrints)
        }
        
        var timeSpans = [Double]()
        for var i=1; i < peaks.count; i++ {
            let p1 = peaks[i-1].point
            let p2 = peaks[i].point
            
            let time = millsBetweenPoints(p1, p2)
            timeSpans.append(time)
        }
        
        timeSpans = timeSpans.filter { $0 > MINIMUM_HR_TIME_SPAN }
        timeSpans = timeSpans.map { MILLS_PER_MIN/$0 }
                
        var avgMap = [Double]()
        for var i=0; i < timeSpans.count - 1; i++ {
            let t1 = timeSpans[i].0
            let t2 = timeSpans[i+1].0
            let avg = (t1 + t2) / 2
            avgMap.append(avg)
        }
        
        return avg(timeSpans)
    }
    
    func calculateBloodOxygenSaturation(ledPeaks: [DataPoint], irPeaks: [DataPoint]) -> Double {
        
        //First Pass
        println("\(ledPeaks.count) LEDPeaks, \(irPeaks.count) IRPeaks")
        
        var ledGen = ledPeaks.generate()
        var irGen = irPeaks.generate()
        
        var peakRatios = [Double]()
        while let irPeak = irGen.next(),
            let ledPeak = ledGen.next() {
                
                let calRED = ledPeak.value * IR_RED_RATIO
                peakRatios.append(calRED/ledPeak.value)
        }
        
        return avg(peakRatios)
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
