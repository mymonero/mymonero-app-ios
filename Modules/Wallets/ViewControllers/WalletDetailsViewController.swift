//
//  WalletDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/14/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UICommonComponents.Details
{
	class WalletBalanceDisplayFieldView: UICommonComponents.Details.FieldView
	{
		//
		// Constants - Overrides
		override var contentInsets: UIEdgeInsets {
			return UIEdgeInsetsMake(0, 0, 0, 0)
		}
		//
		// Constants
		static let height: CGFloat = 71
		//
		// Properties
		var wallet: Wallet!
		let label = UILabel()
		//
		// Init
		init(wallet: Wallet)
		{
			self.wallet = wallet
			super.init()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup()
		{
			super.setup()
			self.addSubview(self.label)
		}
		//
		// Imperatives - Layout - Overrides
		override func sizeToFitAndLayOutSubviews(
			withContainingWidth containingWidth: CGFloat,
			withXOffset xOffset: CGFloat,
			andYOffset yOffset: CGFloat
			)
		{
			self.label.frame = CGRect(
				x: 0,
				y: 6,
				width: 0,
				height: WalletBalanceDisplayFieldView.height
			)
			self.label.sizeToFit()
			//
			self.frame = CGRect(
				x: xOffset,
				y: yOffset,
				width: containingWidth,
				height: WalletBalanceDisplayFieldView.height
			)
		}
	}
	
}

class WalletDetailsViewController: UICommonComponents.Details.ViewController
{
	//
	// Constants/Types
	let fieldLabels_variant = UICommonComponents.Details.FieldLabel.Variant.middling
	//
	// Properties
	var wallet: Wallet
	//
	var sectionView_balance = UICommonComponents.Details.SectionView(sectionHeaderTitle: nil)
	//
	//
	// Imperatives - Init
	init(wallet: Wallet)
	{
		self.wallet = wallet
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	//
	// Overrides
	override func setup_views()
	{
		super.setup_views()
		self.scrollView.contentInset = UIEdgeInsetsMake(14, 0, 14, 0)
		do {
			let sectionView = self.sectionView_balance
			do {
				let view = UICommonComponents.Details.WalletBalanceDisplayFieldView(wallet: self.wallet)
				sectionView.add(fieldView: view)
			}
			self.scrollView.addSubview(sectionView)
		}
		//		self.view.borderSubviews()
		self.view.setNeedsLayout()
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.set_navigationTitle() // also to be called on contact info updated
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .edit,
			target: self,
			action: #selector(tapped_rightBarButtonItem)
		)
	}
	override var overridable_wantsBackButton: Bool {
		return true
	}
	//
	override func startObserving()
	{
		super.startObserving()
		NotificationCenter.default.addObserver(self, selector: #selector(wasDeleted), name: PersistableObject.NotificationNames.wasDeleted.notificationName, object: self.wallet)
	}
	override func stopObserving()
	{
		super.stopObserving()
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.wasDeleted.notificationName, object: self.wallet)
	}
	//
	// Imperatives
	func set_navigationTitle()
	{
		self.navigationItem.title = self.wallet.walletLabel
	}
	//
	// Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		self.sectionView_balance.sizeToFitAndLayOutSubviews(
			withContainingWidth: self.view.bounds.size.width, // since width may have been updated…
			withXOffset: 0,
			andYOffset: 0
		)
		//
		let bottomMostView = self.sectionView_balance // TODO: transactions list section … but wouldn't it be nicer to make it a UITableView?
		self.scrollableContentSizeDidChange(withBottomView: bottomMostView, bottomPadding: 12) // btm padding in .contentInset
	}
	//
	// Delegation - Interactions
	func tapped_rightBarButtonItem()
	{
		assert(false, "display wallet edit modal")
	}
	//
	// Delegation - Notifications
	func wasDeleted()
	{
		if self.navigationController!.topViewController! != self {
			assert(false)
			return
		}
		self.navigationController!.popViewController(animated: true)
	}
}
