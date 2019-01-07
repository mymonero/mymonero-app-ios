//
//  WalletDetailsBalanceViewCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/15/17.
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

extension WalletDetails
{
	struct Balance
	{
		static let secondaryBalances_dx: CGFloat = 8
		static let secondaryBalances_dy: CGFloat = 8
		static let secondaryBalances_h: CGFloat = 16
		static let secondaryBalances_padding_btm: CGFloat = 2
		//
		class Cell: UICommonComponents.Tables.ReusableTableViewCell
		{
			override class func reuseIdentifier() -> String {
				return "WalletDetails.Balance.Cell"
			}
			override class func cellHeight(
				withPosition cellPosition: UICommonComponents.CellPosition
			) -> CGFloat {
				fatalError("Table view should have called cellHeight(withPosition:hasSecondaryBalances:) instead")
			}
			class func cellHeight(
				withPosition cellPosition: UICommonComponents.CellPosition,
				hasSecondaryBalances: Bool
			) -> CGFloat {
				var h = DisplayView.height
				if hasSecondaryBalances {
					h += Balance.secondaryBalances_dy + Balance.secondaryBalances_h + Balance.secondaryBalances_padding_btm
				}
				return h
			}
			//
			let balanceDisplayView = DisplayView()
			let secondaryBalancesLabel = UILabel()
			override func setup()
			{
				super.setup()
				do {
					self.selectionStyle = .none
					self.backgroundColor = UIColor.contentBackgroundColor
					self.addSubview(self.balanceDisplayView)
				}
				do {
					let view = self.secondaryBalancesLabel
					view.numberOfLines = 0
					view.font = UIFont.middlingRegularMonospace
					view.textColor = UIColor.contentTextColor
					view.textAlignment = .left
					view.lineBreakMode = .byTruncatingTail
					view.adjustsFontSizeToFitWidth = true
					view.minimumScaleFactor = 0.5
					self.addSubview(view)
				}
			}
			//
			// Overrides
			override func layoutSubviews()
			{
				super.layoutSubviews()
				do {
					let l = WalletDetails.ViewController.margin_h - DisplayView.imagePaddingInsets.left
					let r = WalletDetails.ViewController.margin_h - DisplayView.imagePaddingInsets.right
					self.balanceDisplayView.frame = CGRect.init(
						x: l,
						y: -DisplayView.imagePaddingInsets.top,
						width: self.bounds.size.width - l - r,
						height: DisplayView.height + DisplayView.imagePaddingInsets.top + DisplayView.imagePaddingInsets.bottom
					)
				}
				do {
					self.secondaryBalancesLabel.frame = CGRect.init(
						x: self.balanceDisplayView.frame.origin.x + secondaryBalances_dx,
						y: self.balanceDisplayView.frame.origin.y + self.balanceDisplayView.frame.size.height + secondaryBalances_dy,
						width: self.balanceDisplayView.frame.size.width - 2*secondaryBalances_dx,
						height: secondaryBalances_h
					)
				}
			}
			override func _configureUI()
			{
				let wallet = self.configuration!.dataObject as! Wallet
				self.balanceDisplayView.set(balanceWithWallet: wallet)
				//
				let pendingAmount = wallet.new_pendingBalanceAmount
				let lockedAmount = wallet.lockedBalanceAmount
				let hasSecondaryBalances = pendingAmount > 0 || lockedAmount > 0
				if hasSecondaryBalances {
					var text = ""
					if pendingAmount > 0 {
						let components = CcyConversionRates.Currency.amountConverted_displayStringComponents(
							from: pendingAmount,
							ccy: SettingsController.shared.displayCurrency,
							chopNPlaces: 3
						)
						text += String(
							format: NSLocalizedString(
								"%@ pending",
								comment: "{amount} pending"
							),
							components.formattedAmount
						)
					}
					if lockedAmount > 0 {
						if text != "" {
							text += "; "
						}
						let components = CcyConversionRates.Currency.amountConverted_displayStringComponents(
							from: lockedAmount,
							ccy: SettingsController.shared.displayCurrency,
							chopNPlaces: 3
						)
						text += String(
							format: NSLocalizedString(
								"%@ locked",
								comment: "{amount} locked"
							),
							components.formattedAmount
						)
					}
					self.secondaryBalancesLabel.text = text
					self.secondaryBalancesLabel.isHidden = false
				} else {
					self.secondaryBalancesLabel.text = ""
					self.secondaryBalancesLabel.isHidden = true
				}
			}
		}
		class DisplayViewLabel: UILabel
		{
			//
			// Accessors - Overrides - UIResponder
			override var canBecomeFirstResponder: Bool {
				return true
			}
			//
			// Accessors - Overrides
			override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool
			{
				return action == #selector(copy(_:))
			}
			//
			// Imperatives - Overrides - UIResponderStandardEditActions
			override func copy(_ sender: Any?)
			{
				UIPasteboard.general.string = self.text
			}
		}
		class DisplayView: UIImageView
		{
			//
			// Constants
			static let height: CGFloat = 71
			//
			static let imagePaddingInsets = UIEdgeInsets.init(top: 2, left: 1, bottom: 2, right: 1)
			static let cornerRadius: CGFloat = 5
			static func stretchableBackgroundImage(forSwatchColor swatchColor: Wallet.SwatchColor) -> UIImage
			{
				let name = "balanceDisplayBG_stretchable_\(swatchColor.colorName)"
				let image = UIImage(named: name)!
				let stretchableImage = image.stretchableImage(
					withLeftCapWidth: Int(imagePaddingInsets.left + cornerRadius),
					topCapHeight: Int(imagePaddingInsets.top + cornerRadius)
				)
				return stretchableImage
			}
			//
			// Properties
			let label = DisplayViewLabel()
			//
			// Init
			init()
			{
				super.init(frame: .zero)
				self.setup()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			func setup()
			{
				do {
					let view = self.label
					view.isUserInteractionEnabled = true // allow pass through of touches for menu
					view.numberOfLines = 1
					view.lineBreakMode = .byTruncatingTail
					view.font = UIFont(name: UIFont.lightMonospaceFontName, size: 32)
					self.addSubview(view)
					//
					let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(did_longPress(_:)))
					gestureRecognizer.minimumPressDuration = 0.3
					view.addGestureRecognizer(gestureRecognizer)
				}
				self.isUserInteractionEnabled = true // for long press
			}
			//
			// Overrides
			override func layoutSubviews() {
				super.layoutSubviews()
				let imagePaddingInsets = type(of: self).imagePaddingInsets
				let contentFrame = self.bounds.insetBy(dx: imagePaddingInsets.left, dy: imagePaddingInsets.top)
				do {
					var labelFrame = contentFrame.insetBy(dx: 18, dy: 0)
					labelFrame.origin.y -= 2 // visual vertical alignment
					self.label.frame = labelFrame
				}
			}
			//
			// Accessors
			func mainSectionTextColor(withWallet wallet: Wallet) -> UIColor {
				if wallet.swatchColor.isADarkColor {
					return UIColor(rgb: 0xF8F7F8) // so use light text
				} else {
					return UIColor(rgb: 0x161416) // so use dark text
				}
			}
			func secondarySectionTextColor(withWallet wallet: Wallet) -> UIColor {
				if wallet.swatchColor.isADarkColor {
					return UIColor(red: 248/255, green: 247/255, blue: 248/255, alpha: 0.2)
				} else {
					return UIColor(red: 29/255, green: 26/255, blue: 29/255, alpha: 0.2)
				}
			}
			//
			// Imperatives
			func set(balanceWithWallet wallet: Wallet)
			{
				if wallet.didFailToInitialize_flag == true {
					self.set(
						utilityText: NSLocalizedString("LOAD ERROR", comment: ""),
						withWallet: wallet
					)
					return
				}
				if wallet.didFailToBoot_flag == true {
					self.set(
						utilityText: NSLocalizedString("LOGIN ERROR", comment: ""),
						withWallet: wallet
					)
					return
				}
				if wallet.hasEverFetched_accountInfo == false {
					self.set(
						utilityText: NSLocalizedString("LOADING…", comment: ""),
						withWallet: wallet
					)
					return
				}
				var finalized_main_string = ""
				var finalized_paddingZeros_string = ""
				var displayCurrency = SettingsController.shared.displayCurrency
				do {
					let components = CcyConversionRates.Currency.amountConverted_displayStringComponents(
						from: wallet.balanceAmount,
						ccy: displayCurrency
					)
					let raw_balanceString = components.formattedAmount
					displayCurrency = components.final_ccy // must use the returned one
					let display_coinUnitPlaces = displayCurrency.unitsForDisplay
					//
					// TODO: the following should probably be factored and placed into something like an/the Amounts class
					let locale_decimalSeparator = Locale.current.decimalSeparator ?? "."
					let raw_balanceString__components = raw_balanceString.components(separatedBy: locale_decimalSeparator)
					if raw_balanceString__components.count == 1 {
						let balance_aspect_integer = raw_balanceString__components[0]
						if balance_aspect_integer == "0" {
							finalized_main_string = ""
							finalized_paddingZeros_string = "00" + locale_decimalSeparator + String(repeating: "0", count: display_coinUnitPlaces)
						} else {
							finalized_main_string = balance_aspect_integer + locale_decimalSeparator + "0"
							finalized_paddingZeros_string = String(repeating: "0", count: display_coinUnitPlaces - 1/*for ".0"*/)
						}
					} else if raw_balanceString__components.count == 2 {
						finalized_main_string = raw_balanceString
						let decimalComponent = raw_balanceString__components[1]
						let decimalComponent_length = decimalComponent.count
						if decimalComponent_length < display_coinUnitPlaces {
							finalized_paddingZeros_string = String(repeating: "0", count: display_coinUnitPlaces - decimalComponent_length)
						}
					} else {
						assert(false, "Couldn't parse formatted balance string.")
						finalized_main_string = raw_balanceString
						finalized_paddingZeros_string = ""
					}
				}
				let attributes: [NSAttributedString.Key : Any] = [:]
				let attributedText = NSMutableAttributedString(string: "\(finalized_main_string)\(finalized_paddingZeros_string)", attributes: attributes)
				let mainSectionTextColor = self.mainSectionTextColor(withWallet: wallet)
				let secondarySectionTextColor = self.secondarySectionTextColor(withWallet: wallet)
				let displayCurrency_hasAtomicUnits = displayCurrency.hasAtomicUnits
				do {
					var finalizable_rangeLength = finalized_main_string.count
					if displayCurrency_hasAtomicUnits == false {
						finalizable_rangeLength += finalized_paddingZeros_string.count
					}
					let final_rangeLength = finalizable_rangeLength
					attributedText.addAttributes(
						[
							NSAttributedString.Key.foregroundColor: mainSectionTextColor,
						],
						range: NSMakeRange(0, final_rangeLength)
					)
					if displayCurrency_hasAtomicUnits {
						if finalized_paddingZeros_string.count > 0 {
							attributedText.addAttributes(
								[
									NSAttributedString.Key.foregroundColor: secondarySectionTextColor,
								],
								range: NSMakeRange(
									finalized_main_string.count,
									attributedText.string.count - finalized_main_string.count
								)
							)
						}
					}
					//
					// currency suffix
					if displayCurrency != .XMR {
						let string = " " + displayCurrency.symbol
						let attrString = NSAttributedString(
							string: string,
							attributes:
							[
								NSAttributedString.Key.foregroundColor: secondarySectionTextColor // secondary to annotate value itself
							]
						)
						attributedText.append(attrString)
					}
				}
				self.label.textColor = secondarySectionTextColor // for the '…' during truncation
				self.label.attributedText = attributedText
				self._configureBackgroundColor(withWallet: wallet)
			}
			fileprivate func set(utilityText text: String, withWallet wallet: Wallet)
			{
				self.label.textColor = self.mainSectionTextColor(withWallet: wallet)
				self.label.text = text
				self._configureBackgroundColor(withWallet: wallet)
			}
			func _configureBackgroundColor(withWallet wallet: Wallet)
			{
				self.image = type(of: self).stretchableBackgroundImage(forSwatchColor: wallet.swatchColor ?? Wallet.SwatchColor.blue)
			}
			//
			// Delegation - Interactions
			@objc func did_longPress(_ recognizer: UIGestureRecognizer)
			{
				guard recognizer.state == .began else { // instead of .recognized - so user knows asap that it's long-pressable
					return
				}
				guard let recognizerView = recognizer.view else {
					return
				}
				guard let recognizerSuperView = recognizerView.superview else {
					return
				}
				guard recognizerView.becomeFirstResponder() else {
					return
				}
				let menuController = UIMenuController.shared
				menuController.setTargetRect(recognizerView.frame, in: recognizerSuperView)
				menuController.setMenuVisible(true, animated:true)
			}
		}
	}
}
