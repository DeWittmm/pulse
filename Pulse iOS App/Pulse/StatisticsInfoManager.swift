//
//  StatisticsInfo.swift
//  Pulse
//
//  Created by Michael DeWitt on 3/1/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

struct User {
    let age: Int
    let baseHR: Double
    let baseSpO2: Double
}

typealias Info = (String, String)

protocol UpdateInfoDelegate: class {
    func didUpdateInfo(statistics: StatisticsInfoManager)
}

class StatisticsInfoManager {
    
    let user: User
    let client = HeartfulAPIClient()
    var currentInfo = [Info]()
    
    weak var delegate: UpdateInfoDelegate?
    
    init(user: User) {
        self.user = user
        
        //FIXME: First Pass
        client.retriveMaxHRForAge(user.age) { (maxHR, error)  in
            if let mx = maxHR {
                self.currentInfo.append(("\(user.age)", "\(mx)"))
                self.delegate?.didUpdateInfo(self)
            }
        }
    }
    
    func infoForIndex(indexPath: NSIndexPath) -> Info? {
        let info = currentInfo[indexPath.row - 1]
        
        switch indexPath.row {
        case 1:
            return ("Expected MaxHR (age: \(info.0))", "\(info.1) BPM")
        default:
            return ("--", "")
        }
    }
}