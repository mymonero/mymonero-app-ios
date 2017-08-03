//
//  MMApplication.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/2/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class MMApplication: UIApplication
{
	//
	// Constants
	enum NotificationNames: String
	{
		case didSendEvent = "MMApplication.NotificationNames.didSendEvent"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	enum NotificationUserInfoKeys: String
	{
		case event = "MMApplication.NotificationUserInfoKeys.event"
		var key: String {
			return self.rawValue
		}
	}
	//
	// Imperatives - Overrides
	override func sendEvent(_ event: UIEvent)
	{
		super.sendEvent(event)
		//
		let userInfo: [String: Any] =
		[
			NotificationUserInfoKeys.event.key: event
		]
		DispatchQueue.main.async
		{ // certainly don't want to hold up sendEvent(_:)…
			NotificationCenter.default.post(
				name: NotificationNames.didSendEvent.notificationName,
				object: nil,
				userInfo: userInfo
			)
		}
	}
}
