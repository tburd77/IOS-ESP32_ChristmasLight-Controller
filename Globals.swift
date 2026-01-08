//
//  Globals.swift
//  Christmas Light Controller
//
//  Created by Terry Burdett on 12/13/25.
//

import Foundation
import UIKit
import CoreBluetooth

let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890ab")
let rxUUID      = CBUUID(string: "12345678-1234-1234-1234-1234567890ac") // Write
let txUUID      = CBUUID(string: "12345678-1234-1234-1234-1234567890ad") // Notify


let idCharUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890ae")// unique to this device

var bleSendText = ""
//let idCharUUID = CBUUID(string: "XMASLIGHTS_4")
struct BLEDevice {
    let id: String
    var peripheral: CBPeripheral
    var isConnected: Bool
}
