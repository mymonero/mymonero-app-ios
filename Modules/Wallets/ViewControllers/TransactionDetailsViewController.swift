//
//  TransactionDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

struct TransactionDetails {}

extension TransactionDetails
{
	static var _cell_dateFormatter: DateFormatter? = nil
	static func lazy_cell_dateFormatter() -> DateFormatter
	{
		if TransactionDetails._cell_dateFormatter == nil {
			let formatter = DateFormatter() // would be nice
			formatter.dateFormat = "d MMM yyyy HH:mm:ss"
			TransactionDetails._cell_dateFormatter = formatter
		}
		return TransactionDetails._cell_dateFormatter!
	}
	//
	class ViewController: UICommonComponents.Details.ViewController
	{
		//
		// Constants/Types
		let fieldLabels_variant = UICommonComponents.Details.FieldLabel.Variant.small
		//
		// Properties
		var transaction: MoneroHistoricalTransactionRecord
		//
		var sectionView_details = UICommonComponents.Details.SectionView(
			sectionHeaderTitle: NSLocalizedString("DETAILS", comment: "")
		)
		var date__fieldView: UICommonComponents.Details.ShortStringFieldView!
//		var memo__fieldView: UICommonComponents.Details.ShortStringFieldView!
		var amountsFeesTotals__fieldView: UICommonComponents.Details.ShortStringFieldView! // TODO: multi value field
		var ringsize__fieldView: UICommonComponents.Details.ShortStringFieldView!
		var transactionHash__fieldView: UICommonComponents.Details.CopyableLongStringFieldView!
		var paymentID__fieldView: UICommonComponents.Details.CopyableLongStringFieldView!
		//
		//
		// Imperatives - Init
		init(transaction: MoneroHistoricalTransactionRecord)
		{
			self.transaction = transaction
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
			// TODO: contact sent-to or received-from
			do {
				let sectionView = self.sectionView_details
				do {
					// TODO ShortStringFieldView
					let view = UICommonComponents.Details.ShortStringFieldView(
						labelVariant: self.fieldLabels_variant,
						title: NSLocalizedString("Date", comment: ""),
						valueToDisplayIfZero: nil
					)
					self.date__fieldView = view
					sectionView.add(fieldView: view)
				}
//				do {
//					let view = UICommonComponents.Details.ShortStringFieldView(
//						labelVariant: self.fieldLabels_variant,
//						title: NSLocalizedString("Memo", comment: ""),
//						valueToDisplayIfZero: nil
//					)
//					self.memo__fieldView = view
//					sectionView.add(fieldView: view)
//				}
				do {
					// TODO MultiValueFieldView
					let view = UICommonComponents.Details.ShortStringFieldView(
						labelVariant: self.fieldLabels_variant,
						title: NSLocalizedString("Total", comment: ""),
						valueToDisplayIfZero: nil
					)
					self.amountsFeesTotals__fieldView = view
					sectionView.add(fieldView: view)
				}
				do {
					let view = UICommonComponents.Details.ShortStringFieldView(
						labelVariant: self.fieldLabels_variant,
						title: NSLocalizedString("Ringsize", comment: ""),
						valueToDisplayIfZero: nil
					)
					self.ringsize__fieldView = view
					sectionView.add(fieldView: view)
				}
				do {
					let view = UICommonComponents.Details.CopyableLongStringFieldView(
						labelVariant: self.fieldLabels_variant,
						title: NSLocalizedString("Transaction Hash", comment: ""),
						valueToDisplayIfZero: NSLocalizedString("N/A", comment: "")
					)
					self.transactionHash__fieldView = view
					sectionView.add(fieldView: view)
				}
				do {
					let view = UICommonComponents.Details.CopyableLongStringFieldView(
						labelVariant: self.fieldLabels_variant,
						title: NSLocalizedString("Payment ID", comment: ""),
						valueToDisplayIfZero: NSLocalizedString("N/A", comment: "")
					)
					self.paymentID__fieldView = view
					sectionView.add(fieldView: view)
				}
				self.scrollView.addSubview(sectionView)
			}
//			self.view.borderSubviews()
		}
		override func setup_navigation()
		{
			super.setup_navigation()
		}
		override var overridable_wantsBackButton: Bool {
			return true
		}
		//
		override func startObserving()
		{
			super.startObserving()
		}
		override func stopObserving()
		{
			super.stopObserving()
		}
		//
		// Accessors - Overrides
		override func new_navigationBarTitleColor() -> UIColor?
		{
			return self.transaction.approxFloatAmount > 0
				? nil // for theme default/reset
				: UIColor(rgb: 0xF97777)
		}
		//
		// Imperatives
		func set_navigationTitleAndColor()
		{
			self.configureNavigationBarTitleColor() // may be redundant but is also necessary for infoUpdated()
			self.navigationItem.title = "\(self.transaction.approxFloatAmount)"
		}
		//
		// Overrides - Layout
		override func viewDidLayoutSubviews()
		{
			super.viewDidLayoutSubviews()
			//
			self.sectionView_details.sizeToFitAndLayOutSubviews(
				withContainingWidth: self.view.bounds.size.width, // since width may have been updated…
				withXOffset: 0,
				andYOffset: 0
			)
			self.scrollableContentSizeDidChange(withBottomView: self.sectionView_details, bottomPadding: 12) // btm padding in .contentInset
		}
		//
		// Imperatives 
		func configureUI()
		{
			self.set_navigationTitleAndColor()
			// TODO: status messages
			var validationMessage = ""
			if transaction.isJustSentTransientTransactionRecord || transaction.cached__isConfirmed == false {
				validationMessage += NSLocalizedString("Your Monero is on its way.", comment: "")
			}
			if transaction.cached__isUnlocked == false {
				assert(transaction.cached__lockedReason != nil)
				if validationMessage != "" {
					validationMessage += "\n\n"
				}
				validationMessage += NSLocalizedString("Transaction currently locked. Reason: ", comment: "")
				validationMessage += transaction.cached__lockedReason! // this is not necessarily a good localized way to concat strings
			}
			if validationMessage != "" {
				self.set(validationMessage: validationMessage, wantsXButton: false)
			} else {
				self.clearValidationMessage()
			}
			do {
				let value = TransactionDetails.lazy_cell_dateFormatter().string(from: self.transaction.timestamp).uppercased()
				self.date__fieldView.set(text: value)
			}
//			do {
//				let value = self.transaction.memo
//				self.memo__fieldView.set(text: value)
//			}
			do {
				// TODO: array of multivaluefieldrowdescriptions w/clr etc for amount and two fees
				let floatAmount = self.transaction.approxFloatAmount
				let value = "\(floatAmount)"
				self.amountsFeesTotals__fieldView.set(text: value, color: floatAmount < 0 ? UIColor(rgb: 0xF97777) : nil)
			}
			do {
				let value = "\(self.transaction.mixin)"
				self.ringsize__fieldView.set(text: value)
			}
			do {
				let value = self.transaction.hash
				self.transactionHash__fieldView.set(text: value)
			}
			do {
				let value = self.transaction.paymentId
				self.paymentID__fieldView.set(text: value)
			}
			//
			do {
				let text =
					self.transaction.cached__isConfirmed
					? NSLocalizedString("CONFIRMED", comment: "")
					: NSLocalizedString("PENDING", comment: "")
				self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
					type: .valueDisplayLabel,
					target: nil,
					action: nil,
					title_orNilForDefault: text // .valueDisplayLabel is implemented such that it requires an initial title passed in - cannot do at object's runtime yet
				)
			}
			//
			self.view.setNeedsLayout()
		}
		//
		// Delegation - Notifications
		func infoUpdated()
		{
			self.configureUI()
		}
		// TODO:
//		func wallet_EventName_transactionsChanged()
//		{
//			var updated_transaction = null // to find
//			const transactions = self.wallet.New_StateCachedTransactions() // important to use this instead of .transactions
//			const transactions_length = transactions.length
//			for (let i = 0 ; i < transactions_length ; i++) {
//				const this_transaction = transactions[i]
//				if (this_transaction.hash === self.transaction.hash) {
//					updated_transaction = this_transaction
//					break
//				}
//			}
//			if (updated_transaction !== null) {
//				self.transaction = updated_transaction
//				if (typeof self.navigationController !== 'undefined' && self.navigationController !== null) {
//					self.navigationController.SetNavigationBarTitleNeedsUpdate()
//				}
//				self._configureUIWithTransaction() // updated - it might not be this one which updated but (a) it's quite possible and (b) configuring the UI isn't too expensive
//			} else {
//				throw "Didn't find same transaction in already open details view. Probably a server bug."
//			}
//		}
		//
		// Delegation - View lifecycle
		override func viewWillAppear(_ animated: Bool)
		{
			super.viewWillAppear(animated)
			//
			self.configureUI() // deferring til here instead of setup() b/c we ask for navigationController
		}
	}
}
