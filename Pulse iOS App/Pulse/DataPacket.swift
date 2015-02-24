//
//  DataPacket.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/17/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

public struct DataPoint {
    public let point: Int
    public let value: Double
    
    public init(point: Int, value: Double) {
        self.point = point
        self.value = value
    }
    
    public static func Zero() -> DataPoint {
        return DataPoint(point: 0, value: 0.0)
    }
}

public func + (p1: DataPoint, p2: DataPoint) -> DataPoint {
    return DataPoint(point: p1.point + p2.point, value: p1.value + p2.value)
}

public enum LightSource: UInt8 {
    case RedLED = 0
    case IR = 1
}

let PACKET_SIZE = 19
public let PACKET_DATA_SIZE = 15
public let MAX_ARDUINO_TIME = 65535 //Before time bits roll over

public class DataPacket {
    
    public let dataPoints: [DataPoint]
    public let startTime: Int
    public let endTime: Int
    public let timePerPoint: Double
    public let lightSource:LightSource
    
    public var values: [Double] {
        return dataPoints.map { $0.value }
    }
    
    public var points: [Int] {
        return dataPoints.map { $0.point }
    }
    
    public init?(rawData: [UInt8]) {
//        println("DataPacket: \(rawData)")
        
        if rawData.count < PACKET_SIZE || (LightSource(rawValue: rawData[0]) == nil) {
            dataPoints = []
            timePerPoint = 0.0
            startTime = 0
            endTime = 0
            lightSource = .RedLED
            return nil
        }
        
        //Extract Header Info
        lightSource = LightSource(rawValue: rawData[0])!
        var startmillis = Int(rawData[2])
        startmillis <<= 8
        startmillis |= Int(rawData[1])
        startTime = startmillis
        
        var endmillis = Int(rawData[4])
        endmillis <<= 8
        endmillis |= Int(rawData[3])
        
        if startTime > endmillis { //control for wrap
            endmillis += MAX_ARDUINO_TIME
        }
        
        endTime = endmillis
        
        let rawValues = Array(rawData[5..<rawData.count])
        var pointTime = Double(endmillis - startmillis) / Double(rawValues.count)
        timePerPoint = pointTime * 2
        
        var indicies = [DataPoint]()
        for (index, value) in enumerate(rawValues) {
            indicies.append(DataPoint(point: index, value: Double(value)))
        }
        dataPoints = indicies
        
        if dataPoints.isEmpty || timePerPoint <= 0 {
            return nil
        }
    }
    
    init() {
        
        dataPoints = [DataPoint(point: 0, value: 0.0)]
        self.timePerPoint = 0
        self.lightSource = .RedLED
        self.startTime = 0
        self.endTime = 0
    }
}