//
//  WalletDetailsTransactionsSectionHeader.swift
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
//
extension WalletDetails
{
	class TransactionsSectionHeaderView: UIView
	{
		//
		enum Mode
		{
			case scanningIndicator
			case importTransactionsButton
		}
		static var bottomPadding: CGFloat {
			return 6
		}
		static func fullViewHeight(forMode: Mode, topPadding: CGFloat) -> CGFloat
		{
			return topPadding + 16 + TransactionsSectionHeaderView.bottomPadding // TODO: get fixed height instead of '16'
		}
		//
		// Properties - Settable after init
		var importTransactions_tapped_fn: (() -> Void)?
		//
		// Properties - Settable via init
		var mode: Mode
		var wallet: Wallet // self SHOULD be torn down on a table .reloadData() so we can keep this as strong
		var contentView: UIView!
		init(mode: Mode, wallet: Wallet)
		{
			self.mode = mode
			self.wallet = wallet
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			switch self.mode {
			case .scanningIndicator:
				let view = UICommonComponents.GraphicAndTwoUpLabelsActivityIndicatorView()
				// we will set the main text in layoutSubviews - oddly enough - b/c that is where we get informed of the superview width
				view.set(
					accessoryLabelText: String(
						format: NSLocalizedString(
							"%d blocks behind",
							comment: ""
						),
						self.wallet.nBlocksBehind
					)
				)
				do {
					view.frame = CGRect( // initial
						x: CGFloat.form_label_margin_x,
						y: 0, // will set in layoutSubviews
						width: 0, // we'll set this in layoutSubviews
						height: view.new_height_withoutVSpacing // cause we manage v spacing here
					)
				}
				view.isHidden = true // quirk of activityIndicator API - must start hidden in order to .show(), which triggers startAnimating() - could just reach in and call startAnimating directly, or improve API
				self.contentView = view
				self.addSubview(view)
				break
			case .importTransactionsButton:
				let view = UICommonComponents.LinkButtonView(mode: .mono_default, title: NSLocalizedString("IMPORT TRANSACTIONS", comment: ""))
				view.addTarget(self, action: #selector(importTransactions_tapped), for: .touchUpInside)
				view.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: 0, // will set
					width: view.frame.size.width,
					height: view.frame.size.height
				)
				self.contentView = view
				self.addSubview(view)
				break
			}
		}
		//
		deinit
		{
			if self.mode == .scanningIndicator {
				if self.indicatorView.activityIndicator.isAnimating {
					self.indicatorView.activityIndicator.stopAnimating()
				}
				assert(self.indicatorView.activityIndicator.isAnimating == false)
			}
		}
		//
		//
		var indicatorView: UICommonComponents.GraphicAndTwoUpLabelsActivityIndicatorView {
			return self.contentView as! UICommonComponents.GraphicAndTwoUpLabelsActivityIndicatorView
		}
		//
		// Overrides - Imperatives
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			let view = self.contentView! // why is ! necessary?
			let x = view.frame.origin.x // allow setup to specify x
			let w = self.mode == .importTransactionsButton ? view.frame.size.width : self.frame.size.width - 2*x // preserving sizedToFit LinkButtonView
			view.frame = CGRect(
				x: x,
				y: self.frame.size.height - view.frame.size.height - TransactionsSectionHeaderView.bottomPadding, // need to set Y
				width: w,
				height: view.frame.size.height
			)
			//
			switch self.mode {
				case .scanningIndicator:
					let isLargerFormatScreen = self.frame.size.width > 320
					let text = isLargerFormatScreen
						? NSLocalizedString("SCANNING BLOCKCHAIN…", comment: "") // ambiguous w/o " BLOCKCHAIN"
						: NSLocalizedString("SCANNING…", comment: "") // just not enough space
					if self.indicatorView.label.text != text {
						self.indicatorView.set(
							labelText: text
						)
					} else {
						// unlikely but possible
					}
				default:
					break // nothing to do
			}
		}
		//
		// Delegation - Interactions
		@objc func importTransactions_tapped()
		{
			if let fn = self.importTransactions_tapped_fn {
				fn()
			}
		}
	}
}
