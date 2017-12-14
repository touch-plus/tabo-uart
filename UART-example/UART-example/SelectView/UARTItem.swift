//
//  UARTItem.swift
//
//  Created by kasuhisa on 2015/09/10.
//  Copyright (c) 2015年 Bascule Inc. All rights reserved.
//

import UIKit
import CoreBluetooth

class UARTItem:NSObject
{
	var uuid		:String!
	var name		:String!
	var RSSI		:NSNumber!
	var state		:CBPeripheralState?
	
	init( uuid:String, name:String, RSSI:NSNumber )
	{
		self.uuid = uuid
		self.name = name
		self.RSSI = RSSI
	}
}
