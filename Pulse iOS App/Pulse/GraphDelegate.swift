//
//  graphViewDelegate.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/9/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

class GraphDelegate: NSObject, BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate {
    
    //MARK: Properties    
    private var graphView: BEMSimpleLineGraphView
    
    private var refreshDate = NSDate()
    private var minRefreshTime: NSTimeInterval = 2.5
    
    var data:[Double] = [Double]() {
        didSet {
            refresh()
        }
    }
    
    init(graph: BEMSimpleLineGraphView) {
        graphView = graph
        super.init()

        graphView.colorTop = UIColor.clearColor()
        graphView.colorBottom = UIColor.clearColor()
        graphView.backgroundColor = UIColor.clearColor()
        graphView.widthLine = 4.0
        graphView.enableTouchReport = true
        graphView.enablePopUpReport = true
//        graphView.enableYAxisLabel = true
        graphView.autoScaleYAxis = true
//        graphView.enableReferenceYAxisLines = true
//        graphView.alwaysDisplayDots = true
        graphView.delegate = self
        graphView.dataSource = self
    }
    
    func refresh() {
        let interval = -self.refreshDate.timeIntervalSinceNow
        if  interval > minRefreshTime {
            graphView.reloadGraph()
            refreshDate = NSDate()
            
//            println("MaxValue: \(graphView.calculateMaximumPointValue())")
//            println("MinValue: \(graphView.calculateMinimumPointValue())")
        }
    }
    
    //MARK: LineGraphDelegate
    
    func lineGraph(graph: BEMSimpleLineGraphView!, alwaysDisplayPopUpAtIndex index: CGFloat) -> Bool {
        return true
    }
    
    func maxValueForLineGraph(graph: BEMSimpleLineGraphView!) -> CGFloat {
        return 450.0
    }

    func minValueForLineGraph(graph: BEMSimpleLineGraphView!) -> CGFloat {
        return 150.0
    }
    
    //MARK: LineGraphDataSource
    
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView!) -> Int {
        graphView = graph
        
        return data.count
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView!, valueForPointAtIndex index: Int) -> CGFloat {
        
        return CGFloat(data[index])
    }
    
}