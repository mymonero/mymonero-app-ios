//
//  ForgotPasswordViewController.swift
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

class ForgotPasswordViewController: UIViewController
{
	var emptyStateView: UICommonComponents.EmptyStateView!
	var nevermind_actionButtonView: UICommonComponents.ActionButton!
	var deleteEverything_actionButtonView: UICommonComponents.ActionButton!
	//
	init()
	{
		super.init(nibName: nil, bundle: nil)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.setup_views()
		self.setup_navigation()
	}
	func setup_views()
	{
		do {
			self.view.backgroundColor = UIColor.contentBackgroundColor
			self.automaticallyAdjustsScrollViewInsets = false // to fix apparent visual bug of vertical transit on nav push/pop
		}
		do {
			let view = UICommonComponents.EmptyStateView(
				emoji: "😳",
				message: NSLocalizedString("Password reset is not possible,\nas your data is encrypted and local.\n\nIf you can't remember it, you'll need\nto clear all data and re-import your\nwallets to continue.", comment: "")
			)
			self.emptyStateView = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: true)
			view.addTarget(self, action: #selector(nevermind_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Nevermind", comment: ""), for: .normal)
			self.nevermind_actionButtonView = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.ActionButton(pushButtonType: .destructive, isLeftOfTwoButtons: false)
			view.addTarget(self, action: #selector(deleteEverything_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Clear all data", comment: ""), for: .normal)
			self.deleteEverything_actionButtonView = view
			self.view.addSubview(view)
		}
	}
	func setup_navigation()
	{
		self.navigationItem.title = NSLocalizedString("Forgot \(PasswordController.shared.passwordType.capitalized_humanReadableString)?", comment: "")
		do {
			let item = UICommonComponents.NavigationBarButtonItem(
				type: .back,
				tapped_fn:
				{ [unowned self] in
					self.navigationController?.popViewController(animated: true)
				}
			)
			self.navigationItem.leftBarButtonItem = item
		}
	}
	//
	// Delegation - Overrides - Views
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let safeAreaInsets = self.view.polyfilled_safeAreaInsets
		let contentAreaFrame = UIEdgeInsetsInsetRect(self.view.bounds, safeAreaInsets)
		//
		let margin_h = UICommonComponents.EmptyStateView.default__margin_h
		let emptyStateView_margin_top: CGFloat = 14
		self.emptyStateView.frame = CGRect(
			x: contentAreaFrame.origin.x + margin_h,
			y: contentAreaFrame.origin.y + emptyStateView_margin_top,
			width: contentAreaFrame.size.width - 2 * margin_h,
			height: contentAreaFrame.size.height - emptyStateView_margin_top - UICommonComponents.ActionButton.wholeButtonsContainerHeight
		).integral
		let buttons_y = self.emptyStateView.frame.origin.y + self.emptyStateView.frame.size.height + UICommonComponents.ActionButton.topMargin
		self.nevermind_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
		self.deleteEverything_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
	}
	//
	// Delegation - Interactions
	@objc func nevermind_tapped()
	{
		self.navigationController?.popViewController(animated: true)
	}
	@objc func deleteEverything_tapped()
	{
		let alertController = UIAlertController(
			title: NSLocalizedString("Delete everything?", comment: ""),
			message: NSLocalizedString(
				"Are you sure you want to clear your locally stored data?\n\nAny wallets will remain permanently on the Monero blockchain. At present, local-only data like contacts would not be recoverable.",
				comment: ""
			),
			preferredStyle: .alert
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Delete Everything", comment: ""),
				style: .destructive
			)
			{ (result: UIAlertAction) -> Void in
				PasswordController.shared.initiateDeleteEverything()
			}
		)
		alertController.addAction(
			UIAlertAction(
				title: NSLocalizedString("Cancel", comment: ""),
				style: .default
			)
			{ (result: UIAlertAction) -> Void in
			}
		)
		self.navigationController!.present(alertController, animated: true, completion: nil)
	}
	//
	// Delegation - View lifecycle
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		ThemeController.shared.styleViewController_navigationBarTitleTextAttributes(
			viewController: self,
			titleTextColor: nil // default
		) // probably not necessary but probably a good idea here to support clearing potential red clr transactions details on popping to self
	}
}
