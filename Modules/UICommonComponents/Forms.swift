//
//  Forms.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright (c) 2014-2018, MyMonero.com
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
extension UICommonComponents
{
	class FormViewController: ScrollableValidatingInfoViewController,
		UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate
	{
		//
		// Constants
		static let fieldScrollDuration = 0.3 // oddly this must not exceed .4 or some sort of layout racing happens and the eventual scroll offset becomes wrong
		//
		// Properties - Cached
		//
		// Properties - Derived
		var new__label_x: CGFloat {
			return CGFloat.form_label_margin_x + self.new_subviewLayoutInsets.left
		}
		var new__input_x: CGFloat {
			return CGFloat.form_input_margin_x + self.new_subviewLayoutInsets.left
		}
		var new__labelAccessoryLabel_x: CGFloat {
			return CGFloat.form_labelAccessoryLabel_margin_x + self.new_subviewLayoutInsets.left
		}
		//
		var new__textField_w: CGFloat {
			let fieldsInsets = self.new_subviewLayoutInsets
			return self.scrollView/*not view*/.frame.size.width - 2 * CGFloat.form_input_margin_x - fieldsInsets.left - fieldsInsets.right
		}
		var new__fieldLabel_w: CGFloat {
			let fieldsInsets = self.new_subviewLayoutInsets
			return self.scrollView/*not view*/.frame.size.width - /*intentionally not "2*"!*/CGFloat.form_label_margin_x - CGFloat.form_input_margin_x - fieldsInsets.left - fieldsInsets.right
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
		var _new_heightForKeyboardInContentInsetsBottom: CGFloat {
			return self.keyboardIsShowing == true ? self.keyboardHeight! : 0
		}
		override func new_contentInset() -> UIEdgeInsets
		{ // overridable but inheriting safeAreaInsets from super
			let base = super.new_contentInset()
			return UIEdgeInsetsMake(
				base.top + 0,
				base.left + 0,
				base.bottom + self._new_heightForKeyboardInContentInsetsBottom,
				base.right + 0
			)
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
			var estimatedDesiredAdditional__margin_y: CGFloat = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView + UICommonComponents.Form.FieldLabel.fixedHeight + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView
			do { // to finalize margin_y, in case it's not a direct subview of scrollView (e.g. UITextView inside container)
				var this_view = inputView
				var this_superview = this_view.superview!
				while this_superview != self.scrollView {
					estimatedDesiredAdditional__margin_y += this_view.frame.origin.y
					//
					this_view = this_superview // walk up
					this_superview = this_view.superview!
				}
			}
			let toBeVisible_frame__relative = inputView.frame.insetBy(dx: 0, dy: -estimatedDesiredAdditional__margin_y)
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
			finished_fn: @escaping (() -> Void)
		) {
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
				delay: 0,
				options: [ .curveEaseInOut ],
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
		func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
		{
			if text == "\n" { // simulate single-line input
				let _ = self.aField_shouldReturn(textView, returnKeyType: textView.returnKeyType)
				return false // never allow \n
			}
			if text == "\t" {
				return false // no need to allow tabs anywhere (yet) afaik
			}
			return true
		}
		//
		// Delegation - Internal/Convenience - Field interactions
		@objc func aField_editingChanged()
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
				self.scrollView.resignCurrentFirstResponder()
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
			self.scrollView.resignCurrentFirstResponder()
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
		@objc func keyboardWillShow(notification: Notification)
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
			self.configure_scrollView_contentInset()
		}
		@objc func keyboardWillHide(notification: Notification)
		{
			if self.keyboardIsShowing == false { // this actually happens on launch in the Simulator when a text field is shown and focused immediately, e.g. pw entry, but the software keyboard is not to be shown
				return
			}
			// state
			self.keyboardIsShowing = false
			self.keyboardHeight = nil
			// configuration
			self.configure_scrollView_contentInset()
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
			static let fixedFont = UIFont.smallBoldMonospace
			static let fixedHeight: CGFloat = FieldLabel.fixedFont.lineHeight
			//
			static let visual_marginBelow: CGFloat = UIFont.shouldStepDownLargerFontSizes ? 9 : 10
			static let marginBelowLabelAboveTextInputView: CGFloat = Form.FieldLabel.visual_marginBelow - FormInputCells.imagePadding_y
			static let marginBelowLabelAbovePushButton: CGFloat = Form.FieldLabel.visual_marginBelow - PushButtonCells.imagePaddingForShadow_v
			//
			static let visual_marginAboveLabelForUnderneathField: CGFloat = 22
			static let marginAboveLabelForUnderneathField_textInputView: CGFloat = Form.FieldLabel.visual_marginAboveLabelForUnderneathField - FormInputCells.imagePadding_y + (UIFont.shouldStepDownLargerFontSizes ? 0 : 12)
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
				self.font = FieldLabel.fixedFont
				self.isUserInteractionEnabled = false // do not intercept touches destined for the form background tap recognizer
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
		// if input is not immutable (typical), actually using the same images for 'disabled', therefore not declaring new cases for disabled state. this may change. but it is done to prevent 'visual flash' on fast form submits when elements are temporarily disabled even though not immutable
		//
		// and for immutable, no distinction between enabled/disabled anyway
		case textField_bg_immutable_noErr = "textField_bg_immutable_noErr_stretchable"
		case textField_bg_immutable_error = "textField_bg_immutable_error_stretchable"
		//
		static var imagePadding_x: CGFloat { return 1 }
		static var imagePadding_y: CGFloat { return 1 }
		//
		static var stretchableImage_capWidth_left: Int = 2 + FormInputCells.background_outlineInternal_cornerRadius
		static var stretchableImage_capWidth_top: Int = 2 + FormInputCells.background_outlineInternal_cornerRadius
		//
		static var background_outlineVisualThickness_h: CGFloat = 1/UIScreen.main.scale // hm; unsure
		static var background_outlineVisualThickness_v: CGFloat = 1/UIScreen.main.scale // hm; unsure
		//
		static var background_outlineInternal_cornerRadius: Int { return 3 }
		//
		var stretchableImage: UIImage
		{
			return UIImage(
				named: self.rawValue
			)!.stretchableImage(
				withLeftCapWidth: FormInputCells.stretchableImage_capWidth_left,
				topCapHeight: FormInputCells.stretchableImage_capWidth_top
			)
		}
	}
	class FormTextViewContainerView: UIView
	{
		static let stretchableBackgroundImage = FormInputCells.textField_bg_noErr.stretchableImage
		static let disabled_stretchableBackgroundImage = FormInputCells.textField_bg_noErr.stretchableImage // actually the same, for now
		static let immutable_stretchableBackgroundImage = FormInputCells.textField_bg_immutable_noErr.stretchableImage
		//
		var textView: FormTextView!
		var isImmutable: Bool = false
		{
			didSet {
				// logically+semantically does not matter if enabled but consumer should .set(isEnabled: false), too so that interactivity of field disabled and interactivity values are also correct at runtime
				self.setNeedsDisplay() // must cause redraw
			}
		}
		//
		static let visual__height: CGFloat = 68
		static let height: CGFloat = FormTextViewContainerView.visual__height + 2*UICommonComponents.FormInputCells.imagePadding_y
		//
		func heightThatFits(width fixedWidth: CGFloat) -> CGFloat
		{
			let fittingSize = self.textView.sizeThatFits(
				CGSize(
					width: fixedWidth,
					height: CGFloat.greatestFiniteMagnitude
				)
			)
			return fittingSize.height + 8 + 7
		}
		//
		override var isHidden: Bool {
			didSet {
				if self.isHidden == false {
					self.setNeedsDisplay() // draw disabled bg if started from hidden
				}
			}
		}
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
		// Imperatives
		func set(isEnabled: Bool)
		{
			assert(Thread.isMainThread)
			//
			self.textView.isEditable = isEnabled
			do { // whether or not to ignore touches, to support bg taps to blur 
				self.isUserInteractionEnabled = isEnabled
				self.textView.isUserInteractionEnabled = isEnabled
			}
			self.setNeedsDisplay() // redraw bg
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
			var image: UIImage!
			if self.isImmutable { // doesn't matter if it's enabled anyway
				image = FormTextViewContainerView.immutable_stretchableBackgroundImage
			} else if self.textView.isEditable {
				image = FormTextViewContainerView.stretchableBackgroundImage
			} else {
				image = FormTextViewContainerView.disabled_stretchableBackgroundImage
			}
			image.draw(in: rect)
			super.draw(rect)
		}
	}
	class FormTextView: UITextView
	{
		var placeholder: String?
		var placeholderLabel: UILabel?
		override var isEditable: Bool {
			willSet {
				self._configureTextFontAndColor(withManual_isEnabled: newValue)
			}
		}
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
		func setup()
		{
			self.backgroundColor = UIColor.clear
			self.keyboardAppearance = .dark // TODO: configure based on ThemeController
			self.configureTextFontAndColor()
			self.textContainerInset = UIEdgeInsetsMake(6, 4, 0, 4)
			//
			let view = UILabel(frame: .zero)
			view.numberOfLines = 0 // to fix line wrapping bug
			view.textColor = UIColor(rgb: 0x6B696B)
			view.font = UIFont.middlingRegularMonospace // light is too light
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
		func configureTextFontAndColor()
		{
			self._configureTextFontAndColor(withManual_isEnabled: self.isEditable)
		}
		func _configureTextFontAndColor(withManual_isEnabled isEnabled: Bool)
		{
			if isEnabled {
				self.textColor = UIColor(rgb: 0xDFDEDF)
				self.font = UIFont.middlingLightMonospace
			} else {
				self.textColor = UIColor(rgb: 0x7C7A7C)
				self.font = UIFont.middlingRegularMonospace // light is too light
			}
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
				placeholderLabel.isHidden = self.text.count > 0
			}
		}
	}
	class FormInputField: UITextField
	{
		//
		// Common - Constants
		static let visual__height: CGFloat = UIFont.shouldStepDownLargerFontSizes ? 36 : 44
		static let height: CGFloat = FormInputField.visual__height + 2*FormInputCells.imagePadding_y
		//
		static let font_default = UIFont.shouldStepDownLargerFontSizes
			? UIFont.subMiddlingRegularMonospace /* slightly improve truncation of long placeholders on iPhone SE */
			: UIFont.middlingRegularMonospace
		//
		static let textInsets = UIEdgeInsetsMake(8, 10, 8, 10)
		//
		var validationErrorMessageLabel: FormFieldAccessoryMessageLabel?
		var init_placeholder: String?
		//
		var isImmutable: Bool = false
		{
			didSet {
				// logically+semantically does not matter if enabled but consumer should .set(isEnabled: false), too so that interactivity of field disabled and interactivity values are also correct at runtime
				self._configureBackground() // need to update the images
				self.setNeedsDisplay() // must cause redraw
			}
		}
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
			self.init_placeholder = placeholder
			super.init(frame: frame)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.font = type(of: self).font_default
			self.keyboardAppearance = .dark // TODO: configure based on ThemeController
			if self.init_placeholder != nil {
				self.set(placeholder: self.init_placeholder!)
			}
			self.textColor = UIColor(rgb: 0xDFDEDF)
			self.borderStyle = .none
			self.configureWithValidationError(nil)
		}
		//
		// Accessors - Overrides
		override func textRect(forBounds bounds: CGRect) -> CGRect
		{ // placeholder position?
			return bounds.insetBy(dx: FormInputField.textInsets.left, dy: FormInputField.textInsets.top)
		}
		override func editingRect(forBounds bounds: CGRect) -> CGRect
		{ // text position
			return bounds.insetBy(dx: FormInputField.textInsets.left, dy: FormInputField.textInsets.top)
		}
		override func placeholderRect(forBounds bounds: CGRect) -> CGRect
		{
			return bounds.insetBy(dx: FormInputField.textInsets.left, dy: FormInputField.textInsets.top)
		}
		//
		// Imperatives - Placeholder
		func set(placeholder text: String)
		{
			let string = NSMutableAttributedString(string: text)
			let range = NSRange(location: 0, length: text.count)
			string.addAttributes(
				[
					NSAttributedStringKey.foregroundColor: UIColor(rgb: 0x6B696B),
					NSAttributedStringKey.font: FormInputField.font_default
				],
				range: range
			)
			self.attributedPlaceholder = string
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
			self.layout_validationErrorMessageLabel() // lay it out immediately so that we have the layout by the time we exit this function - we'll just assume that we have a self.frame.size.width by now - and if we don't, we will just lay out the validation label again in layoutSubviews()
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
				self.disabledBackground = self.isImmutable ? FormInputCells.textField_bg_immutable_error.stretchableImage : FormInputCells.textField_bg_error.stretchableImage
			} else {
				self.background = FormInputCells.textField_bg_noErr.stretchableImage
				self.disabledBackground = self.isImmutable ? FormInputCells.textField_bg_immutable_noErr.stretchableImage : FormInputCells.textField_bg_noErr.stretchableImage
			}
		}
		//
		func layout_validationErrorMessageLabel()
		{
			assert(self.validationErrorMessageLabel != nil)
			let validationErrorMessageLabel = self.validationErrorMessageLabel!
			let frame = CGRect(
				x: FormInputField.textInsets.left,
				y: self.frame.size.height + FormInputField.textInsets.top,
				width: self.frame.size.width - FormInputField.textInsets.left - FormInputField.textInsets.right,
				height: 0
			)
			validationErrorMessageLabel.frame = frame
			validationErrorMessageLabel.sizeToFit()
		}
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			if self.validationErrorMessageLabel != nil {
				self.layout_validationErrorMessageLabel()
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
		}
		//
		func setMessageText(_ text: String)
		{
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center // must be set here
			paragraphStyle.lineSpacing = 3
			let string = NSMutableAttributedString(string: text)
			string.addAttribute(
				NSAttributedStringKey.paragraphStyle,
				value: paragraphStyle,
				range: NSRange(location: 0, length: text.count)
			)
			
			self.attributedText = string
		}
	}
	//
	class FormFieldAccessoryMessageLabel: UILabel
	{
		static let heightIfFixed: CGFloat = 13
		//
		static let visual_marginAbove: CGFloat = 8
		static let marginAboveLabelBelowTextInputView: CGFloat = FormFieldAccessoryMessageLabel.visual_marginAbove - FormInputCells.imagePadding_y
		//
		enum DisplayMode
		{
			case normal
			case prominent
		}
		var displayMode: DisplayMode!
		convenience init(text: String?)
		{
			self.init(text: text, displayMode: .normal)
		}
		init(text: String?, displayMode: DisplayMode)
		{
			self.displayMode = displayMode
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
			self.textColor = UIColor(
				rgb: self.displayMode == .normal ? 0x8D8B8D : 0x9E9C9E
			)
			self.numberOfLines = 0
		}
		//
		func setMessageText(_ text: String)
		{
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.lineSpacing = 3
			let string = NSMutableAttributedString(string: text)
			string.addAttribute(
				NSAttributedStringKey.paragraphStyle,
				value: paragraphStyle,
				range: NSRange(location: 0, length: text.count)
			)
			self.attributedText = string
		}
	}
}
//
extension UICommonComponents.Form
{
	class FieldGroupDecorationSectionView: UICommonComponents.Details.SectionView
	{
		override func layoutSubviews()
		{
			super.layoutSubviews() // in which nothing is actually done
		}
		//
		//
		func sizeAndLayOutToEncompass(
			topFieldView: UIView,
			bottomFieldView: UIView,
			//
			withContainingWidth containingWidth: CGFloat,
			yOffset: CGFloat
		) {
			// manual/patch call to custom method:
			self.layOutSubviews(
				withContainingWidth: containingWidth, // cannot use self.frame.size.width yet
				withXOffset: 0,
				andYOffset: 0
			) // as used, this will cause the SectionContentContainerView to size itself but have height (and on first run, width) of 0
			do { // so adjust height manually
				var to_frame = self.containerView.frame
				do {
					let unpadded_fieldsHeight = (bottomFieldView.frame.origin.y + bottomFieldView.frame.size.height) - topFieldView.frame.origin.y
					let padded_fieldsHeight = unpadded_fieldsHeight + 3*UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView // TODO: inexact - improve
					//
					to_frame.size.height = padded_fieldsHeight
					//
					to_frame = to_frame.integral
				}
				self.containerView.frame = to_frame
			}
			self.frame = CGRect(
				x: 0,
				y: yOffset,
				width: containingWidth,
				height: self.containerView.frame.origin.y + self.containerView.frame.size.height
			)
		}
	}
}
