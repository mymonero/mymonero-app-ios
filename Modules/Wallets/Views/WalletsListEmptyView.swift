//
//  WalletsListEmptyView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/13/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class WalletsListEmptyView: UIView
{
	var emptyStateView: UICommonComponents.EmptyStateView!
	var useExisting_actionButtonView: UICommonComponents.ActionButton!
	var createNew_actionButtonView: UICommonComponents.ActionButton!
	var useExisting_tapped_fn: (Void) -> Void
	var createNew_tapped_fn: (Void) -> Void
	//
	init(
		useExisting_tapped_fn: @escaping (Void) -> Void,
		createNew_tapped_fn: @escaping (Void) -> Void
	)
	{
		self.useExisting_tapped_fn = useExisting_tapped_fn
		self.createNew_tapped_fn = createNew_tapped_fn
		//
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
				emoji: "😃",
				message: NSLocalizedString("Welcome to MyMonero!\nLet's get started.", comment: "")
			)
			self.emptyStateView = view
			self.addSubview(view)
		}
		do {
			let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: true)
			view.addTarget(self, action: #selector(useExisting_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Use existing wallet", comment: ""), for: .normal)
			self.useExisting_actionButtonView = view
			self.addSubview(view)
		}
		do {
			let view = UICommonComponents.ActionButton(pushButtonType: .action, isLeftOfTwoButtons: false)
			view.addTarget(self, action: #selector(createNew_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Create new wallet", comment: ""), for: .normal)
			self.createNew_actionButtonView = view
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
		self.emptyStateView.frame = CGRect(
			x: margin_h,
			y: emptyStateView_margin_top,
			width: self.frame.size.width - 2*margin_h,
			height: self.frame.size.height - emptyStateView_margin_top - UICommonComponents.ActionButton.wholeButtonsContainerHeight
			).integral
		let buttons_y = self.emptyStateView.frame.origin.y + self.emptyStateView.frame.size.height + UICommonComponents.ActionButton.topMargin
		self.useExisting_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
		self.createNew_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
	}
	//
	// Delegation - Interactions
	func useExisting_tapped()
	{
		self.useExisting_tapped_fn()
	}
	func createNew_tapped()
	{
		self.createNew_tapped_fn()
	}
}
