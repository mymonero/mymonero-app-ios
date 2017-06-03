//
//  PasswordEntryBaseView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class PasswordEntryScreenViewController: UIViewController
{
	var isForChangingPassword: Bool!
	//
	var userSubmittedNonZeroPassword_cb: ((_ password: PasswordController.Password) -> Void)?
	var cancelButtonPressed_cb: ((Void) -> Void)?
	//
	init(isForChangingPassword: Bool)
	{
		super.init(nibName: nil, bundle: nil)
		//
		self.isForChangingPassword = isForChangingPassword
		self.setup()
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
	}
}
