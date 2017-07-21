//
//  WalletDetailsTransactionsEmptyStateCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/21/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
import UIKit
//
extension WalletDetails
{
	struct TransactionsEmptyState
	{
		class Cell: UICommonComponents.Tables.ReusableTableViewCell
		{
			//
			// Constants
			static let contentView_margin_h: CGFloat = 16
			//
			// Class - Overrides
			override class func reuseIdentifier() -> String {
				return "WalletDetails.TransactionsEmptyState.Cell"
			}
			override class func cellHeight(withPosition cellPosition: UICommonComponents.CellPosition) -> CGFloat
			{
				return 240 // somewhat arbitrary
			}
			//
			// Properties
			let cellContentView = UICommonComponents.EmptyStateView(
				emoji: "😴",
				message: NSLocalizedString("You don't have any\ntransactions yet.", comment: "")
			)
			//
			// Setup
			override func setup()
			{
				super.setup()
				do {
					self.isOpaque = true // performance
					self.selectionStyle = .none
					self.backgroundColor = UIColor.contentBackgroundColor
				}
				self.contentView.addSubview(self.cellContentView)
			}
			//
			// Imperatives - Configuration
			override func _configureUI()
			{
			}
			//
			// Overrides - Imperatives
			override func layoutSubviews()
			{
				super.layoutSubviews()

				let frame = UIEdgeInsetsInsetRect(
					self.bounds,
					UIEdgeInsetsMake(
						0,
						WalletDetails.TransactionsEmptyState.Cell.contentView_margin_h,
						0,
						WalletDetails.TransactionsEmptyState.Cell.contentView_margin_h
					)
				)
				self.cellContentView.frame = frame
			}
		}
	}
}
