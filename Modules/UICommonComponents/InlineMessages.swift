//
//  InlineMessages.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/24/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
extension UICommonComponents
{
	class InlineMessageView: UIView
	{
		//
		// Properties
		let label = UILabel()
		let closeButton = UIButton(type: .custom)
		//
		var didHide: ((Void) -> Void)! // this is so we can route self.closeButton tap directly to clearAndHide() internally
		//
		// Lifecycle - Init
		init(didHide: @escaping ((Void) -> Void))
		{
			super.init(frame: .zero)
			self.didHide = didHide
			self.setup()
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
			do {
				let view = closeButton
				view.setImage(UIImage(named: "inlineMessageDialog_closeBtn"), for: .normal)
				view.adjustsImageWhenHighlighted = true
				view.addTarget(self, action: #selector(closeButton_tapped), for: .touchUpInside)
				self.addSubview(view)
			}
		}
		//
		// Accessors
		var shouldPerformLayOut: Bool {
			return self.isHidden == false // i.e. lay out if showing
		}
		//
		// Imperatives - Configuration
		// NOTE: This interface/API for config->layout->show->layout could possibly be improved/condensed slightly
		func set(text: String)
		{ // after this, be sure to call layOut(…) and then show()
			label.text = text
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
			let label_w = width - InlineMessageView.padding.left - InlineMessageView.button_side // no need to subtract padding.right b/c button_side incorporates that
			label.frame = CGRect(x: 0, y: 0, width: label_w, height: 0)
			label.sizeToFit() // now that we have the width
			label.frame = CGRect(
				x: InlineMessageView.padding.left,
				y: InlineMessageView.padding.top,
				width: max(label.frame.size.width, label_w),
				height: label.frame.size.height
			)
			//
			closeButton.frame = CGRect(
				x: label.frame.origin.x + label.frame.size.width,
				y: 0,
				width: InlineMessageView.button_side,
				height: InlineMessageView.button_side
			)
			//
			self.frame = CGRect(
				x: x,
				y: y,
				width: width,
				height: InlineMessageView.padding.top + label.frame.size.height + InlineMessageView.padding.bottom
			)
		}
		//
		// Delegation - Interactions
		func closeButton_tapped()
		{
			self.clearAndHide() // will notify parent/consumer so it can re-lay-itself-out
		}
	}
}
