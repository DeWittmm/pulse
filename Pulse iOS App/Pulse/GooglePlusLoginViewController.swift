//
//  GooglePlusLoginViewController.swift
//  Pulse
//
//  Created by Spencer Lewson on 3/16/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit
import HealthKit

class GooglePlusLoginViewController: UIViewController, GPPSignInDelegate {

    var healthStore: HKHealthStore!
    var user: User!
    var googleId: String?

    //MARK: Private Properties
    private let client = HeartfulAPIClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var signIn = GPPSignIn.sharedInstance()
        signIn.shouldFetchGooglePlusUser = true
        signIn.shouldFetchGoogleUserID = true
        signIn.shouldFetchGoogleUserEmail = true
        signIn.clientID = kClientId
        signIn.scopes = [kGTLAuthScopePlusUserinfoEmail, kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe, kGTLAuthScopePlusUserinfoProfile]
        signIn.delegate = self
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
                
                //Create User
                let currentUser = self.user
                self.client.postUserBaseInfo(currentUser.age, name: "Private", baseHR: currentUser.baseHR ?? 0, baseSPO2: currentUser.baseSpO2 ?? 0) { (error) -> Void in
                    println("Created User!")
                }
            }
        }
    }
    
    func uploadTodaysActivity() {
        let predicate = todayPredicate
        let activityTag = ""
        if let gId = googleId {
            healthStore.fetchHeartRateData(predicate) { (data, error) -> Void in
                self.client.postUserReading(gId, type: activityTag, heartRates: data, forDate: NSDate()) { (error) -> Void in
                    if error == nil {
                        println("Uploaded Data!")
                    }
                }
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
