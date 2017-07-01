//
//  UIView+Debug.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UIView
{
	func giveBorder()
	{
		self.layer.borderColor = UIColor.randomColor.cgColor
		self.layer.borderWidth = 1
	}
	func borderSubviews()
	{
		for (_, subview) in self.subviews.enumerated() {
			subview.giveBorder()
			subview.borderSubviews()
		}
	}
}
