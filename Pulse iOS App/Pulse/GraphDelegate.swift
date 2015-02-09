//
//  HRGraphDelegate.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/9/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

class GraphDelegate: NSObject, BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate {
    
    //MARK: Properties
    var dataBinSize = 100
    
    private var graphView: BEMSimpleLineGraphView
    private var data = [CGFloat]()
    
    init(graph: BEMSimpleLineGraphView) {
        graphView = graph
        super.init()

        graphView.widthLine = 3.0
        graphView.enablePopUpReport = true
        graphView.delegate = self
        graphView.dataSource = self
    }
    
    func addData(newData: [CGFloat]) {
        data += newData
        if data.count > dataBinSize {
            data.removeRange(dataBinSize...data.count)
        }
        
        graphView.reloadGraph()
    }
    
    //MARK: LineGraphDelegate
    
    func lineGraph(graph: BEMSimpleLineGraphView!, alwaysDisplayPopUpAtIndex index: CGFloat) -> Bool {
        return true
    }
    
    //MARK: LineGraphDataSource
    
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView!) -> Int {
        graphView = graph
        
        return data.count
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView!, valueForPointAtIndex index: Int) -> CGFloat {
        
        return data[index]
    }
    
}