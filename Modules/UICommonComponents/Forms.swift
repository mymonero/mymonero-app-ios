//
//  Forms.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
extension UICommonComponents
{
	class FormViewController: ScrollableValidatingInfoViewController,
		UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate
	{
		//
		// Constants
		static let fieldScrollDuration = 0.25
		//
		// Properties - Cached
		//
		// Properties - Derived
		var new__textField_w: CGFloat { return self.scrollView.frame.size.width - 2 * CGFloat.form_input_margin_x }
		var new__fieldLabel_w: CGFloat {
			return self.scrollView.frame.size.width - CGFloat.form_label_margin_x - CGFloat.form_input_margin_x
		}
		//
		// Lifecycle - Init
		override func setup_views()
		{ // override but call on super
			super.setup_views()
			self.view.backgroundColor = UIColor.contentBackgroundColor // prevent weird effects on nav/modal transitions
		}
		override func setup_scrollView()
		{
			super.setup_scrollView()
			do {
				self.scrollView.indicatorStyle = .white
			}
			do {
				let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
				recognizer.delegate = self
				self.scrollView.addGestureRecognizer(recognizer)
			}
		}
		override func startObserving()
		{ // override, but call on super
			super.startObserving()
			self.startObserving_keyboard()
		}
		func startObserving_keyboard()
		{
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(keyboardWillShow),
				name: Notification.Name.UIKeyboardWillShow,
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(keyboardWillHide),
				name: Notification.Name.UIKeyboardWillHide,
				object: nil
			)
		}
		override func stopObserving()
		{
			super.stopObserving()
			NotificationCenter.default.removeObserver(
				self,
				name: Notification.Name.UIKeyboardWillShow,
				object: nil
			)
			NotificationCenter.default.removeObserver(
				self,
				name: Notification.Name.UIKeyboardWillHide,
				object: nil
			)
		}
		//
		// Runtime - Accessors - Form components configuration
		func new_wantsBackgroundTapToFocusResponder_orNilToBlurInstead() -> UIResponder?
		{
			return nil
		}
		func new_wantsBGTapRecognizerToReceive_tapped(onView view: UIView) -> Bool
		{
			if view.canBecomeFirstResponder {
				return false
			}
			return true // default
		}
		//
		// Runtime - Accessors - State - Overridable
		func new_isFormSubmittable() -> Bool
		{
			DDLog.Warn("UICommonComponents", "Override \(#function)")
			assert(false)
			return true
		}
		//
		// Runtime - Accessors - Form fields - Overridable
		func nextInputFieldViewAfter(inputView: UIView) -> UIView?
		{ // for automated field advancing (if you use returnKeyType=.next)
			assert(false, "Override and implement this method")
			return nil
		}
		func new_contentInset() -> UIEdgeInsets
		{
			let bottom: CGFloat = self.keyboardIsShowing == true ? self.keyboardHeight! : 0
			//
			return UIEdgeInsetsMake(0, 0, bottom, 0)
		}
		//
		// Runtime - Imperatives - Scrolling
		var visibleScroll_rect: CGRect {
			let visibleScroll_size_height = (self.scrollView.bounds.size.height - scrollView.contentInset.top - scrollView.contentInset.bottom)
			let visibleScroll_size = CGSize(
				width: scrollView.bounds.size.width,
				height: visibleScroll_size_height
			)
			let visibleScroll_rect = CGRect(origin: scrollView.contentOffset, size: visibleScroll_size)
			//
			return visibleScroll_rect
		}
		
