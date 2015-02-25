//
//  HKStorePermissions.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/24/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import HealthKit

//MARK: HealthKit
extension HKHealthStore {
    
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
    
    func requestAccess() {
        
        if HKHealthStore.isHealthDataAvailable() {
            
            requestAuthorizationToShareTypes(writeDataTypes, readTypes: readDataTypes) { (success, error) in
                
                if !success {
                    println("ERROR: Failed to get access to HealthStore read write data types: \(error.localizedDescription)")
                }
            }
        }
    }
}