//
//  GoalViewController.swift
//  Pulse
//
//  Created by Michael DeWitt on 1/21/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit

class GoalViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var targetLabel: UILabel!
    
    @IBOutlet weak var actualVerticalSpace: UILabel!
    @IBOutlet weak var targetBannerVerticalSpace: NSLayoutConstraint!
    
    
    private let MAX_HR = 180
    private let MIN_HR = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func panGesture(sender: UIPanGestureRecognizer) {
        
        let point = sender.locationInView(view)
        if sender.state == .Ended || sender.state == .Began {
            sender.setTranslation(CGPointZero, inView: view)
        }
        
//        var translation = sender.translationInView(view).y / 15.0
//        topRedConstraint.constant += translation
//        bottomBlueConstraint.constant += translation
//        bottomLabelConstraint.constant += translation
        
        if point.y > 0 {
            view.layoutIfNeeded()
            targetBannerVerticalSpace.constant = point.y
        }
        
        let step = CGFloat(MAX_HR - MIN_HR) / view.frame.height
        
        let value = MAX_HR - Int(point.y * step)
        
        targetLabel.text = "\(value)\nBPM"
    }

}
