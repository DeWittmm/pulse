//
//  HeartfulAPIClient.swift
//  Pulse
//
//  Created by Michael DeWitt on 3/1/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

let CLIENT_ID = "639656764286-ehcmeafioq7lrhsgtmfldm11vkar0hpb.apps.googleusercontent.com"
let CLIENT_SECRECT = "Kj4n8BrXJDJW34zhIZS6SKNX"

class HeartfulAPIClient {
    
    typealias JSONDictionary = [String: AnyObject]
//    typealias APICallback<T> = ((T?, NSError?) -> ())
    
    let baseURL = NSURL(string: "http://52.10.162.213")!
//      let baseURL = NSURL(string: "http://127.0.0.1:8000")! //Local
    lazy var config = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config) //Declaring type is required
    
    let callbackQueue: dispatch_queue_t
    
    init(queue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        callbackQueue = queue
    }
    
    func getMaxHRForAge(age: Int, completion: (maxHR: Int?, targetRange: (Int, Int)?, error: NSError!)->Void) {
        
        let ext = "analysis/?age=\(age)"
        let url = NSURL(string: ext, relativeToURL: baseURL)!
        let request = NSMutableURLRequest(URL: url)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(self.callbackQueue) {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch(httpResponse.statusCode) {
                    case 200, 201:
                        if let json = self.parseJSON(data){
                            if let hr = json["max_hr"] as? Int {
                                if let target = json["target_hr"] as? [Int]{
                                if target.count == 2 {
                                completion(maxHR: hr, targetRange: (target[0], target[1]), error: nil)
                            }
                            }
                        }
                        }
                    default:
                        println("HTTP \(httpResponse.statusCode):")
                    }
                } else {
                    completion(maxHR: nil, targetRange: nil, error: error)
                    println("API ERROR: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func postUserBaseInfo(age: Int, name: String, gId: String, baseHR: Double, baseSPO2: Double, completion: (error: NSError!)->Void) {
        
        let ext = "user/"
        let url = NSURL(string: ext, relativeToURL: baseURL)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        let params = ["age":age, "name":name, "googleid":gId, "heartrate":baseHR, "spO2":baseSPO2]
        var err: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        if let err = err { println("ERROR: \(err.localizedDescription)") }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(self.callbackQueue) {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch(httpResponse.statusCode) {
                    case 200, 201:
                        if let json = self.parseJSON(data) {
                            println("User Response: \(json)")
                            completion(error: nil)
                        }
                    default:
                        println("HTTP \(httpResponse.statusCode): \(NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode))")
                    }
                } else {
                    completion(error: error)
                    println("ERROR: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func postUserReading(googleid: String, type: String, heartRates: [Double], forDate date: NSDate, completion: (error: NSError!)->Void) {
        
        let ext = "dataSet/"
        let url = NSURL(string: ext, relativeToURL: baseURL)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        var values = [NSDictionary]()
        for val in heartRates {
            values.append(["value": val,
                       "unit": "bpm",
                        "date_time": "2015-03-17 13:45:34-07"])
        }
        
        let params = ["googleid": googleid, "type": type, "heartrate_values":values]
        
        println(params)
        var err: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        if err != nil { println("ERROR: \(err?.localizedDescription)") }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(self.callbackQueue) {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch(httpResponse.statusCode) {
                    case 200, 201:
                        completion(error: nil)
                    default:
                        println("HTTP \(httpResponse.statusCode): \(NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode))")
                    }
                } else {
                    completion(error: error)
                    println("ERROR: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func parseJSON(data: NSData) ->JSONDictionary? {
        var err: NSError?
        if let json: AnyObject =  NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &err) {
            
            if let err = err {
                println(err.localizedDescription)
            }
            
            return json as? JSONDictionary
        }
        return nil
    }
}