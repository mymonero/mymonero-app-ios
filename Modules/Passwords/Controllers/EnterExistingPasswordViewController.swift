//
//  EnterExistingPasswordViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class EnterExistingPasswordViewController: PasswordEntryScreenViewController
{
	override func setup()
	{
		super.setup()
		//
		self.navigationItem.title = "Enter \(PasswordController.shared.passwordType.humanReadableString.capitalized)"
		self.navigationItem.leftBarButtonItem = self._new_leftBarButtonItem()
		self.navigationItem.rightBarButtonItem = self._new_rightBarButtonItem()
	}
	//
	// Accessors - Factories - Views
	func _new_leftBarButtonItem() -> MMNavigationBarButtonItem?
	{
		if self.isForChangingPassword != true {
			return nil
		}
		let item = MMNavigationBarButtonItem(
			type: .cancel,
			target: self,
			action: #selector(tapped_leftBarButtonItem)
		)
		return item
	}
	func _new_rightBarButtonItem() -> MMNavigationBarButtonItem?
	{
		let item = MMNavigationBarButtonItem(
			type: .save,
			target: self,
			action: #selector(tapped_rightBarButtonItem),
			title_orNilForDefault: NSLocalizedString("Next", comment: "")
		)
		NSLog("TODO: get actual pw input layer val here for toggling Next btn interactivity")
		let passwordInputValue: String? = "asdfasd"//self.passwordInputLayer.text
		item.isEnabled = passwordInputValue != nil && passwordInputValue != "" // need to enter PW first
		//
		return item
	}
	//
	// Delegation - Navigation bar buttons
	@objc
	func tapped_leftBarButtonItem()
	{
		
	}
	@objc
	func tapped_rightBarButtonItem()
	{
		
	}
}
