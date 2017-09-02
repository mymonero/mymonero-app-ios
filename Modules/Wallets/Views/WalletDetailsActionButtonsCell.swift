//
//  WalletDetailsActionButtonsCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
				return UICommonComponents.ActionButton.topMargin + UICommonComponents.ActionButton.buttonHeight // no .bottomMargin because the section-to-follow supplies its header margin
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
					self.receive_actionButtonView = view
					self.addSubview(view)
				}
				do {
					let iconImage = UIImage(named: "actionButton_iconImage__send")!
					let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: false, iconImage: iconImage)
					view.addTarget(self, action: #selector(send_tapped), for: .touchUpInside)
					view.setTitle(NSLocalizedString("Send From", comment: ""), for: .normal)
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
			func send_tapped()
			{
				let configuration = self.configuration!
				let wallet = configuration.dataObject as! Wallet
				WalletAppWalletActionsCoordinator.Trigger_sendFunds(fromWallet: wallet)
			}
			func receive_tapped()
			{
				let configuration = self.configuration!
				let wallet = configuration.dataObject as! Wallet
				WalletAppWalletActionsCoordinator.Trigger_receiveFunds(toWallet: wallet)
			}
		}
	}
}
