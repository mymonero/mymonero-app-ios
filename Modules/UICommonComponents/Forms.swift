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
