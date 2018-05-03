//
//  WalletDetailsActionButtonsCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/15/17.
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

extension WalletDetails
{
	struct ActionButtons
	{
		class Cell: UICommonComponents.Tables.ReusableTableViewCell
		{
			//
			// Class - Overrides
			override class func reuseIdentifier() -> String
			{
				return "WalletDetails.ActionButtons.Cell"
			}
			override class func cellHeight(withPosition cellPosition: UICommonComponents.CellPosition) -> CGFloat
			{
				//
				return UICommonComponents.ActionButton.topMargin + UICommonComponents.ActionButton.buttonHeight + 6
			}
			//
			// Properties
			var receive_actionButtonView: UICommonComponents.ActionButton!
			var send_actionButtonView: UICommonComponents.ActionButton!
			//
			// Lifecycle - Init - Overrides
			override func setup()
			{
				super.setup()
				do {
					self.selectionStyle = .none
					self.backgroundColor = UIColor.contentBackgroundColor
				}
				do {
					let iconImage = UIImage(named: "actionButton_iconImage__request")! // TODO: borrowing the 'request' image for this - not great
					let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: true, iconImage: iconImage)
					view.addTarget(self, action: #selector(receive_tapped), for: .touchUpInside)
					view.setTitle(NSLocalizedString("Receive At", comment: ""), for: .normal)
					view.titleEdgeInsets = UICommonComponents.ActionButton.new_titleEdgeInsets_withIcon
					self.receive_actionButtonView = view
					self.addSubview(view)
				}
				do {
					let iconImage = UIImage(named: "actionButton_iconImage__send")!
					let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: false, iconImage: iconImage)
					view.addTarget(self, action: #selector(send_tapped), for: .touchUpInside)
					view.setTitle(NSLocalizedString("Send From", comment: ""), for: .normal)
					view.titleEdgeInsets = UICommonComponents.ActionButton.new_titleEdgeInsets_withIcon
					self.send_actionButtonView = view
					self.addSubview(view)
				}
			}
			//
			// Imperatives - Overrides - Layout
			override func layoutSubviews()
			{
				super.layoutSubviews()
				let buttons_y = UICommonComponents.ActionButton.topMargin
				self.receive_actionButtonView.givenSuperview_layOut(
					atY: buttons_y,
					withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h
				)
				self.send_actionButtonView.givenSuperview_layOut(
					atY: buttons_y,
					withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h
				)
			}
			//
			// Imperatives - Overrides - Configuration
			override func _configureUI()
			{
				let configuration = self.configuration!
				let wallet = configuration.dataObject as? Wallet
				if wallet == nil {
					assert(false)
					return
				}
				if wallet!.didFailToInitialize_flag == true || wallet!.didFailToBoot_flag == true {
					self.send_actionButtonView.isEnabled = false
					self.receive_actionButtonView.isEnabled = false
				} else if wallet!.hasEverFetched_accountInfo == false {
					self.send_actionButtonView.isEnabled = false
					self.receive_actionButtonView.isEnabled = false
				} else {
					self.send_actionButtonView.isEnabled = true
					self.receive_actionButtonView.isEnabled = true
				}
			}
			//
			// Delegation - Interactions
			@objc func send_tapped()
			{
				let configuration = self.configuration!
				let wallet = configuration.dataObject as! Wallet
				WalletAppWalletActionsCoordinator.Trigger_sendFunds(fromWallet: wallet)
			}
			@objc func receive_tapped()
			{
				let configuration = self.configuration!
				let wallet = configuration.dataObject as! Wallet
				WalletAppWalletActionsCoordinator.Trigger_receiveFunds(toWallet: wallet)
			}
		}
	}
}
