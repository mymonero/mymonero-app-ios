//
//  ForgotPasswordViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
		let margin_h = UICommonComponents.EmptyStateView.default__margin_h
		let emptyStateView_margin_top: CGFloat = 14
		self.emptyStateView.frame = CGRect(
			x: margin_h,
			y: emptyStateView_margin_top,
			width: self.view.frame.size.width - 2*margin_h,
			height: self.view.frame.size.height - emptyStateView_margin_top - UICommonComponents.ActionButton.wholeButtonsContainerHeight
		).integral
		let buttons_y = self.emptyStateView.frame.origin.y + self.emptyStateView.frame.size.height + UICommonComponents.ActionButton.topMargin
		self.nevermind_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
		self.deleteEverything_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
	}
	//
	// Delegation - Interactions
	func nevermind_tapped()
	{
		self.navigationController?.popViewController(animated: true)
	}
	func deleteEverything_tapped()
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
}
