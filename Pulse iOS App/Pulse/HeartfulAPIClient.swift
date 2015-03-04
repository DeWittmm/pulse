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
//    let baseURL = NSURL(string: "http://127.0.0.1:8000")! //Local
    lazy var config = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config) //Declaring type is required
    
    let callbackQueue: dispatch_queue_t
    
    init(queue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        callbackQueue = queue
    }
    
    func getMaxHRForAge(age: Int, completion: (maxHR: Double?, error: NSError!)->Void) {
        
        let ext = "analysis/?age=\(age)"
        let url = NSURL(string: ext, relativeToURL: baseURL)!
        let request = NSMutableURLRequest(URL: url)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(self.callbackQueue) {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch(httpResponse.statusCode) {
                    case 200, 201:
                        if let json = self.parseJSON(data), let hr = json["max_hr"] as? Double {
                            completion(maxHR: hr, error: nil)
                        }
                    default:
                        println("HTTP \(httpResponse.statusCode):")
                    }
                } else {
                    completion(maxHR: nil, error: error)
                    println("ERROR: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func postUserReading(age: Int, completion: (maxHR: Double?, error: NSError!)->Void) {
        
        let ext = "analysis/?age=\(age)"
        let url = NSURL(string: ext, relativeToURL: baseURL)!
        let request = NSMutableURLRequest(URL: url)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(self.callbackQueue) {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch(httpResponse.statusCode) {
                    case 200, 201:
                        if let json = self.parseJSON(data), let hr = json["max_hr"] as? Double {
                            completion(maxHR: hr, error: nil)
                        }
                    default:
                        println("HTTP \(httpResponse.statusCode):")
                    }
                } else {
                    completion(maxHR: nil, error: error)
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