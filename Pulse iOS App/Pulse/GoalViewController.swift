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
        let step = CGFloat(MAX_HR - MIN_HR) / view.frame.height
        
        let value = MAX_HR - Int(point.y * step)
        
        label.text = "\(value) BPM"
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
