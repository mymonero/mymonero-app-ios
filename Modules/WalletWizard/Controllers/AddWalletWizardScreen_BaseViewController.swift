//
//  AddWalletWizardScreen_BaseViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class AddWalletWizardScreen_BaseViewController: UICommonComponents.FormViewController
{
	//
	// Properties
	var wizardController: AddWallet_WizardController
	//
	// Lifecycle - Init
	required init(wizardController: AddWallet_WizardController)
	{
		self.wizardController = wizardController
		super.init()
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		if self.wantsRightSideNextBarButtonItem() {
			let item = UICommonComponents.NavigationBarButtonItem(
				type: .save,
				target: self,
				action: #selector(tapped_nextBarButtonItem),
				title_orNilForDefault: self.new_titleForNavigationBarButtonItem__next()
			)
			self.navigationItem.rightBarButtonItem = item
		}
	}
	//
	// Accessors - Overridable
	func new_titleForNavigationBarButtonItem__next() -> String
	{
		return NSLocalizedString("Next", comment: "")
	}
	func wantsRightSideNextBarButtonItem() -> Bool { return true }
	//
	// Delegation - View lifecycle
	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)
		if self.isMovingFromParentViewController {
			self._viewControllerIsBeingPoppedFrom()
		}
	}
	func _viewControllerIsBeingPoppedFrom()
	{ // overridable - and is overriden to set state back to what it should be per VC
	}
	//
	// Delegation - Interactions
	func tapped_nextBarButtonItem()
	{
		self.aFormSubmissionButtonWasPressed() 
	}
}