		func scrollInputViewToVisible(
			_ inputView: UIView
		)
		{
			var estimated__margin_y: CGFloat = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView + UICommonComponents.Form.FieldLabel.fixedHeight + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView
			do { // to finalize margin_y, in case it's not a direct subview of scrollView (e.g. UITextView inside container)
				var this_view = inputView
				var this_superview = this_view.superview!
				while this_superview != self.scrollView {
					estimated__margin_y += this_view.frame.origin.y
					//
					this_view = this_superview // walk up
					this_superview = this_view.superview!
				}
			}
			let margin_y = estimated__margin_y
			let toBeVisible_frame__relative = inputView.frame.insetBy(dx: 0, dy: -margin_y)
			let toBeVisible_frame__absolute = inputView.superview == scrollView ? toBeVisible_frame__relative : inputView.convert(toBeVisible_frame__relative, to: scrollView)
			var scrollEdge: Form.InputScrollEdge
			do {
				if toBeVisible_frame__absolute.origin.y < self.scrollView.contentOffset.y {
					scrollEdge = .top
				} else {
					scrollEdge = .bottom
				}
			}
			self.scrollRectToVisible(
				toBeVisible_frame__absolute: toBeVisible_frame__absolute,
				atEdge: scrollEdge,
				finished_fn:
				{
				}
			)
		}
		func scrollRectToVisible(
			toBeVisible_frame__absolute: CGRect,
			atEdge scrollEdge: UICommonComponents.Form.InputScrollEdge,
			finished_fn: @escaping ((Void) -> Void)
		)
		{
			let visibleScroll_rect = self.visibleScroll_rect
			if visibleScroll_rect.contains(toBeVisible_frame__absolute) { // already fully contained - do not scroll
				return
			}
			var contentOffset_y: CGFloat
			if scrollEdge == .top {
				let toBeVisible_topEdge = toBeVisible_frame__absolute.origin.y
				contentOffset_y = toBeVisible_topEdge
			} else if scrollEdge == .bottom {
				contentOffset_y = toBeVisible_frame__absolute.origin.y - visibleScroll_rect.size.height + toBeVisible_frame__absolute.size.height
			} else {
				assert(false)
				contentOffset_y = 0
			}
			UIView.animate(
				withDuration: FormViewController.fieldScrollDuration,
				animations:
				{ [unowned self] in
					self.scrollView.contentOffset = CGPoint(x: 0, y: contentOffset_y)
				},
				completion:
				{ (finished) in
					if finished {
						finished_fn()
					}
				}
			)
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
		// Runtime - Imperatives - Convenience/Overridable - Submission/Interactivity
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
		// Delegation - Scrollview
		func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
		{ // this may or may not be preferable…
			self.scrollView.resignCurrentFirstResponder()
		}
		//
		// Delegation - Gesture recognition
		@objc func tapped()
		{
			guard let viewToFocus_orNilToBlur = self.new_wantsBackgroundTapToFocusResponder_orNilToBlurInstead() else {
				self.scrollView.resignCurrentFirstResponder()
				return
			}
			if viewToFocus_orNilToBlur.isFirstResponder == false { // this check is probably not necessary
				viewToFocus_orNilToBlur.becomeFirstResponder()
			}
		}
		//
		// Delegation - Internal/Convenience - UITextFieldDelegate
		func textFieldDidBeginEditing(_ textField: UITextField)
		{
			self.aField_didBeginEditing(textField)
		}
		func textFieldShouldReturn(_ textField: UITextField) -> Bool
		{
			return self.aField_shouldReturn(textField, returnKeyType: textField.returnKeyType)
		}
		//
		// Delegation - Internal/Convenience - UITextViewDelegate
		func textViewDidBeginEditing(_ textView: UITextView)
		{
			self.aField_didBeginEditing(textView)
		}
		func textViewDidChange(_ textView: UITextView)
		{
			return self.aField_editingChanged()
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
		func aField_didBeginEditing(_ inputView: UIView, butSuppressScroll suppressScrollToVisible: Bool = false)
		{
			if suppressScrollToVisible != true {
				self.scrollInputViewToVisible(self.scrollView.currentFirstResponder! as! UIView)
			}
		}
		//
		// Delegation - Internal/Convenience - Form submission
		func aFormSubmissionButtonWasPressed()
		{
			self._tryToSubmitForm()
		}
		//
		// Delegation - View
		override func viewWillAppear(_ animated: Bool)
		{
			super.viewWillAppear(animated)
			self.set_isFormSubmittable_needsUpdate()
		}
		override func viewWillDisappear(_ animated: Bool)
		{
			super.viewWillDisappear(animated)
			if self.isBeingDismissed || self.navigationController != nil && self.navigationController!.isBeingDismissed {
				self.scrollView.resignCurrentFirstResponder()
			}
		}
		//
		// Delegation - Notifications - Keyboard
		var keyboardIsShowing: Bool = false
		var keyboardHeight: CGFloat?
		func keyboardWillShow(notification: Notification)
		{
			let userInfo = notification.userInfo!
			if self.keyboardIsShowing == true { // this actually happens when the keyboard is already showing and fields are just switched
				return
			}
			// arguments
			let keyboard_size = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)!.cgRectValue
			// state
			self.keyboardIsShowing = true
			self.keyboardHeight = keyboard_size.height
			// configuration
			self.scrollView.contentInset = self.new_contentInset()
		}
		func keyboardWillHide(notification: Notification)
		{
			if self.keyboardIsShowing == false { // this actually happens on launch in the Simulator when a text field is shown and focused immediately, e.g. pw entry, but the software keyboard is not to be shown
				return
			}
			// state
			self.keyboardIsShowing = false
			self.keyboardHeight = nil
			// configuration
			self.scrollView.contentInset = self.new_contentInset()
		}
		//
		// Delegation - Gestures - Tap
		func gestureRecognizer(
			_ gestureRecognizer: UIGestureRecognizer,
			shouldReceive touch: UITouch
		) -> Bool
		{
			if let view = touch.view {
				return self.new_wantsBGTapRecognizerToReceive_tapped(onView: view)
			}
			return true
		}
	}
	struct Form
	{ // TODO: port the entire remainder of this file, Form.swift, to this namespace, Form
		
