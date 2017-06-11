//
//  ActionButtons.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UICommonComponents
{
	class ActionButton: UICommonComponents.PushButton
	{
		var isLeftOfTwoButtons: Bool!
		var margins: UIEdgeInsets
		{
			return UIEdgeInsetsMake(
				ActionButton.topMargin,
				CGFloat(0), // left
				ActionButton.bottomMargin,
				CGFloat(isLeftOfTwoButtons == true ? ActionButton.spaceBetweenSiblingButtons : 0) // right
			)
		}
		static var spaceBetweenSiblingButtons: CGFloat = 8
		static var buttonHeight: CGFloat = 32+2 // +2 because the grey image has shadow around it, and we add extra space for that in the blue and disabled images
		static var topMargin: CGFloat = 8
		static var bottomMargin: CGFloat = 8
		static var wholeButtonsContainerHeight: CGFloat = ActionButton.topMargin + ActionButton.buttonHeight + ActionButton.bottomMargin
		//
		init(pushButtonType: PushButtonType, isLeftOfTwoButtons: Bool)
		{
			self.isLeftOfTwoButtons = isLeftOfTwoButtons
			super.init(pushButtonType: pushButtonType)
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup()
		{
			super.setup()
		}
		//
		func givenSuperview_layOut(atY y: CGFloat, withMarginH margin_h: CGFloat)
		{
			let containerWidth = self.superview!.frame.size.width
			let width = (containerWidth - 2*margin_h)/2 - ActionButton.spaceBetweenSiblingButtons/2
			let x = margin_h + (self.isLeftOfTwoButtons == true ? 0 : width + ActionButton.spaceBetweenSiblingButtons)
			self.frame = CGRect(
				x: x,
				y: y,
				width: width,
				height: ActionButton.buttonHeight
			)
		}
	}
}
