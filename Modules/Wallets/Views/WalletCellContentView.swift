//
//  WalletCellContentView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
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

class WalletCellContentView: UIView
{
	var sizeClass: UICommonComponents.WalletIconView.SizeClass
	var wantsNoSecondaryBalances: Bool
	var wantsOnlySpendableBalance: Bool
	//
	var iconView: UICommonComponents.WalletIconView!
	var titleLabel: UILabel!
	var subtitleLabel: UILabel!
	//
	// Lifecycle - Init
	init(
		sizeClass: UICommonComponents.WalletIconView.SizeClass,
		wantsNoSecondaryBalances: Bool,
		wantsOnlySpendableBalance: Bool
	) {
		self.sizeClass = sizeClass
		self.wantsNoSecondaryBalances = wantsNoSecondaryBalances
		self.wantsOnlySpendableBalance = wantsOnlySpendableBalance
		//
		super.init(frame: .zero)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		do {
			let view = UICommonComponents.WalletIconView(sizeClass: self.sizeClass)
			self.addSubview(view)
			self.iconView = view
		}
		do {
			let view = UILabel()
			view.textColor = UIColor(rgb: 0xFCFBFC)
			view.font = UIFont.middlingSemiboldSansSerif
			view.numberOfLines = 1
			self.addSubview(view)
			self.titleLabel =  view
		}
		do {
			let view = UILabel()
			view.textColor = UIColor(rgb: 0x9E9C9E)
			view.font = UIFont.shouldStepDownLargerFontSizes ? UIFont.subMiddlingRegularMonospace : UIFont.middlingRegularMonospace // subMiddling seems too small visually and is an interrim solution given balances with all decimal places
			view.numberOfLines = 0
			view.minimumScaleFactor = 0.7
			view.adjustsFontSizeToFitWidth = true
			self.addSubview(view)
			self.subtitleLabel =  view
		}
	}
	//
	// Lifecycle - Teardown/Reuse
	deinit
	{
		self.tearDown_object()
	}
	func tearDown_object()
	{
		if self.object != nil { // TODO: there's some kind of bug seen here. self.object is nil when it still needs to have self removed as an observer
			self._stopObserving_object()
			self.object = nil
		}
	}
	func prepareForReuse()
	{
		self.tearDown_object()
	}
	func _stopObserving_object()
	{
		assert(self.object != nil)
		self.__stopObserving(specificObject: self.object!)
	}
	func _stopObserving(objectBeingDeinitialized object: Wallet)
	{
		assert(self.object == nil) // special case - since it's a weak ref I expect self.object to actually be nil
		assert(self.hasStoppedObservingObject_forLastNonNilSetOfObject != true) // initial expectation at least - this might be able to be deleted
		//
		self.__stopObserving(specificObject: object)
	}
	func __stopObserving(specificObject object: Wallet)
	{
		if self.hasStoppedObservingObject_forLastNonNilSetOfObject == true {
			// then we've already handled this
			DDLog.Warn("WalletCellContentView", "Not redundantly calling stopObserving")
			return
		}
		self.hasStoppedObservingObject_forLastNonNilSetOfObject = true // must set to true so we can set back to false when object is set back to non-nil
		//
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.booted.notificationName, object: object)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.failedToBoot.notificationName, object: object)
		//
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: object)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: object)
		//
		NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.labelChanged.notificationName, object: object)
		NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.balanceChanged.notificationName, object: object)
		NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.swatchColorChanged.notificationName, object: object)
		//
		NotificationCenter.default.removeObserver(
			self,
			name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
			object: nil
		)
		NotificationCenter.default.removeObserver(
			self,
			name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
			object: nil
		)
	}
	//
	// Accessors
	var iconView_x: CGFloat
	{
		switch self.sizeClass {
			case .large48, .large43:
				return 16
			case .medium32:
				return 15
		}
	}
	var labels_x: CGFloat
	{
		switch self.sizeClass {
			case .large48:
				return 80
			case .large43:
				return 75
			case .medium32:
				return 66
		}
	}
	var titleLabels_y: CGFloat
	{
		switch self.sizeClass {
			case .large48:
				return 23
			case .large43:
				return 22
			case .medium32:
				return 15
		}
	}
	var __primaryBalanceLabelText: String {
		var amount: MoneroAmount
		if self.wantsOnlySpendableBalance {
			amount = self.object!.unlockedBalance
		} else {
			amount = self.object!.balanceAmount
		}
		let components = CcyConversionRates.Currency.amountConverted_displayStringComponents(
			from: amount,
			ccy: SettingsController.shared.displayCurrency,
			chopNPlaces: 3
		)
		var str: String
		if self.wantsOnlySpendableBalance && self.object!.hasLockedFunds {
			str = String(
				format: NSLocalizedString("%@ %@ unlocked", comment: "{amount} {currency symbol} unlocked"),
				components.formattedAmount,
				components.final_ccy.symbol
			)
		} else {
			str = String(
				format: NSLocalizedString("%@ %@", comment: "{amount} {currency symbol}"),
				components.formattedAmount,
				components.final_ccy.symbol
			)
		}
		return str
	}
	//
	// Imperatives - Configuration
	weak var object: Wallet? // weak to prevent self from preventing .willBeDeinitialized from being received
	var hasStoppedObservingObject_forLastNonNilSetOfObject = true // I'm using this addtl state var which is not weak b/c object will be niled purely by virtue of it being freed by strong reference holders (other objects)… and I still need to call stopObserving on that object - while also not doing so redundantly - therefore this variable must be set back to false after self.object is set back to non-nil or possibly more rigorously, in startObserving
	func configure(withObject object: Wallet)
	{
		if self.object != nil {
			self.prepareForReuse() // in case this is not being used in an actual UITableViewCell (which has a prepareForReuse)
		}
		assert(self.object == nil)
		self.object = object
		self._configureUIWithWallet()
		self.startObserving_object()
	}
	func _configureUIWithWallet()
	{
		assert(self.object != nil)
		self.__configureUIWithWallet_labels()
		self.__configureUIWithWallet_swatchColor()
	}
	func __configureUIWithWallet_labels()
	{
		if self.object == nil {
			// did stopObserving not get called on idle teardown? this is being entered by _wallet_booted upon pw re-entry
			return // just going to avoid the crash for now
		}
		assert(self.object != nil)
		self.titleLabel.text = self.object!.walletLabel
		if self.object!.isLoggingIn {
			self.subtitleLabel.text = "Logging in…"
			return
		}
		if self.object!.didFailToInitialize_flag == true { // unlikely but possible
			self.subtitleLabel.text = "Load error"
			return
		}
		if self.object!.didFailToBoot_flag == true { // possible when server incorrect
			self.subtitleLabel.text = "Login error"
			return
		}
		var subtitleLabel_text: String?
		do {
			if self.object!.hasEverFetched_accountInfo == false {
				subtitleLabel_text = "Loading…"
			} else if self.wantsNoSecondaryBalances {
				subtitleLabel_text = self.__primaryBalanceLabelText
			} else {
				subtitleLabel_text = ""
				//
				let pendingAmount = self.object!.new_pendingBalanceAmount
				let lockedBalanceAmount = self.object!.lockedBalanceAmount
				if pendingAmount > 0 {
					let components = CcyConversionRates.Currency.amountConverted_displayStringComponents(
						from: pendingAmount,
						ccy: SettingsController.shared.displayCurrency,
						chopNPlaces: 3
					)
					subtitleLabel_text! += String(
						format: NSLocalizedString(
							"%@ %@ pending",
							comment: "{amount} {currency symbol} pending"
						),
						components.formattedAmount,
						components.final_ccy.symbol
					)
				}
				if lockedBalanceAmount > 0 {
					let components = CcyConversionRates.Currency.amountConverted_displayStringComponents(
						from: lockedBalanceAmount,
						ccy: SettingsController.shared.displayCurrency,
						chopNPlaces: 3
					)
					subtitleLabel_text! += String(
						format: NSLocalizedString(
							"%@%@ %@ locked",
							comment: "{' or ;'}{amount} {currency symbol}"
						),
						subtitleLabel_text != "" ? "; " : "",
						components.formattedAmount,
						components.final_ccy.symbol
					)
				}
				if subtitleLabel_text == "" {
					subtitleLabel_text = self.__primaryBalanceLabelText
				}
			}
		}
		assert(subtitleLabel_text != nil)
		self.subtitleLabel.text = subtitleLabel_text
		//
		self.setNeedsLayout()
	}
	func __configureUIWithWallet_swatchColor()
	{
		self.iconView.configure(withSwatchColor: self.object!.swatchColor)
	}
	func clearFields()
	{
		self.iconView.configure(withSwatchColor: .blue)
		self.titleLabel.text = ""
		self.subtitleLabel.text = ""
	}
	//
	func startObserving_object()
	{
		assert(self.object != nil)
		assert(self.hasStoppedObservingObject_forLastNonNilSetOfObject == true) // verify that it was reset back to false
		self.hasStoppedObservingObject_forLastNonNilSetOfObject = false // set to false so we make sure to stopObserving
		NotificationCenter.default.addObserver(self, selector: #selector(_wallet_booted), name: PersistableObject.NotificationNames.booted.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_wallet_failedToLogIn), name: PersistableObject.NotificationNames.failedToBoot.notificationName, object: self.object!)
		//
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeinitialized(_:)), name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
		//
		NotificationCenter.default.addObserver(self, selector: #selector(_labelChanged), name: Wallet.NotificationNames.labelChanged.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_balanceChanged), name: Wallet.NotificationNames.balanceChanged.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_swatchColorChanged), name: Wallet.NotificationNames.swatchColorChanged.notificationName, object: self.object!)
		//
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(CcyConversionRates_didUpdateAvailabilityOfRates),
			name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(SettingsController__NotificationNames_Changed__displayCurrencySymbol),
			name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
			object: nil
		)
	}
	//
	// Imperatives - Overrides
	override func layoutSubviews()
	{
		super.layoutSubviews()
		self.iconView.frame = CGRect(
			x: self.iconView_x,
			y: 16,
			width: self.iconView.frame.size.width,
			height: self.iconView.frame.size.height
		)
		let labels_x = self.labels_x
		let labels_rightMargin: CGFloat = 24
		let titleLabel_h: CGFloat = 16
		let labels_width = self.frame.size.width - labels_x - labels_rightMargin
		self.titleLabel.frame = CGRect(
			x: labels_x,
			y: 0,
			width: labels_width,
			height: titleLabel_h
		).integral
		//
		let subtitleLabel_dy: CGFloat = (self.sizeClass == .large48 ? 2 : 1)
		self.subtitleLabel.frame = CGRect(
			x: 0,
			y: 0,
			width: labels_width,
			height: 0
		).integral
		self.subtitleLabel.sizeToFit()
		let subtitleLabel_h = min(37, self.subtitleLabel.frame.size.height) // after sizeToFit()
		//
		let total_labels_h = self.titleLabel.frame.size.height + subtitleLabel_dy + subtitleLabel_h
		//
		// Now vertically center labels and give them final heights
		self.titleLabel.frame = CGRect(
			x: labels_x,
			y: (self.bounds.size.height - total_labels_h)/2,
			width: labels_width,
			height: titleLabel_h
		).integral
		self.subtitleLabel.frame = CGRect(
			x: labels_x,
			y: self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + subtitleLabel_dy,
			width: labels_width,
			height: subtitleLabel_h // max 2 lines
		).integral
	}
	//
	// Delegation - Wallet NSNotifications
	@objc func _wallet_booted()
	{
		self.__configureUIWithWallet_labels()
	}
	@objc func _wallet_failedToLogIn()
	{
		self.__configureUIWithWallet_labels()
	}
	@objc func _labelChanged()
	{
		self.__configureUIWithWallet_labels()
	}
	@objc func _balanceChanged()
	{
		self.__configureUIWithWallet_labels()
	}
	@objc func _swatchColorChanged()
	{
		self.__configureUIWithWallet_swatchColor()
	}
	@objc func _willBeDeleted()
	{
		self.tearDown_object() // stopObserving/release
	}
	@objc func _willBeDeinitialized(_ note: Notification)
	{ // This obviously doesn't work for calling stopObserving on self.object --- because self.object is nil by the time we get here!!
		let objectBeingDeinitialized = note.userInfo![PersistableObject.NotificationUserInfoKeys.object.key] as! Wallet
		self._stopObserving( // stopObserving specific object - self.object will be nil by now - but also call specific method for this as it has addtl check
			objectBeingDeinitialized: objectBeingDeinitialized
		)
	}
	//
	@objc func CcyConversionRates_didUpdateAvailabilityOfRates()
	{
		self.__configureUIWithWallet_labels()
	}
	@objc func SettingsController__NotificationNames_Changed__displayCurrencySymbol()
	{
		self.__configureUIWithWallet_labels()
	}
}
