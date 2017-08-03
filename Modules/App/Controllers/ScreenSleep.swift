//
//  ScreenSleep.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
struct ScreenSleep
{
	static func temporarilyDisable_screenSleep()
	{
		UIApplication.shared.isIdleTimerDisabled = true
	}
	static func reEnable_screenSleep()
	{
		UIApplication.shared.isIdleTimerDisabled = false
	}
}
