//
//  UART.swift
//  UART
//
//  Created by kasuhisa on 2015/08/13.
//  Copyright (c) 2015年 Bascule Inc. All rights reserved.
//

//import UIKit
import CoreBluetooth

/// UART
open class UART
{
    internal var manager			:CBCentralManager!
    fileprivate var queue			:DispatchQueue!
    
    /// 切断された場合に再接続処理するかの判定
    internal var retry				:Bool = false
    /// デバイススキャン時に重複を許可するかの判定
    fileprivate var duplicate		:Bool = false
    /// 接続タイムアウトを監視
    fileprivate var connTimer		:Timer!
    
    fileprivate var deviceDelegate	:UARTDeviceDelegate!
    
    public struct UUID
    {
        /// UARTサービスUUID
        public static var service						:String = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
        /// 送信キャラスティックUUID
        public static var write							:String = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
        /// 受信キャラスティックUUID
        public static var read							:String = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
        
        /// デバイス情報サービスUUID
        internal static let deviceInformationService	:String = "180A"
        /// ハードウェアリビジョンUUID
        internal static let hardwareRevision			:String = "2A27"
    }
    
    fileprivate init()
    {
        UART.logger?.info?( "init!!!" )
        
        self.queue = DispatchQueue( label: "command", attributes: [] )
        self.deviceDelegate = UARTDeviceDelegate()
    }
    
    /// デバイスをスキャンを開始する
    internal func scan()
    {
        UART.logger?.info?( "scan:\(self.manager.isScanning)" )
        
        if !self.manager.isScanning {
            self.manager.scanForPeripherals( withServices: [CBUUID(string:UUID.service) ],
                                             options:[CBCentralManagerScanOptionAllowDuplicatesKey:self.duplicate] // 同一デバイス発見の通知が1回のみにする
            )
        }
    }
    
    /// Rawデータを書き込む
    fileprivate func writeRawData( _ device:UARTDevice!, data:Data )
    {
        UART.logger?.debug?( data.base16EncodedString() )
        
        if device.peripheral.state != .connected { return }
        
        if( device.write == nil ) { return }
        
        if( ( device.write.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue ) != 0 ) {
            self.queue.async(execute: {
                usleep( 20 * 1000 )
                device.peripheral.writeValue( data, for:device.write, type:CBCharacteristicWriteType.withoutResponse )
            } )
        } else if( ( device.write.properties.rawValue & CBCharacteristicProperties.write.rawValue ) != 0 ) {
            self.queue.async(execute: {
                usleep( 20 * 1000 )
                device.peripheral.writeValue( data, for:device.write, type:CBCharacteristicWriteType.withResponse )
            } )
        } else {
            UART.logger?.warn?( "No write property on TX characteristic, \(device.write.properties)." )
        }
    }
}

// MARK: - デリゲート
extension UART
{
    /**
     デリゲートを追加する
     - parameter key: オブジェクト
     - parameter delegate: デリゲート
     */
    public func addDelegate( _ key:NSObject, delegate:UARTDelegate )
    {
        self.deviceDelegate.delegates[key] = delegate
    }
    
    /**
     デリゲートを削除する
     - parameter key: オブジェクト
     */
    public func removeDelegate( _ key:NSObject )
    {
        self.deviceDelegate.delegates.removeValue( forKey: key )
    }
    
    public var delegate:UARTDelegate?
    {
        set {
            if newValue != nil
            {
                self.deviceDelegate.delegates["\(#file)" as NSObject] = newValue
            } else {
                self.deviceDelegate.delegates.removeValue( forKey: "\(#file)" as NSObject )
            }
        }
        get {
            return self.deviceDelegate.delegates["\(#file)" as NSObject]
        }
    }
}

// MARK: - 公開メソッド
extension UART
{
    /// インスタンスを提供する
    public class var sharedInstance:UART
    {
        struct Static {
            static let instance:UART = UART()
        }
        return Static.instance
    }
    
    /// UARTログ出力のプロトコル
    public static var logger:UARTLogger? = UARTDefaultLogger()
    
