//
//  Constants.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/23/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import Foundation

//MARK: Constants
let MILLS_PER_MIN = 60000.0

//MARK:
// Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V)
public let ArudinoVoltageConversionFactor = 1.0 //4.0 / 1023.0
public let MAX_ARDUINO_TIME = 65535 //Before time bits roll over

public let BLE_PACKET_SIZE = 20
public let PACKET_DATA_SIZE = 15


//MARK: Peak Detection
let STEP = 5
let DECLINE_CUTTOFF: Double = -1.0
let MINIMUM_SLOPE_LENGTH: Int = 10
let MINIMUM_SLOPE: Double = 1.0

//MARK: Processing
let MINIMUM_HR_TIME_SPAN = 100.0
let VALUE_CUTTOFF: Double = 20.0
