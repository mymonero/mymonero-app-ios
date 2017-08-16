//
//  WalletAppWalletActionsCoordinator.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
