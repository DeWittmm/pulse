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
        signIn.scopes = [kGTLAuthScopePlusLogin]
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
- (void)viewDidLoad {
[super viewDidLoad];

GPPSignIn *signIn = [GPPSignIn sharedInstance];
signIn.shouldFetchGooglePlusUser = YES;
//signIn.shouldFetchGoogleUserEmail = YES;  // Uncomment to get the user's email

// You previously set kClientId in the "Initialize the Google+ client" step
signIn.clientID = kClientId;

// Uncomment one of these two statements for the scope you chose in the previous step
signIn.scopes = @[ kGTLAuthScopePlusLogin ];  // "https://www.googleapis.com/auth/plus.login" scope
//signIn.scopes = @[ @"profile" ];            // "profile" scope

// Optional: declare signIn.actions, see "app activities"
signIn.delegate = self;
}
*/

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
