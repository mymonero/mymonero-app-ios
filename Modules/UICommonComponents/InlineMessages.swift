//
//  InlineMessages.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/24/17.
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
	class InlineMessageView: UIView
	{
		//
		// Constants
		enum Mode
		{
			case withCloseButton
			case noCloseButton
		}
		//
		// Properties
		var mode: Mode
		let label = UILabel()
		var closeButton: UIButton?
		//
		var didHide: (() -> Void)! // this is so we can route self.closeButton tap directly to clearAndHide() internally
		//
		// Lifecycle - Init
		init(mode: Mode, didHide: (() -> Void)?)
		{
			self.mode = mode
			super.init(frame: .zero)
			self.didHide = didHide ?? {}
			self.setup()
		}
		convenience init(mode: Mode) // for .noCloseButton; TODO: improve by limiting to only that mode
		{
			self.init(mode: mode, didHide: nil)
		}
		required init?(coder aDecoder: NSCoder)
		{
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			do {
				self.isHidden = true // just start off hidden
				//
				self.backgroundColor = UIColor(
					red: 245.0/255.0,
					green: 230.0/255.0,
					blue: 126.0/255.0,
					alpha: 0.05
				)
				self.layer.borderColor = UIColor(
					red: 245.0/255.0,
					green: 230.0/255.0,
					blue: 126.0/255.0,
					alpha: 0.3
				).cgColor
				self.layer.borderWidth = 1.0/UIScreen.main.scale // hairline
				self.layer.cornerRadius = 3
			}
			do {
				let view = label
				view.font = .smallMediumSansSerif
				view.textColor = UIColor(rgb: 0xF5E67E)
				view.lineBreakMode = .byWordWrapping
				view.numberOfLines = 0
				self.addSubview(view)
			}
			if self.mode == .withCloseButton {
				let view = UIButton(type: .custom)
				self.closeButton = view
				view.setImage(UIImage(named: "inlineMessageDialog_closeBtn"), for: .normal)
				view.adjustsImageWhenHighlighted = true
				view.addTarget(self, action: #selector(closeButton_tapped), for: .touchUpInside)
				self.addSubview(view)
			}
		}
		//
		// Accessors
		//
		// Imperatives - Configuration
		// NOTE: This interface/API for config->layout->show->layout could possibly be improved/condensed slightly
		func set(text: String)
		{ // after this, be sure to call layOut(…) and then show()
			label.text = text
		}
		func set(mode: Mode)
		{ // NOTE: any caller of this should also re-call self.layOut(…)
			self.mode = mode
			if mode == .withCloseButton {
				if self.closeButton == nil {
					let view = UIButton(type: .custom)
					self.closeButton = view
					view.setImage(UIImage(named: "inlineMessageDialog_closeBtn"), for: .normal)
					view.adjustsImageWhenHighlighted = true
					view.addTarget(self, action: #selector(closeButton_tapped), for: .touchUpInside)
					self.addSubview(view)
				}
			} else {
				if let view = self.closeButton {
					view.removeFromSuperview()
					self.closeButton = nil
				}
			}
		}
		func show()
		{
			self.isHidden = false
		}
		func clearAndHide()
		{
			label.text = ""
			self.isHidden = true
			self.didHide()
		}
		//
		// NOTE: Doing this instead of sizeThatFits(:) b/c that was slightly annoying. This
		// may be improved slightly by going with sizeThatFits(:)
		static let padding = UIEdgeInsetsMake(7, 8, 8, 8)
		static let button_side: CGFloat = 29
		func layOut(atX x: CGFloat, y: CGFloat, width: CGFloat)
		{
			let label_w = width - InlineMessageView.padding.left - (self.closeButton != nil ? InlineMessageView.button_side : InlineMessageView.padding.right) // no need to subtract padding.right b/c button_side incorporates that
			label.frame = CGRect(x: 0, y: 0, width: label_w, height: 0)
			label.sizeToFit() // now that we have the width
			label.frame = CGRect(
				x: InlineMessageView.padding.left,
				y: InlineMessageView.padding.top,
				width: max(label.frame.size.width, label_w),
				height: label.frame.size.height
			)
			//
			if let view = closeButton {
				view.frame = CGRect(
					x: label.frame.origin.x + label.frame.size.width,
					y: 0,
					width: InlineMessageView.button_side,
					height: InlineMessageView.button_side
				)
			}
			//
			self.frame = CGRect(
				x: x,
				y: y,
				width: width,
				height: InlineMessageView.padding.top + label.frame.size.height + InlineMessageView.padding.bottom
			).integral // no split pixels
		}
		//
		// Delegation - Interactions
		@objc func closeButton_tapped()
		{
			self.clearAndHide() // will notify parent/consumer so it can re-lay-itself-out
		}
	}
}
