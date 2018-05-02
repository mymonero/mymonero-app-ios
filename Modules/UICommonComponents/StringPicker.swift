//
//  StringPicker.swift
//  MyMonero
//
//  Created by Paul Shapiro on 10/19/17.
//  Copyright © 2014-2018 MyMonero. All rights reserved.
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

extension UICommonComponents.Form
{
	struct StringPicker {}
}
extension UICommonComponents.Form.StringPicker
{
	class PickerButtonView: UICommonComponents.PushButton, UITextFieldDelegate
	{
		//
		// Interface - Constants
		static let visual__h: CGFloat = UICommonComponents.FormInputField.visual__height
		static let h = PickerButtonView.visual__h + 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
		//
		static let visual__arrowRightPadding: CGFloat = 12
		static let label_insets_left: CGFloat = 12
		//
		// Properties
		var allValues: [String]
		//
		var tapped_fn: (() -> Void)?
		var picker_inputField_didBeginEditing: ((_ textField: UITextField) -> Void)?
		var selectedValue_fn: (() -> Void)?
		
		var selectedValue: String?
		var pickerView: UICommonComponents.Form.StringPicker.PickerView!
		var picker_inputField: UITextField!
		var contentView: UILabel!
		//
		// Lifecycle - Init
		init(selectedValue: String?, allValues: [String])
		{
			self.allValues = allValues
			//
			if selectedValue != nil {
				self.selectedValue = selectedValue!
			} else {
				self.selectedValue = self.allValues.first
			}
			//
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
				let view = PickerView(allValues: self.allValues)
				if self.selectedValue != nil {
					view.selectWithoutYielding(value: self.selectedValue!) // initial value
				}
				//
				view.didSelect_fn =
				{ [unowned self] (value) in
					self.set(
						selectedValue: value,
						skipSettingOnPickerView: true // because we got this from the picker view - avoid inf loop
					)
				}
				view.reloaded_fn =
				{ [unowned self] in
					do { // reconfigure /self/ with selected value, not picker
						if let _ = self.selectedValue {
							let values = self.allValues
							if values.count == 0 { // e.g. booted state deconstructed
								self.selectedValue = nil
								if self.picker_inputField.isFirstResponder {
									self.picker_inputField.resignFirstResponder()
								}
								//
								self.contentView.text = ""
								//
								return
							}
						} else {
							//							DDLog.Info("UICommonComponents.StringPicker", "Going to check selectedValue no currently selected value")
						}
						let picker_selectedValue = self.pickerView.selectedValue
						if picker_selectedValue == nil {
							self.contentView.text = "" // might as well call it even tho it will have been handled
							return
						}
						let selectedValue = picker_selectedValue!
						if self.selectedValue == nil || self.selectedValue! != selectedValue {
							self.selectedValue = selectedValue
							//
							self.contentView.text = selectedValue
						} else {
							DDLog.Warn("UICommonComponents.StringPicker", "reloaded but was same")
						}
					}
				}
				self.pickerView = view
			}
			do {
				let view = UITextField(frame: .zero) // invisible - and possibly wouldn't work if hidden
				view.delegate = self
				view.inputView = pickerView
				self.picker_inputField = view
				self.addSubview(view)
			}
			do {
				let view = UILabel(frame: .zero)
				self.contentView = view
				view.textColor = UIColor(rgb: 0xFCFBFC)
				view.font = UIFont.middlingMediumSansSerif
				view.numberOfLines = 1
				view.isUserInteractionEnabled = false // pass touches through to self
				self.addSubview(view)
			}
			if self.selectedValue != nil {
				self.configure(withValue: self.selectedValue!)
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
				height: PickerButtonView.h
			)
			//
			self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
		}
		//
		// Internal - Accessors
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			let iconImageColumn_w = self.image(for: .normal)!.size.width + PickerButtonView.visual__arrowRightPadding
			self.contentView.frame = CGRect(
				x: UICommonComponents.PushButtonCells.imagePaddingForShadow_h + type(of: self).label_insets_left,
				y: UICommonComponents.PushButtonCells.imagePaddingForShadow_v,
				width: self.frame.size.width - 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_h - iconImageColumn_w - type(of: self).label_insets_left,
				height: self.frame.size.height - 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
			)
			//
			self.imageEdgeInsets = UIEdgeInsetsMake(
				1,
				self.frame.size.width - UICommonComponents.PushButtonCells.imagePaddingForShadow_h - iconImageColumn_w,
				0,
				PickerButtonView.visual__arrowRightPadding + UICommonComponents.PushButtonCells.imagePaddingForShadow_h
			)
		}
		//
		// Imperatives - Config
		func set(
			selectedValue value: String,
			skipSettingOnPickerView: Bool = false // leave as false if you're setting from anywhere but the PickerView
		) {
			self.selectedValue = value
			self.configure(withValue: value)
			if skipSettingOnPickerView == false {
				self.pickerView.selectWithoutYielding(value: value)
			}
			if let fn = self.selectedValue_fn {
				fn()
			}
		}
		//
		func configure(withValue value: String)
		{
			self.contentView.text = value
		}
		//
		// Delegation - Interactions
		@objc func tapped()
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
		//
		// Delegation - UITextField
		func textFieldDidBeginEditing(_ textField: UITextField)
		{
			if textField == self.picker_inputField {
				self.picker_inputField_didBeginEditing?(textField)
			}
		}
	}
	//
	class PickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource
	{
		//
		// Constants
		
		//
		// Properties
		let allValues: [String] // immutable
		//
		var didSelect_fn: ((_ value: String) -> Void)?
		var reloaded_fn: (() -> Void)?
		//
		// Lifecycle
		init(allValues: [String])
		{
			self.allValues = allValues
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.backgroundColor = .customKeyboardBackgroundColor
			self.delegate = self
			self.dataSource = self
			//
			self.startObserving()
		}
		func startObserving()
		{
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
		}
		//
		// Accessors
		var label_insets_left: CGFloat = 8
		var selectedValue: String? {
			let selectedIndex = self.selectedRow(inComponent: 0)
			if selectedIndex == -1 {
				return nil
			}
			let values = self.allValues
			if values.count <= selectedIndex {
				DDLog.Warn("UICommonComponents", "StringPicker has non -1 selectedIndex but too few strings for the selectedIndex to be correct. Returning nil.")
				return nil
			}
			return values[selectedIndex]
		}
		//
		// Imperatives - Interface - Setting value externally
		func selectWithoutYielding(value: String)
		{
			let row = self.allValues.index(of: value)!
			self.selectRow(row, inComponent: 0, animated: false) // not pickValue(atRow:) b/c that will merely notify
		}
		//
		// Delegation - Yielding
		func didPickValue(atRow row: Int)
		{
			let record = self.allValues[row]
			if let fn = self.didSelect_fn {
				fn(record)
			}
		}
		//
		// Delegation - UIPickerView
		func numberOfComponents(in pickerView: UIPickerView) -> Int
		{
			return 1
		}
		func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
		{
			return self.allValues.count
		}
		func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
		{
			return PickerCellView.h
		}
		func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
		{
			self.didPickValue(atRow: row)
		}
		func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat
		{
			let safeAreaInsets = pickerView.polyfilled_safeAreaInsets
			let w = pickerView.frame.size.width - safeAreaInsets.left - safeAreaInsets.right - 2*CGFloat.form_input_margin_x - self.label_insets_left
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
				mutable_view = PickerCellView()
			}
			let cellView = mutable_view as! PickerCellView
			let value = self.allValues[row]
			cellView.configure(withValue: value)
			//
			return cellView
		}
		//
		// Delegation - Notifications
		@objc func PersistedObjectListController_Notifications_List_updated()
		{
			self.reloadAllComponents()
			if let fn = self.reloaded_fn {
				fn()
			}
		}
	}
	//
	//
	class PickerCellView: UIView
	{
		//
		// Interface - Constants
		static let h: CGFloat = 42
		//
		// Internal - Properties
		var label = UILabel()
		//
		// Interface - Init
		init()
		{
			super.init(frame: .zero)
			//
			self.setup()
		}
		//
		// Internal - Init
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.backgroundColor = .customKeyboardBackgroundColor
			do {
				let view = UILabel(frame: .zero)
				self.label = view
				view.textColor = UIColor(rgb: 0xFCFBFC)
				view.font = UIFont.keyboardContentSemiboldSansSerif
				view.numberOfLines = 1
				view.textAlignment = .center
				self.addSubview(view)
			}
		}
		//
		// Interface - Imperatives
		func configure(withValue value: String)
		{
			self.label.text = value
		}
		//
		// Overrides - Imperatives
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			self.label.frame = self.bounds
		}
	}
}
