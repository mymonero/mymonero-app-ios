//
//  CreateWallet_Instructions_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class CreateWallet_Instructions_ViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Lifecycle - Init
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = "New Wallet"
	}
	//
	// Delegation - Internal - Overrides
	override func _viewControllerIsBeingPoppedFrom()
	{ // must maintain correct state if popped
		self.wizardController.patchToDifferentWizardTaskMode_withoutPushingScreen(
			patchTo_wizardTaskMode: self.wizardController.current_wizardTaskMode,
			atIndex: self.wizardController.current_wizardTaskMode_stepIdx - 1
		)		
	}
}
