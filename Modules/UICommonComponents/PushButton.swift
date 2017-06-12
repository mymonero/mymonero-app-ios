//
//  PushButton.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
extension UICommonComponents
{
	class PushButton: UIButton
	{
		enum PushButtonType
		{
			case utility
			case action
			case destructive
		}
		var pushButtonType: PushButtonType
		init(pushButtonType: PushButtonType)
		{
			self.pushButtonType = pushButtonType
			super.init(frame: .zero)
			self.setup()
		}
		func setup()
		{
			var image: UIImage!
			let disabledImage = UICommonComponents.HighlightableCells.Variant.disabled.image
			var highlightedImage: UIImage!
			var font: UIFont!
			var color: UIColor!
			let disabledColor = UIColor(rgb: 0x6B696B)
			switch self.pushButtonType
			{
			case .utility:
				image = UICommonComponents.HighlightableCells.Variant.utility.image
				highlightedImage = UICommonComponents.HighlightableCells.Variant.utility_highlighted.image
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0xFCFBFC)
				break
			case .action:
				image = UICommonComponents.HighlightableCells.Variant.action.image
				highlightedImage = UICommonComponents.HighlightableCells.Variant.action_highlighted.image
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0x161416)
				break
			case .destructive:
				image = UICommonComponents.HighlightableCells.Variant.destructive.image
				highlightedImage = UICommonComponents.HighlightableCells.Variant.destructive_highlighted.image
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0x161416)
				break
			}
			self.setBackgroundImage(image, for: .normal)
			self.setBackgroundImage(disabledImage, for: .disabled)
			self.setBackgroundImage(highlightedImage, for: .highlighted)
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
