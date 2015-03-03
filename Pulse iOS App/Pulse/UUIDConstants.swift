//
//  UUIDConstants.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/12/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import CoreBluetooth

// BLUETOOTH LOW ENERGY TINYSHIELD - REV 2
struct TinyShield {
    static let ServiceUUID = CBUUID(string: "195ae58a-437a-489b-b0cd-b7c9c394bae4")
    static let Char1UUID = CBUUID(string: "5fc569a0-74a9-4fa4-b8b7-8354c86e45a4")
    static let Char2UUID = CBUUID(string: "21819ab0-c937-4188-b0db-b9621e1696cd")
}

//REDBEAR LAB
struct REDBearShield {
    static let ServiceUUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
    static let CHAR_TX_UUID = CBUUID(string:  "713D0002-503E-4C75-BA94-3148F18D941E")
    static let CHAR_RX_UUID = CBUUID(string: "713D0003-503E-4C75-BA94-3148F18D941E")
}

struct Read {}
struct Write {}
struct CharUUID<T> {
    let UUID: CBUUID
}

let serviceUUIDS = [TinyShield.ServiceUUID, REDBearShield.ServiceUUID]

let characteristicUUIDS: [CBUUID] = [REDBearShield.CHAR_TX_UUID, TinyShield.Char1UUID, TinyShield.Char2UUID]