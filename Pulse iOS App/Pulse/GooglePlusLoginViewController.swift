//
//  GooglePlusLoginViewController.swift
//  Pulse
//
//  Created by Spencer Lewson on 3/16/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit

class GooglePlusLoginViewController: UIViewController, GPPSignInDelegate {

    @IBOutlet var signInButton: GPPSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var signIn = GPPSignIn.sharedInstance()
        signIn.shouldFetchGooglePlusUser = true
        signIn.clientID = kClientId
        signIn.scopes = [kGTLAuthScopePlusUserinfoProfile]
        signIn.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
      
        // Dispose of any resources that can be recreated.
    }
    
    func finishedWithAuth(auth: GTMOAuth2Authentication!, error: NSError!) {
        println("FinishedWithAuth: \(auth) and error: \(error)")
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
