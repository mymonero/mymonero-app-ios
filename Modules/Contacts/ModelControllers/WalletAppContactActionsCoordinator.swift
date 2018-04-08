//
//  WalletAppContactActionsCoordinator.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/2/17.
//  Copyright (c) 2014-2018, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
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
		case contact = "WalletAppWalletActionsCoordinator.NotificationUserInfoKeys.contact"
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
