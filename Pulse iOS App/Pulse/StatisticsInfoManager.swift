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

public enum TimeRange: Int {
    case Day, Week, Month
}

class StatisticsInfoManager {
    
    let healthStore: HKHealthStore
    var timeRange: TimeRange = .Day {
        didSet {
            refreshAll()
        }
    }

    //MARK: Info Properties
    let user: User
    
    var age = Dynamic("")
    var maxTargetHR = Dynamic("")
    
    var avgHR = Dynamic("")
    var maxMinHR = Dynamic("")
    var hrData = Dynamic([0.0])
    
    init(healthStore: HKHealthStore) {
        let usersAge = 23//healthStore.readUsersAge()
        let user = User(age: usersAge)
        
        self.user = user
        self.healthStore = healthStore
        
        //FIXME: Test
//        client.postUserBaseInfo(usersAge, name: "NO", baseHR: 84, baseSPO2: 0.99) { (error) -> Void in }
    }
    
    func refreshAll() {
        let predicate: NSPredicate
        switch timeRange {
        case .Day:
            predicate = todayPredicate
        case .Week:
            predicate = weekPredicate
        case .Month:
            predicate = monthPredicate
        }
        
        refreshHealthKitData(predicate)
        refreshHealthKitStatistics(predicate)
        retriveInfoFromHeartful()
    }
    
    private func refreshHealthKitData(predicate: NSPredicate) {
        healthStore.fetchHeartRateData(predicate) { (data, error) -> Void in
//            println("Data: \(data)")
            
            dispatch_async(dispatch_get_main_queue()) {
                self.hrData.value = data
                self.hrData.valueChanged()
            }
        }
    }
    
    private func refreshHealthKitStatistics(predicate: NSPredicate) {
        let heartRateQuantity  = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        
        let avgHRquery = HKStatisticsQuery(quantityType: heartRateQuantity, quantitySamplePredicate: predicate, options: HKStatisticsOptions.DiscreteAverage){ (query, statisticsInfo, error) in
            
            if let avgQuantity = statisticsInfo.averageQuantity() {
                let avg = avgQuantity.doubleValueForUnit(bpmUnit)
                println("Avg HR: \(avg)")
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.avgHR.value = String(format: "%0.2f BPM", arguments: [avg])
                    return
                }
            }
        }
        healthStore.executeQuery(avgHRquery)
        
        let maxQuery = HKStatisticsQuery(quantityType: heartRateQuantity, quantitySamplePredicate: predicate, options: HKStatisticsOptions.DiscreteMax){ (query, maxInfo, error) in
            
            if let maxQuantity = maxInfo.maximumQuantity() {
                let max = maxQuantity.doubleValueForUnit(bpmUnit)
                println("Max HR: \(max)")
                
                let minQuery = HKStatisticsQuery(quantityType: heartRateQuantity, quantitySamplePredicate: predicate, options: HKStatisticsOptions.DiscreteMin){ (query, minInfo, error) in
                    
                    if let minQuantity = minInfo.minimumQuantity() {
                        let min = minQuantity.doubleValueForUnit(bpmUnit)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.maxMinHR.value = String(format: "%0.2f/ %0.2f", arguments: [max,min])
                            return
                        }
                    }
                }
                self.healthStore.executeQuery(minQuery)
            }
        }
        healthStore.executeQuery(maxQuery)
    }
    
    private func retriveInfoFromHeartful() {
        client.getMaxHRForAge(user.age) { (maxHR, targetRange, error)  in
            if let mx = maxHR, targetRange = targetRange {
                self.age.value = "\(self.user.age)"
                self.maxTargetHR.value = "\(mx)/ \(targetRange.0)-\(targetRange.1) BPM"
            }
        }
    }
    
    //MARK: Private Properties
    private let client = HeartfulAPIClient()
    
    private let weekPredicate: NSPredicate = {
        let calendar = NSCalendar.currentCalendar()
        let now = NSDate()
        
        let startDate = calendar.dateByAddingUnit(.CalendarUnitDay, value: -6, toDate: now, options: NSCalendarOptions.allZeros)
        let endDate = calendar.dateByAddingUnit(.CalendarUnitDay, value: 1, toDate: now, options: NSCalendarOptions.allZeros)
        
        return HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .StrictStartDate)
        }()
    
    private let monthPredicate: NSPredicate = {
        let calendar = NSCalendar.currentCalendar()
        let today = NSDate()
        
        let startDate = calendar.dateByAddingUnit(.CalendarUnitDay, value: -30, toDate: today, options: NSCalendarOptions.allZeros)
        let endDate = calendar.dateByAddingUnit(.CalendarUnitDay, value: 1, toDate: today, options: NSCalendarOptions.allZeros)

        //Instead of grabbing month, look at previous 30 days
//        let components = calendar.components(NSCalendarUnit.CalendarUnitMonth, fromDate: today)
//        
//        components.day = 1
//        let firstDateOfMonth: NSDate = calendar.dateFromComponents(components)!
//        
//        components.month += 1
//        components.day = 0
//        let lastDateOfMonth: NSDate = calendar.dateFromComponents(components)!
        
        return HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .StrictStartDate)
        }()
}