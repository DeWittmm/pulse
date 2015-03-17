//
//  UploadTableViewController.swift
//  Pulse
//
//  Created by Spencer Lewson on 3/16/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit
import HealthKit

class UploadTableViewController: UITableViewController, GPPSignInDelegate {
    
    //MARK: Outlets
    
    @IBOutlet var signInButton: GPPSignInButton!

    
    //MARK: Properties
    
    var healthStore: HKHealthStore!
    var user: User!
    var googleId: String?
    
    //MARK: Private Properties
    private let client = HeartfulAPIClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Sign into Google Plus"
        signIntoGooglePlus()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = "Heartful"
    }
    
    //MARK: Google+
    func signIntoGooglePlus() {
        var signIn = GPPSignIn.sharedInstance()
        signIn.shouldFetchGooglePlusUser = true
        signIn.shouldFetchGoogleUserID = true
        signIn.shouldFetchGoogleUserEmail = true
        signIn.clientID = kClientId
        signIn.scopes = [kGTLAuthScopePlusUserinfoEmail, kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe, kGTLAuthScopePlusUserinfoProfile]
        signIn.delegate = self

        if signIn.trySilentAuthentication() {
            signInButton.hidden = true
        }
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
                self.signInButton.hidden = true
                self.createUser()
            }
        }
    }
    
    func createUser() {
        let currentUser = self.user
        self.client.postUserBaseInfo(currentUser.age, name: "Private", baseHR: currentUser.baseHR ?? 0, baseSPO2: currentUser.baseSpO2 ?? 0) { (error) -> Void in
            
            println("***Created User!")
        }
    }

    //MARK: Upload
    @IBAction func upload(sender: UIButton) {
        uploadTodaysActivity()
    }
    
    func uploadTodaysActivity() {
        let predicate = todayPredicate
        let activityTag = "Posting from iOS"
        if let gId = googleId {
            healthStore.fetchHeartRateData(predicate) { (data, error) -> Void in
                self.client.postUserReading(gId, type: activityTag, heartRates: data, forDate: NSDate()) { (error) -> Void in
                    if error == nil {
                        println("***Uploaded Data!")
                    }
                }
            }
        }
    }
}
