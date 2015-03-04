//
//  HKStorePermissions.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/24/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import HealthKit

//MARK: Permissions
var writeDataTypes: Set<HKObjectType> {
    let heartRateQuantity  = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) // Scalar(Count)/Time, Discrete
    
    let bloodOxygenQuantity = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierOxygenSaturation)  // Scalar (Percent, 0.0 - 1.0,  Discrete
    
    return [heartRateQuantity, bloodOxygenQuantity]
}

var readDataTypes: Set<HKObjectType> {
    var dataTypes = writeDataTypes
    
    let birthDay = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)
    dataTypes.insert(birthDay)
    
    return dataTypes
}

let bpmUnit = HKUnit(fromString: "count/min")

//MARK: HealthKit
extension HKHealthStore {
    
    //MARK: Reading
    func readUsersAge() -> Int {
        var error: NSError?
        let dateOfBirth = dateOfBirthWithError(&error)
        
        // Compute the age of the user.
        let ageComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.YearCalendarUnit, fromDate: dateOfBirth ?? NSDate(), toDate: NSDate(), options: NSCalendarOptions.WrapComponents)
        
        return ageComponents.year
    }
    
    func fetchHeartRateData(predicate: NSPredicate, completion: (data: [Double], error: NSError!) -> Void) {
        let heartRateQuantity  = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        
        let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: heartRateQuantity, predicate: predicate, limit: 0, sortDescriptors: [timeSortDescriptor]) { (query, results, error) in
            
            let values = results.map { value in
                 (value as! HKQuantitySample).quantity.doubleValueForUnit(bpmUnit)
            }
            
            completion(data: values, error: error);
        }
        executeQuery(query)
    }

    //MARK: Writing
    func saveHeartRate(hr: Double) {
        let hrQuanity = HKQuantity(unit: bpmUnit, doubleValue: hr)
        
        var hrType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        let nowDate = NSDate()
        
        let heartRateSample = HKQuantitySample(type: hrType
            , quantity: hrQuanity, startDate: nowDate, endDate: nowDate)
        
        saveObject(heartRateSample) { (success, error) in
            if success == true {
                println("Saved HR to HealthKit")
            }
            else {
                println("ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: Queries
    func fetchAvgHeartRate(predicate: NSPredicate, completion: (avgHr: Double, error: NSError!) -> Void) {
        let heartRateQuantity  = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        
        let query = HKStatisticsQuery(quantityType: heartRateQuantity, quantitySamplePredicate: predicate, options: HKStatisticsOptions.DiscreteAverage){ (query, statisticsInfo, error) in
            
            if let avgQuantity = statisticsInfo.averageQuantity() {
                let avg = avgQuantity.doubleValueForUnit(bpmUnit)
                            
                completion(avgHr: avg, error: error)
            }
        }
        
        executeQuery(query)
    }
}