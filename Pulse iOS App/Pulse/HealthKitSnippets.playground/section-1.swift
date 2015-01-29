// Playground - noun: a place where people can play

import UIKit
import HealthKit

let heartRateQuantity  = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) // Scalar(Count)/Time,          Discrete

let bloodOxygenQuantity = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierOxygenSaturation)  // Scalar (Percent, 0.0 - 1.0,  Discrete

let readWriteSet = NSSet(array: [heartRateQuantity, bloodOxygenQuantity])

//Request permission for read/write access to user's HKHealthStore

let healthStore = HKHealthStore()

healthStore.requestAuthorizationToShareTypes(readWriteSet, readTypes: readWriteSet) { success, error in
    //Access previously saved information here.
    
}

//HKObserverQuery

func heartRateValueHandler(HKObserverQuery!,
    HKObserverQueryCompletionHandler!,
    NSError!) {
        println("Found heartRateValue")
}
//let predicate = NSPredicate() //A predicate that limits the samples matched by the query. Pass nil if you want to receive updates for every new sample of the specified type.

let observe = HKObserverQuery(sampleType: heartRateQuantity, predicate: nil, updateHandler: heartRateValueHandler)


if (1 == 2) || 2 == 1 {
    print("Order operation test")
}