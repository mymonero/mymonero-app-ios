//
//  UIResponder+Current.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UIView
{
	func resignCurrentFirstResponder()
	{
		if let responder = self.currentFirstResponder {
			responder.resignFirstResponder()
		}
	}
	var currentFirstResponder: UIResponder?
	{
		if self.isFirstResponder {
			return self
		}
		for view in self.subviews {
			if let responder = view.currentFirstResponder {
				return responder
			}
		}
		return nil
	}
}
