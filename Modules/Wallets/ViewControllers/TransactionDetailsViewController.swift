//
//  TransactionDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/19/17.
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
		var wallet: Wallet! // strong ok since self will be torn down
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
		init(transaction: MoneroHistoricalTransactionRecord, inWallet wallet: Wallet)
		{
			self.transaction = transaction
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
			// TODO: contact sent-to or received-from
			do {
				let sectionView = self.sectionView_details
				do {
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
						title: NSLocalizedString("Ring size", comment: ""),
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
		//
		override func startObserving()
		{
			super.startObserving()
			NotificationCenter.default.addObserver(self, selector: #selector(wallet_transactionsChanged), name: Wallet.NotificationNames.transactionsChanged.notificationName, object: self.wallet)
		}
		override func stopObserving()
		{
			super.stopObserving()
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.transactionsChanged.notificationName, object: self.wallet)
		}
		//
		// Accessors - Overrides
		override func new_navigationBarTitleColor() -> UIColor?
		{
			return self.transaction.approxFloatAmount > 0
				? nil // for theme default/reset
				: UIColor(rgb: 0xF97777)
		}
		override var overridable_wantsBackButton: Bool {
			return true
		}
		override func new_contentInset() -> UIEdgeInsets
		{
			var inset = super.new_contentInset()
			inset.bottom += 14
			
			return inset
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
			self.sectionView_details.layOut(
				withContainingWidth: self.scrollView/*not view*/.bounds.size.width, // since width may have been updated…
				withXOffset: 0,
				andYOffset: self.yOffsetForViewsBelowValidationMessageView
			)
			self.scrollableContentSizeDidChange(withBottomView: self.sectionView_details, bottomPadding: 12) // btm padding in .contentInset
		}
		//
		// Imperatives 
		func configureUI()
		{
			self.set_navigationTitleAndColor()
			//
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
				self.amountsFeesTotals__fieldView.set(
					text: value,
					color: floatAmount < 0 ? UIColor(rgb: 0xF97777) : nil
				)
			}
			do {
				let value = "\(self.transaction.mixin + 1)" // ringsize is mixin + 1
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
		@objc func wallet_transactionsChanged()
		{
			var mutable__updated_transaction: MoneroHistoricalTransactionRecord? // to find
			do {
				let transactions = self.wallet.transactions!
				for (_, this_transaction) in transactions.enumerated() {
					if this_transaction.hash == self.transaction.hash {
						mutable__updated_transaction = this_transaction
						break
					}
				}
			}
			if mutable__updated_transaction == nil {
				var shouldTrip = false
				#if MOCK_SUCCESSOFTXSUBMISSION
					#if !DEBUG
						assert(false, "MOCK_SUCCESSOFTXSUBMISSION && !DEBUG") // no need to trip below assert
					#endif
					if self.transaction.cached__isConfirmed != false {
						// ^-- approximately detecting whether this is the tx details view for the tx which was just (not really) submitted … doing so because this assert will trip when MOCK_SUCCESSOFTXSUBMISSION
						shouldTrip = true
					}
				#else
					shouldTrip = true
				#endif
				assert(shouldTrip == false, "Didn't find same transaction in already open details view. Likely a server issue.")
				#if !MOCK_SUCCESSOFTXSUBMISSION
					assert(false)
				#endif
				return // or else just prevent fallthrough
			}
			let updated_transaction = mutable__updated_transaction!
			self.transaction = updated_transaction // grab updated record
			self.configureUI() // may not be this one which was updated but it's not that expensive to reconfig UI
		}
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
