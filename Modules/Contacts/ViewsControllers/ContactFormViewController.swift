//
//  ContactFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/29/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
class ContactFormViewController: UICommonComponents.FormViewController
{
	//
	// Properties
	//
	// Lifecycle - Init
	override init()
	{
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func setup_views()
	{
		super.setup_views()
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		let item = UICommonComponents.NavigationBarButtonItem(
			type: .save,
			target: self,
			action: #selector(tapped_rightBarButtonItem),
			title_orNilForDefault: nil
		)
		self.navigationItem.rightBarButtonItem = item
	}
	//
	// Accessors - Overridable
	override func new_isFormSubmittable() -> Bool
	{
//		if self.isSubmitting == true {
//			return false
//		}
		return true
	}
	//
	// Runtime - Imperatives - Overrides
	override func disableForm()
	{
		super.disableForm()
		//
		self.scrollView.isScrollEnabled = false
		//
		// TODO
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		// TODO
	}
	var isSubmitting = false
	override func _tryToSubmitForm()
	{

	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		let textField_w = self.new__textField_w
		
//		self.address_label.frame = CGRect(
//			x: CGFloat.form_label_margin_x,
//			y: self.name_inputView.frame.origin.y + self.name_inputView.frame.size.height + UICommonComponents.FormLabel.marginAboveLabelForUnderneathField_textInputView,
//			width: textField_w,
//			height: self.address_label.frame.size.height
//		).integral
//		self.address_inputView.frame = CGRect(
//			x: CGFloat.form_input_margin_x,
//			y: self.address_label.frame.origin.y + self.address_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
//			width: textField_w,
//			height: self.address_inputView.frame.size.height
//		).integral
		//
//		self.formContentSizeDidChange(withBottomView: self.walletColorPicker_inputView, bottomPadding: self.topPadding)
	}
	override func viewDidAppear(_ animated: Bool)
	{
		let isFirstAppearance = self.hasAppearedBefore == false
		super.viewDidAppear(animated)
		if isFirstAppearance {
			DispatchQueue.main.async
			{ [unowned self] in
				assert(false) // TODO
//				self.name_inputView.textView.becomeFirstResponder()
			}
		}
	}
	//
	// Delegation - UITextView
	func textView(
		_ textView: UITextView,
		shouldChangeTextIn range: NSRange,
		replacementText text: String
		) -> Bool
	{
		if text == "\n" { // simulate single-line input
			return self.aField_shouldReturn(textView, returnKeyType: textView.returnKeyType)
		}
		return true
	}
	//
	// Delegation - Interactions
	func tapped_rightBarButtonItem()
	{
		assert(false) // TODO save
	}

}
