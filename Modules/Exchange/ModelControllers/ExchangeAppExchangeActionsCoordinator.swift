//
//  ExchangeAppAppExchangeController.swift
//  MyMonero
//
//  Created by Karl Buys on 2020/10/27.
//  Copyright © 2020 MyMonero. All rights reserved.
//
import UIKit
//
class ExchangeAppExchangeActionsController
{
	enum NotificationNames: String
	{
		case willTrigger_sendFundsFromWallet = "ExchangeAppExchangeActionsController.NotificationNames.willTrigger_sendFundsFromWallet"
		case didTrigger_sendFundsFromWallet = "ExchangeAppExchangeActionsController.NotificationNames.didTrigger_sendFundsFromWallet"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	enum NotificationUserInfoKeys: String
	{
		case wallet = "ExchangeAppExchangeActionsController.NotificationUserInfoKeys.wallet"
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

	static func Trigger_sendFunds(fromWallet wallet: Wallet) // We're getting info back from the wallet here
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
}
