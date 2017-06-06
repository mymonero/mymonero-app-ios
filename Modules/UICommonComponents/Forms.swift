//
//  Forms.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

// TODO: scrolling to field/textarea on field focus

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
			height: CGFloat(33)
		)
		super.init(frame: frame)
		self.placeholder = placeholder
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
		let backgroundImage = UIImage(named: "textField_bg_error_xStretchable")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
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
		let backgroundImage = UIImage(named: "textField_bg_noErr_xStretchable")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
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
