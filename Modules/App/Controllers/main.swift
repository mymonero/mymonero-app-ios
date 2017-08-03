//
//  main.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/2/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import UIKit

UIApplicationMain(
	CommandLine.argc,
	UnsafeMutableRawPointer(CommandLine.unsafeArgv)
		.bindMemory(
			to: UnsafeMutablePointer<Int8>.self,
			capacity: Int(CommandLine.argc)),
	NSStringFromClass(MMApplication.self),
	NSStringFromClass(AppDelegate.self)
)
