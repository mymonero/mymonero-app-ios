//
//  UIColor+Random.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UIColor
{
	static var randomColor: UIColor
	{
		let hue = CGFloat(arc4random() % 256) / CGFloat(256)
		let saturation = CGFloat(arc4random() % 128) / 256 + 0.5 // +0.5 'to stay away from white and black'
		let brightness = CGFloat(arc4random() % 128) / 256 + 0.5
		//
		return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
	}
}
