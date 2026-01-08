//
//  ViewController.swift
//  BLE_Test3
//
//  Created by Terry Burdett on 12/13/25.
//

import UIKit
import CoreBluetooth

var selectedDeviceID: String?

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    @IBAction func rescanForBLEDevices(_ sender: Any) {
        reScan()
    }
    var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var peripheralNames: [UUID: String] = [:]



    // MARK: - Connected peripheral
    var connectedPeripheral: CBPeripheral?
    var rxChar: CBCharacteristic?
    var txChar: CBCharacteristic?
    var idChar: CBCharacteristic?
    var minuteTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(setColor), name: Notification.Name(rawValue: "setColor"), object: nil)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true

        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let id = selectedDeviceID,
              let row = BLEDeviceStore.shared.devices.firstIndex(
                  where: { $0.id == id }
              ) {
               tableView.selectRow(
                   at: IndexPath(row: row, section: 0),
                   animated: false,
                   scrollPosition: .none
               )
           }
    }

    func reScan() {
        print("rescan start")
        guard centralManager.state == .poweredOn else { return }

        centralManager.stopScan()

        DispatchQueue.main.async {
            self.peripherals.removeAll()
            self.peripheralNames.removeAll()
            self.tableView.reloadData()
        }

        // Give CoreBluetooth time to reset the scan
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.centralManager.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
        print("rescan end")
    }
    
    @objc func appDidBecomeActive() {
        if centralManager.state == .poweredOn {
            reScan()
        }
    }
    
    @objc func setColor() {
        send(bleSendText)
    }
}

// MARK: - CBCentralManagerDelegate
extension ViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            peripherals.removeAll()
            
            central.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false])

        }
        
        
        DispatchQueue.main.async {
                switch central.state {
                case .poweredOn:
                    self.navigationItem.title = "Scanning BLE Devices"

                case .poweredOff:
                    self.navigationItem.title = "Bluetooth Off"

                default:
                    self.navigationItem.title = "Bluetooth Unavailable"
                }
            }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        
        guard !peripherals.contains(where: { $0.identifier == peripheral.identifier }) else {//skip if duplicate
            print("skip peripheral \(peripheral.identifier)")
            return
        }
 
        peripherals.append(peripheral)
        
        guard let data = advertisementData[
            CBAdvertisementDataManufacturerDataKey
        ] as? Data else { return }

        let id = String(decoding: data, as: UTF8.self)
        
        let r = peripheral.identifier.uuidString
        print("r = \(r)")
        peripheralNames[peripheral.identifier] = id
        print("peripheralNames[peripheral.identifier] = \(id)")
        
        BLEDeviceStore.shared.upsert(
            peripheral: peripheral,
            id: id
        )

        tableView.reloadData()
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        
        BLEDeviceStore.shared.setConnectionState(
                peripheral,
                connected: true
            )
            tableView.reloadData()
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        BLEDeviceStore.shared.setConnectionState(
            peripheral,
            connected: false
        )
        tableView.reloadData()
    }

    
}

// MARK: - CBPeripheralDelegate
extension ViewController: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([rxUUID, txUUID], for: service)
  
        }
        
        
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {

        guard let characteristics = service.characteristics else { return }

        for char in characteristics {
            switch char.uuid {
            case rxUUID:
                rxChar = char
            case txUUID:
                txChar = char
                peripheral.setNotifyValue(true, for: char)
            case idCharUUID:
                peripheral.readValue(for: char)
                idChar = char
            default:
                break
            }
            // }
            
            if char.uuid == idCharUUID {
                peripheral.readValue(for: char)
            }
        }
        
        if idChar != nil {
            print("found idCharUUID")
        }
        if rxChar != nil && txChar != nil {
            send("Hello ESP32 from IOS")
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        guard characteristic.uuid == txUUID,
              let data = characteristic.value,
              let text = String(data: data, encoding: .utf8) else { return }

        print("Received from ESP32:", text)
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BLEDeviceStore.shared.devices.count
      //  return peripherals.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "BLECell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "BLECell")

    //    cell.backgroundColor = UIColor.green
        
        let device =
               BLEDeviceStore.shared.devices[indexPath.row]

      //     let cell = tableView.dequeueReusableCell(
             //  withIdentifier: "BLECell",
            //   for: indexPath
           //)
        cell.backgroundColor = UIColor.green
        
           cell.textLabel?.text = device.id
           cell.detailTextLabel?.text =
               device.isConnected ? "Connected" : "Available"
        
    //    let peripheral = peripherals[indexPath.row]

      //  cell.textLabel?.text = peripheralNames[peripheral.identifier]
     //   cell.detailTextLabel?.text = peripheral.identifier.uuidString

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "BLE Devices"
    }
    
     func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
    //    tableView.deselectRow(at: indexPath, animated: true)

        let device = BLEDeviceStore.shared.devices[indexPath.row]
        selectedDeviceID = device.id
       
        
      //  guard device.peripheral.state == .disconnected else {
      //      tableView.deselectRow(at: indexPath, animated: true)
       //     return
      //  }
 

        device.peripheral.delegate = self
        centralManager.connect(device.peripheral, options: nil)
        
        
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "ColorPicker"
        )

        navigationController?.pushViewController(vc!, animated: true)
    }
    
  /*   func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        let device = BLEDeviceStore.shared.devices[indexPath.row]

        // Avoid reconnect spam
        guard device.peripheral.state == .disconnected else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        device.peripheral.delegate = self
        centralManager.connect(device.peripheral, options: nil)

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = peripherals[indexPath.row]

        centralManager.stopScan()
        centralManager.connect(peripheral)
        
        
        let selectedPeripheral = peripherals[indexPath.row]

            let vc = storyboard?.instantiateViewController(
                withIdentifier: "ColorPicker"
            )

           // vc.peripheral = selectedPeripheral

        navigationController?.pushViewController(vc!, animated: true)
    }*/
}

// MARK: - Write to ESP32
extension ViewController {
    func send(_ text: String) {
        guard let rxChar = rxChar,
              let peripheral = connectedPeripheral else { return }

        let data = text.data(using: .utf8)!
        peripheral.writeValue(data, for: rxChar, type: .withResponse)
    }
}
