//
//  UARTSelectView.swift
//
//  Created by kasuhisa on 2015/08/18.
//  Copyright (c) 2015年 Bascule Inc. All rights reserved.
//

import UIKit
import UART
import CoreBluetooth

@objc protocol UARTSelectViewDelegate
{
	/// 接続通知
    @objc optional func didConnectionNotify( item:UARTItem )
	/// 切断通知
	@objc optional func didDisconnectionNotify( item:UARTItem )
	/// 接続確認
	@objc optional func didConnectionConfirmation( item:UARTItem )
	/// 切断確認
	@objc optional func didDisconnectionConfirmation( item:UARTItem )
}

extension UARTSelectView:UITableViewDelegate, UITableViewDataSource
{
	/*
	Cellが選択された際に呼び出されるデリゲートメソッド.
	*/
    func tableView( _ tableView:UITableView, didSelectRowAt indexPath:IndexPath )
	{
		self.stopScan()
		
		if let item = self.items[indexPath.row] as? UARTItem {
			
            NSLog( "state:\(String(describing: item.state?.name))" )
			
            if( item.state == .connected ) {
                self.delegate?.didDisconnectionConfirmation?( item: item )
			} else {
                item.state = CBPeripheralState.connecting
                self.delegate?.didConnectionConfirmation?( item: item )
			}
		}
	}
	
	/*
	Cellの総数を返すデータソースメソッド.
	(実装必須)
	*/
    func tableView( _ tableView:UITableView, numberOfRowsInSection section:Int ) -> Int
	{
		return self.items.count
	}
	
	/*
	Cellに値を設定するデータソースメソッド.
	(実装必須)
	*/
    func tableView( _ tableView:UITableView, cellForRowAt indexPath:IndexPath ) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCell( withIdentifier: "mycell", for:indexPath ) as! UARTSelectViewCell
		if let item = self.items[indexPath.row] as? UARTItem {
            cell.setup( item: item )
		}
		return cell
	}
	
	/*
	行の高さ
	*/
    func tableView( _ tableView:UITableView, heightForRowAt indexPath:IndexPath ) -> CGFloat
	{
		return 55
	}
}

extension UARTSelectView:UARTDelegate
{
	/**
	準備が完了した場合に呼ばれる
	*/
	func didReady(_ uuid: String)
	{
		NSLog( "didReady:\(uuid)" )

        if let item = self.getItem( uuid: uuid ) {
			
			NSLog( "didReady:\(self.delegate?.didConnectionNotify != nil)" )
			
            self.delegate?.didConnectionNotify?( item: item )
		}
		
		UART.sharedInstance.removeDelegate( self )
	}
	
	/**
	ハードウェアリビジョン文字列を受信した場合に呼ばれる
	
	- parameter string: 受信文字列データ
	*/
	func didReadHardwareRevisionString(_ uuid: String, data: String)
	{
		NSLog( "didReadHardwareRevisionString" )
	}
	
	/**
	スキャン結果を受け取る
	
	- parameter peripheral: ペリフェラル
	- parameter advertisementData: アドバタイズデータ
	- parameter RSSI: 電波強度
	*/
    func didDiscoverPeripheral( _ uuid:String, advertisementData:[AnyHashable : Any]!, RSSI:NSNumber! )
	{
		var name:String? = advertisementData["kCBAdvDataLocalName" as NSObject] as? String
		if name == nil { name = "no name" }
		
        if let _ = self.getItem( uuid: uuid ) { return }
		
        NSLog( "Did discover peripheral:\(String(describing: name)):::\(uuid)" )
		
        self.items.add( UARTItem( uuid:uuid, name:name!, RSSI:RSSI ) )
		self.tableView.reloadData()
	}
	
	/**
	ペリフェラルとの接続が成功すると呼ばれる
	
	- parameter peripheral: ペリフェラル
	*/
    func didConnectPeripheral(_ uuid: String)
	{
		NSLog( "didConnectPeripheral:\(uuid)" )
		
        if let item = self.getItem( uuid: uuid ) {
            item.state = CBPeripheralState.connected
		}
		
		self.tableView.reloadData()
	}
	
	/**
	ペリフェラルへの接続が失敗すると呼ばれる
	
	- parameter peripheral: ペリフェラル
	- parameter error: エラー
	*/
    func didFailToConnectPeripheral(_ uuid: String, error: NSError!)
	{
		NSLog( "didFailToConnectPeripheral:\(uuid)" )
		
		self.tableView.reloadData()
		
        if let item = self.getItem( uuid: uuid ) {
            item.state = CBPeripheralState.disconnected
            self.items.remove( item )
			self.tableView.reloadData()
            self.delegate?.didDisconnectionNotify?( item: item )
		}
	}
	
