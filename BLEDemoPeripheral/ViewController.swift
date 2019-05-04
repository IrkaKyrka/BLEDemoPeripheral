//
//  ViewController.swift
//  BLEDemoPeripheral
//
//  Created by Ira Golubovich on 5/3/19.
//  Copyright © 2019 Ira Golubovich. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate {
    
    let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD666661")
    let modelNameCharacteristicUUID = CBUUID(string: "0c74d200-DB05-467E-8757-72F6F66666D4")
    let brightnesCharacteristicUUID = CBUUID(string: "08590F7E-DB05-467E-8757-72F6F66666D4")
    
    var peripheralManager: CBPeripheralManager!
    var service : CBMutableService!
    var modelNameCharacteristic : CBMutableCharacteristic!
    var data: NSData!
    var central: CBCentral!
    var brightnesCharacteristic : CBMutableCharacteristic!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
    }
    
    
    @IBAction func tappedStartAdvertising(_ sender: UIButton) {
        
        self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [self.service.uuid]])
    }
    
    @IBAction func tappedStopAdvertising(_ sender: UIButton) {
        
        self.peripheralManager.stopAdvertising()
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        if (peripheral.state == .poweredOn) {
            print("BLE Power On")
            self.addService()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        
        if (error == nil) {
            print("service is added!")
            print("didAdd service \(service)")
        } else {
            print("Failed to add service " + error!.localizedDescription)
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        
        if (error == nil) {
            print("Start advertisement")
            self.data = UIDevice.current.name.data(using: String.Encoding.utf8)! as NSData
            print("peripheralManagerDidStartAdvertising")
        } else {
            print("Failed to start advertisement " + error!.localizedDescription)
            
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
        print("Receive request")
        
        if (!request.characteristic.uuid.isEqual(self.modelNameCharacteristic.uuid)) {
            return
        }
        
        if (request.offset > data.length) {
            self.peripheralManager!.respond(to: request, withResult: CBATTError.invalidOffset)
            return;
        }
        
        request.value = self.data!.subdata(with: NSMakeRange(request.offset, data.length - request.offset))
        self.peripheralManager!.respond(to: request, withResult: CBATTError.success);
        print("Respond to request")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        for request in requests
        {
            if request.characteristic.uuid.isEqual(brightnesCharacteristic.uuid)
            {
                let value = request.value!.withUnsafeBytes {
                    $0.load(as: Float.self)
                }
                
                print(value)
                
                UIScreen.main.brightness = CGFloat(value)
            }
        }
    }
    
    func addService() {
        
        self.service = CBMutableService(type: self.serviceUUID, primary: true)
        self.modelNameCharacteristic = CBMutableCharacteristic(type: self.modelNameCharacteristicUUID, properties: CBCharacteristicProperties.read, value: nil, permissions: CBAttributePermissions.readable)
        self.brightnesCharacteristic = CBMutableCharacteristic(type: self.brightnesCharacteristicUUID, properties: CBCharacteristicProperties.write, value: nil, permissions: CBAttributePermissions.writeable)
        self.service.characteristics = [self.modelNameCharacteristic, self.brightnesCharacteristic]
        self.peripheralManager.add(self.service)
    }
}

