//
//  InlineMessages.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/25/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
extension UICommonComponents
{
	class ReadableInfoHeaderLabel: UILabel
	{
		//
		// Properties
		
		//
		// Lifecycle - Init
		init()
		{
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.font = UIFont.middlingSemiboldSansSerif
			self.textColor = UIColor(rgb: 0xF8F7F8)
			self.numberOfLines = 0
		}
		//
		// Accessors

		//
		// Imperatives

	}
	class ReadableInfoDescriptionLabel: UILabel
	{
		//
		// Properties
		
		//
		// Lifecycle - Init
		init()
		{
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.numberOfLines = 0
		}
		//
		// Accessors
		
		//
		// Imperatives
		func set(text: String)
		{
			let paragraphStyle = NSMutableParagraphStyle()
			do {
				paragraphStyle.lineSpacing = 4
			}
			let attributedString = NSAttributedString(
				string: text,
				attributes:
				[
					NSForegroundColorAttributeName: UIColor(rgb: 0x8D8B8D),
					NSFontAttributeName: UIFont.middlingRegularSansSerif,
					NSParagraphStyleAttributeName: paragraphStyle
				]
			)
			self.attributedText = attributedString
		}
	}
}
