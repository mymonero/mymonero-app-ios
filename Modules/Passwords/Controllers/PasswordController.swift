//
//  PasswordController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/22/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
protocol DeleteEverythingRegistrant
{
//	func …()
}
//
class PasswordController
{
	// Types/Constants
	typealias Password = String
	enum PasswordType
	{
		case PIN
		case Password
	}
	//
	// Lifecycle - Init
	init() {
		
	}
	//
	// Lifecycle - Teardown
	deinit {
		
	}
	//
	// Accessors - Deferring execution convenience methods
	func OncePasswordObtained(_ fn: @escaping (_ password: Password, _ passwordType: PasswordType) -> Void)
	{
		NSLog("TODO: actually obtain pw from user")
		fn("dummy pw", .Password)
	}
	//
	// Imperatives - Delete Everything notification registration
	func AddRegistrantForDeleteEverything(
		_ observer: DeleteEverythingRegistrant
	) -> Void
	{
		NSLog("TODO: AddRegistrantForDeleteEverything")
	}
}
