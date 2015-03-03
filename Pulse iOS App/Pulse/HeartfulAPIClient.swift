//
//  HeartfulAPIClient.swift
//  Pulse
//
//  Created by Michael DeWitt on 3/1/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

class HeartfulAPIClient {
    
    typealias JSONDictionary = Dictionary<String, AnyObject>
//    typealias APICallback<T> = ((T?, NSError?) -> ())
    
    let baseURL = NSURL(string: "http://52.10.162.213")!
    lazy var config = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config) //Declaring type is required
    
    func retriveMaxHRForAge(age: Int, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (maxHR: Double?, error: NSError!)->Void) {
        
        let ext = "analysis/?age=\(age)"
        let url = NSURL(string: ext, relativeToURL: baseURL)!
        let request = NSMutableURLRequest(URL: url)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        //    let params = ["age":"\(age)"]
        //    var err: NSError?
        //    request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        //    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //    request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(queue) {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch(httpResponse.statusCode) {
                    case 200, 201:
                        if let json = self.parseJSON(data), let hr = json["max_hr"] as? Double {
                            completion(maxHR: hr, error: nil)
                        }
                    default:
                        println("HTTP \(httpResponse.statusCode)")
                    }
                } else {
                    completion(maxHR: nil, error: error)
                    println("ERROR: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func parseJSON(data: NSData) ->[String:AnyObject]? {
        var err: NSError?
        if let json: AnyObject =  NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &err) {
            
            if let err = err {
                println(err.localizedDescription)
            }
            
            return json as? [String: AnyObject]
        }
        return nil
    }
}