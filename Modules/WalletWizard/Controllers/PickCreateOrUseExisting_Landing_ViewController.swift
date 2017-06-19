//
//  PickCreateOrUseExisting_Landing_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class PickCreateOrUseExisting_Landing_ViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Lifecycle - Init
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = "Add Wallet"
	}
	//
	// Delegation - Internal - Overrides
	override func _viewControllerIsBeingPoppedFrom()
	{
		assert(false) // unexpected
	}
}
