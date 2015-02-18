//
//  DataPacket.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/17/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

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

enum LightSource: UInt8 {
    case RedLED = 2
    case IR = 10
}

class DataPacket {
    
    let dataPoints: [DataPoint]
    let timePerPoint: Double
    let lightSource:LightSource
    
    var values: [Double] {
        return dataPoints.map { $0.value }
    }
    
    var points: [Int] {
        return dataPoints.map { $0.point }
    }
    
    init(values: [Double], points: [Int], timePerPoint: Double, lightSource: LightSource) {
        
        var i = 0
        dataPoints = values.map { DataPoint(point: points[i++], value: $0) }
        self.timePerPoint = timePerPoint
        self.lightSource = lightSource
    }
    
    init?(rawData: [UInt8]) {
        
        if rawData.count < 3 {
            dataPoints = []
            timePerPoint = 0.0
            lightSource = .RedLED
            return nil
        }
        
        //Extract Header Info
        lightSource = LightSource(rawValue: rawData[0])!
        let startmillis = rawData[1]
        let endmilis = rawData[2]
        
        let rawValues = Array(rawData[3..<rawData.count])
        timePerPoint = Double(endmilis - startmillis) / Double(rawValues.count)
        
        var indicies = [DataPoint]()
        for (index, value) in enumerate(rawValues) {
            indicies.append(DataPoint(point: index, value: Double(value)))
        }
        dataPoints = indicies
        
        if dataPoints.isEmpty || timePerPoint < 0 {
            return nil
        }
    }
    
}