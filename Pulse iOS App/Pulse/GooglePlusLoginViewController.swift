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
        signIn.shouldFetchGoogleUserID = true
        signIn.shouldFetchGoogleUserEmail = true
        signIn.clientID = kClientId
        signIn.scopes = [kGTLAuthScopePlusUserinfoEmail, kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe, kGTLAuthScopePlusUserinfoProfile]
        signIn.delegate = self
                
        //signIn.trySilentAuthentication()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
      
        // Dispose of any resources that can be recreated.
    }
    
    func finishedWithAuth(auth: GTMOAuth2Authentication!, error: NSError!) {
        if let theError = error {
            println(theError.description)
        }
        else {
            getGoogleId()
        }
    }
    
    func getGoogleId() {
        var plusService = GTLServicePlus()
        
        plusService.retryEnabled = true;
        plusService.authorizer = GPPSignIn.sharedInstance().authentication

        var query = GTLQueryPlus.queryForPeopleGetWithUserId("me") as! GTLQueryPlus
        plusService.executeQuery(query) { (ticket, person, error) -> Void in
            if let thePerson = person as? GTLPlusPerson {
                println("THE ID: \(thePerson.identifier)")
            }
        }
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
