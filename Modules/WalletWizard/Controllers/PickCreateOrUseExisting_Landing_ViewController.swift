//
//  PickCreateOrUseExisting_Landing_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class PickCreateOrUseExisting_Landing_ViewController: AddWalletWizardScreen_BaseViewController
{ // NOTE: this does not really need to be a FormViewController
	//
	// Properties - Views
	var emptyStateView: UICommonComponents.EmptyStateView!
	var useExisting_actionButtonView: UICommonComponents.ActionButton!
	var createNew_actionButtonView: UICommonComponents.ActionButton!
	//
	// Lifecycle - Init
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("Add Wallet", comment: "")
		self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .cancel,
			target: self,
			action: #selector(tapped_leftBarButtonItem)
		)
	}
	override func setup_views()
	{
		super.setup_views()
		do {
			let view = UICommonComponents.EmptyStateView(
				emoji: "🤔",
				message: NSLocalizedString("How would you like to\nadd a wallet?", comment: "")
			)
			self.emptyStateView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: true)
			view.addTarget(self, action: #selector(useExisting_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Use existing wallet", comment: ""), for: .normal)
			self.useExisting_actionButtonView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.ActionButton(pushButtonType: .action, isLeftOfTwoButtons: false)
			view.addTarget(self, action: #selector(createNew_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Create new wallet", comment: ""), for: .normal)
			self.createNew_actionButtonView = view
			self.scrollView.addSubview(view)
		}
	}
	//
	// Accessors - Overrides
	override func new_wantsInlineMessageViewForValidationMessages() -> Bool { return false }
	override func wantsRightSideNextBarButtonItem() -> Bool { return false }
	//
	// Delegation - Internal - Overrides
	override func _viewControllerIsBeingPoppedFrom()
	{
		assert(false) // unexpected
	}
	//
	// Imperatives - Overrides
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let margin_h = UICommonComponents.EmptyStateView.default__margin_h
		let emptyStateView_margin_top: CGFloat = 14
		self.emptyStateView.frame = CGRect(
			x: margin_h,
			y: emptyStateView_margin_top,
			width: self.scrollView.frame.size.width - 2*margin_h,
			height: self.scrollView.frame.size.height - emptyStateView_margin_top - UICommonComponents.ActionButton.wholeButtonsContainerHeight
		).integral
		let buttons_y = self.emptyStateView.frame.origin.y + self.emptyStateView.frame.size.height + UICommonComponents.ActionButton.topMargin
		self.useExisting_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
		self.createNew_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: margin_h)
	}
	//
	// Delegation - Actions Buttons - Interactions
	func useExisting_tapped()
	{
		self.wizardController.patchToDifferentWizardTaskMode_byPushingScreen(
			patchTo_wizardTaskMode: AddWallet_WizardController.TaskMode.afterPick_useExisting,
			atIndex: 1 // first screen after 0 - maintain ability to hit 'back'
		)
	}
	func createNew_tapped()
	{
		self.wizardController.patchToDifferentWizardTaskMode_byPushingScreen(
			patchTo_wizardTaskMode: AddWallet_WizardController.TaskMode.afterPick_createWallet,
			atIndex: 1 // first screen after 0 - maintain ability to hit 'back'
		)
	}
	//
	// Delegation - Navigation Bar - Interactions
	func tapped_leftBarButtonItem()
	{
		self.wizardController._fromScreen_userPickedCancel()
	}
}
