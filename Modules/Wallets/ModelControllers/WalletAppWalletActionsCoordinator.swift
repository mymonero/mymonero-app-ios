//
//  WalletAppWalletActionsCoordinator.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/15/17.
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
import UIKit
//
class WalletAppWalletActionsCoordinator
{
	enum NotificationNames: String
	{
		case willTrigger_sendFundsFromWallet = "WalletAppWalletActionsCoordinator.NotificationNames.willTrigger_sendFundsFromWallet"
		case didTrigger_sendFundsFromWallet = "WalletAppWalletActionsCoordinator.NotificationNames.didTrigger_sendFundsFromWallet"
		//
		case willTrigger_receiveFundsToWallet = "WalletAppWalletActionsCoordinator.NotificationNames.willTrigger_receiveFundsToWallet"
		case didTrigger_receiveFundsToWallet = "WalletAppWalletActionsCoordinator.NotificationNames.didTrigger_receiveFundsToWallet"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	enum NotificationUserInfoKeys: String
	{
		case wallet = "WalletAppWalletActionsCoordinator.NotificationUserInfoKeys.wallet"
		//
		var key: String {
			return self.rawValue
		}
	}
	//
	// Accessors
	fileprivate static func common__notification_userInfo(
		withWallet wallet: Wallet
	) -> [String: Any]
	{
		return [
			NotificationUserInfoKeys.wallet.key: wallet
		]
	}
	//
	// Imperatives - Interface
	static func Trigger_sendFunds(fromWallet wallet: Wallet)
	{
		let common_userInfo = self.common__notification_userInfo(withWallet: wallet)
		NotificationCenter.default.post(
			name: NotificationNames.willTrigger_sendFundsFromWallet.notificationName,
			object: nil,
			userInfo: common_userInfo
		)
		//
		NotificationCenter.default.post(
			name: NotificationNames.didTrigger_sendFundsFromWallet.notificationName,
			object: nil,
			userInfo: common_userInfo
		)
	}
	static func Trigger_receiveFunds(toWallet wallet: Wallet)
	{
		let common_userInfo = self.common__notification_userInfo(withWallet: wallet)
		NotificationCenter.default.post(
			name: NotificationNames.willTrigger_receiveFundsToWallet.notificationName,
			object: nil,
			userInfo: common_userInfo
		)
		//
		NotificationCenter.default.post(
			name: NotificationNames.didTrigger_receiveFundsToWallet.notificationName,
			object: nil,
			userInfo: common_userInfo
		)
	}
}
