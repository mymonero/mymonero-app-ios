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
	}
	//
	// Lifecycle - Teardown/Reuse
	deinit
	{
		self.prepareForReuse()
	}
	func prepareForReuse()
	{
		if self.object != nil {
			self.stopObserving_object()
			self.object = nil
		}
	}
	func stopObserving_object()
	{
		assert(self.object != nil)
		DDLog.Todo("Wallets", "stop observing wallet")
	}
	//
	// Accessors
	var iconView_x: CGFloat
	{
		switch self.sizeClass {
			case UICommonComponents.WalletIconView.SizeClass.large48, UICommonComponents.WalletIconView.SizeClass.large43:
				return 16
			case UICommonComponents.WalletIconView.SizeClass.medium32:
				return 15
		}
	}
	//
	// Imperatives - Configuration
	var object: Wallet?
	func configure(withObject object: Wallet)
	{
		assert(self.object == nil)
		self.object = object
		self._configureUIWithWallet()
		self.startObserving_object()
	}
	func _configureUIWithWallet()
	{
		self.__configureUIWithWallet_accountInfo()
		self.__configureUIWithWallet_swatchColor()
	}
	func __configureUIWithWallet_accountInfo()
	{
		DDLog.Todo("Wallets", "configure cell w/ account info")
	}
	func __configureUIWithWallet_swatchColor()
	{
		self.iconView.configure(withSwatchColor: self.object!.swatchColor)
	}
	//
	func startObserving_object()
	{
		DDLog.Todo("Wallets", "start observing wallet")
	}
	//
	// Imperatives - Overrides
	override func layoutSubviews()
	{
		super.layoutSubviews()
		self.iconView.frame = CGRect(
			x: self.iconView_x,
			y: 16 + UICommonComponents.HighlightableCells.imagePaddingForShadow_v, // for img whitespace/padding
			width: self.iconView.frame.size.width,
			height: self.iconView.frame.size.height
		)
	}
}
