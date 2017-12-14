//
//  UARTDevice.swift
//  UART
//
//  Created by kasuhisa on 2016/02/02.
//  Copyright © 2016年 Bascule Inc. All rights reserved.
//

//import UIKit
import CoreBluetooth

internal class UARTDevice
{
	internal var uuid				:String!
	internal var peripheral			:CBPeripheral!
	
	internal var service			:CBService!
	internal var read				:CBCharacteristic!
	internal var write				:CBCharacteristic!
	
	internal init( peripheral:CBPeripheral )
	{
		self.peripheral = peripheral
		self.uuid = peripheral.identifier.uuidString
	}
}
