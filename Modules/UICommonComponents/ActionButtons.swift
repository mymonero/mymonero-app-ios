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
		//
		static var buttonHeight: CGFloat = 32+2 // +2 because the grey image has shadow around it, and we add extra space for that in the blue and disabled images
		static var topMargin: CGFloat = 8
		static var bottomMargin: CGFloat = 8
		//
		static var wholeButtonsContainerHeight = ActionButton.topMargin + ActionButton.buttonHeight + ActionButton.bottomMargin
		static var wholeButtonsContainerHeight_withoutTopMargin = ActionButton.buttonHeight + ActionButton.bottomMargin
		static var wholeButtonsContainer_margin_h: CGFloat = 16
		//
		var iconImage: UIImage?
		//
		init(pushButtonType: PushButtonType, isLeftOfTwoButtons: Bool)
		{
			self.isLeftOfTwoButtons = isLeftOfTwoButtons
			super.init(pushButtonType: pushButtonType)
		}
		init(pushButtonType: PushButtonType, isLeftOfTwoButtons: Bool, iconImage: UIImage)
		{
			self.isLeftOfTwoButtons = isLeftOfTwoButtons
			self.iconImage = iconImage
			super.init(pushButtonType: pushButtonType)
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup()
		{
			super.setup()
			if self.iconImage != nil {
				self.setImage(iconImage, for: .normal)
				self.imageEdgeInsets = UIEdgeInsetsMake(0, 17, 0, 0)
				self.contentHorizontalAlignment = .left
			}
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
		//
		// Accessors - Overrides - Centering title with an image
		override func titleRect(forContentRect contentRect: CGRect) -> CGRect
		{
			let titleRect = super.titleRect(forContentRect: contentRect)
			if self.iconImage == nil {
				return titleRect 
			}
			let imageSize = self.currentImage?.size ?? .zero
			let availableWidth = contentRect.width - self.imageEdgeInsets.right - imageSize.width - titleRect.width
			return titleRect.offsetBy(dx: round(availableWidth / 2), dy: 0)
		}
	}
}
