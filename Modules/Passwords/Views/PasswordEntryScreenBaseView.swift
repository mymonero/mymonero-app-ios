//
//  PasswordEntryScreenBaseView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class PasswordEntryScreenBaseView: UIView, UITextFieldDelegate
{
	var textFieldEventDelegate: PasswordEntryTextFieldEventDelegate!
	//
	init()
	{
		super.init(frame: .zero)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.backgroundColor = UIColor.contentBackgroundColor
	}
	//
	// Imperatives - Overridable - Validation error message
	func setValidationMessage(_ message: String)
	{
		assert(false, "Override this")
	}
	func clearValidationMessage()
	{
		assert(false, "Override this")
	}
	//
	// Imperatives - Overridable - Interactivity
	
	//
	// Imperatives
	func disable()
	{
		assert(false, "Override this")
	}
	func reEnable()
	{
		assert(false, "Override this")
	}
}
