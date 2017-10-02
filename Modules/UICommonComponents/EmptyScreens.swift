//
//  EmptyScreens.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright (c) 2014-2017, MyMonero.com
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
				view.layer.borderColor = UICommonComponents.Details.FieldSeparatorView.Mode.contentBackgroundAccent.color.cgColor
				view.layer.borderWidth = UICommonComponents.Details.FieldSeparatorView.h
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
                    NSAttributedStringKey.paragraphStyle,
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
