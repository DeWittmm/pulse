//
//  StatisticsInfo.swift
//  Pulse
//
//  Created by Michael DeWitt on 3/1/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import HealthKit

struct User {
    let age: Int
    var baseHR: Double?
    var baseSpO2: Double?
    
    init(age: Int) {
        self.age = age
    }
}

typealias Info = (String, String)

class StatisticsInfoManager {
    
    //MARK: Private Properties
    private let client = HeartfulAPIClient()
    
    private let todayPredicate: NSPredicate = {
        let calendar = NSCalendar.currentCalendar()
        
        let now = NSDate()
        
        let startDate = calendar.startOfDayForDate(now)
        let endDate = calendar.dateByAddingUnit(.CalendarUnitDay, value: 1, toDate: startDate, options: NSCalendarOptions.allZeros)
        
        return HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .StrictStartDate)
    }()
    
    let healthStore: HKHealthStore

    //MARK: Info Properties
    let user: User
    
    var userAge: Dynamic<String?> = Dynamic("")
    var ageMaxHR: Dynamic<String?> = Dynamic("")
    var avgHR: Dynamic<String?> = Dynamic("")
//    var hrData: Dynamic<String?> = Dynamic([0.0])
    
    init(healthStore: HKHealthStore) {
        let usersAge = healthStore.readUsersAge()
        let user = User(age: usersAge)
        println("Age: \(usersAge)")
        
        self.userAge.value = "Age: \(usersAge) years"
        self.user = user
        self.healthStore = healthStore
        
        refreshHealthKitData()
        refreshHealthKitStatistics()
        retriveInfoFromHeartful()
    }
    
    func updateValues() {
        userAge.valueChanged()
        ageMaxHR.valueChanged()
        avgHR.valueChanged()
//        hrData.valueChanged()
    }
    
    func refreshHealthKitData() {
        healthStore.fetchHeartRateData(todayPredicate) { (data, error) -> Void in
            println("Data: \(data)")
            
            dispatch_async(dispatch_get_main_queue()) {
//                self.hrData.value = data
            }
        }
    }
    
    func refreshHealthKitStatistics() {
        healthStore.fetchAvgHeartRate(todayPredicate) { (avgHR, error) in
            println("Avg HR: \(avgHR)")

            dispatch_async(dispatch_get_main_queue()) {
                self.avgHR.value = "Average HR \(avgHR)"
                return
            }
        }
    }
    
    func retriveInfoFromHeartful() {
        client.retriveMaxHRForAge(user.age) { (maxHR, error)  in
            if let mx = maxHR {
                self.ageMaxHR.value = "Expected MaxHR: \(mx)"
            }
        }
    }
}