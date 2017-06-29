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
		var messageView: UICommonComponents.InlineMessageView?
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
			self.startObserving()
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
			if self.new_wantsInlineMessageViewForValidationMessages() {
				let view = UICommonComponents.InlineMessageView(
					mode: .withCloseButton,
					didHide:
					{ [unowned self] in
						self.view.setNeedsLayout()
					}
				)
				self.messageView = view
				self.view.addSubview(view)
			}
		}
		func setup_navigation()
		{ // override but call on super
		}
		func startObserving()
		{ // override, but call on super
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
		//
		// Lifecycle - Deinit
		deinit
		{
			self.tearDown()
		}
		func tearDown()
		{
			self.stopObserving()
		}
		func stopObserving()
		{
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
		func new_wantsInlineMessageViewForValidationMessages() -> Bool
		{ // overridable
			return true
		}
		//
		// Accessors - Lookups/Derived - Layout metrics
		var inlineMessageValidationView_topMargin: CGFloat
		{
			return 13
		}
		var inlineMessageValidationView_bottomMargin: CGFloat
		{
			return 13
		}
		var yOffsetForViewsBelowValidationMessageView: CGFloat
		{
			assert(self.new_wantsInlineMessageViewForValidationMessages() == true)
			let topMargin = self.inlineMessageValidationView_topMargin
			if self.messageView!.isHidden {
				return topMargin
			}
			let bottomMargin = self.inlineMessageValidationView_bottomMargin
			let y = topMargin + self.messageView!.frame.size.height + bottomMargin
			//
			return y
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
		func new_contentInset() -> UIEdgeInsets
		{
			let bottom: CGFloat = self.keyboardIsShowing == true ? self.keyboardHeight! : 0
			//
			return UIEdgeInsetsMake(0, 0, bottom, 0)
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
		// Runtime - Imperatives - Convenience/Overridable - Validation error
		func setValidationMessage(_ message: String)
		{
			if self.new_wantsInlineMessageViewForValidationMessages() == false {
				assert(false, "override \(#function)")
				return
			}
			let view = self.messageView! // this ! is not necessary according to the var's optionality but there seems to be a compiler bug
			view.set(text: message)
			self.layOut_messageView() // this can be slightly redundant, but it is called here so we lay out before showing. maybe rework this so it doesn't require laying out twice and checking visibility. maybe a flag saying "ought to be showing". maybe.
			view.show()
			self.view.setNeedsLayout() // so views (below messageView) get re-laid-out
		}
		func clearValidationMessage()
		{
			if self.new_wantsInlineMessageViewForValidationMessages() == false {
				assert(false, "override \(#function)")
				return
			}
			self.messageView!.clearAndHide() // as you can see, no ! required here. compiler bug?
			// we don't need to call setNeedsLayout() here b/c the messageView callback in self.setup will do so
		}
		//
		// Imperatives - Internal - Layout
		func layOut_messageView()
		{
			assert(self.new_wantsInlineMessageViewForValidationMessages() == true)
			let x = CGFloat.visual__form_input_margin_x // use visual__ instead so we don't get extra img padding
			let w = self.new__textField_w
			self.messageView!.layOut(atX: x, y: self.inlineMessageValidationView_topMargin, width: w)
		}
		//
		// Runtime - Imperatives - Scrolling
		func scrollInputViewToVisible(_ inputView: UIView)
		{
			let visibleScroll_size_height = (self.scrollView.bounds.size.height - scrollView.contentInset.top - scrollView.contentInset.bottom)
			let visibleScroll_size = CGSize(
				width: scrollView.bounds.size.width,
				height: visibleScroll_size_height
			)
			let visibleScroll_rect = CGRect(origin: scrollView.contentOffset, size: visibleScroll_size)
			var margin_y: CGFloat = UICommonComponents.FormLabel.marginAboveLabelForUnderneathField_textInputView + UICommonComponents.FormLabel.fixedHeight + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView
			do { // to finalize margin_y, in case it's not a direct subview of scrollView (e.g. UITextView inside container)
				var this_view = inputView
				var this_superview = this_view.superview!
				while this_superview != scrollView {
					margin_y += this_view.frame.origin.y
					//
					this_view = this_superview // walk up
					this_superview = this_view.superview!
				}
			}
			let toBeVisible_frame__relative = inputView.frame.insetBy(dx: 0, dy: -margin_y)
			let toBeVisible_frame__absolute = inputView.superview == scrollView ? toBeVisible_frame__relative : inputView.convert(toBeVisible_frame__relative, to: scrollView)
			if visibleScroll_rect.contains(toBeVisible_frame__absolute) { // already fully contained - do not scroll
				return
			}
			var contentOffset_y: CGFloat
			if toBeVisible_frame__absolute.origin.y < self.scrollView.contentOffset.y {
				let toBeVisible_topEdge = toBeVisible_frame__absolute.origin.y
				contentOffset_y = toBeVisible_topEdge
			} else {
				contentOffset_y = toBeVisible_frame__absolute.origin.y - visibleScroll_size_height + toBeVisible_frame__absolute.size.height
			}
			UIView.animate(withDuration: 0.25, animations:
			{ [unowned self] in
				self.scrollView.contentOffset = CGPoint(x: 0, y: contentOffset_y)
			})
		}
		//
		// Delegation - View
		override func viewDidLayoutSubviews()
		{
			super.viewDidLayoutSubviews()
			if self.new_wantsInlineMessageViewForValidationMessages() {
				if self.messageView!.shouldPerformLayOut { // i.e. is visible
					self.layOut_messageView()
				}
			}
		}
		//
		// Delegation - Scrollview
		func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
		{ // this may or may not be preferable…
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
		func aField_didBeginEditing(_ inputView: UIView)
		{
			self.scrollInputViewToVisible(self.view.currentFirstResponder! as! UIView)
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
		var hasAppearedBefore = false
		override func viewDidAppear(_ animated: Bool)
		{
			super.viewDidAppear(animated)
			if self.hasAppearedBefore == false {
				self.hasAppearedBefore = true
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
		static var imagePadding_x: CGFloat { return 1 }
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
		//
		// Properties - Static
		static let fixedHeight: CGFloat = 13
		//
		static let visual_marginBelow: CGFloat = 7
		static let marginBelowLabelAboveTextInputView: CGFloat = FormLabel.visual_marginBelow - FormInputCells.imagePadding_y
		//
		static let visual_marginAboveLabelForUnderneathField: CGFloat = 13
		static let marginAboveLabelForUnderneathField_textInputView: CGFloat = FormLabel.visual_marginAboveLabelForUnderneathField - FormInputCells.imagePadding_y
		//
		// Lifecycle - Init
		init(title: String, sizeToFit: Bool? = false)
		{
			let frame = CGRect(
				x: CGFloat(0),
				y: CGFloat(0),
				width: CGFloat(0),
				height: FormLabel.fixedHeight
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
