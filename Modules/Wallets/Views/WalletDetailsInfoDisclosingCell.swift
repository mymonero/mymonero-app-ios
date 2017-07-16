//
//  WalletDetailsInfoDisclosingCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension WalletDetails
{
	struct InfoDisclosing
	{
		class Cell: UICommonComponents.Tables.ReusableTableViewCell
		{
			override class func reuseIdentifier() -> String {
				return "UICommonComponents.Details.WalletDetails.InfoDisclosing.Cell"
			}
			override class func height() -> CGFloat {
				assert(false, "Intentionally not implemented")
				return 5
			}
			// Declared instead for consumer (tableView)
			var cellHeight: CGFloat {
				if self.isDisclosed {
					return self.contentContainerView.frame.size.height // rely on having been sized already
				} else { // start with constant since we might not be sized yet
					return WalletDetails.InfoDisclosing.ContentContainerView.height__closed
				}
			}
			//
			// Properties - Internally managed
			var contentContainerView: ContentContainerView
			var isDisclosed: Bool {
				return self.contentContainerView.isDisclosed
			}
			//
			// Lifecycle - Init
			init(wantsMnemonicDisplay: Bool)
			{
				self.contentContainerView = ContentContainerView(wantsMnemonicDisplay: wantsMnemonicDisplay)
				super.init()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			required init() {
				fatalError("init() has not been implemented, use init(wantsMnemonicDisplay:) instead, which calls super.init()")
			}
			override func setup()
			{
				super.setup()
				do {
					self.selectionStyle = .none
					self.backgroundColor = UIColor.contentBackgroundColor
				}
				do {
					let view = self.contentContainerView
					self.contentView.addSubview(view)
				}
			}
			//
			// Overrides
			override func layoutSubviews()
			{
				super.layoutSubviews()
			}
			override func _configureUI()
			{
				let configuration = self.configuration!
				let wallet = configuration.dataObject as? Wallet
				if wallet == nil {
					assert(false)
					return
				}
				if wallet!.didFailToInitialize_flag == true || wallet!.didFailToBoot_flag == true {
					return
				} else {
					self.contentContainerView.set(infoWithWallet: wallet!)
				}
			}
			//
			// Imperatives - Disclosure
			func toggleDisclosureAndPrepareToAnimate_returningContentContainerViewFrame() -> CGRect
			{
				return self.contentContainerView.toggleDisclosureAndPrepareToAnimate_returningNewSelfFrame()
			}
			func configureForJustToggledDisclosureState(animated: Bool)
			{
				self.contentContainerView.configureForJustToggledDisclosureState(animated: animated)
			}
		}
		
		class InfoDisclosing_CopyableLongStringFieldView: UICommonComponents.Details.CopyableLongStringFieldView
		{
			override var contentInsets: UIEdgeInsets {
				return UIEdgeInsetsMake(17, 44, 17, 16)
			}
		}
		class InfoDisclosing_Truncated_CopyableLongStringFieldView: InfoDisclosing_CopyableLongStringFieldView
		{
			override var contentInsets: UIEdgeInsets {
				return UIEdgeInsetsMake(17, 44, 12, 16)
			}
			override func setup()
			{
				super.setup()
				do {
					let view = self.contentLabel!
					view.numberOfLines = 1 // special case
					view.lineBreakMode = .byTruncatingTail
				}
			}
			override func layOut_contentLabel(
				content_x: CGFloat,
				content_w: CGFloat
			)
			{
				let x: CGFloat = 73
				self.contentLabel.frame = CGRect(
					x: x,
					y: self.titleLabel.frame.origin.y - 3,
					width: content_w - x,
					height: 19
				)
			}

		}
		
		class ContentContainerView: UICommonComponents.Details.SectionContentContainerView
		{
			//
			// Constants
			static let height__closed: CGFloat = 47
			//
			// Properties
			var isDisclosed = false
			let arrowIconView = UIImageView(image: UIImage(named: "disclosureArrow_icon")!)
			//
			let truncated__fieldView_address = InfoDisclosing_Truncated_CopyableLongStringFieldView(
				labelVariant: .middling,
				title: NSLocalizedString("Address", comment: ""),
				valueToDisplayIfZero: nil
			)
			//
			let disclosed__fieldView_address = InfoDisclosing_CopyableLongStringFieldView(
				labelVariant: .middling,
				title: NSLocalizedString("Address", comment: ""),
				valueToDisplayIfZero: nil
			)
			let disclosed__fieldView_viewKey = InfoDisclosing_CopyableLongStringFieldView(
				labelVariant: .middling,
				title: NSLocalizedString("Secret View Key", comment: ""),
				valueToDisplayIfZero: nil
			)
			let disclosed__fieldView_spendKey = InfoDisclosing_CopyableLongStringFieldView(
				labelVariant: .middling,
				title: NSLocalizedString("Secret Spend Key", comment: ""),
				valueToDisplayIfZero: nil
			)
			let disclosed__fieldView_mnemonic = InfoDisclosing_CopyableLongStringFieldView(
				labelVariant: .middling,
				title: NSLocalizedString("Secret Mnemonic", comment: ""),
				valueToDisplayIfZero: nil
			)
			//
			// Lifecycle - Init
			var wantsMnemonicDisplay: Bool
			init(wantsMnemonicDisplay: Bool)
			{
				self.wantsMnemonicDisplay = wantsMnemonicDisplay
				super.init()
				self.addSubview(self.arrowIconView)
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			//
			// Accessors
			var _new_fieldViews: [UICommonComponents.Details.FieldView] {
				if self.isDisclosed == false {
					return [
						self.truncated__fieldView_address
					]
				} else {
					var fieldViews: [UICommonComponents.Details.FieldView] = [
						self.disclosed__fieldView_address,
						self.disclosed__fieldView_viewKey,
						self.disclosed__fieldView_spendKey
					]
					if self.wantsMnemonicDisplay {
						fieldViews.append(self.disclosed__fieldView_mnemonic)
					}
					return fieldViews
				}
			}
			//
			// Imperatives
			func set(infoWithWallet wallet: Wallet)
			{
				self._configureFieldViews(withWallet: wallet)
				self.regenerateArrayOfFieldViews()
				self.frame = self.sizeAndLayOutSubviews_returningSelfFrame()
			}
			func _configureFieldViews(withWallet wallet: Wallet)
			{
				self.truncated__fieldView_address.set(text: wallet.public_address)
				self.disclosed__fieldView_address.set(text: wallet.public_address)
				self.disclosed__fieldView_viewKey.set(text: wallet.private_keys.view)
				self.disclosed__fieldView_spendKey.set(text: wallet.private_keys.spend)
				if self.wantsMnemonicDisplay {
					self.disclosed__fieldView_mnemonic.set(text: wallet.mnemonicString!)
				}
			}
			func regenerateArrayOfFieldViews()
			{
				self.set(fieldViews: self._new_fieldViews)
			}
			//
			// Imperatives - Disclosure
			// I.
			func toggleDisclosureAndPrepareToAnimate_returningNewSelfFrame() -> CGRect
			{
				self.isDisclosed = !self.isDisclosed
				self.regenerateArrayOfFieldViews()
				//
				return self.sizeAndLayOutSubviews_returningSelfFrame()
			}
			// II.
			func configureForJustToggledDisclosureState(animated: Bool)
			{
				let configure: (Void) -> Void =
				{ [unowned self] in
					do { // arrow
						let degreesAngle: Double = self.isDisclosed ? 90 : 0
						let radiansAngle: Double = degreesAngle * .pi / 180
						self.arrowIconView.layer.transform = CATransform3DRotate(
							CATransform3DIdentity,
							CGFloat(radiansAngle), // rotation
							0,
							0,
							1
						)
					}
				}
				if animated {
					UIView.animate(withDuration: 0.2, animations: configure)
				} else {
					configure()
				}
			}
			//
			// Imperatives - Layout
			func sizeAndLayOutSubviews_returningSelfFrame() -> CGRect
			{
				let selfFrame = self.sizeToFitAndLayOutSubviews_butReturnInsteadOfModifyingSelfFrame(
					withContainingWidth: self.superview!.frame.size.width,
					andYOffset: 0
				)				
				return selfFrame
			}
			//
			// Imperatives - Overrides
			override func layoutSubviews()
			{
				super.layoutSubviews()
				self.arrowIconView.frame = CGRect(
					x: 19,
					y: 19,
					width: self.arrowIconView.frame.size.width,
					height: self.arrowIconView.frame.size.height
				)
			}
		}
	}
}
