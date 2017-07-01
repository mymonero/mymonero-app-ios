//
//  EditContactFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/30/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class EditContactFormViewController: ContactFormViewController
{
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("Edit Contact", comment: "")
	}
}
