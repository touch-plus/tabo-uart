//
//  UARTDeviceDelegate.swift
//  UART
//
//  Created by kasuhisa on 2016/02/02.
//  Copyright © 2016年 Bascule Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc
internal class UARTDeviceDelegate:NSObject
{
	/// デリゲートを保持
	internal var delegates	:[NSObject:UARTDelegate] = [:]
	/// スキャンで見つかったデバイスを保持
	internal var devices	:Dictionary<String, UARTDevice?>!
	
	override init()
	{
		self.devices = Dictionary<String, UARTDevice?>()
	}
}

extension UARTDeviceDelegate
{
	/// Peripheralを追加する
	internal func add( _ device:UARTDevice! )
	{
		if !self.has( device.uuid ) {
			self.devices[device.uuid] = device
		}
	}
	
	/// Peripheralを取得する
	internal func get( _ uuid:String ) -> UARTDevice?
	{
        if let device = self.devices[uuid] {
            return device;
        }
//		return self.devices[uuid]
        return nil
	}
	
	/// Peripheralを取得する
	@nonobjc
	internal func get( _ peripheral:CBPeripheral ) -> UARTDevice?
	{
		return self.get( peripheral.identifier.uuidString )
	}
	
	/// UUIDに紐づくPeripheralを削除する
	internal func remove( _ uuid:String )
	{
		self.devices.removeValue( forKey: uuid )
	}
	
	/// UUIDに紐づくPeripheralを保持しているか
	internal func has( _ uuid:String ) -> Bool
	{
		if let _ = self.get( uuid ) {
			return true
		}
		return false
	}
	
	@nonobjc
	internal func has( _ peripheral:CBPeripheral ) -> Bool
	{
		if let _ = self.get( peripheral ) {
			return true
		}
		return false
	}
}


/// CBPeripheralDelegate の機能実装
extension UARTDeviceDelegate:CBPeripheralDelegate
{
	// RSSIが更新された場合に呼ばれる
	func peripheral( _ peripheral:CBPeripheral, didReadRSSI RSSI:NSNumber, error:Error? )
	{
		if error != nil {
			UART.logger?.error?( "Error did read RSSI: \(String(describing: error))" )
			return
		}
		
        UART.logger?.debug?( "didReadRSSI:\(String(describing: peripheral.name)):\(RSSI)" )
		
		if let device = self.get( peripheral ) {
			for ( _, value ) in self.delegates {
				// RSSI更新
				value.didReadRSSI?( device.uuid, RSSI:RSSI )
			}
		}
	}
	
	// サービス発見時に呼ばれる
	func peripheral( _ peripheral:CBPeripheral, didDiscoverServices error:Error? )
	{
		UART.logger?.info?( "Did discover services: \(peripheral)" )
		
		if error != nil {
			UART.logger?.error?( "Error discovering services: \(String(describing: error))" )
			return
		}
		
		if let device = self.get( peripheral ) {
			
			for service:CBService in peripheral.services! {
				
				UART.logger?.debug?( "Service UUID:\(service.uuid.uuidString)" )
				
				if service.uuid.isEqual( CBUUID(string:UART.UUID.service) ) {
					
                    UART.logger?.debug?( "Found correct service" )
					
					device.service = service
					device.peripheral.discoverCharacteristics( [CBUUID(string:UART.UUID.write), CBUUID(string:UART.UUID.read)], for:device.service )
				} else if service.uuid.isEqual( CBUUID(string:UART.UUID.deviceInformationService) ) {
					device.peripheral.discoverCharacteristics( [CBUUID(string:UART.UUID.hardwareRevision)], for:service )
				}
			}
		}
	}
	
	// キャラクタリスティック発見時に呼ばれる
	func peripheral( _ peripheral:CBPeripheral, didDiscoverCharacteristicsFor service:CBService, error:Error? )
	{
		UART.logger?.info?( "Did discover characteristics for service: \(peripheral)" )
		
		if error != nil {
			UART.logger?.error?( "Error discovering characteristics: \(String(describing: error))" )
			return
		}
		
		if let device = self.get( peripheral )
        {
			for characteristic in service.characteristics!
            {
                UART.logger?.debug?( "Characteristic UUID:\(characteristic.uuid.uuidString)" )
                
                if characteristic.uuid.isEqual( CBUUID(string:UART.UUID.read) )
                {
                    UART.logger?.debug?( "Found RX characteristic" )
                    device.read = characteristic
                    /// データ更新通知の受け取りを開始する
                    device.peripheral.setNotifyValue( true, for:device.read )
                } else if characteristic.uuid.isEqual( CBUUID(string:UART.UUID.write) )
                {
                    UART.logger?.debug?( "Found TX characteristic" )
                    device.write = characteristic
                } else if characteristic.uuid.isEqual( CBUUID(string:UART.UUID.hardwareRevision) )
                {
                    UART.logger?.debug?( "Found Hardware Revision String characteristic" )
                    device.peripheral.readValue( for: characteristic )
                }
			}
			// 準備完了
			for ( _, value ) in self.delegates
            {
				value.didReady?( device.uuid )
			}
		}
	}
	
