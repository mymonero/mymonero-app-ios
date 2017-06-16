//
//  ContactsListEmptyView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class ContactsListEmptyView: UIView
{
	var emptyStateView: UICommonComponents.EmptyStateView!
	//
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
		do {
			let view = UICommonComponents.EmptyStateView(
				emoji: "😬",
				message: NSLocalizedString("You haven't created any\ncontacts yet.", comment: "")
			)
			self.emptyStateView = view
			self.addSubview(view)
		}
	}
	//
	// Imperatives - Overrides
	override func layoutSubviews()
	{
		super.layoutSubviews()
		//
		let margin_h = UICommonComponents.EmptyStateView.default__margin_h
		let emptyStateView_margin_top: CGFloat = 0
		let emptyStateView_margin_bottom: CGFloat = 16
		self.emptyStateView.frame = CGRect(
			x: margin_h,
			y: emptyStateView_margin_top,
			width: self.frame.size.width - 2*margin_h,
			height: self.frame.size.height - emptyStateView_margin_top - emptyStateView_margin_bottom
		).integral
	}
}
