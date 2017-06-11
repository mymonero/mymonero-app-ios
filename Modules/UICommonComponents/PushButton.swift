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
class MMPushButton: UIButton
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
		let disabledImage = UIImage(named: "pushButtonBG_disabled")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
		var highlightedImage: UIImage!
		var font: UIFont!
		var color: UIColor!
		let disabledColor = UIColor(rgb: 0x6B696B)
		switch self.pushButtonType
		{
		case .utility:
			image = UIImage(named: "pushButtonBG_utility")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
			highlightedImage = UIImage(named: "pushButtonBG_utility_highlighted")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
			font = UIFont.middlingSemiboldSansSerif
			color = UIColor(rgb: 0xFCFBFC)
			break
		case .action:
			image = UIImage(named: "pushButtonBG_action")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
			highlightedImage = UIImage(named: "pushButtonBG_action_highlighted")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
			font = UIFont.middlingSemiboldSansSerif
			color = UIColor(rgb: 0x161416)
			break
		case .destructive:
			image = UIImage(named: "pushButtonBG_destructive")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
			highlightedImage = UIImage(named: "pushButtonBG_destructive_highlighted")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
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