	func peripheral( _ peripheral:CBPeripheral, didUpdateNotificationStateFor characteristic:CBCharacteristic, error:Error? )
	{
		if error != nil {
			UART.logger?.error?( "update notification state for characteristic:\(characteristic): \(String(describing: error))" )
		} else {
			UART.logger?.debug?( "update notification state for characteristic: \(characteristic.isNotifying)" )
		}
	}
	
	// データ更新時に呼ばれる
	func peripheral( _ peripheral:CBPeripheral, didUpdateValueFor characteristic:CBCharacteristic, error:Error? )
	{
		if error != nil {
			UART.logger?.error?( "update value for characteristic \(characteristic): \(String(describing: error))" )
			return
		}
		
		UART.logger?.info?( "Received data on a characteristic: \(peripheral)" )
		
		if let device = self.get( peripheral )
        {
			if characteristic == device.read
            {
				if let data:Data = characteristic.value
                {
					for ( _, value ) in self.delegates
                    {
						value.didReceiveDataByte?( device.uuid, data:data )
					}
				}
			}
		}
	}
}

/// CBCentralManagerDelegate の機能実装
@available(iOSApplicationExtension 10.0, *)
extension UARTDeviceDelegate:CBCentralManagerDelegate
{
	/// セントラルマネージャの状態変化を取得する
    func centralManagerDidUpdateState( _ central:CBCentralManager )
	{
		UART.logger?.info?( "centralManagerDidUpdateState:\(central.state.name)" )
		
		for ( _, value ) in self.delegates {
			value.didUpdateState?( UARTCentralState.toState( central.state ) )
		}
		
		if central.state == .poweredOn {
			UART.sharedInstance.scan()
		}
	}
	
	/// スキャン結果を受け取る
	func centralManager( _ central:CBCentralManager, didDiscover peripheral:CBPeripheral, advertisementData:[String:Any], rssi RSSI:NSNumber )
	{
        let device:UARTDevice!
		if self.has( peripheral ) {
			device = self.get( peripheral )
		} else {
			device = UARTDevice( peripheral:peripheral )
			device.peripheral.delegate = self
			self.add( device )
		}
        
        UART.logger?.debug?( "didDiscover:\(device.uuid)" )
        
		for ( _, value ) in self.delegates {
			value.didDiscoverPeripheral?( device.uuid, advertisementData:advertisementData, RSSI:RSSI )
		}
	}
	
	/// ペリフェラルとの接続が成功すると呼ばれる
	func centralManager( _ central:CBCentralManager, didConnect peripheral:CBPeripheral )
	{
		
		UART.sharedInstance.clearTimer()
		
		if let device = self.get( peripheral ) {
			
			UART.logger?.info?( "Did connect peripheral:\(String(describing: device.peripheral.name))" )
			// サービスを指定して探索
			device.peripheral.discoverServices( [CBUUID(string:UART.UUID.service), CBUUID(string:UART.UUID.deviceInformationService)] )
			
			for ( _, value ) in self.delegates {
				value.didConnectPeripheral?( device.uuid )
			}
		}
	}
	
	/// ペリフェラルへの接続が失敗すると呼ばれる
	func centralManager( _ central:CBCentralManager, didFailToConnect peripheral:CBPeripheral, error:Error? )
	{
		UART.logger?.info?( "Did failed connect:\(String(describing: peripheral.name)), error code\(error!._code)" )
		
		if let device = self.get( peripheral ) {	
			for ( _, value ) in self.delegates {
				value.didFailToConnectPeripheral?( device.uuid, error:error! as NSError )
			}
		}
	}
	
	/// ペリフェラルとの接続が切断されると呼ばれる
	func centralManager( _ central:CBCentralManager, didDisconnectPeripheral peripheral:CBPeripheral, error:Error? )
	{
		UART.logger?.info?( "Did disconnect peripheral:\(String(describing: peripheral.name))" )
		
		if let device = self.get( peripheral ) {
			
			for ( _, value ) in self.delegates {
				value.didDisconnectPeripheral?( device.uuid )
			}
			
			UART.sharedInstance.manager.cancelPeripheralConnection( device.peripheral )
			
			if UART.sharedInstance.retry {
				UART.logger?.debug?( "retry !!!" )
				UART.sharedInstance.connect( device.uuid, retry:true )
			}
		}
	}
}
