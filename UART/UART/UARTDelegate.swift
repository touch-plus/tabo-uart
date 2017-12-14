//
//  UARTDelegate.swift
//  UART
//
//  Created by kasuhisa on 2016/02/02.
//  Copyright © 2016年 Bascule Inc. All rights reserved.
//

import Foundation

///　UART のプロトコル
@objc
public protocol UARTDelegate
{
	/**
	準備が完了した場合に呼ばれる
	*/
	@objc optional func didReady( _ uuid:String )
	
	/**
	データを受信した場合に呼ばれる
	
	- parameter data: バイトデータ
	*/
	@objc optional func didReceiveDataByte( _ uuid:String, data:Data )
	
	/**
	ハードウェアリビジョン文字列を受信した場合に呼ばれる
	
	- parameter data: 受信文字列データ
	*/
	@objc optional func didReadHardwareRevisionString( _ uuid:String, data:String )
	
	/**
	セントラルマネージャの状態変化が変化した場合に呼ばれる
	
	- parameter state: 状態
	*/
	@objc optional func didUpdateState( _ state:UARTCentralState )
	
	/**
	スキャン結果を受け取る
	
	- parameter peripheral: ペリフェラル
	- parameter advertisementData: アドバタイズデータ
	- parameter RSSI: 電波強度
	*/
	@objc optional func didDiscoverPeripheral( _ uuid:String, advertisementData:[AnyHashable: Any]!, RSSI:NSNumber! )
	
	/**
	ペリフェラルとの接続が成功すると呼ばれる
	
	- parameter peripheral: ペリフェラル
	*/
	@objc optional func didConnectPeripheral( _ uuid:String )
	
	/**
	ペリフェラルへの接続が失敗すると呼ばれる
	
	- parameter peripheral: ペリフェラル
	- parameter error: エラー
	*/
	@objc optional func didFailToConnectPeripheral( _ uuid:String, error:NSError! )
	
	/**
	ペリフェラルとの接続が切断されると呼ばれる
	
	- parameter peripheral: ペリフェラル
	*/
	@objc optional func didDisconnectPeripheral( _ uuid:String )
	
	/**
	ペリフェラルのRSSIが更新されると呼ばれる
	
	- parameter peripheral: ペリフェラル
	*/
	@objc optional func didReadRSSI( _ uuid:String, RSSI:NSNumber )
}
