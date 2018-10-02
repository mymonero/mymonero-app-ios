//
//  ActionButtons.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright (c) 2014-2018, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
import UIKit

extension UICommonComponents
{
	class ActionButton: UICommonComponents.PushButton
	{
		//
		// Properties - Derived - Overrides
		override var _overridable_font: UIFont {
			return UIFont.shouldStepDownLargerFontSizes ? .smallSemiboldSansSerif : .largeSemiboldSansSerif
		}
		// Interface - Properties - Convenience
		static var new_titleEdgeInsets_withIcon: UIEdgeInsets {
			return UIEdgeInsets.init(top: 0, left: 2, bottom: 0, right: 0)
		}
		//
		// Properties
		var isLeftOfTwoButtons: Bool!
		var margins: UIEdgeInsets
		{
			return UIEdgeInsets.init(
				top: ActionButton.topMargin,
				left: CGFloat(0), // left
				bottom: ActionButton.bottomMargin,
				right: CGFloat(isLeftOfTwoButtons == true ? ActionButton.spaceBetweenSiblingButtons : 0) // right
			)
		}
		static var spaceBetweenSiblingButtons: CGFloat = 8
		//
		static var buttonHeight: CGFloat = (UIFont.shouldStepDownLargerFontSizes ? 34 : 42) + 2 // in different width, using smaller font size; +2 because the grey image has shadow around it, and we add extra space for that in the blue and disabled images
		static var topMargin: CGFloat = 8
		static var bottomMargin: CGFloat = 8
		//
		static var wholeButtonsContainerHeight = ActionButton.topMargin + ActionButton.buttonHeight + ActionButton.bottomMargin
		static var wholeButtonsContainerHeight_withoutTopMargin = ActionButton.buttonHeight + ActionButton.bottomMargin
		static var wholeButtonsContainer_margin_h: CGFloat = 16
		//
		var iconImage: UIImage?
		//
		// Imperatives - Init
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
				self.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 17, bottom: 0, right: 0)
				self.contentHorizontalAlignment = .left
			}
		}
		//
		func givenSuperview_layOut(atY y: CGFloat, withMarginH margin_h: CGFloat)
		{
			let superview = self.superview!
			let safeAreaInsets = superview.polyfilled_safeAreaInsets
			let containerWidth = superview.frame.size.width - safeAreaInsets.left - safeAreaInsets.right
			let width = (containerWidth - 2*margin_h)/2 - ActionButton.spaceBetweenSiblingButtons/2
			let x = margin_h + (self.isLeftOfTwoButtons == true ? 0 : width + ActionButton.spaceBetweenSiblingButtons) + safeAreaInsets.left
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
