//
//  ContactPicker.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/7/17.
//  Copyright (c) 2014-2019, MyMonero.com
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
	class ContactAndAddressPickerView: UIView,
		UITextFieldDelegate,
		UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
	{

		//
		// Constants
		static let maxHeight: CGFloat = UICommonComponents.FormInputField.height
		//
		// Types
		enum InputMode
		{
			case contactsOnly
			case contactsAndAddresses
		}
		enum AccessoryInfoDisplayMode
		{
			case noResolvedFields
			case paymentIds_andResolvedAddrs
		}
		//
		// Properties
		var inputMode: InputMode
		var displayMode: AccessoryInfoDisplayMode
		var parentScrollView: UIScrollView?
		//
		var selectedContact: Contact? // strong should be ok here b/c we unpick the selectedContact when contacts reloads on logged-in runtime teardown
		//
		var inputField = UICommonComponents.FormInputField(
			placeholder: NSLocalizedString("Enter contact name", comment: "")
		)
		var autocompleteResults_inputAccessoryView: ContactPickerSearchResultsInputAccessoryView!
		//
		var selectedContactPillView: SelectedContactPillView?
		var resolving_activityIndicator: UICommonComponents.ResolvingActivityIndicatorView!
		//
		//
		// optl
		var resolvedXMRAddr_label: UICommonComponents.Form.FieldLabel?
		var resolvedXMRAddr_inputView: UICommonComponents.FormTextViewContainerView?
		var resolvedPaymentID_label: UICommonComponents.Form.FieldLabel?
		var resolvedPaymentID_inputView: UICommonComponents.FormTextViewContainerView?
		var detected_iconAndMessageView: UICommonComponents.DetectedIconAndMessageView?
		//
		var textFieldDidBeginEditing_fn: ((_ textField: UITextField) -> Void)?
		var textFieldDidEndEditing_fn: ((_ textField: UITextField) -> Void)?
		var didFinishTypingInInput_afterMediumDelay_fn: (() -> Void)?
		var didUpdateHeight_fn: (() -> Void)?
		//
		var didPickContact_fn: ((_ contact: Contact, _ doesNeedToResolveItsOAAddress: Bool) -> Void)?
		//
		var changedTextContent_fn: (() -> Void)?
		var clearedTextContent_fn: (() -> Void)?
		var isValidatingOrResolvingNonZeroTextInput: Bool = false // internally managed; do not set
		var hasValidTextInput_moneroAddress = false // internally managed; do not set
		var hasValidTextInput_resolvedOAAddress = false // internally managed; do not set
		var willValidateNonZeroTextInput_fn: (() -> Void)?
		var finishedValidatingTextInput_foundInvalidMoneroAddress_fn: (() -> Void)?
		var finishedValidatingTextInput_foundValidMoneroAddress_fn: ((_ detectedEmbedded_paymentID: MoneroPaymentID?) -> Void)?
		var willBeginResolvingPossibleOATextInput_fn: (() -> Void)?
		//
		var yatResolve__preSuccess_terminal_validationMessage_fn: ((_ localizedString: String) -> Void)?
		var yatResolve__success_fn: ((
			_ resolved_xmr_address: String
		) -> Void)?
		
		var oaResolve__preSuccess_terminal_validationMessage_fn: ((_ localizedString: String) -> Void)?
		var oaResolve__success_fn: ((
			_ resolved_xmr_address: MoneroAddress,
			_ payment_id: MoneroPaymentID?,
			_ tx_description: String?
		) -> Void)?
		//
		var didClearPickedContact_fn: ((_ preExistingContact: Contact) -> Void)?
		//
		//
		// Lifecycle
		convenience init(parentScrollView: UIScrollView?)
		{
			self.init(
				inputMode: .contactsOnly,
				displayMode: .noResolvedFields,
				parentScrollView: parentScrollView
			)
		}
		init(
			inputMode: InputMode,
			displayMode: AccessoryInfoDisplayMode,
			parentScrollView: UIScrollView?
		) {
			self.inputMode = inputMode
			self.displayMode = displayMode
			self.parentScrollView = parentScrollView
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			debugPrint("Setup for ContactPicker invoked")
			do {
				let view = self.inputField
				view.delegate = self
				view.autocapitalizationType = self.inputMode == .contactsAndAddresses ? .none/*prevent caps in OA addrs*/ : .words
				view.keyboardType = self.inputMode == .contactsAndAddresses ? .emailAddress/* or URL but that lacks @ … email lacks ".com" */ : .asciiCapable
				view.autocorrectionType = .no
				view.addTarget(self, action: #selector(inputField_editingChanged), for: .editingChanged)
				self.addSubview(view)
			}
			do {
				let view = ContactPickerSearchResultsInputAccessoryView()
				view.collectionView.delegate = self
				view.collectionView.dataSource = self
				self.autocompleteResults_inputAccessoryView = view
				self.inputField.inputAccessoryView = view
				self.inputField.reloadInputViews() // necessary? shouldn't currently be first responder…
			}
			do {
				let view = UICommonComponents.ResolvingActivityIndicatorView()
				view.isHidden = true
				self.resolving_activityIndicator = view
				self.addSubview(view)
			}
			if self.displayMode == .paymentIds_andResolvedAddrs {
				do {
					let view = UICommonComponents.Form.FieldLabel(
						title: NSLocalizedString("MONERO ADDRESS", comment: "")
					)
					view.isHidden = true
					self.resolvedXMRAddr_label = view
					self.addSubview(view)
				}
				do {
					let view = UICommonComponents.FormTextViewContainerView(
						placeholder: nil
					)
					view.set(isEnabled: false)
					view.isImmutable = true
					view.isHidden = true
					self.resolvedXMRAddr_inputView = view
					self.addSubview(view)
				}
				//
				do {
					let view = UICommonComponents.Form.FieldLabel(
						title: NSLocalizedString("PAYMENT ID", comment: "")
					)
					view.isHidden = true
					self.resolvedPaymentID_label = view
					self.addSubview(view)
				}
				do {
					let view = UICommonComponents.FormTextViewContainerView(
						placeholder: nil
					)
					view.set(isEnabled: false)
					view.isImmutable = true
					view.isHidden = true
					self.resolvedPaymentID_inputView = view
					self.addSubview(view)
				}
				//
				do {
					let view = UICommonComponents.DetectedIconAndMessageView()
					view.isHidden = true
					self.addSubview(view)
					self.detected_iconAndMessageView = view
				}
			}
			self.updateBounds() // initial frame, to get h
			self.startObserving()
		}
		func startObserving()
		{
		}
		//
		// Accessors - Overrides
		override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
		{
			for (_, subview) in self.subviews.enumerated() {
				if subview.hitTest(self.convert(point, to: subview), with: event) != nil {
					return true
				}
			}
			return false // do not accept touches on self - this way, touches will be passed through to form w/o excluding subviews that want to be interactive
		}
		//
		// Accessors
		var isResolving: Bool {
			// different, consistent ways to check this…
//			return self.resolving_activityIndicator.isHidden == false
			return self.oaResolverRequestMaker != nil // because we say we must set it back to nil when done resolving
		}
		//
		var new_h: CGFloat {
			// if any resolved/detected fields are not displaying, the 'resolving' act. ind. might be visible and so would be the bottom-most view - it would be nice to formalize that with typed modes
			if self.resolving_activityIndicator.isHidden == false {
				return self.resolving_activityIndicator!.frame.origin.y + self.resolving_activityIndicator!.frame.size.height
			}
			if let view = self.detected_iconAndMessageView {
				if view.isHidden == false {
					return view.frame.origin.y + view.frame.size.height // this works because if any of the detected/resolved payment id (below addr field) is visible, self.detected_iconAndMessageView will not be hidden
				}
			}
			if let view = self.resolvedXMRAddr_inputView {
				if view.isHidden == false {
					return view.frame.origin.y + view.frame.size.height // but the 'detected' view won't necessarily be showing if we're only showing the address
				}
			}
			// otherwise..
			if self.selectedContact == nil {
				return self.inputField.frame.origin.y + self.inputField.frame.size.height
			}
			let pillView = self.selectedContactPillView!
			//
			return pillView.frame.origin.y + pillView.frame.size.height
		}
		var records: [Contact] { return ContactsListController.shared.records as! [Contact] }
		var searchString: String? {
			return self.inputField.text
		}
		var new_searchResults: [Contact] {
			guard let searchString = self.searchString, searchString != "" else {
				return self.records // unfiltered
			}
			var results = [Contact]()
			for (_, record) in self.records.enumerated() {
				let matchAgainstField_value = record.fullname!
				let range = matchAgainstField_value.range(
					of: searchString,
					options: [.caseInsensitive, .diacriticInsensitive],
					range: nil,
					locale: nil
				)
				if range != nil {
					results.append(record)
				}
			}
			return results
		}
		//
		// Imperatives - UI state modifications
		func clearAndReset()
		{
			self.unpickSelectedContact_andRedisplayInputField(
				skipFocusingInputField: true // do not re-focus input
			)
			self.inputField.text = ""
			self._hide_resolved_XMRAddress()
			self._hide_resolved_paymentID()
		}
		func _removeSelectedContactPillView()
		{
			let hadExistingContact = self.selectedContact != nil
			let existing_selectedContact = self.selectedContact
			self.selectedContact = nil
			if self.selectedContactPillView != nil {
				self.selectedContactPillView!.removeFromSuperview()
				self.selectedContactPillView = nil
			}
			do {
				self.set(resolvingIndicatorIsVisible: false) // just in case it was visible
				self.oaResolverRequestMaker = nil // cancel existing requests, if any; and we must do this /before/ the didClearPickedContact_fn callback so that the consumer can check if we're still resolving
			}
			if self.displayMode == .paymentIds_andResolvedAddrs {
				self._hide_resolved_XMRAddress()
				self._hide_resolved_paymentID()
			}
			if hadExistingContact {
				if let fn = self.didClearPickedContact_fn {
					fn(existing_selectedContact!)
				}
			}
		}
		//
		var searchResults: [Contact]?
		func _searchForAndDisplaySearchResults()
		{
			self.searchResults = self.new_searchResults
			self.autocompleteResults_inputAccessoryView.collectionView.reloadData()
			//
			assert(self.searchResults != nil)
			if self.searchResults!.count == 0 {
				self.__removeAllAndHideSearchResults() // to 'remove' them is slightly redundant but not wrong here
				return
			}
			//
			self.autocompleteResults_inputAccessoryView.isHidden = false
		}
		func __removeAllAndHideSearchResults()
		{
			self.searchResults = nil
			self.autocompleteResults_inputAccessoryView.isHidden = true
			self.updateBounds()
		}
		func __clearAndHideInputLayer()
		{
			if self.inputField.isFirstResponder {
				self.inputField.resignFirstResponder()
			}
			self.inputField.isHidden = true
			self.inputField.text = ""
		}
		//
		var oaResolverRequestMaker: OpenAliasResolverRequestMaker?
		func pick(contact: Contact)
		{
			self.pick(
				contact: contact,
				skipOAResolve: false,
				useContactPaymentID: true
			)
		}
		func pick(
			contact: Contact,
			skipOAResolve: Bool = false,
			useContactPaymentID: Bool = true
		) { // This function must also be able to handle being called while a contact is already selected
			//
			
			if self.selectedContact != nil {
				if self.selectedContact! == contact {
					// nothing to do - same contact already selected
					return
				}
			}
			//
			let doesNeedToResolve = contact.hasOpenAliasAddress
			self.oaResolverRequestMaker = nil // deinit any existing; should cancel the existing request
			// only not setting resolvingIndicatorIsVisible here b/c we always do it just below
			//
			self.__removeAllAndHideSearchResults()
			self._removeSelectedContactPillView() // but don't do stuff like focusing the input layer
			self.__clearAndHideInputLayer()
			//
			self.selectedContact = contact
			self._display(pickedContact: contact)
			//
			self.set(resolvingIndicatorIsVisible: !skipOAResolve && doesNeedToResolve)
			if doesNeedToResolve {
				if skipOAResolve != true {
					let parameters = ContactPickerOpenAliasResolverRequestMaker.Parameters(
						address: contact.address,
						oaResolve__preSuccess_terminal_validationMessage_fn:
						{ [unowned self] (localizedString) in
							self.set(resolvingIndicatorIsVisible: false)
							self.oaResolverRequestMaker = nil // must free, and before call-back
							do {
								if self.displayMode == .paymentIds_andResolvedAddrs {
									self._hide_resolved_XMRAddress()
									self._hide_resolved_paymentID()
								}
							}
							if let fn = self.oaResolve__preSuccess_terminal_validationMessage_fn {
								fn(localizedString)
							}
						},
						oaResolve__success_fn:
						{ [unowned self] (resolved_xmr_address, payment_id, tx_description) in
							self.set(resolvingIndicatorIsVisible: false)
							self.oaResolverRequestMaker = nil // must free, and before call-back
							do {
								if self.displayMode == .paymentIds_andResolvedAddrs {
									let generator = UINotificationFeedbackGenerator()
									generator.prepare()
									generator.notificationOccurred(.success)
									//
									self._display(resolved_XMRAddress: resolved_xmr_address)
									if useContactPaymentID {
										if payment_id != nil && payment_id != "" {
											self._display(resolved_paymentID: payment_id!)
										} else {
											self._hide_resolved_paymentID()
										}
									} else {
										self._hide_resolved_paymentID()
									}
								}
							}
							if let fn = self.oaResolve__success_fn {
								fn(resolved_xmr_address, payment_id, tx_description)
							}
						}
					)
					let resolver = ContactPickerOpenAliasResolverRequestMaker(parameters: parameters)
					self.oaResolverRequestMaker = resolver
					DispatchQueue.main.async
					{ // placing this on "next tick" so as to allow self.didPickContact_fn not to race with a failure to resolve due to no connection
						resolver.resolve()
					}
				}
			} else {
				if self.displayMode == .paymentIds_andResolvedAddrs {
					self._hide_resolved_XMRAddress()
					if useContactPaymentID {
						if contact.payment_id != nil && contact.payment_id != "" {
							self._display(resolved_paymentID: contact.payment_id!)
						} else {
							// TODO: check if this is an integrated address. if it is, decode it, and display resolved
							self._hide_resolved_paymentID() // just in case - and so we don't have to make sure to hide it later
							// TODO: assert we think this is a monero addr first?
							let (err_str, decodedAddress) = MyMoneroCore.shared_objCppBridge.decoded(address: contact.address)
							if err_str != nil {
								DDLog.Warn("UICommonComponents.ContactPicker", "Couldn't decode CONTACT's non-OA address as a Monero address!")
								assert(false) // We're never expecting this here
								// TODO: implement something like this: (but named discretely obvs)
								//									if let fn = self.finishedValidatingTextInput_foundInvalidMoneroAddress_fn {
								//										fn()
								//									}
								return // just return silently
							}
							let integratedAddress_paymentId = decodedAddress!.intPaymentId
							let isIntegratedAddress = integratedAddress_paymentId != nil && integratedAddress_paymentId! != "" ? true : false
							if isIntegratedAddress {
								self._display(resolved_paymentID: integratedAddress_paymentId!) // just for display - Send is smart enough to ignore/nil
							}
						}
					} else {
						self._hide_resolved_paymentID()
					}
				}
				let generator = UINotificationFeedbackGenerator()
				generator.prepare()
				generator.notificationOccurred(.success)
			}
			// making sure to call this callback /after/ having set self.oaResolverRequestMaker so that isResolving will be true if consumer asks for it
			if let fn = self.didPickContact_fn {
				fn(contact, doesNeedToResolve)
			}
		}
		func _display(pickedContact: Contact)
		{
			if self.selectedContactPillView == nil {
				let view = SelectedContactPillView()
				view.xButton_tapped_fn =
				{ [unowned self] in
					if self.inputField.isEnabled == false {
						DDLog.Info("UICommonComponents", "Disallowing user unpick of contact while inputField is disabled.")
						return
					}
					self.unpickSelectedContact_andRedisplayInputField(skipFocusingInputField: false)
				}
				view.set(contact: self.selectedContact!)
				self.selectedContactPillView = view
				self.addSubview(view)
			} else {
				self.selectedContactPillView!.set(contact: self.selectedContact!)
			}
		}
		func unpickSelectedContact_andRedisplayInputField(
			skipFocusingInputField: Bool = false
		) {
			self._removeSelectedContactPillView()
			self.inputField.isHidden = false
			if skipFocusingInputField != true {
				DispatchQueue.main.async
				{ [unowned self] in// to decouple redisplay of input layer and un-picking from the display of the unfiltered results triggered by this focus:
					self.inputField.becomeFirstResponder()
				}
			}
		}
		//
		// Imperatives - Resolving - Interface
		func cancelAny_oaResolverRequestMaker()
		{
			self.set(resolvingIndicatorIsVisible: false)
			self.oaResolverRequestMaker = nil
		}
		//
		// Imperatives - Resolving indicator
		func set(resolvingIndicatorIsVisible: Bool)
		{
			if resolvingIndicatorIsVisible {
				self.resolving_activityIndicator.show()
			} else {
				self.resolving_activityIndicator.hide()
			}
			self.updateBounds()
		}
		//
		// Imperatives - Resolved values
		func _display(resolved_XMRAddress value: String)
		{
			self.resolvedXMRAddr_inputView!.textView.text = value
			self.resolvedXMRAddr_label!.isHidden = false
			self.resolvedXMRAddr_inputView!.isHidden = false
			/* not going to show this for address only
			self.detected_iconAndMessageView!.isHidden = false
			*/
			self.updateBounds()
		}
		func _hide_resolved_XMRAddress()
		{
			self.resolvedXMRAddr_label!.isHidden = true
			self.resolvedXMRAddr_inputView!.isHidden = true
			self.resolvedXMRAddr_inputView!.textView.inputView = nil
			/* since we're not showing this for addr only, we don't need to worry about hiding it for addr only
			if self.resolvedPaymentID_inputView!.isHidden == true {
				self.detected_iconAndMessageView!.isHidden = true
			}
			*/
			self.updateBounds()
		}
		func _display(resolved_paymentID value: String)
		{
			self.resolvedPaymentID_inputView!.textView.text = value
			self.resolvedPaymentID_label!.isHidden = false
			self.resolvedPaymentID_inputView!.isHidden = false
			self.detected_iconAndMessageView!.isHidden = false
			self.updateBounds()
		}
		func _hide_resolved_paymentID()
		{
			self.resolvedPaymentID_label!.isHidden = true
			self.resolvedPaymentID_inputView!.isHidden = true
			self.resolvedPaymentID_inputView!.textView.inputView = nil
			if self.resolvedXMRAddr_inputView!.isHidden == true {
				self.detected_iconAndMessageView!.isHidden = true
			}
			self.updateBounds()
		}
		//
		// Imperatives - Internal - Parent scrolling UX
		// NOTE: This may be somewhat fragile and make problems.
		func temporarilyDisableParentScrolling()
		{
			self.parentScrollView?.isScrollEnabled = false
		}
		func reEnableParentScrolling()
		{
			self.parentScrollView?.isScrollEnabled = true
		}
		//
		// Imperatives - Internal - Layout
		private func updateBounds()
		{
			// would be nice if we could batch this per runloop to avoid redundant calculations
			// hopefully devices are fast enough for it to be negligible
			
			self.sizeAndLayOutSubviews()
			self.bounds = CGRect(
				x: 0,
				y: 0,
				width: self.bounds.size.width,
				height: self.new_h
			)
			assert(self.bounds.size.height != 0)
			if let fn = self.didUpdateHeight_fn {
				fn()
			}
		}
		func sizeAndLayOutSubviews()
		{
			let bottomMostView_beforeAccessoryAndResolvingViews: UIView!
			if self.selectedContact == nil {
				self.inputField.frame = CGRect(
					x: 0,
					y: 0,
					width: self.frame.size.width, // size to width
					height: self.inputField.frame.size.height
				)
				bottomMostView_beforeAccessoryAndResolvingViews = self.inputField
			} else {
				guard let pillView = self.selectedContactPillView else {
					assert(false)
					return
				}
				pillView.layOut(
					withX: 0,
					y: 0,
					inWidth: self.frame.size.width
				)
				bottomMostView_beforeAccessoryAndResolvingViews = pillView
			}
			//
			var bottomMostView_beforeAccessoryViews: UIView!
			if self.resolving_activityIndicator.isHidden == false {
				let x: CGFloat = 8 
				self.resolving_activityIndicator.frame = CGRect(
					x: x,
					y: bottomMostView_beforeAccessoryAndResolvingViews.frame.origin.y + bottomMostView_beforeAccessoryAndResolvingViews.frame.size.height + UICommonComponents.GraphicAndLabelActivityIndicatorView.marginAboveActivityIndicatorBelowFormInput,
					width: self.frame.size.width - 2*x,
					height: self.resolving_activityIndicator.new_height_withoutVSpacing // since components below will space themselves
				).integral
				bottomMostView_beforeAccessoryViews = self.resolving_activityIndicator
			} else {
				bottomMostView_beforeAccessoryViews = bottomMostView_beforeAccessoryAndResolvingViews
			}
			//
			if self.displayMode == .paymentIds_andResolvedAddrs {
				assert(bottomMostView_beforeAccessoryViews != nil)
				assert(self.resolvedXMRAddr_inputView != nil)
				assert(self.resolvedPaymentID_inputView != nil)
				let labels_x =  CGFloat.form_label_margin_x - CGFloat.form_input_margin_x // this is a little weird but is the tradeoff for having self positioned at input_x automatically instead of 0
				if self.resolvedXMRAddr_inputView!.isHidden == false {
					let yOffset = bottomMostView_beforeAccessoryViews.frame.origin.y + bottomMostView_beforeAccessoryViews.frame.size.height + 10
					self.resolvedXMRAddr_label!.frame = CGRect(
						x: labels_x,
						y: yOffset,
						width: self.frame.size.width - 2*labels_x,
						height: self.resolvedXMRAddr_label!.frame.size.height
					).integral
					self.resolvedXMRAddr_inputView!.frame = CGRect(
						x: 0,
						y: self.resolvedXMRAddr_label!.frame.origin.y + self.resolvedXMRAddr_label!.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
						width: self.frame.size.width,
						height: self.resolvedXMRAddr_inputView!.heightThatFits(width: self.frame.size.width)
					).integral
				}
				if self.resolvedPaymentID_inputView!.isHidden == false {
					let mostPreviouslyVisibleView: UIView
					let topMargin: CGFloat
					do {
						if self.resolvedXMRAddr_inputView!.isHidden == false {
							mostPreviouslyVisibleView = self.resolvedXMRAddr_inputView!
							topMargin = 10
						} else {
							mostPreviouslyVisibleView = bottomMostView_beforeAccessoryViews
							topMargin = 8
						}
					}
					let yOffset = mostPreviouslyVisibleView.frame.origin.y + mostPreviouslyVisibleView.frame.size.height + topMargin
					self.resolvedPaymentID_label!.frame = CGRect(
						x: labels_x,
						y: yOffset,
						width: self.frame.size.width - 2*labels_x,
						height: self.resolvedPaymentID_label!.frame.size.height
					).integral
					self.resolvedPaymentID_inputView!.frame = CGRect(
						x: 0,
						y: self.resolvedPaymentID_label!.frame.origin.y + self.resolvedPaymentID_label!.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
						width: self.frame.size.width,
						height: self.resolvedPaymentID_inputView!.heightThatFits(width: self.frame.size.width)
					).integral
				}
				if self.detected_iconAndMessageView!.isHidden == false {
					let mostPreviouslyVisibleView: UIView
					do {
						if self.resolvedPaymentID_inputView!.isHidden == false {
							mostPreviouslyVisibleView = self.resolvedPaymentID_inputView!
						} else {
							mostPreviouslyVisibleView = self.resolvedXMRAddr_inputView!
						}
					}
					let yOffset = mostPreviouslyVisibleView.frame.origin.y + mostPreviouslyVisibleView.frame.size.height + (7 - UICommonComponents.FormInputCells.imagePadding_y)
					self.detected_iconAndMessageView!.frame = CGRect(
						x: labels_x,
						y: yOffset,
						width: self.frame.size.width - 2*labels_x,
						height: self.detected_iconAndMessageView!.frame.size.height
					).integral
				}
			}
		}
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			self.sizeAndLayOutSubviews()
		}
		
		func handleLookupError(error: String) {
			debugPrint("Handle the error");
		}
		
		//
		// Imperatives - Internal - Manually input addresses
		func validateTextInputAsPossibleAddress()
		{
			debugPrint("validateTextInputAsPossibleAddress invoked")
			assert(self.inputMode == .contactsAndAddresses)
			let possibleAddress = self.inputField.text ?? ""
			let hasEnteredNoAddressContent = possibleAddress == ""
			//
			self.oaResolverRequestMaker = nil // will call its own .cancel… on its deinit
			self.set(resolvingIndicatorIsVisible: false) // jic cancellation needs
			//
			self._hide_resolved_XMRAddress()
			self._hide_resolved_paymentID()
			//
			if let fn = self.changedTextContent_fn {
				fn() // allow observers to clear validation msg
			}
			//
			if hasEnteredNoAddressContent {
				if let fn = self.clearedTextContent_fn {
					fn() // allow consumers to re-show their add payment id buttons, etc
				}
				return
			}
			//
			self.isValidatingOrResolvingNonZeroTextInput = true // essential that it's set back to false before any subsequent exit
			if let fn = willValidateNonZeroTextInput_fn {
				fn()
			}
			// Yat checking
			/*						oaResolve__success_fn:
			{ [unowned self] (resolved_xmr_address, payment_id, tx_description) in
						 self.set(resolvingIndicatorIsVisible: false)
						 self.oaResolverRequestMaker = nil // must free, and before call-back
						 do {
							 if self.displayMode == .paymentIds_andResolvedAddrs {
								 let generator = UINotificationFeedbackGenerator()
								 generator.prepare()
								 generator.notificationOccurred(.success)
								 //
								 self._display(resolved_XMRAddress: resolved_xmr_address)
								 if useContactPaymentID {
									 if payment_id != nil && payment_id != "" {
										 self._display(resolved_paymentID: payment_id!)
									 } else {
										 self._hide_resolved_paymentID()
									 }
								 } else {
									 self._hide_resolved_paymentID()
								 }
							 }
						 }
						 if let fn = self.oaResolve__success_fn {
							 fn(resolved_xmr_address, payment_id, tx_description)
						 }
					 }*/
			debugPrint("Do Yat checking")
			
			// This could still be a Yat address -- let's check
			debugPrint(type(of: possibleAddress))
			let Yat = YatLookup(debugMode: true)
			let isValidYat = false
			
			if Yat.containsEmojis(possibleAddress: possibleAddress) {
				self.set(resolvingIndicatorIsVisible: true)
				debugPrint("Possible Yat")
				do {
					let isValidYat = try Yat.isValidYatHandle(possibleAddress: possibleAddress)
					if (!isValidYat) {
						return
					}
					let yatResponse = try Yat.performLookup(yatHandle: possibleAddress, completion: {response in

						debugPrint("UPTO 1")
						if (response.isFailure == true) {
							if let fn = self.yatResolve__preSuccess_terminal_validationMessage_fn {
								fn("The Yat handle \"\(possibleAddress)\" is not owned by anyone")
							}
						}

						debugPrint("UPTO 2")
						debugPrint(response)
						let responseDict = response.value
						debugPrint(responseDict)
						if let recordCount = responseDict?.count {
							switch (recordCount) {
								case 0:
									debugPrint("UPTO CASE 0")
									if let fn = self.yatResolve__preSuccess_terminal_validationMessage_fn {
										fn("The Yat handle \(possibleAddress) does not have any Monero addresses associated with it")
									}
								case 1:
									debugPrint("UPTO CASE 1")
									let address = responseDict?.first?.value
									self._display(resolved_XMRAddress: address!)
									if let fn = self.yatResolve__success_fn {
										fn("Yat success YAY!!!!!!!!!!!!!!")
									}
								case 2:
									debugPrint("UPTO CASE 2")
									self._display(resolved_XMRAddress: (responseDict?["0x1001"]!)!)
									if let fn = self.yatResolve__success_fn {
										fn("Yat success YAY!!!!!!!!!!!!!!")
									}
									// Use
								default:
									print("Shouldn't ever see this")
							}
						
						} else {
							// is this even possible?
							debugPrint("Didn't get a count value")
						}
					})
					
				} catch YatLookupError.addressContainsNonEmojiCharacters {
					if let fn = self.yatResolve__preSuccess_terminal_validationMessage_fn {
						fn("It looks like you're trying to pay a Yat, but Yat addresses don't support non-emoji characters")
					}
					return
				} catch YatLookupError.addressContainsInvalidEmojis(let error) {
					debugPrint(error)
					if let fn = self.yatResolve__preSuccess_terminal_validationMessage_fn {
						fn(error)
					}
				} catch YatLookupError.yatLengthInvalid {
					if let fn = self.yatResolve__preSuccess_terminal_validationMessage_fn {
						fn("A Yat can only be a maximum of five emojis")
					}
				} catch YatLookupError.yatNotFound {
					debugPrint("YAT NOT OWNED")
					if let fn = self.yatResolve__preSuccess_terminal_validationMessage_fn {
						fn("The Yat \"\(possibleAddress)\" is not owned by anyone")
					}
				} catch let error as YatLookupError {
					debugPrint("Caught an error")
					debugPrint(error)
					
					if let fn = self.yatResolve__preSuccess_terminal_validationMessage_fn {
						fn("Unexpected error occurred: \(error). Please report this to the MyMonero team via our website's support functionality")
					}
					
				} catch {
					debugPrint("We should never see this text")
				}
			}

			// Do stuff with lookup response
			debugPrint("\(possibleAddress) is a valid Yat Handle")
			//YatLookup.lookupMoneroAddresses(yatHandle: possibleAddress)
			
			
			if let fn = self.finishedValidatingTextInput_foundInvalidMoneroAddress_fn {
				debugPrint("Inside fn2")
				fn()
			}
				//
			debugPrint("Could be OA address?")
			let couldBeOAAddress = OpenAlias.containsPeriod_excludingAsXMRAddress_qualifyingAsPossibleOAAddress(possibleAddress)
			if couldBeOAAddress == false {
				let (err_str, decodedAddressComponents) = MyMoneroCore.shared_objCppBridge.decoded(address: possibleAddress)
				if let _ = err_str {
					DDLog.Warn("UICommonComponents.ContactPicker", "Couldn't decode as a Monero address.")
					self.isValidatingOrResolvingNonZeroTextInput = false // un-set due to imminent exit
					if let fn = self.finishedValidatingTextInput_foundInvalidMoneroAddress_fn {
						fn()
					}
					return // just return silently
				}
				let integratedAddress_paymentId = decodedAddressComponents!.intPaymentId
				let isIntegratedAddress = integratedAddress_paymentId != nil && integratedAddress_paymentId! != "" ? true : false
				var returning_paymentID: MoneroPaymentID?
				if isIntegratedAddress {
					returning_paymentID = integratedAddress_paymentId // use this one instead
//						self._display(resolved_XMRAddress: decodedAddressComponents!.decodedAddress) // would be super cool to do this here
					self._display(resolved_paymentID: returning_paymentID!)
				}
				self.isValidatingOrResolvingNonZeroTextInput = false // un-set due to imminent exit
				self.hasValidTextInput_moneroAddress = true // IS valid; isValidOA is already false
				if let fn = self.finishedValidatingTextInput_foundValidMoneroAddress_fn {
					// consumer can display yielded payment id
					fn(returning_paymentID)
				}
				return
			}

			// then this could be an OA address…
			self.set(resolvingIndicatorIsVisible: true)
			if let fn = self.willBeginResolvingPossibleOATextInput_fn {
				fn()
			}
			let parameters = ContactPickerOpenAliasResolverRequestMaker.Parameters(
				address: possibleAddress,
				oaResolve__preSuccess_terminal_validationMessage_fn:
				{ [unowned self] (localizedString) in
					self.set(resolvingIndicatorIsVisible: false)
					self.oaResolverRequestMaker = nil // must free, and before call-back
					//
					self._hide_resolved_XMRAddress()
					self._hide_resolved_paymentID()
					//
					self.isValidatingOrResolvingNonZeroTextInput = false // un-set due to imminent exit
					// but set no success flags
					//
					if let fn = self.oaResolve__preSuccess_terminal_validationMessage_fn {
						fn(localizedString)
					}
				},
				oaResolve__success_fn:
				{ [unowned self] (resolved_xmr_address, payment_id, tx_description) in
					self.set(resolvingIndicatorIsVisible: false)
					self.oaResolverRequestMaker = nil // must free, and before call-back
					do {
						self._display(resolved_XMRAddress: resolved_xmr_address)
						if payment_id != nil && payment_id != "" {
							self._display(resolved_paymentID: payment_id!)
						} else {
							self._hide_resolved_paymentID()
						}
					}
					//
					self.isValidatingOrResolvingNonZeroTextInput = false // un-set due to imminent exit
					self.hasValidTextInput_resolvedOAAddress = true // IS valid; isValidMoneroAddress is already false
					//
					if let fn = self.oaResolve__success_fn {
						fn(resolved_xmr_address, payment_id, tx_description)
					}
				}
			)
			let resolver = ContactPickerOpenAliasResolverRequestMaker(parameters: parameters)
			self.oaResolverRequestMaker = resolver
			resolver.resolve()
		}
		//
		// Imperatives - Convenience - Setting inputField text
		func setInputField(text: String)
		{
			self.inputField.text = text
			/*
			self.inputField.sendActions(for: .editingChanged) // so we trigger our .editingChanged observer
			Since this comes with a delay for regular usage, I'm going to bypass and just say '0' delay - we're done "typing"
			*/
			self.__inputField_editingChanged(withTypingDelayOverride: 0)
		}
		//
		// Delegation - Text field
//		func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
//		{
//			return true
//		}
		func textFieldDidBeginEditing(_ textField: UITextField)
		{
			debugPrint("textFieldDidBeginEditing")
			self._searchForAndDisplaySearchResults()
			if let fn = self.textFieldDidBeginEditing_fn {
				fn(textField)
			}
		}
		func textFieldDidEndEditing(_ textField: UITextField)
		{
			self.__removeAllAndHideSearchResults()
			if let fn = self.textFieldDidEndEditing_fn {
				fn(textField)
			}
		}
		func textFieldShouldReturn(_ textField: UITextField) -> Bool
		{
			return true
		}
		func textField(
			_ textField: UITextField,
			shouldChangeCharactersIn range: NSRange,
			replacementString string: String
		) -> Bool {
			return true
		}
		var mediumDelay_waitingToFinishTypingTimer: Timer?
		@objc func inputField_editingChanged()
		{
			self.__inputField_editingChanged() // use default (non-programmatic) typing delay
		}
		static let actualUsage_typingDelay: TimeInterval = 0.6 // so slow b/c mobile typing is slower than keyboard
		func __inputField_editingChanged(
			// v--- only provide this in special cases:
			withTypingDelayOverride typingDelay: TimeInterval = ContactAndAddressPickerView.actualUsage_typingDelay
		) {
			debugPrint("__inputField_editingChanged")
			do { // zeroing text input state
				self.hasValidTextInput_moneroAddress = false
				self.hasValidTextInput_resolvedOAAddress = false
			}
			do { // cancel just in case
				self.set(resolvingIndicatorIsVisible: false)
				self.oaResolverRequestMaker = nil // must free, and before call-back
			}
			if self.inputField.isHidden == true {
//				|| self.inputField.isFirstResponder == false
				// commenting this as I think we do we need to handle programmatic entries
				DDLog.Warn("ContactPicker", "__inputField_editingChanged called but skipping update as field is hidden... verify this is desired.")
				return // in case we're editing .text programmatically
			}
			//
			self._searchForAndDisplaySearchResults() // b/c this computation is local, and cheap, we can do it immediately w/o waiting for delay
			do {
				if self.mediumDelay_waitingToFinishTypingTimer != nil {
					self.mediumDelay_waitingToFinishTypingTimer!.invalidate()
					self.mediumDelay_waitingToFinishTypingTimer = nil
				}
				//
				func editingDidFinish()
				{
					DispatchQueue.main.async
					{ [unowned self] in
						if let fn = self.didFinishTypingInInput_afterMediumDelay_fn {
							fn()
						}
					}
					self.didFinishTypingInInput_afterMediumDelay()
				}
				if typingDelay == 0 {
					editingDidFinish() // immediately
				} else {
					// wait for sufficient pause in typing
					self.mediumDelay_waitingToFinishTypingTimer = Timer.scheduledTimer(
						withTimeInterval: typingDelay,
						repeats: false,
						block:
						{ [unowned self] (timer) in
							do {
								assert(timer == self.mediumDelay_waitingToFinishTypingTimer)
								self.mediumDelay_waitingToFinishTypingTimer!.invalidate() // necessary?
								self.mediumDelay_waitingToFinishTypingTimer = nil
							}
							editingDidFinish()
						}
					)
				}
			}
		}
		//
		// Delegation - Text field interaction signals
		func didFinishTypingInInput_afterMediumDelay()
		{
			if self.inputMode == .contactsAndAddresses {
				self.validateTextInputAsPossibleAddress() // we'll do this even though results may be visible… because it's very unlikely that results will show up for an address/domain
			}
		}
		//
		// Delegation - CollectionView
		func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
		{
			return self.searchResults != nil ? self.searchResults!.count : 0
		}
		func collectionView(
			_ collectionView: UICollectionView,
			layout collectionViewLayout: UICollectionViewLayout,
			sizeForItemAt indexPath: IndexPath
		) -> CGSize {
			guard let searchResults = self.searchResults else {
				// I think this probably shouldn't be happening but I'm just going to assume here that the results were cleared automatically by a programmatic form hydration and ignore this b/c it looks currently like an effectively harmless race
				return .zero
			}
			let contact = searchResults[indexPath.row]
			let w = ContactPickerSearchResultsCellView.widthOfSelf(withContact: contact)
			let h = ContactPickerSearchResultsCellView.h
			//
			return CGSize(width: w, height: h)
		}
		func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
		{
			return 0
		}
		func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
		{
			return 3
		}
		func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
		{
			let dequeued_cell = collectionView.dequeueReusableCell(
				withReuseIdentifier: ContactPickerSearchResultsCellView.reuseIdentifier,
				for: indexPath
			)
			var cell = dequeued_cell as? ContactPickerSearchResultsCellView
			if cell == nil {
				cell = ContactPickerSearchResultsCellView()
			}
			guard let searchResults = self.searchResults else {
				// I think this probably shouldn't be happening but I'm just going to assume here that the results were cleared automatically by a programmatic form hydration and ignore this b/c it looks currently like an effectively harmless race
				return cell!
			}
			let contact = searchResults[indexPath.row]
			cell!.configure(
				withContact: contact,
				isLast: (indexPath.row == searchResults.count - 1)
			)
			//
			return cell!
		}
		func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
		{
			let contact = self.searchResults![indexPath.row]
			self.pick(contact: contact)
		}
		//
		// Delegation - Scrolling
		func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
		{
			self.temporarilyDisableParentScrolling()
		}
		func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
		{
			self.reEnableParentScrolling()
		}
		func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
		{ // TODO: redundant?
			self.reEnableParentScrolling()
		}
	}
	//
	class ContactPickerSearchResultsInputAccessoryView: UIView
	{
		//
		// Constants/Static
		static let h: CGFloat = ContactPickerSearchResultsCellView.h
		//
		// Properties
		var collectionView: UICollectionView!
		//
		// Lifecycle - Init
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
			do {
				self.backgroundColor = UIColor.contentBackgroundColor
				self.translatesAutoresizingMaskIntoConstraints = false // this must be turned off for height not to end up being set to 0 by conflicting constraint
			}
			do {
				let layout = UICollectionViewFlowLayout()
				layout.scrollDirection = .horizontal
				//
				let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
				view.contentInset = UIEdgeInsets.init(top: 0, left: 3, bottom: 0, right: 3)
				view.showsHorizontalScrollIndicator = false
				view.layer.masksToBounds = true
				view.backgroundColor = self.backgroundColor
				view.register(
					ContactPickerSearchResultsCellView.self,
					forCellWithReuseIdentifier: ContactPickerSearchResultsCellView.reuseIdentifier
				)
				self.collectionView = view
				self.addSubview(view)
			}
		}
		//
		// Lifecycle - Teardown
		deinit
		{
			self.teardown()
		}
		func teardown()
		{
		}
		//
		// Overrides - Accessors
		override var intrinsicContentSize: CGSize {
			return CGSize(
				width: self.frame.size.width,
				height: ContactPickerSearchResultsInputAccessoryView.h
			)
		}
		//
		// Overrides - Imperatives
		override func layoutSubviews()
		{
			super.layoutSubviews()
			self.collectionView.frame = self.bounds
		}
	}
	class ContactPickerSearchResultsCellView: UICollectionViewCell
	{
		//
		// Constants
		static let reuseIdentifier = "ContactPickerSearchResultsCellView"
		static let h: CGFloat = 8 * 5
		static let max_w: CGFloat = 180
		static let emojiLabel_x: CGFloat = 0
		static let emojiLabel_w: CGFloat = 46
		static let titleLabel_x_relativeToEmojiLabel: CGFloat = -3
		static let padding_right: CGFloat = 12 - titleLabel_x_relativeToEmojiLabel
		static let titleFont: UIFont = UIFont.middlingSemiboldSansSerif
		static func widthOfSelf(withContact contact: Contact) -> CGFloat
		{
			let string = contact.fullname!
			let constraintRect = CGSize(
				width: ContactPickerSearchResultsCellView.max_w,
				height: h
			)
			let boundingBox = string.boundingRect(
				with: constraintRect,
				options: .usesLineFragmentOrigin,
				attributes: [
					.font: ContactPickerSearchResultsCellView.titleFont
				],
				context: nil
			)
			let titleString_w = ceil(boundingBox.width)
			//
			return emojiLabel_w + ContactPickerSearchResultsCellView.titleLabel_x_relativeToEmojiLabel + titleString_w + padding_right
		}
		//
		// Properties
		var emojiLabel = UILabel()
		var nameLabel = UILabel()
		//
		// Lifecycle - Init
		override init(frame: CGRect)
		{
			super.init(frame: frame)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			do {
				self.isOpaque = true // performance
				self.layer.cornerRadius = 4
				self.backgroundColor = UIColor(red: 252/255, green: 251/255, blue: 252/255, alpha: 1)
			}
			do {
				let view = UIView()
				view.backgroundColor = UIColor(red: 223/255, green: 222/255, blue: 223/255, alpha: 0.9)
				self.selectedBackgroundView = view
			}
			do {
				let view = self.emojiLabel
				view.font = UIFont.systemFont(ofSize: 16)
				view.numberOfLines = 1
				view.textAlignment = .center
				self.addSubview(view)
			}
			do {
				let view = self.nameLabel
				view.font = type(of: self).titleFont
				view.textAlignment = .left
				view.numberOfLines = 1
				view.lineBreakMode = .byTruncatingTail
				view.textColor = UIColor(rgb: 0x1D1B1D)
				self.addSubview(view)
			}
		}
		//
		// Overrides - Imperatives - Layout
		override func layoutSubviews()
		{
			super.layoutSubviews()
			do {
				let w: CGFloat = type(of: self).emojiLabel_w
				self.emojiLabel.frame = CGRect(x: type(of: self).emojiLabel_x, y: 0, width: w, height: self.frame.size.height)
			}
			do {
				let x = self.emojiLabel.frame.origin.x + self.emojiLabel.frame.size.width + type(of: self).titleLabel_x_relativeToEmojiLabel
				self.nameLabel.frame = CGRect(
					x: x,
					y: 0,
					width: self.frame.size.width - x - type(of: self).padding_right,
					height: self.frame.size.height
				)
			}
		}
		//
		// Imperatives - Configuration
		func configure(withContact contact: Contact, isLast: Bool)
		{
			self.isAccessibilityElement = true
			self.accessibilityTraits = UIAccessibilityTraits.button
			self.accessibilityIdentifier = "button.\(contact.fullname!)" // just going to assume this is unique >_>
			//
			self.emojiLabel.text = contact.emoji!
			self.nameLabel.text = contact.fullname!
		}
	}
	//
	class SelectedContactPillView: UIView
	{
		//
		// Constants
		static let visual__h: CGFloat = UIFont.shouldStepDownLargerFontSizes ? 31 : 35
		static let h = SelectedContactPillView.visual__h + 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
		
		static let emoji_w: CGFloat = UIFont.shouldStepDownLargerFontSizes ? 35 : 37
		static let xButton_leftMargin: CGFloat = 7
		static let xButton_side = SelectedContactPillView.visual__h
		//
		// Properties
		weak var contact: Contact? // in order to prevent deinit from occurring while property still set
		var xButton_tapped_fn: (() -> Void)!
		//
		let backgroundImageView = UIImageView(image: UICommonComponents.PushButtonCells.Variant.utility.stretchableImage)
		var emojiLabel = UILabel()
		var nameLabel = UILabel()
		var xButton = UIButton()
		//
		// Lifecycle - Init
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
			do {
				let view = self.backgroundImageView
				view.isUserInteractionEnabled = false
				self.addSubview(view)
			}
			do {
				let view = self.emojiLabel
				view.isUserInteractionEnabled = false
				view.font = UIFont.systemFont(ofSize: UIFont.shouldStepDownLargerFontSizes ? 13 : 15)
				view.numberOfLines = 1
				view.textAlignment = .center
				self.addSubview(view)
			}
			do {
				let view = self.nameLabel
				view.isUserInteractionEnabled = false
				view.font = UIFont.middlingBoldMonospace
				view.textAlignment = .left
				view.numberOfLines = 1
				view.lineBreakMode = .byTruncatingTail
				view.textColor = UIColor(rgb: 0xFCFBFC)
				self.addSubview(view)
			}
			do {
				let view = self.xButton
				let image = UIImage(named: "contactPicker_xBtnIcn")!
				view.contentVerticalAlignment = .center
				view.contentHorizontalAlignment = .center
				view.setImage(image, for: .normal)
				view.adjustsImageWhenHighlighted = true
				view.addTarget(self, action: #selector(xButton_tapped), for: .touchUpInside)
				self.addSubview(view)
			}
		}
		//
		// Lifecycle - Teardown
		deinit {
			self.teardown()
		}
		func teardown()
		{
			self.teardown_object()
		}
		func prepareForReuse()
		{
			self.teardown_object()
		}
		func teardown_object()
		{
			if self.contact != nil { // must check as we may call this redundantly to cover all cases
				self.stopObserving_contact()
				self.contact = nil
			}
		}
		func stopObserving_contact()
		{
			let contact = self.contact!
			NotificationCenter.default.removeObserver(
				self,
				name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName,
				object: contact
			)
			NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: contact)
			NotificationCenter.default.removeObserver(self, name: Contact.NotificationNames.infoUpdated.notificationName, object: contact)
		}
		//
		// Accessors - Overrides
		override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
		{
			for (_, subview) in self.subviews.enumerated() {
				if subview.hitTest(self.convert(point, to: subview), with: event) != nil {
					return true
				}
			}
			return false // do not accept touches on self - this way, touches will be passed through to form w/o excluding subviews that want to be interactive
		}
		//
		// Imperatives - Configuration
		func set(contact: Contact)
		{
			if self.contact != nil {
				if self.contact == contact {
					return
				}
				self.prepareForReuse()
			}
			self.contact = contact
			self.configureWithContact()
			self.startObserving_contact()
		}
		func startObserving_contact()
		{
			let contact = self.contact!
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(willBeDeinitialized),
				name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName,
				object: contact
			)
			NotificationCenter.default.addObserver(self, selector: #selector(willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: contact)
			NotificationCenter.default.addObserver(self, selector: #selector(infoUpdated), name: Contact.NotificationNames.infoUpdated.notificationName, object: contact)
		}
		//
		// Imperatives - Configuration
		func configureWithContact()
		{
			let contact = self.contact!
			self.nameLabel.text = contact.fullname!
			self.emojiLabel.text = contact.emoji!
			self.setNeedsLayout()
		}
		//
		// Interface - Layout - Imperatives
		public func layOut(
			withX x: CGFloat,
			y: CGFloat,
			inWidth containerWidth: CGFloat
		) {
			self.frame = CGRect(
				x: x,
				y: y,
				width: containerWidth, // just take up whole space so subviews can size accordingly
				height: SelectedContactPillView.h
			)
			// will trigger layoutSubviews()
		}
		override func layoutSubviews()
		{
			super.layoutSubviews()
			//
			assert(self.contact != nil, "Contact was nil")
			if self.contact == nil {
				return
			}
			//
			let visual__maxW = self.frame.size.width - 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
			let nameLabel_maxW = visual__maxW - SelectedContactPillView.emoji_w - SelectedContactPillView.xButton_leftMargin - SelectedContactPillView.xButton_side
			
			self.emojiLabel.frame = CGRect(
				x: UICommonComponents.PushButtonCells.imagePaddingForShadow_v,
				y: UICommonComponents.PushButtonCells.imagePaddingForShadow_v,
				width: SelectedContactPillView.emoji_w,
				height: SelectedContactPillView.visual__h
			)
			do {
				self.nameLabel.frame = CGRect(
					x: self.emojiLabel.frame.origin.x + self.emojiLabel.frame.size.width,
					y: UICommonComponents.PushButtonCells.imagePaddingForShadow_v,
					width: 0,
					height: SelectedContactPillView.visual__h
				)
				self.nameLabel.sizeToFit()
				self.nameLabel.frame = CGRect(
					x: self.nameLabel.frame.origin.x,
					y: self.nameLabel.frame.origin.y,
					width: min(nameLabel_maxW, self.nameLabel.frame.size.width),
					height: SelectedContactPillView.visual__h // must use full height or will not be vertically aligned
				)
			}
			do {
				let yOffset: CGFloat = 1
				self.xButton.frame = CGRect(
					x: self.nameLabel.frame.origin.x + self.nameLabel.frame.size.width + SelectedContactPillView.xButton_leftMargin,
					y: UICommonComponents.PushButtonCells.imagePaddingForShadow_v + yOffset,
					width: SelectedContactPillView.xButton_side,
					height: SelectedContactPillView.xButton_side - yOffset
				)
			}
			self.backgroundImageView.frame = CGRect(
				x: 0,
				y: 0,
				width: self.xButton.frame.origin.x + self.xButton.frame.size.width + UICommonComponents.PushButtonCells.imagePaddingForShadow_h,
				height: self.frame.size.height
			)
		}
		//
		// Delegation
		@objc func xButton_tapped()
		{
			self.xButton_tapped_fn()
		}
		//
		@objc func willBeDeleted()
		{
			self.xButton.sendActions(for: .touchUpInside) // simulate tap to unpick deleted contact - will clear
		}
		@objc func willBeDeinitialized()
		{
			self.xButton.sendActions(for: .touchUpInside) // simulate tap to unpick freed contact - will clear
		}
		@objc func infoUpdated()
		{
			self.configureWithContact()
		}
	}
	//
	
	//
	class ContactPickerOpenAliasResolverRequestMaker: OpenAliasResolverRequestMaker
	{
		struct Parameters
		{
			var address: String
			var oaResolve__preSuccess_terminal_validationMessage_fn: ((_ localizedString: String) -> Void)?
			var oaResolve__success_fn: ((_ resolved_xmr_address: MoneroAddress, _ payment_id: MoneroPaymentID?, _ tx_description: String?) -> Void)?
		}
		var parameters: Parameters
		init(parameters: Parameters)
		{
			self.parameters = parameters
		}
		// deinit already cancels the request, if any
		//
		// Imperatives
		func resolve()
		{
			self.resolve_lookupHandle = OpenAliasResolver.shared.resolveOpenAliasAddress(
				openAliasAddress: self.parameters.address,
				forCurrency: .monero,
				{ [weak self] ( // rather than unowned
					err_str: String?,
					addressWhichWasPassedIn: String?,
					response: OpenAliasResolver.OpenAliasResolverResponse?
				) in
					if self == nil {
						return
					}
					let this = self!
					if this.parameters.address != addressWhichWasPassedIn {
						assert(false, "another request's resolution was returned on this form… does that mean it wasn't cancelled from earlier?")
						return
					}
					//
					let handle_wasNil = this.resolve_lookupHandle == nil
					this.resolve_lookupHandle = nil
					//
					if err_str != nil {
						if let fn = this.parameters.oaResolve__preSuccess_terminal_validationMessage_fn {
							fn(err_str!)
						}
						return
					}
					// we'll only care about whether the handle was nil after err_str != nil b/c it can be nil on sync callback e.g. on network error
					if handle_wasNil {
						// something else may have cancelled the request or it was not able to even return yet (i.e. callback happened synchronously but on non-error case)
						assert(false)
						return
					}
					let cached_OAResolved_XMR_address = response!.moneroReady_address
					if cached_OAResolved_XMR_address == nil {
						if let fn = this.parameters.oaResolve__preSuccess_terminal_validationMessage_fn {
							fn(NSLocalizedString("OpenAlias address no longer lists Monero address", comment: ""))
							return
						}
					}
					let paymentID = response!.returned__payment_id
					let tx_description = response!.tx_description ?? ""
					if let fn = this.parameters.oaResolve__success_fn {
						fn(cached_OAResolved_XMR_address!, paymentID, tx_description)
					}
				}
			)
		}
	}
}