	/**
	ペリフェラルとの接続が切断されると呼ばれる
	
	- parameter peripheral: ペリフェラル
	- parameter error: エラー
	*/
    func didDisconnectPeripheral(_ uuid: String)
	{
		NSLog( "didDisconnectPeripheral:\(uuid)" )
		
		self.tableView.reloadData()
		
        if let item = self.getItem( uuid: uuid ) {
            item.state = CBPeripheralState.disconnected
            self.items.remove( item )
			self.tableView.reloadData()
            self.delegate?.didDisconnectionNotify?( item: item )
		}
	}
}

class UARTSelectView:UIView
{
	var delegate	:UARTSelectViewDelegate?
	var items		:NSMutableArray = []
    var timer		:Timer!
	
	@IBOutlet weak var tableView			:UITableView!
	@IBOutlet weak var scanButton			:UIButton!
	@IBOutlet weak var activityIndicator	:UIActivityIndicatorView!
	@IBOutlet weak var bacugroundView		:UIView!
	
    /**
	検索ボタンを押下した場合
	
	- parameter sender: ボタン
	*/
	@IBAction func onSearch( _ sender: Any )
	{
        if self.activityIndicator.isAnimating {
			self.stopScan()
		} else {
			self.startScan()
		}
	}
	
	override init( frame:CGRect )
	{
		super.init( frame:frame )
		
        let view = Bundle.main.loadNibNamed( "UARTSelectView", owner:self, options:nil )?.first as! UIView
			view.frame = self.bounds
			view.translatesAutoresizingMaskIntoConstraints = true
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
		
		self.addSubview( view )
		
		self.activityIndicator.hidesWhenStopped = true
		self.activityIndicator.stopAnimating()
		
        self.scanButton.setTitle( "もういちど探す", for:UIControlState.normal )
		self.scanButton.backgroundColor = UIColor( red:0/255, green:122/255, blue:255/255, alpha:1 )
		self.scanButton.layer.cornerRadius = 10.0
		
        self.tableView.register( UINib( nibName:"UARTSelectViewCell", bundle:nil ), forCellReuseIdentifier:"mycell" )
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.reloadData()
		self.tableView.layer.cornerRadius = 10.0
        self.tableView.layer.borderColor = UIColor( red:100/255, green:100/255, blue:100/255, alpha:1 ).cgColor
		self.tableView.layer.borderWidth = 1.0
		
		self.bacugroundView.layer.cornerRadius = 10.0
        self.bacugroundView.layer.borderColor = UIColor( red:100/255, green:100/255, blue:100/255, alpha:1 ).cgColor
		self.bacugroundView.layer.borderWidth = 1.0
		
		self.items = []
	}

	required init?( coder aDecoder:NSCoder )
	{
	    fatalError( "init(coder:) has not been implemented" )
	}
	
	private func getItem( uuid:String ) -> UARTItem?
	{
		NSLog( "getItem:\(uuid)" )
		
		for item in self.items {
			if let temp = item as? UARTItem {
				if temp.uuid == uuid {
					return temp
				}
			}
		}
		return nil
	}
	
    private func setTimeout( delay:TimeInterval, block:@escaping ()->Void ) -> Timer
	{
        return Timer.scheduledTimer( timeInterval: delay, target: BlockOperation( block:block ), selector:#selector(Operation.main), userInfo:nil, repeats:false )
	}
	
    private func clearTimeout( timer:Timer? ) -> Void
	{
		timer?.invalidate()
	}
}

extension UARTSelectView
{
	/// スキャンを開始する
	func startScan()
	{
		NSLog( "startScan" )
		
		self.activityIndicator.hidesWhenStopped = false
		self.activityIndicator.startAnimating()
		
        self.scanButton.setTitle( "探すのをやめる", for:.normal )
		self.scanButton.backgroundColor = UIColor( red:255/255, green:0/255, blue:125/255, alpha:1 )
		
		self.items = []
		
		self.tableView.reloadData()
		
		UART.sharedInstance.addDelegate( self, delegate:self )
		UART.sharedInstance.stopScan()
		UART.sharedInstance.startScan( true )
		
        self.timer = setTimeout( delay: 2 ) { self.stopScan() }
	}
	
	/// スキャンを停止する
	func stopScan()
	{
		NSLog( "stopScan" )
		
        clearTimeout( timer: self.timer )
		
		self.activityIndicator.hidesWhenStopped = true
		self.activityIndicator.stopAnimating()
        self.scanButton.setTitle( "もういちど探す", for:.normal )
		self.scanButton.backgroundColor = UIColor( red:0/255, green:122/255, blue:255/255, alpha:1 )
		
		UART.sharedInstance.stopScan()
	}

	/// 接続する
	func connect( item:UARTItem )
	{
		UART.sharedInstance.connect( item.uuid, retry:false )
	}
	
	/// 切断する
	func disconnect( item:UARTItem )
	{
		UART.sharedInstance.disconnect( item.uuid )
	}
}

