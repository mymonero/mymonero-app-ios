//
//  Forms.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
// TODO: scrolling to field/textarea on field focus where necessary, parent sizing w/inset
//
extension UIView
{ // this should probably be moved out
	func resignCurrentFirstResponder()
	{
		if let responder = self.currentFirstResponder {
			responder.resignFirstResponder()
		}
	}
	var currentFirstResponder: UIResponder?
	{
		if self.isFirstResponder {
			return self
		}
		for view in self.subviews {
			if let responder = view.currentFirstResponder {
				return responder
			}
		}
		return nil
	}
}
//
extension UICommonComponents
{
	class FormViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate
	{
		//
		// Properties - Cached
		//
		// Properties - Derived
		var scrollView: UIScrollView { return self.view as! UIScrollView }
		var new__textField_w: CGFloat { return self.view.frame.size.width - 2 * CGFloat.form_input_margin_x }
		//
		// Lifecycle - Init
		init()
		{
			super.init(nibName: nil, bundle: nil)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.setup_views() // must be before _navigation b/c that may rely on _views
			self.setup_navigation()
		}
		override func loadView()
		{
			self.view = UIScrollView()
			self.scrollView.delegate = self
		}
		func setup_views()
		{ // override but call on super
			do {
				self.view.backgroundColor = UIColor.contentBackgroundColor
			}
			do {
				let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
				self.view.addGestureRecognizer(tapGestureRecognizer)
			}
		}
		func setup_navigation()
		{ // override but call on super
		}
		//
		// Runtime - Accessors - State - Overridable
		func new_isFormSubmittable() -> Bool
		{
			DDLog.Warn("UICommonComponents", "Override \(#function)")
			return true
		}
		//
		// Runtime - Accessors - Form fields - Overridable
		func nextInputFieldViewAfter(inputView: UIView) -> UIView?
		{ // for automated field advancing (if you use returnKeyType=.next)
			assert(false, "Override and implement this method")
			return nil
		}
		//
		// Runtime - Imperatives - State
		func set_isFormSubmittable_needsUpdate()
		{
			let isFormSubmittable =
				self.isFormEnabled && self.isFormSubmitting == false && self.new_isFormSubmittable()
			if let item = self.navigationItem.rightBarButtonItem {
				item.isEnabled = isFormSubmittable
			}
		}
		//
		// Runtime - Imperatives - Convenience/Overridable - Submission
		func _tryToSubmitForm()
		{
			assert(false, "Override and implement \(#function)")
		}
		//
		var isFormEnabled = true
		func disableForm()
		{
			self.isFormEnabled = false
			self.set_isFormSubmittable_needsUpdate()
		}
		func reEnableForm()
		{
			self.isFormEnabled = true
			self.set_isFormSubmittable_needsUpdate()
		}
		//
		var isFormSubmitting = false
		func set(isFormSubmitting: Bool)
		{
			self.isFormSubmitting = isFormSubmitting
			self.set_isFormSubmittable_needsUpdate()
		}
		//
		// Runtime - Imperatives - Convenience/Overridable - Validation error
		func setValidationMessage(_ message: String)
		{
			assert(false, "override \(#function)")
		}
		func clearValidationMessage()
		{
			assert(false, "override \(#function)")
		}
		//
		// Delegation - Scrollview
		func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
		{
			self.view.resignCurrentFirstResponder()
		}
		//
		// Delegation - Gesture recognition
		@objc func tapped()
		{
			self.view.resignCurrentFirstResponder()
		}
		//
		// Delegation - Internal/Convenience - Scroll view
		func formContentSizeDidChange(withBottomView bottomView: UIView, bottomPadding: CGFloat)
		{
			self.scrollView.contentSize = CGSize(
				width: self.view.frame.size.width,
				height: bottomView.frame.origin.y + bottomView.frame.size.height + bottomPadding
			)
		}
		//
		// Delegation - Internal/Convenience - UITextFieldDelegate
		func textFieldShouldReturn(_ textField: UITextField) -> Bool
		{
			return self.aField_shouldReturn(textField, returnKeyType: textField.returnKeyType)
		}
		//
		// Delegation - Internal/Convenience - Field interactions
		func aField_editingChanged()
		{
			self.set_isFormSubmittable_needsUpdate()
		}
		func aField_shouldReturn(_ inputView: UIView, returnKeyType: UIReturnKeyType) -> Bool
		{
			switch returnKeyType {
				case .go:
					self.aField_didReturnWithKey_go(inputView)
					return false
				case .next:
					self.aField_didReturnWithKey_next(inputView)
					break
				default:
					assert(false, "Unrecognized return key type")
					break
				}
			return true
		}
		func aField_didReturnWithKey_go(_ inputView: UIView)
		{
			if self.navigationItem.rightBarButtonItem!.isEnabled {
				self._tryToSubmitForm()
			}
		}
		func aField_didReturnWithKey_next(_ inputView: UIView)
		{
			if let next_inputView = self.nextInputFieldViewAfter(inputView: inputView) {
				next_inputView.becomeFirstResponder()
			}
		}
		//
		// Delegation - Internal/Convenience - Form submission
		func aFormSubmissionButtonWasPressed()
		{
			self._tryToSubmitForm()
		}
	}
}
//
extension UICommonComponents
{
	enum FormInputCells: String
	{
		case textField_bg_noErr = "textField_bg_noErr_stretchable"
		case textField_bg_error = "textField_bg_error_stretchable"
		//
		static var imagePadding_y: CGFloat { return 2 }
		//
		var stretchableImage: UIImage
		{
			return UIImage(named: self.rawValue)!
				.stretchableImage(withLeftCapWidth: 5, topCapHeight: 5)
		}
	}
	class FormTextViewContainerView: UIView
	{
		var textView: FormTextView!
		let stretchableBackgroundImage = FormInputCells.textField_bg_noErr.stretchableImage
		//
		init(placeholder: String?)
		{
			let frame = CGRect(
				x: CGFloat(0),
				y: CGFloat(0),
				width: CGFloat(0),
				height: CGFloat(69)
			)
			self.textView = FormTextView(placeholder: placeholder)
			super.init(frame: frame)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder)
		{
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.backgroundColor = UIColor.clear
			self.addSubview(self.textView)
		}
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			let x: CGFloat = 1
			let top: CGFloat = FormInputCells.imagePadding_y + 2
			let bottom: CGFloat = FormInputCells.imagePadding_y + 2 // '+ k' so it fits visually within the 'well'
			self.textView.frame = CGRect(
				x: x,
				y: top,
				width: self.frame.size.width - 2*x,
				height: self.frame.size.height - top - bottom
			)
		}
		override func draw(_ rect: CGRect)
		{
			self.stretchableBackgroundImage.draw(in: rect)
			//
			super.draw(rect)
		}
	}
	class FormTextView: UITextView
	{
		var placeholder: String?
		var placeholderLabel: UILabel?
		init(placeholder: String?)
		{
			super.init(frame: .zero, textContainer: nil)
			self.placeholder = placeholder
			//
			self.setup()
		}
		required init?(coder aDecoder: NSCoder)
		{
			fatalError("init(coder:) has not been implemented")
		}
		var stretchableBackgroundImage = FormInputCells.textField_bg_noErr.stretchableImage
		func setup()
		{
			self.backgroundColor = UIColor.clear
			self.textColor = UIColor(rgb: 0xDFDEDF)
			self.font = UIFont.middlingLightMonospace
			self.textContainerInset = UIEdgeInsetsMake(6, 4, 0, 4)
			//
			if let placeholder = self.placeholder {
				let view = UILabel(frame: .zero)
				view.textColor = UIColor(rgb: 0x6B696B)
				view.font = UIFont.middlingLightMonospace
				view.text = placeholder
				self.addSubview(view)
				self.placeholderLabel = view
			}
			//
			// so as not to have to take control of the delegate
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(textViewDidChange),
				name: NSNotification.Name.UITextViewTextDidChange,
				object: nil
			)
		}
		//
		// Lifecycle - Deinit
		deinit
		{
			NotificationCenter.default.removeObserver(
				self,
				name: NSNotification.Name.UITextViewTextDidChange,
				object: nil
			)
		}
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			if let placeholderLabel = self.placeholderLabel {
				let x = self.textContainer.lineFragmentPadding + self.textContainerInset.left
				let y = self.textContainerInset.top
				let w = self.frame.width - 2*x
				placeholderLabel.frame = CGRect(x: x, y: y, width: w, height: 0)
				placeholderLabel.sizeToFit() // to get h
			}
		}
		//
		// Delegation
		@objc func textViewDidChange()
		{
			if let placeholderLabel = self.placeholderLabel {
				placeholderLabel.isHidden = self.text.characters.count > 0
			}
		}
	}
	class FormInputField: UITextField
	{
		var validationErrorMessageLabel: FormFieldAccessoryMessageLabel?
		//
		init(placeholder: String?)
		{
			let frame = CGRect(
				x: CGFloat(0),
				y: CGFloat(0),
				width: CGFloat(0),
				height: CGFloat(37)
			)
			super.init(frame: frame)
			if placeholder != nil {
				let string = NSMutableAttributedString(string: placeholder!)
				string.addAttribute(
					NSForegroundColorAttributeName,
					value: UIColor(rgb: 0x6B696B),
					range: NSRange(location: 0, length: placeholder!.characters.count)
				)
				self.attributedPlaceholder = string
			}
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.font = UIFont.middlingLightMonospace
			self.textColor = UIColor(rgb: 0xDFDEDF)
			//
			self.borderStyle = .none
			self.configureWithValidationError(nil)
		}
		//
		// Accessors - Overrides
		override func textRect(forBounds bounds: CGRect) -> CGRect
		{ // placeholder position
			return bounds.insetBy(dx: 8, dy: 8)
		}
		override func editingRect(forBounds bounds: CGRect) -> CGRect
		{ // text position
			return bounds.insetBy(dx: 8, dy: 8)
		}
		//
		// Imperatives - Validation errors
		func setValidationError(_ message: String)
		{
			if message == "" {
				self.clearValidationError()
				return
			}
			let backgroundImage = FormInputCells.textField_bg_error.stretchableImage
			self.background = backgroundImage
			if self.validationErrorMessageLabel == nil {
				let view = FormFieldAccessoryMessageLabel(text: nil)
				view.textColor = UIColor.standaloneValidationTextOrDestructiveLinkContentColor
				self.validationErrorMessageLabel = view
				self.addSubview(view)
			}
			self.validationErrorMessageLabel!.setMessageText(message)
			self.setNeedsLayout()
		}
		func clearValidationError()
		{
			let backgroundImage = FormInputCells.textField_bg_noErr.stretchableImage
			self.background = backgroundImage
			//
			if self.validationErrorMessageLabel != nil {
				self.validationErrorMessageLabel!.removeFromSuperview()
				self.validationErrorMessageLabel = nil
			}
		}
		func configureWithValidationError(_ message: String?)
		{
			if message == nil {
				self.clearValidationError()
			} else {
				self.setValidationError(message!)
			}
		}
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			if let validationErrorMessageLabel = self.validationErrorMessageLabel {
				let margin_x: CGFloat = 8
				let margin_y: CGFloat = 8
				let frame = CGRect(
					x: margin_x,
					y: self.frame.size.height + margin_y,
					width: self.frame.size.width - 2 * margin_x,
					height: 0
				)
				validationErrorMessageLabel.frame = frame
				validationErrorMessageLabel.sizeToFit()
			}
		}
	}
	//
	class FormLabel: UILabel
	{
		static let visual_marginBelow: CGFloat = 7
		static let marginBelowLabelAboveTextInputView: CGFloat = FormLabel.visual_marginBelow - FormInputCells.imagePadding_y

		static let visual_marginAboveLabelForUnderneathField: CGFloat = 13
		static let marginAboveLabelForUnderneathField_textInputView: CGFloat = FormLabel.visual_marginAboveLabelForUnderneathField - FormInputCells.imagePadding_y
		
		init(title: String, sizeToFit: Bool? = false)
		{
			let frame = CGRect(
				x: CGFloat(0),
				y: CGFloat(0),
				width: CGFloat(0),
				height: CGFloat(13)
			)
			super.init(frame: frame)
			self.text = title
			self.setup()
			if sizeToFit == true { // after receiving style
				self.sizeToFit()
			}
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.font = UIFont.smallRegularMonospace
			self.textColor = UIColor(rgb: 0xF8F7F8)
			self.numberOfLines = 1
		}
	}
	//
	class FormFieldAccessoryMessageLabel: UILabel
	{
		init(text: String?)
		{
			super.init(frame: .zero)
			self.setup()
			if text != nil {
				self.setMessageText(text!)
			}
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.font = UIFont.messageBearingSmallLightMonospace
			self.textColor = UIColor(rgb: 0x8D8B8D)
			self.numberOfLines = 0
		}
		//
		func setMessageText(_ text: String)
		{
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.lineSpacing = 3
			let string = NSMutableAttributedString(string: text)
			string.addAttribute(
				NSParagraphStyleAttributeName,
				value: paragraphStyle,
				range: NSRange(location: 0, length: text.characters.count)
			)
			self.attributedText = string
		}
	}
}
