//
//  WalletPicker.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/5/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UICommonComponents
{
	class WalletPickerButtonView: UICommonComponents.PushButton
	{
		//
		// Constants
		static let listController = WalletsListController.shared
		static let records = listController.records // array instance never changes, but is mutated
		//
		static let visual__h: CGFloat = 66
		static let h = WalletPickerButtonView.visual__h + 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
		//
		static let visual__arrowRightPadding: CGFloat = 16
		//
		// Properties
		var tapped_fn: ((Void) -> Void)?
		var selectedWallet: Wallet?
		var pickerView: WalletPickerView!
		var picker_inputField: UITextField!
		var contentView = WalletCellContentView(sizeClass: .medium32)
		//
		// Lifecycle - Init
		init(selectedWallet: Wallet?)
		{
//			assert(WalletPickerButtonView.records.count > 0) // not actually going to assert this, b/c the Send view will need to be able to have this set up w/o any wallets being available yet
			if selectedWallet != nil {
				self.selectedWallet = selectedWallet!
			} else {
				self.selectedWallet = WalletPickerButtonView.records.first as? Wallet
			}
			super.init(pushButtonType: .utility)
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup()
		{
			super.setup()
			//
			do {
				let view = WalletPickerView()
				view.didSelect_fn =
				{ [unowned self] (wallet) in
					self.selectedWallet = wallet
					self.contentView.configure(withObject: wallet)
					// TODO/NOTE: bubble if necessary
				}
				view.reloaded_fn =
				{ [unowned self] in
					if let _ = self.selectedWallet {
						let records = WalletPickerButtonView.records
						if records.count == 0 { // e.g. booted state deconstructed
							self.selectedWallet = nil
							if self.picker_inputField.isFirstResponder {
								self.picker_inputField.resignFirstResponder()
							}
							self.contentView.prepareForReuse()
							return
						}
//						if records.contains(selectedWallet) == false { // if the selected wallet no longer exists
//							// we don't need to do anything here, b/c the following will update state
//						}
					}
					let picker_selectedWallet = self.pickerView.selectedWallet
					if self.selectedWallet != picker_selectedWallet {
						if self.selectedWallet != nil {
							self.contentView.configure(withObject: self.selectedWallet!)
						} else {
							self.contentView.prepareForReuse() // might as well call it even though it will have handled
						}
					}
				}
				self.pickerView = view
			}
			do {
				let view = UITextField(frame: .zero) // invisible - and possibly wouldn't work if hidden
				view.inputView = pickerView
				self.picker_inputField = view
				self.addSubview(view)
			}
			do {
				let view = self.contentView
				view.isUserInteractionEnabled = false // pass touches through to self
				self.addSubview(view)
			}
			if self.selectedWallet != nil {
				self.configure(withRecord: self.selectedWallet!)
			}
			//
			let image = UIImage(named: "dropdown-arrow-down")!
			self.setImage(image, for: .normal)
			//
			self.contentHorizontalAlignment = .left
			self.titleEdgeInsets = UIEdgeInsetsMake(0, 1, 0, 0)
			//
			self.frame = CGRect(
				x: 0,
				y: 0,
				width: 0,
				height: WalletPickerButtonView.h
			)
			//
			self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
		}
		//
		// Accessors
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			let iconImageColumn_w = self.image(for: .normal)!.size.width + WalletPickerButtonView.visual__arrowRightPadding
			self.contentView.frame = CGRect(
				x: UICommonComponents.PushButtonCells.imagePaddingForShadow_h,
				y: UICommonComponents.PushButtonCells.imagePaddingForShadow_v,
				width: self.frame.size.width - 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_h - iconImageColumn_w,
				height: self.frame.size.height - 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
			)
			//
			self.imageEdgeInsets = UIEdgeInsetsMake(
				1,
				self.frame.size.width - UICommonComponents.PushButtonCells.imagePaddingForShadow_h - iconImageColumn_w,
				0,
				WalletPickerButtonView.visual__arrowRightPadding + UICommonComponents.PushButtonCells.imagePaddingForShadow_h
			)
		}
		//
		// Imperatives - Config
		func configure(withRecord record: Wallet)
		{
			self.contentView.configure(withObject: record)
		}
		//
		// Delegation - Interactions
		var popover: EmojiPickerPopoverView?
		func tapped()
		{
			// the popover should be guaranteed not to be showing here…
			if let tapped_fn = self.tapped_fn {
				tapped_fn()
			}
			if self.picker_inputField.isFirstResponder {
				self.picker_inputField.resignFirstResponder()
			} else {
				self.picker_inputField.becomeFirstResponder()
			}
		}
	}
	//
	class WalletPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource
	{
		//
		// Constants
		static let listController = WalletsListController.shared
		static let records = listController.records // array instance never changes, but is mutated
		//
		// Properties
		var didSelect_fn: ((_ record: Wallet) -> Void)?
		var reloaded_fn: ((Void) -> Void)?
		//
		// Lifecycle
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
			self.backgroundColor = .contentBackgroundColor
			self.delegate = self
			self.dataSource = self
			//
			self.startObserving()
		}
		func startObserving()
		{
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(PersistedObjectListController_Notifications_List_updated),
				name: PersistedObjectListController.Notifications_List.updated.notificationName,
				object: WalletPickerView.listController
			)
		}
		//
		deinit
		{
			self.teardown()
		}
		func teardown()
		{
			self.stopObserving()
		}
		func stopObserving()
		{
			NotificationCenter.default.removeObserver(
				self,
				name: PersistedObjectListController.Notifications_List.updated.notificationName,
				object: WalletPickerView.listController
			)
		}
		//
		// Accessors
		var selectedWallet: Wallet? {
			let selectedIndex = self.selectedRow(inComponent: 0)
			if selectedIndex == -1 {
				return nil
			}
			return WalletPickerView.records[selectedIndex] as? Wallet
		}
		//
		// Delegation - UIPickerView
		func numberOfComponents(in pickerView: UIPickerView) -> Int
		{
			return 1
		}
		func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
		{
			return WalletPickerView.records.count
		}
		func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
		{
			return WalletPickerButtonView.h - 6 // i dunno where the 6 is coming from
		}
		func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
		{
			let record = WalletPickerView.records[row] as! Wallet
			if let fn = self.didSelect_fn {
				fn(record)
			}
		}
		func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat
		{
			let w = pickerView.frame.size.width - 2*CGFloat.form_input_margin_x
			//
			return w
		}
		func pickerView(
			_ pickerView: UIPickerView,
			viewForRow row: Int,
			forComponent component: Int,
			reusing view: UIView?
		) -> UIView
		{
			var mutable_view: UIView? = view
			if mutable_view == nil {
				mutable_view = WalletCellContentView(sizeClass: .medium32)
			}
			let cellView = mutable_view as! WalletCellContentView
			let record = WalletPickerView.records[row] as! Wallet
			cellView.configure(withObject: record)
			//
			return cellView
		}
		//
		// Delegation - Notifications
		func PersistedObjectListController_Notifications_List_updated()
		{
			self.reloadComponent(0)
			if let fn = self.reloaded_fn {
				fn()
			}
		}
	}
}
