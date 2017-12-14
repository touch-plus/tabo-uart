//
//  ViewController.swift
//  UART-example
//
//  Created by kasuhisa on 2016/02/10.
//  Copyright © 2016年 Bascule Inc. All rights reserved.
//
//  接続、切断、コマンドの送受信のサンプル
//

import UIKit
import UART

class ViewController:UIViewController
{
    var dialog	:UARTSelectView!
    var item	:UARTItem!
    
    @IBOutlet weak var nicknameTF: UITextField!
    
    // 変更ボタンが押下された場合
    @IBAction func onTouchChangeNickname(_ sender: Any)
    {
        print( "onTouchChangeNickname" )
        
        if let uuid = self.item.uuid, let text = self.nicknameTF.text
        {
            // ニックネームを変更する
            UART.sharedInstance.writeString( uuid, string: "SDN:\(text)\0")
        }
    }
    
    // 赤ボタンが押下された場合
    @IBAction func onTouchR( _ sender: Any )
    {
        print( "onTouchR" )
        
        if let uuid = self.item.uuid
        {
            // 目の色を変更する
            UART.sharedInstance.writeString( uuid, string: "LAI:255,0,0")
        }
    }
    // 緑ボタンが押下された場合
    @IBAction func onTouchG( _ sender: Any )
    {
        print( "onTouchG" )
        
        if let uuid = self.item.uuid
        {
            // 目の色を変更する
            UART.sharedInstance.writeString( uuid, string: "LAI:0,255,0")
        }
    }
    // 青ボタンが押下された場合
    @IBAction func onTouchB( _ sender: Any )
    {
        print( "onTouchB" )
        
        if let uuid = self.item.uuid
        {
            // 目の色を変更する
            UART.sharedInstance.writeString( uuid, string: "LAI:0,0,255")
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.nicknameTF.delegate = self
        
        // 接続ダイアログを表示
        self.dialog = UARTSelectView( frame:self.view.frame )
        self.dialog.delegate = self
        self.dialog.startScan()
        self.dialog.isHidden = false
        self.view.addSubview( self.dialog )
    }
    
    override func viewDidAppear( _ animated:Bool )
    {
        NotificationCenter.default.addObserver(
            self,
            selector:#selector(ViewController.onOrientationChange),
            name:NSNotification.Name.UIDeviceOrientationDidChange,
            object:nil )
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
    
    // 端末の向きがかわったら呼び出される
    @objc func onOrientationChange( notification:NSNotification )
    {
        if self.dialog != nil {
            self.dialog.frame = self.view.frame
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

extension ViewController:UITextFieldDelegate
{
    /// テキストが編集された場合
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        if let text = textField.text
        {
            let str = text + string
            if str.count <= 15 { return true }
        }
        return false
    }
}

extension ViewController:UARTDelegate
{
    /**
     ペリフェラルとの接続が切断されると呼ばれる
     
     - parameter peripheral: ペリフェラル
     - parameter error: エラー
     */
    func didDisconnectPeripheral( _ uuid:String )
    {
        print( "didDisconnectPeripheral:\(uuid)" )
        
        // 接続ダイアログを表示
        self.dialog.delegate = self
        self.dialog.isHidden = false
        self.dialog.startScan()
        
        self.item = nil
        
        UART.sharedInstance.removeDelegate( self )
    }
    
    /**
     データを受信した場合に呼ばれる
     
     - parameter data: バイトデータ
     */
    func didReceiveDataByte( _ uuid:String, data:Data )
    {
        if let out = NSString( data:data, encoding:String.Encoding.utf8.rawValue )
        {
            print( "didReceiveDataByte:\(out)" )
        }
    }
}

extension ViewController:UARTSelectViewDelegate
{
    /// 接続通知
    func didConnectionNotify( item:UARTItem )
    {
        print( "didConnectionNotify" )
        
        UART.sharedInstance.addDelegate( self, delegate:self )
        
        self.item = item
        
        // 接続ダイアログを非表示
        self.dialog.delegate = nil
        self.dialog.isHidden = true
        
        // 接続したTABOの名前をセット
        self.nicknameTF.text = self.item.name
    }
    
    /// 切断通知
    func didDisconnectionNotify( item:UARTItem )
    {
        print( "didDisconnectionNotify" )
    }
    
    /// 接続確認
    func didConnectionConfirmation( item:UARTItem )
    {
        print( "didConnectionConfirmation" )
        
        let name:String = item.name!
        
        let otherAction = UIAlertAction( title:"はい", style:.default ){ action in
            print( "pushed OK!" )
            self.dialog.connect( item: item )
        }
        let cancelAction = UIAlertAction( title:"いいえ", style:.cancel ){ action in
            print( "Pushed CANCEL!" )
        }
        let alertController = UIAlertController( title:"接続確認", message:"\(name)と接続しますか？", preferredStyle:.alert )
        alertController.addAction( otherAction )
        alertController.addAction( cancelAction )
        
        self.present( alertController, animated:false, completion:nil )
    }
    
    /// 切断確認
    func didDisconnectionConfirmation( item:UARTItem )
    {
        print( "didDisconnectionConfirmation" )
        
        let name:String = item.name!
        
        let otherAction = UIAlertAction( title:"はい", style:.default ){ action in
            print( "pushed OK!" )
            self.dialog.disconnect( item: item )
        }
        let cancelAction = UIAlertAction( title:"いいえ", style:.cancel ){ action in
            print( "Pushed CANCEL!" )
        }
        let alertController = UIAlertController( title:"切断確認", message:"\(name)を切断しますか？", preferredStyle:.alert )
        alertController.addAction( otherAction )
        alertController.addAction( cancelAction )
        
        self.present( alertController, animated:false, completion:nil )
    }
}
