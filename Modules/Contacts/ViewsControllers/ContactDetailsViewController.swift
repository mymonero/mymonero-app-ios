//
//  ContactDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class ContactDetailsViewController: UICommonComponents.DetailsViewController
{
	//
	// Constants/Types
	//
	// Properties
	var contact: Contact
	//
	// Imperatives - Init
	init(contact: Contact)
	{
		self.contact = contact
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	// Overrides
	override var overridable_wantsBackButton: Bool {
		return true
	}
}
