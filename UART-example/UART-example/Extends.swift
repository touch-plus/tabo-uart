//
//  Extends.swift
//  UART-example
//
//  Created by kazuhisa.maegawa on 2017/11/28.
//  Copyright © 2017年 Bascule Inc. All rights reserved.
//

import UIKit

@IBDesignable
extension UIView
{
    @IBInspectable var cornerRadius: CGFloat
    {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat
    {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor?
    {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set {
            self.layer.borderColor = newValue?.cgColor
        }
    }
}

