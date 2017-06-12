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
			let capSize: Int = 5
			var image: UIImage!
			let disabledImage = UIImage(named: "highlightableCellBG_disabled")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize)
			var highlightedImage: UIImage!
			var font: UIFont!
			var color: UIColor!
			let disabledColor = UIColor(rgb: 0x6B696B)
			switch self.pushButtonType
			{
			case .utility:
				image = UIImage(named: "highlightableCellBG_utility")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize)
				highlightedImage = UIImage(named: "highlightableCellBG_utility_highlighted")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize)
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0xFCFBFC)
				break
			case .action:
				image = UIImage(named: "highlightableCellBG_action")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize)
				highlightedImage = UIImage(named: "highlightableCellBG_action_highlighted")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize)
				font = UIFont.middlingSemiboldSansSerif
				color = UIColor(rgb: 0x161416)
				break
			case .destructive:
				image = UIImage(named: "highlightableCellBG_destructive")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize)
				highlightedImage = UIImage(named: "highlightableCellBG_destructive_highlighted")!.stretchableImage(withLeftCapWidth: capSize, topCapHeight: capSize)
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
