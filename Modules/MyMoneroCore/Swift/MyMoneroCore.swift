//
//  MyMoneroCore.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import UIKit // because we use a WKWebView
import SwiftDate
//
// Accessory types
typealias MoneroSeed = String
typealias MoneroSeedAsMnemonic = String
typealias MoneroAddress = String
typealias MoneroPaymentID = String
typealias MoneroTransactionHash = String
typealias MoneroKey = String
typealias MoneroKeyImage = String
struct MoneroDecodedAddress
{
	var publicKeys: MoneroKeyDuo
	var intPaymentId: MoneroPaymentID? // would be encrypted, i.e. an integrated address
}
struct MoneroKeyDuo
{
	var view: MoneroKey
	var spend: MoneroKey
}
struct MoneroWalletDescription
{
	var mnemonic: MoneroSeedAsMnemonic
	var seed: MoneroSeed
	var publicAddress: MoneroAddress
	var publicKeys: MoneroKeyDuo
	var privateKeys: MoneroKeyDuo
}
struct MoneroVerifiedComponentsForLogIn
{
	var seed: MoneroSeed
	var publicAddress: MoneroAddress
	var publicKeys: MoneroKeyDuo
	var privateKeys: MoneroKeyDuo
	var isInViewOnlyMode: Bool
}
enum MoneroMnemonicWordsetName: String
{
	case English = "english"
	case Japanese = "japanese"
	case Spanish = "spanish"
	case Portuguese = "portuguese"
}
//
// Constants
struct MoneroConstants
{
	static let currency_name = "Monero"
	static let currency_symbol = "XMR"
	static let currency_requestURIPrefix = "monero:"
	static let currency_requestURIPrefix_sansColon = "monero"
	static let currency_openAliasPrefix = "xmr" // OpenAlias prefix
	//
	static let addressPrefix = 18 // Prefix code for addresses; 18 => addresses start with "4"
	static let integratedAddressPrefix = 19 // Prefix code for addresses
	//
	static let currency_unitPlaces = 12 // Number of atomic units in one unit of currency. e.g. 12 => 10^12 = 
	
	static let txMinConfirms = 10 // Minimum number of confirmations for a transaction to show as confirmed
	static let maxBlockNumber = 500000000 // Maximum block number, used for tx unlock time
	static let avgBlockTime = 60 // Average block time in seconds, used for unlock time estimation
	//
	static let feePerKB = MoneroAmount("2000000000")! // 0.002 XMR; Network per kb fee in atomic units
	static let dustThreshold = MoneroAmount("10000000000")! // Dust threshold in atomic units; 10^10 used for choosing outputs/change - we decompose all the way down if the receiver wants now regardless of threshold
}
//
// Namespaces
struct MyMoneroCoreUtils {}
//
// Principal type
class MyMoneroCore : MyMoneroCoreJS
// TODO? alternative to subclassing MyMoneroCoreJS would be to hold an instance of it and provide proxy fns as interface.
// 
{
	override init(window: UIWindow)
	{
		super.init(window: window)
	}
}