		enum InputScrollEdge
		{
			case top
			case bottom
		}
		//
		class FieldLabel: UILabel
		{
			//
			// Properties - Static
			static let fixedHeight: CGFloat = 13
			//
			static let visual_marginBelow: CGFloat = 7
			static let marginBelowLabelAboveTextInputView: CGFloat = Form.FieldLabel.visual_marginBelow - FormInputCells.imagePadding_y
			static let marginBelowLabelAbovePushButton: CGFloat = Form.FieldLabel.visual_marginBelow - PushButtonCells.imagePaddingForShadow_v
			//
			static let visual_marginAboveLabelForUnderneathField: CGFloat = 22
			static let marginAboveLabelForUnderneathField_textInputView: CGFloat = Form.FieldLabel.visual_marginAboveLabelForUnderneathField - FormInputCells.imagePadding_y
			//
			// Lifecycle - Init
			init(title: String, sizeToFit: Bool? = false)
			{
				let frame = CGRect(
					x: CGFloat(0),
					y: CGFloat(0),
					width: CGFloat(0),
					height: Form.FieldLabel.fixedHeight
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
		class FieldLabelAccessoryLabel: UILabel
		{
			//
			// Properties - Static
			static let fixedHeight: CGFloat = FieldLabel.fixedHeight
			//
			// Lifecycle - Init
			init(title: String)
			{
				let frame = CGRect(
					x: CGFloat(0),
					y: CGFloat(0),
					width: CGFloat(0),
					height: Form.FieldLabelAccessoryLabel.fixedHeight
				)
				super.init(frame: frame)
				self.text = title
				self.setup()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			func setup()
			{
				self.font = UIFont.smallRegularMonospace
				self.textColor = UIColor(rgb: 0x6B696B)
				self.numberOfLines = 1
				self.textAlignment = .right
			}
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
		case textField_bg_disabled_noErr = "textField_bg_disabled_noErr_stretchable"
		case textField_bg_disabled_error = "textField_bg_disabled_error_stretchable"
		//
		static var imagePadding_x: CGFloat { return 1 }
		static var imagePadding_y: CGFloat { return 1 }
		//
		var stretchableImage: UIImage
		{
			return UIImage(named: self.rawValue)!
				.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
		}
	}
	class FormTextViewContainerView: UIView
	{
		var textView: FormTextView!
		let stretchableBackgroundImage = FormInputCells.textField_bg_noErr.stretchableImage
		//
		static let visual__height: CGFloat = 64
		static let height: CGFloat = FormTextViewContainerView.visual__height + 2*UICommonComponents.FormInputCells.imagePadding_y
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
			let view = UILabel(frame: .zero)
			view.numberOfLines = 0 // to fix line wrapping bug
			view.textColor = UIColor(rgb: 0x6B696B)
			view.font = UIFont.middlingRegularMonospace// LightMonospace - too light
			if let placeholder = self.placeholder {
				view.text = placeholder
			} else {
				view.isHidden = true
			}
			self.addSubview(view)
			self.placeholderLabel = view
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
		override var text: String!
		{
			didSet {
				self.textViewDidChange()
			}
		}
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
		static let visual__height: CGFloat = 32
		static let height: CGFloat = FormInputField.visual__height + 2*FormInputCells.imagePadding_y
		//
		static let textInsets = UIEdgeInsetsMake(8, 10, 8, 10)
		//
		var validationErrorMessageLabel: FormFieldAccessoryMessageLabel?
		var init_placeholder: String?
		//
		override var isEnabled: Bool {
			didSet {
				self._configureBackground()
			}
		}
		//
		init(placeholder: String?)
		{
			let frame = CGRect(
				x: CGFloat(0),
				y: CGFloat(0),
				width: CGFloat(0),
				height: FormInputField.height
			)
			NSLog("FormInputField.height \(FormInputField.height)")
			self.init_placeholder = placeholder
			super.init(frame: frame)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.font = UIFont.middlingLightMonospace
			if self.init_placeholder != nil {
				let string = NSMutableAttributedString(string: self.init_placeholder!)
				let range = NSRange(location: 0, length: self.init_placeholder!.characters.count)
				string.addAttributes(
					[
						NSForegroundColorAttributeName: UIColor(rgb: 0x6B696B),
						NSFontAttributeName: UIFont.middlingRegularMonospace // light is too light
					],
					range: range
				)
				self.attributedPlaceholder = string
			}
			self.textColor = UIColor(rgb: 0xDFDEDF)
			self.borderStyle = .none
			self.configureWithValidationError(nil)
		}
		//
		// Accessors - Overrides
		override func textRect(forBounds bounds: CGRect) -> CGRect
		{ // placeholder position
			return bounds.insetBy(dx: FormInputField.textInsets.left, dy: FormInputField.textInsets.top)
		}
		override func editingRect(forBounds bounds: CGRect) -> CGRect
		{ // text position
			return bounds.insetBy(dx: FormInputField.textInsets.left, dy: FormInputField.textInsets.top)
		}
		//
		// Imperatives - Validation errors
		func setValidationError(_ message: String)
		{
			if message == "" {
				self.clearValidationError()
				return
			}
			if self.validationErrorMessageLabel == nil {
				let view = FormFieldAccessoryMessageLabel(text: nil)
				view.textColor = UIColor.standaloneValidationTextOrDestructiveLinkContentColor
				self.validationErrorMessageLabel = view
				self.addSubview(view)
			}
			self.validationErrorMessageLabel!.setMessageText(message)
			self._configureBackground() // AFTER setting self.validationErrorMessageLabel
			self.setNeedsLayout()
		}
		func clearValidationError()
		{
			if self.validationErrorMessageLabel != nil {
				self.validationErrorMessageLabel!.removeFromSuperview()
				self.validationErrorMessageLabel = nil
			}
			self._configureBackground() // AFTER zeroing self.validationErrorMessageLabel
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
		func _configureBackground()
		{
			if self.validationErrorMessageLabel != nil {
				self.background = FormInputCells.textField_bg_error.stretchableImage
				self.disabledBackground = FormInputCells.textField_bg_disabled_error.stretchableImage
			} else {
				self.background = FormInputCells.textField_bg_noErr.stretchableImage
				self.disabledBackground = FormInputCells.textField_bg_disabled_noErr.stretchableImage
			}
		}
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			if let validationErrorMessageLabel = self.validationErrorMessageLabel {
				let frame = CGRect(
					x: FormInputField.textInsets.left,
					y: self.frame.size.height + FormInputField.textInsets.top,
					width: self.frame.size.width - FormInputField.textInsets.left - FormInputField.textInsets.right,
					height: 0
				)
				validationErrorMessageLabel.frame = frame
				validationErrorMessageLabel.sizeToFit()
			}
		}
	}
	//
	class FormAccessoryMessageLabel: UILabel
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
			self.font = UIFont.middlingRegularSansSerif
			self.textColor = UIColor(rgb: 0x9E9C9E)
			self.numberOfLines = 0
			self.textAlignment = .center
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
			self.font = UIFont.smallRegularMonospace
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
//
// Amount input
extension UICommonComponents.Form
{
	class AmountInputFieldsetView: UIView
	{
		//
		// Properties
		let inputField = AmountInputField()
		let currencyLabel = AmountCurrencyLabel(title: "XMR")
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
			self.addSubview(inputField)
			self.addSubview(currencyLabel)
			//
			self.setup_layout()
		}
		func setup_layout()
		{
			self.inputField.frame = CGRect(
				x: 0,
				y: 0,
				width: AmountInputField.w,
				height: AmountInputField.height
			)
			self.currencyLabel.frame = CGRect(
				x: self.inputField.frame.origin.x + self.inputField.frame.size.width + (8 - UICommonComponents.FormInputCells.imagePadding_x),
				y: self.inputField.frame.origin.y,
				width: self.currencyLabel.frame.size.width,
				height: self.currencyLabel.frame.size.height
			)
			self.frame = CGRect(
				x: 0,
				y: 0,
				width: self.currencyLabel.frame.origin.x + self.currencyLabel.frame.size.width,
				height: self.currencyLabel.frame.size.height
			)
		}
	}
	class AmountInputField: UICommonComponents.FormInputField
	{
		//
		// Constants
		static let visual__w: CGFloat = 114
		static let w: CGFloat = visual__w + 2*UICommonComponents.FormInputCells.imagePadding_x
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
		// Accessors
		var isEmpty: Bool {
			if self.text == nil || self.text! == "" {
				return true
			}
			return false
		}
		var hasInputButIsNotSubmittable: Bool {
			if self.isEmpty {
				return false // no input
			}
			let amount = self.submittableAmount_orNil
			if amount == nil {
				return true // has input but not submittable
			}
			return false // has input but is submittable
		}
		var submittableAmount_orNil: MoneroAmount? {
			if self.isEmpty {
				return nil
			}
			let amount = MoneroAmount.new(withUserInputAmountString: self.text!)
			
			return amount
		}
		var submittableDouble_orNil: Double? {
			if self.isEmpty {
				return nil
			}
			let double = MoneroAmount.newDouble(withUserInputAmountString: self.text!)
			
			return double
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
			//
			return true
		}
	}
	class AmountCurrencyLabel: UILabel
	{
		//
		// Properties - Static
		static let w: CGFloat = 24
		static let h: CGFloat = AmountInputField.height // relying on vertical centering
		//
		// Lifecycle - Init
		init(title: String)
		{
			let frame = CGRect(x: 0, y: 0, width: AmountCurrencyLabel.w, height: AmountCurrencyLabel.h)
			super.init(frame: frame)
			self.text = title
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.font = UIFont.smallBoldMonospace
			self.textColor = UIColor(rgb: 0x8D8B8D)
			self.numberOfLines = 1
			self.textAlignment = .left
		}
	}
}

