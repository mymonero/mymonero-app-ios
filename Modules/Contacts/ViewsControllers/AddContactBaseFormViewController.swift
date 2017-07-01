//
//  AddContactBaseFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/29/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class AddContactBaseFormViewController: ContactFormViewController
{
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("New Contact", comment: "")
	}
}
