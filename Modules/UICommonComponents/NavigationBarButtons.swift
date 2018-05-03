//
//  NavigationBarButtons.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
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
//
extension UICommonComponents
{
	class NavigationBarButtonItem: UIBarButtonItem
	{
		enum ButtonItemType
		{
			case back
			case add
			case cancel
			case save
			case send
			case edit
			case valueDisplayLabel
		}
		var tapped_fn: (() -> Void)?
		convenience init(type: ButtonItemType, target: Any?, action: Selector?)
		{
			self.init(type: type, target: target, action: action, title_orNilForDefault: nil)
		}
		convenience init(type: ButtonItemType, tapped_fn: @escaping () -> Void)
		{
			self.init(type: type, tapped_fn: tapped_fn, title_orNilForDefault: nil)
		}
		init(type: ButtonItemType, tapped_fn: @escaping () -> Void, title_orNilForDefault: String?)
		{
			super.init()
			self.tapped_fn = tapped_fn
			self._shared_initializeWith(type: type, target: self, action: #selector(_forFn_tapped), title_orNilForDefault: title_orNilForDefault)
		}
		init(type: ButtonItemType, target: Any?, action: Selector?, title_orNilForDefault: String?)
		{
			super.init()
			self._shared_initializeWith(type: type, target: target, action: action, title_orNilForDefault: title_orNilForDefault)
		}
		func _shared_initializeWith(type: ButtonItemType, target: Any?, action: Selector?, title_orNilForDefault: String?)
		{
			if type == .valueDisplayLabel {
				let view = UILabel()
				view.text = title_orNilForDefault
				view.font = UIFont.smallRegularMonospace
				view.textColor = UIColor(rgb: 0x9E9C9E)
				view.sizeToFit()
				self.customView = view
				//
				return
			}
			var buttonType: NavigationBarButton.NavigationButtonType!
			switch type
			{
				case .add:
					buttonType = .progressActionSolidButton
					break
			// TODO: make back another style?
				case .cancel, .edit, .back, .save, .send:
					buttonType = .systemStandard
					break
				case .valueDisplayLabel: // to be exhaustive
					assert(false)
					break
			}
			let view = NavigationBarButton(navigationButtonType: buttonType)
			if target != nil && action != nil {
				view.addTarget(target!, action: action!, for: .touchUpInside)
			}
			var sizeToFitAndAddPadding = false
			var or_useWidth_notIncludingImagePadding: CGFloat?
			let imagePaddingForShadow_h = UICommonComponents.PushButtonCells.imagePaddingForShadow_h
			let imagePaddingForShadow_v = UICommonComponents.PushButtonCells.imagePaddingForShadow_v
			switch type
			{
				case .back:
					view.setImage(UIImage(named: "backButtonIcon"), for: .normal)
					or_useWidth_notIncludingImagePadding = 44 // was 24; usability
					view.imageEdgeInsets = UIEdgeInsetsMake(0, -16, 0, 0)
					break
				case .add:
					view.setImage(UIImage(named: "addButtonIcon_10"), for: .normal)
					or_useWidth_notIncludingImagePadding = 26
					view.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
					break
				case .cancel:
					view.setTitle(title_orNilForDefault ?? NSLocalizedString("Cancel", comment: ""), for: .normal)
					sizeToFitAndAddPadding = true
					break
				case .save:
					view.setTitle(title_orNilForDefault ?? NSLocalizedString("Save", comment: ""), for: .normal)
					sizeToFitAndAddPadding = true
					break
				case .send:
					view.setTitle(title_orNilForDefault ?? NSLocalizedString("Send", comment: ""), for: .normal)
					sizeToFitAndAddPadding = true
					break
				case .edit:
					view.setTitle(title_orNilForDefault ?? NSLocalizedString("Edit", comment: ""), for: .normal)
					sizeToFitAndAddPadding = true
					break
				case .valueDisplayLabel: // to be exhaustive
					assert(false)
					break
			}
			var frame: CGRect!
			if sizeToFitAndAddPadding {
				view.sizeToFit()
				//
				let padding_x: CGFloat = 8
				frame = view.frame // after sizeToFit()
				frame.size.width += 2*padding_x + 2*imagePaddingForShadow_h
			} else {
				frame = view.frame
				if let width = or_useWidth_notIncludingImagePadding {
					frame.size.width = width + 2*imagePaddingForShadow_h
				}
			}
			frame.size.height = 24 + 2*imagePaddingForShadow_v
			view.frame = frame
			self.customView = view
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		//
		@objc func _forFn_tapped()
		{
			self.tapped_fn!()
		}
	}
	//
	class NavigationBarButton: UIButton
	{
		enum NavigationButtonType
		{
			case systemStandard
			case progressActionSolidButton
			case destructive
		}
		var navigationButtonType: NavigationButtonType
		init(navigationButtonType: NavigationButtonType)
		{
			self.navigationButtonType = navigationButtonType
			super.init(frame: .zero)
			self.setup()
		}
		func setup()
		{
			let font: UIFont = UIFont.shouldStepDownLargerFontSizes ? .middlingSemiboldSansSerif : .largeMediumSansSerif
			var color: UIColor!
			let disabledColor = UIColor(rgb: 0x6B696B)
			switch self.navigationButtonType
			{
			case .systemStandard:
				color = UIColor(rgb: 0x00C6FF)
				break
			case .progressActionSolidButton:
				color = UIColor(rgb: 0x161416)
				self.adjustsImageWhenHighlighted = false // looks better IMO -PS
				let image = UICommonComponents.PushButtonCells.Variant.action.stretchableImage
				let highlightedImage = UICommonComponents.PushButtonCells.Variant.action_highlighted.stretchableImage
				
				let disabledImage = UICommonComponents.PushButtonCells.Variant.disabled.stretchableImage
				self.setBackgroundImage(image, for: .normal)
				self.setBackgroundImage(disabledImage, for: .disabled)
				self.setBackgroundImage(highlightedImage, for: .highlighted)
				//
				break
			case .destructive:
				color = UIColor.standaloneValidationTextOrDestructiveLinkContentColor
				break
			}
			self.titleLabel!.font = font
			self.setTitleColor(color, for: .normal)
			self.setTitleColor(disabledColor, for: .disabled)
		}
		required init?(coder aDecoder: NSCoder)
		{
			fatalError("init(coder:) has not been implemented")
		}
	}
}
