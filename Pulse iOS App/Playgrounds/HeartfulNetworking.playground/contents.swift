// Playground - noun: a place where people can play

import Foundation
import XCPlayground
XCPSetExecutionShouldContinueIndefinitely(continueIndefinitely: true)

typealias JSONDictionary = Dictionary<String, AnyObject>
typealias APICallback = ((AnyObject?, NSError?) -> ())


let baseURL = NSURL(string: "http://52.10.162.213")!
var config = NSURLSessionConfiguration.defaultSessionConfiguration()
var session: NSURLSession = NSURLSession(configuration: config)

func retriveMaxHRForAge(age: Int, completion: (maxHR: Double?, error: NSError!)->Void) {
    
    let ext = "analysis/?age=\(age)"
    let url = NSURL(string: ext, relativeToURL: baseURL)!
    let request = NSMutableURLRequest(URL: url)
    
//    let params = ["age":"\(age)"]
//    var err: NSError?
//    request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
//    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    let task = session.dataTaskWithRequest(request) { (data, response, error) in
        if let httpResponse = response as? NSHTTPURLResponse {
            switch(httpResponse.statusCode) {
            case 200, 201:
                if let json = parseJSON(data), let hr = json["max_hr"] as? Double {
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

retriveMaxHRForAge(23) { (maxHR, error) in
    println(maxHR)
}
