//
//  URLOpening.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/28/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

struct URLOpening
{
	//
	// Constants
	enum NotificationNames: String
	{
		case receivedMoneroURL = "URLOpening.NotificationNames.receivedMoneroURL"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	enum NotificationUserInfoKeys: String
	{
		case url = "URLOpening.NotificationUserInfoKeys.url"
		//
		var key: String {
			return self.rawValue
		}
	}
	//
	// Delegation
	static func appReceived(url: URL) -> Bool // false if was not accepted
	{
		guard let scheme = url.scheme else {
			return false
		}
		if scheme != MoneroConstants.currency_requestURIPrefix_sansColon {
			return false
		}		
		DispatchQueue.main.async
		{
			let userInfo: [String: Any] =
			[
				NotificationUserInfoKeys.url.key: url
			]
			NotificationCenter.default.post(
				name: NotificationNames.receivedMoneroURL.notificationName,
				object: nil,
				userInfo: userInfo
			)
		}
		return true
	}
}

