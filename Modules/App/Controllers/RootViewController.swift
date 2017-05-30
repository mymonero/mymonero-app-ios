//
//  RootViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, PasswordEntryDelegate /* just for now */
{
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
	{
		fatalError("\(#function) has not been implemented")
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("\(#function) has not been implemented")
	}
	init()
	{
		super.init(nibName: nil, bundle: nil)
		
		
		// DUMMY PW interactions
		
		NSLog("dummy pw")
		
		let passwordController = PasswordController.shared
		passwordController.passwordEntryDelegate = self
		
	}	
    override func viewDidLoad()
	{
        super.viewDidLoad()
    }
	
	
	func getUserToEnterExistingPassword(
		isForChangePassword: Bool,
		_ fn: @escaping (Bool?, PasswordController.Password?) -> Void
	)
	{
		fn(false, "dummy password")
	}
	func getUserToEnterNewPasswordAndType(
		isForChangePassword: Bool,
		_ fn: @escaping (Bool?, PasswordController.Password?, PasswordController.PasswordType?) -> Void
	)
	{
		fn(false, "dummy password", .password)
	}
}

