//
//  GoalViewController.swift
//  Pulse
//
//  Created by Michael DeWitt on 1/21/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import HealthKit

class GoalViewController: UIViewController, HKAccessProtocol {

    //MARK: Outlets
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var targetLabel: UILabel!
    
    @IBOutlet weak var actualVerticalSpace: UILabel!
    @IBOutlet weak var targetBannerVerticalSpace: NSLayoutConstraint!
    
    //MARK: Properties
    var hkObserver: HKObserverQuery?
    var healthStore: HKHealthStore? {
        didSet {
            hkObserver = HKObserverQuery(sampleType: heartRateQuantity, predicate: nil, updateHandler: updateHandler)
            healthStore?.executeQuery(hkObserver)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Updates
    func updateHandler(query:HKObserverQuery!, completionHandler: HKObserverQueryCompletionHandler!, error: NSError!) {
        if error != nil {
            println("ERROR: \(error.localizedFailureReason)")
            return
        }
        
        self.healthStore?.fetchHeartRateData(todayPredicate, limit: 1) { (data, error) -> Void in
            
            if let hr = data.first, label = self.label {
                dispatch_async(dispatch_get_main_queue()) {
                    label.text = String(format:"%.01f BPM", arguments: [hr])
                }
            }
        }        
    }
    
    //MARK:
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
            targetBannerVerticalSpace.constant = point.y - 45
        }
        
        let step = CGFloat(MAX_HR - MIN_HR) / view.frame.height
        
        let value = Int(MAX_HR - Double(point.y * step))
        
        targetLabel.text = "\(value)\nBPM"
    }

}
