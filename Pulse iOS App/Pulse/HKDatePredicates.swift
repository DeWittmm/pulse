//
//  DatePredicates.swift
//  Pulse
//
//  Created by Michael DeWitt on 3/11/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import HealthKit

let todayPredicate: NSPredicate = {
    let calendar = NSCalendar.currentCalendar()
    
    let now = NSDate()
    
    let startDate = calendar.startOfDayForDate(now)
    let endDate = calendar.dateByAddingUnit(.CalendarUnitDay, value: 1, toDate: startDate, options: NSCalendarOptions.allZeros)
    
    return HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .StrictStartDate)
    }()

let weekPredicate: NSPredicate = {
    let calendar = NSCalendar.currentCalendar()
    let now = NSDate()
    
    let startDate = calendar.dateByAddingUnit(.CalendarUnitDay, value: -6, toDate: now, options: NSCalendarOptions.allZeros)
    let endDate = calendar.dateByAddingUnit(.CalendarUnitDay, value: 1, toDate: now, options: NSCalendarOptions.allZeros)
    
    return HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .StrictStartDate)
    }()

let monthPredicate: NSPredicate = {
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