//
//  WalletDetailsTransactionsEmptyStateCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/21/17.
//  Copyright (c) 2014-2019, MyMonero.com
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

				let frame = self.bounds.inset(by: UIEdgeInsets.init(
						top: 0,
						left: WalletDetails.TransactionsEmptyState.Cell.contentView_margin_h,
						bottom: 0,
						right: WalletDetails.TransactionsEmptyState.Cell.contentView_margin_h
					)
				)
				self.cellContentView.frame = frame
			}
		}
	}
}
