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
	class ViewController: UICommonComponents.Details.ViewController
	{
		//
		// Constants/Types
		let fieldLabels_variant = UICommonComponents.Details.FieldLabel.Variant.middling
		//
		// Properties
		var transaction: MoneroHistoricalTransactionRecord
		//
		var sectionView_details = UICommonComponents.Details.SectionView(
			sectionHeaderTitle: NSLocalizedString("DETAILS", comment: "")
		)
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
//				do {
//					let view = UICommonComponents.Details.CopyableLongStringFieldView(
//						labelVariant: self.fieldLabels_variant,
//						title: NSLocalizedString("Message for Requestee", comment: ""),
//						valueToDisplayIfZero: nil
//					)
//					view.set(
//						text: self.new_requesteeMessagePlaintextString,
//						ifNonNil_overridingTextAndZeroValue_attributedDisplayText: self.new_requesteeMessageNSAttributedString
//					)
//					sectionView.add(fieldView: view)
//				}
				self.scrollView.addSubview(sectionView)
			}
			//		self.view.borderSubviews()
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
			// TODO: set fields' data
			//
			self.view.setNeedsLayout()
		}
		//
		// Delegation - Notifications
		func infoUpdated()
		{
			self.configureUI()
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
