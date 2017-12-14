//
//  UARTLogger.swift
//  UART
//
//  Created by kasuhisa on 2016/02/02.
//  Copyright © 2016年 Bascule Inc. All rights reserved.
//

import Foundation

@objc
public protocol UARTLogger
{
    /**
     ログレベルを設定する
     - parameter logLevel: ログ出力レベル
     */
    @objc optional func setLoglevel( _ logLevel:Int )
	/**
	詳細
	- parameter message: メッセージ
	*/
	@objc optional func verbose( _ message:String )
	/**
	デバッグ
	- parameter message: メッセージ
	*/
	@objc optional func debug( _ message:String )
	/**
	情報
	- parameter message: メッセージ
	*/
	@objc optional func info( _ message:String )
	/**
	警告
	- parameter message: メッセージ
	*/
	@objc optional func warn( _ message:String )
	/**
	エラー
	- parameter message: デバッグ
	*/
	@objc optional func error( _ message:String )
}

internal class UARTDefaultLogger:NSObject, UARTLogger
{
    internal var logLevel:Int = 5
    
    func setLoglevel( _ logLevel:Int )
    {
        self.logLevel = logLevel
    }
	func verbose( _ message:String )
	{
        if 0 >= self.logLevel { print( "[V]\(message)" ) }
	}
	func debug( _ message:String )
	{
		if 1 >= self.logLevel { print( "[D]\(message)" ) }
	}
	func info( _ message:String )
	{
		if 2 >= self.logLevel { print( "[I]\(message)" ) }
	}
	func warn( _ message:String )
	{
		if 3 >= self.logLevel { print( "[W]\(message)" ) }
	}
	func error( _ message:String )
	{
		if 4 >= self.logLevel { print( "[E]\(message)" ) }
	}
}

internal class UARTMuteLogger:NSObject, UARTLogger
{
    func verbose( message:String )
    {
        
    }
    func debug( message:String )
    {
        
    }
    func info( message:String )
    {
        
    }
    func warn( message:String )
    {
        
    }
    func error( message:String )
    {
        
    }
}

