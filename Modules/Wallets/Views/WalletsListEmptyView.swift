//
//  WalletsListEmptyView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/13/17.
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
			view.accessibilityIdentifier = "button.useExistingWallet"
			self.useExisting_actionButtonView = view
			self.addSubview(view)
		}
		do {
			let view = UICommonComponents.ActionButton(pushButtonType: .action, isLeftOfTwoButtons: false)
			view.addTarget(self, action: #selector(createNew_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Create new wallet", comment: ""), for: .normal)
			view.accessibilityIdentifier = "button.createNewWallet"
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