    /// デバイスのスキャンを開始する
    public func startScan( _ duplicate:Bool=false )
    {
        UART.logger?.info?( "startScan:\(duplicate)" )
        
        self.duplicate = duplicate
        
        if self.manager == nil {
            self.manager = CBCentralManager( delegate:self.deviceDelegate, queue:nil, options:[CBCentralManagerOptionShowPowerAlertKey:true] )
        } else {
            self.scan()
        }
    }
    
    /// デバイスをスキャンを停止する
    public func stopScan()
    {
        UART.logger?.info?( "stopScan" )
        
        if self.manager != nil {
            self.manager.stopScan()
        }
    }
    
    /// 接続する
    public func connect( _ uuid:String, retry:Bool=false )
    {
        UART.logger?.info?( "connect:\(uuid) -> retry:\(retry)" )
        
        if let peripheral = self.deviceDelegate.get( uuid ) {
            
            UART.logger?.info?( "connect:\(uuid),\(peripheral.peripheral)" )
            
            self.retry = retry
            
            self.startTimer( uuid )
            
            self.manager.stopScan()
            self.manager.connect( peripheral.peripheral, options:[CBConnectPeripheralOptionNotifyOnDisconnectionKey:true] )
        }
    }
    
    /// 切断する
    public func disconnect( _ uuid:String )
    {
        UART.logger?.info?( "Did disconnect" )
        
        if let peripheral = self.deviceDelegate.get( uuid ) {
            
            if self.manager != nil {
                self.manager.stopScan()
                
                self.retry = false
                self.manager.cancelPeripheralConnection( peripheral.peripheral )
            }
        }
    }
    
    /// RSSIを取得する
    public func readRSSI()
    {
        UART.logger?.debug?( "readRSSI" )
        
        for container in self.deviceDelegate.devices.values {
            container?.peripheral.readRSSI()
        }
    }
    
    /// 文字列を書き込む
    public func writeString( _ uuid:String, string:String )
    {
        UART.logger?.verbose?( "TX:\(string)" )
        
        if let peripheral = self.deviceDelegate.get( uuid ) {
            let bytes = [UInt8](string.utf8)
            self.writeRawData( peripheral, data:Data( bytes: UnsafePointer<UInt8>(bytes), count:bytes.count ) )
        }
    }
}

// MARK: - 非公開
extension UART
{
    internal func startTimer( _ uuid:String )
    {
        UART.logger?.debug?( "startTimer:\(uuid)" )
        
        self.connTimer = self.setTimeout( 5, userInfo:uuid as AnyObject ) {
            
            self.retry = false
            
            if let uuid = self.connTimer.userInfo as? String {
                
                UART.logger?.debug?( "timeout:\(uuid)" )
                
                if let container = self.deviceDelegate.get( uuid ) {
                    self.manager.cancelPeripheralConnection( container.peripheral )
                    UART.logger?.info?( "connect timeout." )
                }
            }
            
            self.clearTimer()
        }
    }
    
    internal func clearTimer()
    {
        UART.logger?.debug?( "clearTimer" )
        
        if self.connTimer != nil {
            self.connTimer.invalidate()
            self.connTimer = nil
        }
    }
    
    fileprivate func setTimeout( _ delay:TimeInterval, userInfo:AnyObject?=nil, block:@escaping () -> Void ) -> Timer
    {
        return Timer.scheduledTimer( timeInterval: delay, target:BlockOperation( block:block ), selector:#selector(Operation.main), userInfo:userInfo, repeats:false )
    }
}

extension Data
{
    func base16EncodedString( uppercase:Bool=false ) -> String
    {
        let buffer = UnsafeBufferPointer<UInt8>( start:(self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count), count:self.count )
        let hexFormat = uppercase ? "X" : "x"
        let formatString = "0x%02\(hexFormat) "
        let bytesAsHexStrings = buffer.map {
            String( format:formatString, $0 )
        }
        return bytesAsHexStrings.joined( separator: "" )
    }
}
