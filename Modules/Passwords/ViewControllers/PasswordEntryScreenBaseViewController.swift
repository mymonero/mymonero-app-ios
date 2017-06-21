//
//  PasswordEntryBaseView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
class PasswordEntryScreenBaseViewController: UICommonComponents.FormViewController
{
	var isForChangingPassword: Bool!
	//
	// Consumers: set these after init
	var userSubmittedNonZeroPassword_cb: ((_ password: PasswordController.Password) -> Void)!
	var cancelButtonPressed_cb: ((Void) -> Void)!
	//
	init(isForChangingPassword: Bool)
	{
		self.isForChangingPassword = isForChangingPassword
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
