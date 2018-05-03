//
//  CurrencyPicker.swift
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
//
extension UICommonComponents.Form.Amounts
{
	struct CurrencyPicker {}
}
//
extension UICommonComponents.Form.Amounts.CurrencyPicker
{
	class PickerButton: UIButton
	{
		//
		// Common - Constants
		static let disclosureArrow_w: CGFloat = 8
		static let disclosureArrow_margin_right: CGFloat = 6
		static let disclosureArrow_margin_left: CGFloat = 6
		static let selectText_margin_left: CGFloat = 7
		static let selectText_w: CGFloat = 30
		static let fixedWidth: CGFloat
			= selectText_margin_left + selectText_w + disclosureArrow_margin_left + disclosureArrow_w + disclosureArrow_margin_right
		//
		// Interface - Properties
		var selectedCurrency: CcyConversionRates.Currency = SettingsController.shared.displayCurrency
		var didUpdateSelection_fn: (() -> Void)?
		//
		// Internal - Properties
		var mask_shapeLayer: CAShapeLayer!
		var pickerView: PickerView!
		var picker_inputField: UITextField!
		//
		// Interface - Lifecycle
		init()
		{
			super.init(frame: .zero) // whoever instantiates is responsible for sizing even tho cornerRadius is fixed within self… maybe time to bring size in 
			self.setup()
		}
		//
		// Internal - Lifecycle
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.setup_layerMask()
			//
			self.titleEdgeInsets = UIEdgeInsetsMake(
				0,
				-PickerButton.selectText_w + PickerButton.selectText_margin_left,
				0,
				0//PickerButton.disclosureArrow_margin_left + PickerButton.disclosureArrow_w + PickerButton.disclosureArrow_margin_right
					//+ 4 // not sure why this is necessary - basically a difference to JS/HTML
			)
			self.titleLabel!.textAlignment = .left
			self.titleLabel!.font = UIFont.smallSemiboldSansSerif
			self.setTitleColor(
				UIColor(rgb: 0xDFDEDF), // or 0x989698; TODO: obtain from theme controller / UIColor + listen
				for: .normal
			)
			//
			self.setImage(
				UIImage(named: "smallSelect_disclosureArrow")!,
				for: .normal
			)
			self.imageEdgeInsets = UIEdgeInsetsMake(
				0,
				PickerButton.selectText_margin_left + PickerButton.selectText_w + PickerButton.disclosureArrow_margin_left,
				0,
				0
			)
			//
			self.configureBackgroundColor()
			//
			do {
				let view = PickerView()
				view.didSelect_fn =
				{ [unowned self] (currency) in
					self.set(
						selectedCurrency: currency,
						skipSettingOnPickerView: true // because we got this from the picker view
					)
				}
				self.pickerView = view
			}
			do {
				let view = UITextField(frame: .zero) // invisible - and possibly wouldn't work if hidden
				view.inputView = self.pickerView
				self.picker_inputField = view
				self.addSubview(view)
			}
			do {
				self.configureTitleWith_selectedCurrency()
				self.pickerView.selectWithoutYielding(currencySymbol: self.selectedCurrency.symbol) // must do initial config!
			}
			do {
				self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
			}
		}
		func setup_layerMask()
		{
			let shapeLayer = CAShapeLayer()
			self.mask_shapeLayer = shapeLayer
			shapeLayer.frame = self.bounds
			shapeLayer.path = self._new_mask_cgPath
			self.layer.mask = shapeLayer
		}
		//
		// Overrides - Accessors/Derived Properties
		override open var isHighlighted: Bool {
			didSet {
				self.configureBackgroundColor()
			}
		}
		override open var isEnabled: Bool {
			didSet {
				self.configureBackgroundColor()
			}
		}
		//
		// Internal - Accessors/Constants
		let backgroundColor_normal = UICommonComponents.HighlightableCells.Variant.normal.visualEquivalentSemiOpaque_contentBackgroundColor
		let backgroundColor_highlighted = UICommonComponents.HighlightableCells.Variant.highlighted.contentBackgroundColor
		let backgroundColor_disabled = UICommonComponents.HighlightableCells.Variant.disabled.contentBackgroundColor
		//
		var _new_mask_cgPath: CGPath {
			return UIBezierPath(
				roundedRect: self.bounds,
				byRoundingCorners: [ .topRight, .bottomRight ],
				cornerRadii: CGSize(
					width: UICommonComponents.FormInputCells.background_outlineInternal_cornerRadius,
					height: UICommonComponents.FormInputCells.background_outlineInternal_cornerRadius
				)
			).cgPath
		}
		//
		// Overrides - Imperatives
		override func layoutSubviews()
		{
			super.layoutSubviews()
			self.mask_shapeLayer.frame = self.bounds // TODO: must this be updated?
			self.mask_shapeLayer.path = self._new_mask_cgPath // figure this must be updated since it involves the bounds
		}
		//
		// Internal - Imperatives
		func configureBackgroundColor()
		{
			self.backgroundColor = self.isEnabled ? self.isHighlighted ? self.backgroundColor_highlighted : self.backgroundColor_normal : self.backgroundColor_disabled
		}
		func configureTitleWith_selectedCurrency()
		{
			self.setTitle(self.selectedCurrency.symbol.uppercased(), for: .normal)
		}
		//
		// Imperatives - Config
		func set(
			selectedCurrency currency: CcyConversionRates.Currency,
			skipSettingOnPickerView: Bool = false // leave as false if you're setting from anywhere but the PickerView
		)
		{
			self.selectedCurrency = currency
			self.configureTitleWith_selectedCurrency()
			if skipSettingOnPickerView == false {
				self.pickerView.selectWithoutYielding(currencySymbol: currency.symbol)
			}
			//
			if let fn = self.didUpdateSelection_fn {
				fn()
			}
		}
		//
		// Delegation - Interactions
		@objc func tapped()
		{
			if self.picker_inputField.isFirstResponder {
				self.picker_inputField.resignFirstResponder()
				// TODO: or just return?
				//
			} else {
				self.picker_inputField.becomeFirstResponder()
			}
		}
	}
	//
	class PickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource
	{
		//
		// Properties
		var didSelect_fn: ((_ value: CcyConversionRates.Currency) -> Void)?
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
			// no changes to list expected
		}
		//
		// Accessors
		var selectedCurrency: CcyConversionRates.Currency { // always expecting a selection b/c list is predecided
			let selectedIndex = self.selectedRow(inComponent: 0)
			if selectedIndex == -1 {
				fatalError("CurrencyPicker selectedRow unexpectedly -1")
			}
			let records = self.rowValues
			if records.count <= selectedIndex {
				fatalError("CurrencyPicker.PickerView has non -1 selectedIndex but too few records for the selectedIndex to be correct.")
			}
			let selectedCurrencySymbol = records[selectedIndex] as CcyConversionRates.CurrencySymbol
			let selectedCurrency = CcyConversionRates.Currency(rawValue: selectedCurrencySymbol)! // we assume this is always correct b/c we got the symbols straight from the code, not external input
			//
			return selectedCurrency
		}
		var rowValues: [CcyConversionRates.CurrencySymbol] {
			return CcyConversionRates.Currency.lazy_allCurrencySymbols // b/c using allCurrencies and converting to raw values might be less efficient
		}
		//
		// Imperatives - Interface - Setting wallet externally
		func selectWithoutYielding(currencySymbol: CcyConversionRates.CurrencySymbol)
		{
			let rowIndex = self.rowValues.index(
				of: currencySymbol
			)!
			self.selectRow(
				rowIndex,
				inComponent: 0,
				animated: false
			) // not pickWallet(atRow:) b/c that will merely notify
		}
		//
		// Delegation - Yielding
		func didPick(rowAtIndex rowIndex: Int)
		{
			let record = self.rowValues[rowIndex] as CcyConversionRates.CurrencySymbol
			if let fn = self.didSelect_fn {
				let selectedCurrency = CcyConversionRates.Currency(rawValue: record)!
				fn(selectedCurrency)
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
			return CcyConversionRates.Currency.lazy_allCurrencies.count
		}
		func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
		{
			return PickerCellContentView.h
		}
		func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
		{
			self.didPick(rowAtIndex: row)
		}
		func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat
		{
			let safeAreaInsets = pickerView.polyfilled_safeAreaInsets // important…
			let w = pickerView.frame.size.width - safeAreaInsets.left - safeAreaInsets.right - 2*CGFloat.form_input_margin_x
			//
			return w
		}
		func pickerView(
			_ pickerView: UIPickerView,
			viewForRow row: Int,
			forComponent component: Int,
			reusing view: UIView?
		) -> UIView {
			var mutable_view: UIView? = view
			if mutable_view == nil {
				mutable_view = PickerCellContentView()
			}
			let cellView = mutable_view as! PickerCellContentView
			let record = self.rowValues[row] as CcyConversionRates.CurrencySymbol
			cellView.configure(withObject: record)
			//
			return cellView
		}
	}
	class PickerCellContentView: UIView
	{
		//
		// Interface - Constants
		static let h: CGFloat = 42
		//
		// Internal - Properties
		var label: UILabel!
		//
		// Interface - Init
		init()
		{
			super.init(frame: .zero)
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
				view.textAlignment = .center
				view.font = UIFont.keyboardContentSemiboldSansSerif
				view.textColor = UIColor(rgb: 0xF8F7F8) // TODO: obtain from theme controller / UIColor + listen
				self.label = view
				self.addSubview(view)
			}
		}
		//
		// Overrides - Layout
		override func layoutSubviews()
		{
			super.layoutSubviews()
			self.label.frame = self.bounds
		}
		//
		// Interface - Imperatives
		func configure(withObject object: CcyConversionRates.CurrencySymbol)
		{
			self.label.text = object
		}
	}
}
