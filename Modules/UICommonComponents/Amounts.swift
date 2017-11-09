//
//  Amounts.swift
//  MyMonero
//
//  Created by Paul Shapiro on 10/18/17.
//  Copyright © 2014-2017 MyMonero. All rights reserved.
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
extension UICommonComponents.Form
{
	struct Amounts {}
}
//
extension UICommonComponents.Form.Amounts
{
	//
	//
	// Fieldset
	//
	class InputFieldsetView: UIView
	{ // aka MoneroAmountEmittingMultiCurrencyInputFieldsetView
		//
		// Interface - Constants
		static let h: CGFloat = InputField.height
		//
		// Interface - Constants - Initialization Parameters / Modes
		enum EffectiveAmountLabelBehavior
		{
			case yieldingRawOrEffectiveMoneroOnlyAmount
			case yieldingRawUserInputParsedDouble
			case undefined // for cases where the label won't be showing anyway - maybe rename to .none or .off but then be sure to implement not displaying the label - nowhere in MyMonero spec (yet)
		}
		//
		// Interface - Properties
		var didUpdateValueAvailability_fn: (() -> Void)? // settable by consumers; this will be called when the ccyConversion rate changes and when the selected currency changes; to be observed by consumers, to provide hook for call to update e.g. the embedding form's submittability
		//
		// Internal - Properties
		let inputField = InputField()
		var effectiveMoneroAmountLabel: EffectiveMoneroAmountLabel?
		let currencyPickerButton = CurrencyPicker.PickerButton()
		var effectiveAmountLabel_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView?
		//
		var _initial_effectiveAmountLabelBehavior: EffectiveAmountLabelBehavior
		var _initial_effectiveAmountTooltipText_orNil: String?
		//
		// Lifecycle
		convenience init(effectiveAmountLabelBehavior: EffectiveAmountLabelBehavior)
		{
			self.init(
				effectiveAmountLabelBehavior: effectiveAmountLabelBehavior,
				effectiveAmountTooltipText_orNil: nil
			)
		}
		init(
			effectiveAmountLabelBehavior: EffectiveAmountLabelBehavior,
			effectiveAmountTooltipText_orNil: String?
		)
		{
			self._initial_effectiveAmountLabelBehavior = effectiveAmountLabelBehavior
			self._initial_effectiveAmountTooltipText_orNil = effectiveAmountTooltipText_orNil
			//
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			do {
				let view = self.inputField
				view.addTarget(self, action: #selector(inputField_editingChanged), for: .editingChanged)
				self.addSubview(view)
			}
			if self._initial_effectiveAmountLabelBehavior == .yieldingRawOrEffectiveMoneroOnlyAmount {
				let view = EffectiveMoneroAmountLabel(title: "") // empty, since by default, we're in xmr… but we'll config on setup anyway
				self.effectiveMoneroAmountLabel = view
				self.addSubview(view)
			}
			do {
				let view = self.currencyPickerButton
				view.didUpdateSelection_fn =
				{ [weak self] in
					guard let thisSelf = self else {
						return
					}
					thisSelf.__didUpdateCurrencySelection()
				}
				self.addSubview(view)
			}
			if self._initial_effectiveAmountTooltipText_orNil != nil && self._initial_effectiveAmountTooltipText_orNil != "" {
				let text = self._initial_effectiveAmountTooltipText_orNil!
				do {
					let view = UICommonComponents.TooltipSpawningLinkButtonView(
						tooltipText: text
					)
					view.willPresentTipView_fn =
					{ [weak self] in
						guard let thisSelf = self else {
							return
						}
						thisSelf.superview?/*ehhh this is PROBABLY ok*/.resignCurrentFirstResponder() // if any
					}
					view.isHidden = true // for now…
					self.effectiveAmountLabel_tooltipSpawn_buttonView = view
					self.addSubview(view)
				}
			}
			self.configure_effectiveMoneroAmountLabel()
			self.startObserving()
		}
		func startObserving()
		{
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(CcyConversionRates_Controller_didUpdateAvailabilityOfRates),
				name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(SettingsController__NotificationNames_Changed__displayCurrencySymbol),
				name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
				object: nil
			)
		}
		//
		// Lifecycle - Teardown
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
				name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
				object: nil
			)
			NotificationCenter.default.removeObserver(
				self,
				name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
				object: nil
			)

		}
		//
		// Interface - Imperatives
		func clear()
		{
			self.inputField.text = ""
			self.currencyPickerButton.set(
				selectedCurrency: SettingsController.shared.displayCurrency,
				skipSettingOnPickerView: false
			)
			self.configure_effectiveMoneroAmountLabel() // for good measure - jic
		}
		//
		// Internal - Imperatives - Configuration
		func configure_effectiveMoneroAmountLabel()
		{
			if self.effectiveMoneroAmountLabel == nil {
				return
			}
			func __hideEffectiveAmountUI()
			{
				self.effectiveMoneroAmountLabel!.isHidden = true
				self.effectiveAmountLabel_tooltipSpawn_buttonView?.isHidden = true
				//
				self.setNeedsLayout()
			}
			func __setTextOnAmountUI(
				title: String,
				shouldHide_tooltipButton: Bool
			)
			{
				self.effectiveMoneroAmountLabel!.text = title
				self.effectiveMoneroAmountLabel!.isHidden = false
				self.effectiveAmountLabel_tooltipSpawn_buttonView?.isHidden = shouldHide_tooltipButton // won't set if operand is nil due to ?
				//
				self.setNeedsLayout()
			}
			func __convenience_setLoadingTextAndHideTooltip()
			{
				__setTextOnAmountUI(
					title: NSLocalizedString("LOADING…", comment: ""),
					shouldHide_tooltipButton: true
				)
			}
			if self.inputField.isEmptyOrHasIncompleteNumber { // hide; reflow
				__hideEffectiveAmountUI()
				return
			}
			let selectedCurrency = self.currencyPickerButton.selectedCurrency
			let displayCurrency = SettingsController.shared.displayCurrency
			if selectedCurrency == .XMR && displayCurrency == .XMR { // special case - no label necessary
				__hideEffectiveAmountUI()
				return
			}
			//
			let xmrAmountDouble_orNil = self.inputField.submittableMoneroAmountDouble_orNil(selectedCurrency: selectedCurrency)
			if xmrAmountDouble_orNil == nil {
				// but not empty … should have an amount… must be a non-XMR currency
				assert(selectedCurrency != .XMR)
				__convenience_setLoadingTextAndHideTooltip()
				return
			}
			let moneroAmount = MoneroAmount.new(withDouble: xmrAmountDouble_orNil!)
			var finalizable_text: String
			if selectedCurrency == .XMR {
				assert(displayCurrency != .XMR)
				let isRateReady = CcyConversionRates.Controller.shared.isRateReady(
					fromXMRToCurrency: displayCurrency
				)
				if isRateReady == false {
					__convenience_setLoadingTextAndHideTooltip()
					return
				}
				let displayCurrencyAmount = displayCurrency.displayUnitsRounded_amountInCurrency(
					fromMoneroAmount: moneroAmount
				)!
				finalizable_text = String(
					format: NSLocalizedString(
						"~ %@ %@",
						comment: ""
					),
					displayCurrency.nonAtomicCurrency_formattedString(final_amountDouble: displayCurrencyAmount),
					displayCurrency.symbol
				)
			} else {
				finalizable_text = String(
					format: NSLocalizedString(
						"= %@ %@",
						comment: ""
					),
					moneroAmount.humanReadableString,
					CcyConversionRates.Currency.XMR.symbol
				)
			}
			let final_text = finalizable_text
			__setTextOnAmountUI(
				title: final_text,
				shouldHide_tooltipButton: false
			)
		}
		//
		// Overrides - Layout
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			self.inputField.frame = CGRect(
				x: 0,
				y: 0,
				width: InputField.w,
				height: InputField.height
			)
			let inputCell_imagePadding_x = UICommonComponents.FormInputCells.imagePadding_x
			let inputCell_imagePadding_y = UICommonComponents.FormInputCells.imagePadding_y
			let background_outlineVisualThickness_h = UICommonComponents.FormInputCells.background_outlineVisualThickness_h
			let background_outlineVisualThickness_v = UICommonComponents.FormInputCells.background_outlineVisualThickness_v
			do {
				let currencyPickerButton_width = type(of: self.currencyPickerButton).fixedWidth
				self.currencyPickerButton.frame = CGRect(
					x: self.inputField.frame.origin.x + self.inputField.frame.size.width
						- currencyPickerButton_width
						- inputCell_imagePadding_x - background_outlineVisualThickness_h,
					y: self.inputField.frame.origin.y + inputCell_imagePadding_y
						+ background_outlineVisualThickness_v,
					width: currencyPickerButton_width,
					height: UICommonComponents.FormInputField.visual__height // has no imagePadding_* in it!
						-  1*background_outlineVisualThickness_v //and we'll only subtract 1 rather than 2 here for visual effect on its btm edge
				)
			}
			if let view = self.effectiveMoneroAmountLabel {
				if view.isHidden == false {
					view.sizeToFit() // for width
					//
					let margins_x: CGFloat = 8
					let x = self.inputField.frame.origin.x + self.inputField.frame.size.width + (margins_x - inputCell_imagePadding_x)
					let w = min(
						view.frame.size.width /* based on content */,
						self.bounds.size.width - x - margins_x // right side
					) // this way, we can still position a tooltip at the right side of the label
					view.frame = CGRect(
						x: x,
						y: self.inputField.frame.origin.y,
						width: w,
						height: self.inputField.frame.size.height // so it handles vertical centering. 1 line, after all
					)
				}
				if let buttonView = self.effectiveAmountLabel_tooltipSpawn_buttonView {
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					buttonView.frame = CGRect(
						x: view.frame.origin.x + view.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
						y: view.frame.origin.y - (tooltipSpawn_buttonView_h - view.frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
			}
		}
		//
		// Internal - Delegation - CurrencyPicker
		fileprivate func __didUpdateCurrencySelection()
		{
			self.configure_effectiveMoneroAmountLabel()
			//
			if let fn = self.didUpdateValueAvailability_fn { // also call this, b/c ccyConversion rate needs to be recalculated, and therefore, submittability of form may be updated
				fn()
			}
		}
		//
		// Delegation - Notifications
		@objc func CcyConversionRates_Controller_didUpdateAvailabilityOfRates()
		{
			self.configure_effectiveMoneroAmountLabel()
			if let fn = self.didUpdateValueAvailability_fn { // relatively self-explanatory
				fn()
			}
		}
		@objc func SettingsController__NotificationNames_Changed__displayCurrencySymbol()
		{
			self.configure_effectiveMoneroAmountLabel() // if selectedCurrency == .XMR, displayCurrency comes into effect
		}
		//
		// Delegation - Interactions
		@objc func inputField_editingChanged()
		{
			self.configure_effectiveMoneroAmountLabel()
		}
	}
	//
	//
	// Fieldset - Subcomponents
	//
	class InputField: UICommonComponents.FormInputField
	{
		//
		// Constants
		static let visual__w: CGFloat = 114 + UICommonComponents.Form.Amounts.CurrencyPicker.PickerButton.fixedWidth
		static let w: CGFloat = visual__w + 2*UICommonComponents.FormInputCells.imagePadding_x
		//
		// Properties - Interface
		//
		// Lifecycle
		init()
		{
			super.init(placeholder: "00.00")
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup()
		{
			super.setup()
			self.keyboardType = .decimalPad
			self.textAlignment = .right
		}
		//
		// Accessors - Internal - Layout
		func _new_insetTextRect(forBounds bounds: CGRect) -> CGRect
		{
			let right_addtlK: CGFloat = 0
			let pickerButton_fixedWidth = UICommonComponents.Form.Amounts.CurrencyPicker.PickerButton.fixedWidth
			let right = pickerButton_fixedWidth + right_addtlK
			//
			var mutable_bounds = bounds
			mutable_bounds.size.width -= right // accounting for currency select element
			let final_bounds = mutable_bounds
			//
			return final_bounds
		}
		//
		// Accessors - Overrides
		
		override func textRect(forBounds bounds: CGRect) -> CGRect
		{ // placeholder position (?)
			var mutable_bounds = super.textRect(forBounds: bounds)
			mutable_bounds = self._new_insetTextRect(forBounds: mutable_bounds)
			return mutable_bounds
		}
		override func editingRect(forBounds bounds: CGRect) -> CGRect
		{ // text position
			var mutable_bounds = super.editingRect(forBounds: bounds)
			mutable_bounds = self._new_insetTextRect(forBounds: mutable_bounds)
			return mutable_bounds
		}
		override func placeholderRect(forBounds bounds: CGRect) -> CGRect
		{
			var mutable_bounds = super.placeholderRect(forBounds: bounds)
			mutable_bounds = self._new_insetTextRect(forBounds: mutable_bounds)
			return mutable_bounds
		}
		//
		// Accessors
		var isEmpty: Bool {
			if self.text == nil || self.text! == "" {
				return true
			}
			return false
		}
		var isEmptyOrHasIncompleteNumber: Bool {
			if self.isEmpty || self.text! == "." {
				return true
			}
			return false
		}
		func hasInputButMoneroAmountIsNotSubmittable(
			selectedCurrency: CcyConversionRates.Currency
		) -> Bool
		{
			if self.isEmpty {
				return false // no input
			}
			let amountDouble = self.submittableMoneroAmountDouble_orNil(selectedCurrency: selectedCurrency)
			if amountDouble == nil {
				return true // has input but not submittable
			}
			return false // has input but is submittable
		}
		var hasInputButDoubleFormatIsNotSubmittable: Bool { // when you don't want/need to supply the selectedCurrent to hasInputButMoneroAmountIsNotSubmittable()
			if self.isEmpty {
				return false // no input
			}
			let amountDouble = self.submittableAmountRawDouble_orNil
			if amountDouble == nil {
				return true // has input but not submittable
			}
			return false // has input but is submittable
		}
		var submittableAmountRawDouble_orNil: Double? {
			if self.isEmpty {
				return nil
			}
			let rawUserInput_raw = self.text!
			let userInputAmountDouble = MoneyAmount.newDouble(withUserInputAmountString: rawUserInput_raw)
			if userInputAmountDouble == nil {
				return nil // incomplete or malformed input
			}			
			return userInputAmountDouble
		}
		func submittableMoneroAmountDouble_orNil(
			selectedCurrency: CcyConversionRates.Currency
		) -> Double?
		{ // ccyConversion approximation will be performed from user input
			guard let userInputAmountDouble = self.submittableAmountRawDouble_orNil else {
				return nil
			}
			if selectedCurrency == .XMR {
				return userInputAmountDouble // identity rate - NOTE: this is also the RAW non-truncated amount
			}
			let xmrAmountDouble = CcyConversionRates.Currency.rounded_ccyConversionRateCalculated_moneroAmountDouble(
				fromUserInputAmountDouble: userInputAmountDouble,
				fromCurrency: selectedCurrency
			)
			return xmrAmountDouble
		}
		//
		// Delegation - To be called manually by whoever instantiates the AmountInputFieldsetView
		func textField(
			_ textField: UITextField,
			shouldChangeCharactersIn range: NSRange,
			replacementString string: String
		) -> Bool
		{
			let decimalPlaceCharacter = "."
			do { // first check legal characters
				let aSet = NSCharacterSet(charactersIn:"0123456789\(decimalPlaceCharacter)").inverted
				let compSepByCharInSet = string.components(separatedBy: aSet)
				let numberFiltered = compSepByCharInSet.joined(separator: "")
				if string != numberFiltered {
					return false
				}
			}
			do { // disallow more than one decimal character
				let toString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
				let components = toString.components(separatedBy: decimalPlaceCharacter)
				if components.count > 2 {
					return false
				}
			}
			do { // disallow input which is toooo long. some values are out of spec
				if let text = textField.text {
					let newLength = text.characters.count + string.characters.count - range.length
					if newLength >= MoneroConstants.currency_unitPlaces + 2 + 1 { // I figure 14 numerals is a pretty good upper bound guess for inputs no matter what the currency… I might be wrong…
						return false
					}
				}
			}
			//
			return true
		}
	}
	//
	//
	class EffectiveMoneroAmountLabel: UILabel
	{ // TODO: This will be renamed and reimplemented to work as the "effective Monero amount display label"
		//
		// Properties - Static
		static let w: CGFloat = 100 // TODO: flexible with max? consumer should be responsible - that is, FieldsetView
		static let h: CGFloat = UICommonComponents.Form.Amounts.InputField.height // relying on vertical centering
		//
		// Lifecycle - Init
		init(title: String)
		{
			let frame = CGRect(x: 0, y: 0, width: type(of: self).w, height: type(of: self).h)
			super.init(frame: frame)
			self.text = title
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.font = UIFont.middlingRegularMonospace
			self.adjustsFontSizeToFitWidth = true
			self.minimumScaleFactor = 0.3
			self.textColor = UIColor(rgb: 0x9C9A9C)
			self.numberOfLines = 1
			self.textAlignment = .left
			self.lineBreakMode = .byTruncatingMiddle // undecided about this
			//
			self.isHidden = true // initially - consumer show at discretion
		}
	}
}
