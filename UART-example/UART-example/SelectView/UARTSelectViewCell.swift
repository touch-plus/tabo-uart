//
//  UARTSelectViewCell.swift
//
//  Created by kasuhisa on 2015/09/07.
//  Copyright (c) 2015年 Bascule Inc. All rights reserved.
//

import UIKit
import CoreBluetooth

class UARTSelectViewCell:UITableViewCell
{

	@IBOutlet weak var uuidLabel	:UILabel!
	@IBOutlet weak var nameLabel	:UILabel!
	
	required init?( coder aDecoder:NSCoder )
	{
		super.init( coder:aDecoder )
	}
	
	override init( style:UITableViewCellStyle, reuseIdentifier:String! )
	{
		super.init( style:style, reuseIdentifier:reuseIdentifier )
	}
	
	override func awakeFromNib()
	{
		super.awakeFromNib()

		NSLog( "awakeFromNib" )
		
        self.accessoryType = .none
		self.uuidLabel.text = ""
		self.nameLabel.text = ""
	}
	
    override func setSelected( _ selected:Bool, animated:Bool )
	{
		super.setSelected( selected, animated:animated )
	}

	func setup( item:UARTItem )
	{
        self.nameLabel.text = item.name! + " (\( item.RSSI.int32Value ))"
		self.uuidLabel.text = item.uuid
	}
}
