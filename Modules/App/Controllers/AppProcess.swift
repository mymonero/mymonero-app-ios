//
//  AppProcess.swift
//  MyMonero
//
//  Created by Paul Shapiro on 10/3/17.
//  Copyright © 2019 MyMonero. All rights reserved.
//
//
import Foundation
//
struct AppProcess
{
	//
	// Constants
	enum EnvironmentKeys: String
	{
		case isBeingRunByUIAutomation = "IsBeingRunByUIAutomation"
		var key: String {
			return self.rawValue
		}
	}
	enum EnvironmentKeyValues: String
	{
		case isBeingRunByUIAutomation_enabled = "true"
		var value: String {
			return self.rawValue
		}
	}
	//
	// Accessors
	static var isBeingRunByUIAutomation: Bool {
		let environment = ProcessInfo.processInfo.environment
		let isEnabled = environment[EnvironmentKeys.isBeingRunByUIAutomation.key] == EnvironmentKeyValues.isBeingRunByUIAutomation_enabled.value
		//
		return isEnabled
	}
}
