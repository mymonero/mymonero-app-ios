//
//  WalletCellContentView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class WalletCellContentView: UIView
{
	var sizeClass: UICommonComponents.WalletIconView.SizeClass
	var iconView: UICommonComponents.WalletIconView!
	var titleLabel: UILabel!
	var subtitleLabel: UILabel!
	//
	// Lifecycle - Init
	init(sizeClass: UICommonComponents.WalletIconView.SizeClass)
	{
		self.sizeClass = sizeClass
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
			view.font = UIFont.middlingRegularMonospace
			view.numberOfLines = 1
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
		if self.object != nil {
			self.stopObserving_object()
			self.object = nil
		}
	}
	func prepareForReuse()
	{
		self.tearDown_object()
	}
	func stopObserving_object()
	{
		assert(self.object != nil)
		NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.labelChanged.notificationName, object: self.object!)
		NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.balanceChanged.notificationName, object: self.object!)
		NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.swatchColorChanged.notificationName, object: self.object!)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)

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
	//
	// Imperatives - Configuration
	var object: Wallet?
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
		self.__configureUIWithWallet_accountInfo()
		self.__configureUIWithWallet_swatchColor()
	}
	func __configureUIWithWallet_accountInfo()
	{
		assert(self.object != nil)
		if self.object!.didFailToInitialize_flag == true || self.object!.didFailToBoot_flag == true { // unlikely but possible
			self.titleLabel.text = "Error"
			self.subtitleLabel.text = "Couldn't unlock wallet. Please contact support."
			return
		}
		self.titleLabel.text = self.object!.walletLabel
		var subtitleLabel_text: String?
		do {
			if self.object!.hasEverFetched_accountInfo == false {
				subtitleLabel_text = "Loading…"
			} else {
				subtitleLabel_text = "\(self.object!.balance_formattedString) \(self.object!.currency.humanReadableCurrencySymbolString)"
				if self.object!.hasLockedFunds {
					subtitleLabel_text = subtitleLabel_text! + " (${wallet.LockedBalance_FormattedString()} 🔒)"
				}
			}
		}
		assert(subtitleLabel_text != nil)
		self.subtitleLabel.text = subtitleLabel_text
	}
	func __configureUIWithWallet_swatchColor()
	{
		self.iconView.configure(withSwatchColor: self.object!.swatchColor)
	}
	//
	func startObserving_object()
	{
		assert(self.object != nil)
		NotificationCenter.default.addObserver(self, selector: #selector(_labelChanged), name: Wallet.NotificationNames.labelChanged.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_balanceChanged), name: Wallet.NotificationNames.balanceChanged.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_swatchColorChanged), name: Wallet.NotificationNames.swatchColorChanged.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)
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
		let labels_rightMargin: CGFloat = 40
		let labels_width = self.frame.size.width - labels_x - labels_rightMargin
		self.titleLabel.frame = CGRect(
			x: labels_x,
			y: self.titleLabels_y,
			width: labels_width,
			height: 16 // TODO: size with font for accessibility?
		).integral
		self.subtitleLabel.frame = CGRect(
			x: labels_x,
			y: self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 1,
			width: labels_width,
			height: 20 // TODO: size with font for accessibility? NOTE: must support emoji, currently, for locked icon
		).integral
	}
	//
	// Delegation - Wallet NSNotifications
	@objc func _labelChanged()
	{
		self.__configureUIWithWallet_accountInfo()
	}
	@objc func _balanceChanged()
	{
		self.__configureUIWithWallet_accountInfo()
	}
	@objc func _swatchColorChanged()
	{
		self.__configureUIWithWallet_swatchColor()
	}
	func _willBeDeleted()
	{
		self.tearDown_object() // release
	}
}
