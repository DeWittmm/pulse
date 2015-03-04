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
    var graphView: BEMSimpleLineGraphView? {
        didSet {
            formatGraph()
        }
    }
    
    var maxValue:CGFloat = 900.0
    var minValue:CGFloat = 200.0
    
    private var refreshDate = NSDate()
    private var minRefreshTime: NSTimeInterval = 1.5
    
    var data:[Double] = [Double]() {
        didSet {
            refresh()
        }
    }
    
    func formatGraph() {
        if let graphView = graphView {
            graphView.colorTop = UIColor.clearColor()
            graphView.colorBottom = UIColor.clearColor()
            graphView.widthLine = 3.5
            graphView.enableTouchReport = true
            graphView.enablePopUpReport = true
            
            graphView.autoScaleYAxis = true
            //  graphView.enableYAxisLabel = true
            //  graphView.alwaysDisplayDots = true
            
            graphView.delegate = self
            graphView.dataSource = self
        }
    }
    
    func refresh() {
        let interval = -self.refreshDate.timeIntervalSinceNow
        if  interval > minRefreshTime {
            graphView?.reloadGraph()
            refreshDate = NSDate()
            
//            println("MaxValue: \(graphView?.calculateMaximumPointValue())")
//            println("MinValue: \(graphView?.calculateMinimumPointValue())")
        }
    }
    
    //MARK: LineGraphDelegate
    
    func lineGraph(graph: BEMSimpleLineGraphView!, alwaysDisplayPopUpAtIndex index: CGFloat) -> Bool {
        return true
    }
    
    func maxValueForLineGraph(graph: BEMSimpleLineGraphView!) -> CGFloat {
        return maxValue
    }

    func minValueForLineGraph(graph: BEMSimpleLineGraphView!) -> CGFloat {
        return minValue
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

private var handle: UInt8 = 0;

extension GraphDelegate: Bondable {
    var designatedBond: Bond<[Double]> {
        if let b: AnyObject = objc_getAssociatedObject(self, &handle) {
            return b as! Bond<[Double]>
        } else {
            let b = Bond<[Double]>() { [unowned self] v in self.data = v }
            objc_setAssociatedObject(self, &handle, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return b
        }
    }
}