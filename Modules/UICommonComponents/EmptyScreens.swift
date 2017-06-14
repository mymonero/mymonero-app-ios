//
//  EmptyScreens.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UICommonComponents
{
	class EmptyStateView: UIView
	{
		static var default__margin_h: CGFloat = 16
		static var default__margin_v: CGFloat = 18
		//
		var emoji: String!
		var message: String!
		let emojiLabel = UILabel()
		let messageLabel = UILabel()
		init(emoji: String, message: String)
		{
			super.init(frame: .zero)
			self.emoji = emoji
			self.message = message
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		//
		func setup()
		{
			do {
				let view = self
				view.layer.borderColor = UIColor(rgb: 0x373537).cgColor
				view.layer.borderWidth = CGFloat(1)/UIScreen.main.scale // hairline
				view.layer.cornerRadius = 5
			}
			do {
				let view = self.emojiLabel
				view.font = UIFont.middlingRegularSansSerif
				view.textAlignment = .center
				self.addSubview(view)
			}
			do {
				let view = self.messageLabel
				view.numberOfLines = 0
				view.font = UIFont.middlingRegularSansSerif
				view.textColor = UIColor.contentTextColor
				view.textAlignment = .center
				self.addSubview(view)
			}
			self._configureWithContent()
		}
		//
		func set(emoji: String, message: String)
		{
			self.emoji = emoji
			self.message = message
			self._configureWithContent()
		}
		private func _configureWithContent()
		{
			self.emojiLabel.text = emoji
			//
			var attributedString: NSMutableAttributedString!
			do {
				let string = self.message!
				let range = NSRange(location: 0, length: string.characters.count)
				attributedString = NSMutableAttributedString(string: string)
				let paragraphStyle = NSMutableParagraphStyle()
				paragraphStyle.lineSpacing = 4
				paragraphStyle.alignment = .center
				attributedString.addAttribute(
					NSParagraphStyleAttributeName,
					value: paragraphStyle,
					range: range
				)
			}
			self.messageLabel.attributedText = attributedString
			//
			self.emojiLabel.sizeToFit()
			self.messageLabel.sizeToFit()
			self.setNeedsLayout()
		}
		//
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			let emojiLabel_margin_bottom: CGFloat = 22
			let contentBlock_totalHeight = self.emojiLabel.frame.size.height + emojiLabel_margin_bottom + self.messageLabel.frame.size.height
			let contentBlock_y = (self.frame.size.height - contentBlock_totalHeight)/2
			// presumes that labels have been sized-to-fit
			self.emojiLabel.frame = CGRect(
				x: 0,
				y: contentBlock_y,
				width: self.frame.size.width,
				height: self.emojiLabel.frame.size.height
			).integral
			self.messageLabel.frame = CGRect(
				x: 0,
				y: self.emojiLabel.frame.origin.y + self.emojiLabel.frame.size.height + emojiLabel_margin_bottom,
				width: self.frame.size.width,
				height: self.messageLabel.frame.size.height
			).integral
		}
	}
}
