//
//  UARTCentralState.swift
//  UART
//
//  Created by kasuhisa on 2016/02/02.
//  Copyright © 2016年 Bascule Inc. All rights reserved.
//

//import UIKit
import CoreBluetooth

/**
CBManagerStateをラッピングした列挙型
*/
@objc
public enum UARTCentralState:Int
{
	case unknown
	case resetting
	case unsupported
	case unauthorized
	case poweredOff
	case poweredOn
	
    static func toState( _ state:CBManagerState ) -> UARTCentralState
	{
		switch( state ) {
		case .unknown : return UARTCentralState.unknown
		case .resetting : return UARTCentralState.resetting
		case .unsupported : return UARTCentralState.unsupported
		case .unauthorized : return UARTCentralState.unauthorized
		case .poweredOff : return UARTCentralState.poweredOff
		case .poweredOn : return UARTCentralState.poweredOn
		}
	}
}
