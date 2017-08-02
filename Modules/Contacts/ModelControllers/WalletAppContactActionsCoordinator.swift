//
//  WalletAppContactActionsCoordinator.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/2/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class WalletAppContactActionsCoordinator
{
	enum NotificationNames: String
	{
		case willTrigger_requestFundsFromContact = "WalletAppCoordinator.NotificationNames.willTrigger_requestFundsFromContact"
		case didTrigger_requestFundsFromContact = "WalletAppCoordinator.NotificationNames.didTrigger_requestFundsFromContact"
		//
		case willTrigger_sendFundsToContact = "WalletAppCoordinator.NotificationNames.willTrigger_sendFundsToContact"
		case didTrigger_sendFundsToContact = "WalletAppCoordinator.NotificationNames.didTrigger_sendFundsToContact"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	enum NotificationUserInfoKeys: String
	{
		case contact = "WalletAppCoordinator.NotificationUserInfoKeys.contact"
		//
		var key: String {
			return self.rawValue
		}
	}
	//
	// Accessors
	fileprivate static func common__notification_userInfo(
		withContact contact: Contact
	) -> [String: Any]
	{
		return [
			NotificationUserInfoKeys.contact.key: contact
		]
	}
	//
	// Imperatives - Interface
	static func Trigger_requestFunds(fromContact contact: Contact)
	{
		let common_userInfo = self.common__notification_userInfo(withContact: contact)
		NotificationCenter.default.post(
			name: NotificationNames.willTrigger_requestFundsFromContact.notificationName,
			object: nil,
			userInfo: common_userInfo
		)
		//
		NotificationCenter.default.post(
			name: NotificationNames.didTrigger_requestFundsFromContact.notificationName,
			object: nil,
			userInfo: common_userInfo
		)
	}
	static func Trigger_sendFunds(toContact contact: Contact)
	{
		let common_userInfo = self.common__notification_userInfo(withContact: contact)
		NotificationCenter.default.post(
			name: NotificationNames.willTrigger_sendFundsToContact.notificationName,
			object: nil,
			userInfo: common_userInfo
		)
		//
		NotificationCenter.default.post(
			name: NotificationNames.didTrigger_sendFundsToContact.notificationName,
			object: nil,
			userInfo: common_userInfo
		)
	}
}
