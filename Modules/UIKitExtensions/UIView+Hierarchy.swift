//
//  UIView+Hierarchy.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UIView
{
	func isAnyAncestor(_ equalToView: UIView) -> Bool
	{
		if self == equalToView {
			return true
		}
		if self.superview == nil {
			return false // terminate
		}
		return self.superview!.isAnyAncestor(equalToView)
	}
}
