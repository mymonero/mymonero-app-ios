//
//  ContactPicker.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/7/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UICommonComponents.Form
{
	class ContactPickerView: UIView, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource
	{
		//
		// Constants
		static let maxHeight: CGFloat = UICommonComponents.FormInputField.height + ContactPickerSearchResultsInlinePopoverView.maxHeight
		//
		// Properties
		var selectedContact: Contact?
		//
		var inputField = UICommonComponents.FormInputField(
			placeholder: NSLocalizedString("Enter contact name", comment: "")
		)
		var selectedContactPillView: SelectedContactPillView?
		var autocompleteResultsView: ContactPickerSearchResultsInlinePopoverView!
		var resolving_activityIndicator: UICommonComponents.ResolvingActivityIndicatorView!
		//
		var textFieldDidBeginEditing_fn: ((_ textField: UITextField) -> Void)?
		var textFieldDidEndEditing_fn: ((_ textField: UITextField) -> Void)?
		var didUpdateHeight_fn: ((Void) -> Void)?
		//
		var didPickContact_fn: ((_ contact: Contact, _ doesNeedToResolveItsOAAddress: Bool) -> Void)?
		var oaResolve__preSuccess_terminal_validationMessage_fn: ((_ localizedString: String) -> Void)?
		var oaResolve__success_fn: ((_ resolved_xmr_address: MoneroAddress, _ payment_id: MoneroPaymentID?, _ tx_description: String?) -> Void)?
		//
		var didClearPickedContact_fn: ((_ preExistingContact: Contact) -> Void)?
		//
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
			do {
				let view = self.inputField
				view.delegate = self
				view.autocapitalizationType = .words
				view.autocorrectionType = .no
				view.addTarget(self, action: #selector(inputField_editingChanged), for: .editingChanged)
				self.addSubview(view)
			}
			do {
				let view = ContactPickerSearchResultsInlinePopoverView()
				
				view.tableView.delegate = self
				view.tableView.dataSource = self
				view.isHidden = true
				self.autocompleteResultsView = view
				self.addSubview(view)
			}
			do {
				let view = UICommonComponents.ResolvingActivityIndicatorView()
				view.isHidden = true
				self.resolving_activityIndicator = view
				self.addSubview(view)
			}
			self.updateBounds() // initial frame, to get h
			self.startObserving()
		}
		func startObserving()
		{
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
			var h: CGFloat
			if self.selectedContact == nil {
				h = self.inputField.frame.origin.y + self.inputField.frame.size.height
				if self.autocompleteResultsView.isHidden == false {
					h = self.autocompleteResultsView.frame.origin.y + self.autocompleteResultsView.frame.size.height
				}
			} else {
				let pillView = self.selectedContactPillView!
				h = pillView.frame.origin.y + pillView.frame.size.height
			}
			//
			return h
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
				let comparisonResult = matchAgainstField_value.compare(
					searchString,
					options: [
						.diacriticInsensitive,
						.caseInsensitive
					]
				)
				let isAMatch = comparisonResult == .orderedSame
				if isAMatch {
					results.append(record)
				}
			}
			return results
		}
		//
		// Imperatives - UI state modifications
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
			self.autocompleteResultsView.tableView.reloadData()
			//
			assert(self.searchResults != nil)
			if self.searchResults!.count == 0 {
				self.__removeAllAndHideSearchResults() // to 'remove' them is slightly redundant but not wrong here
				return
			}
			//
			self.autocompleteResultsView.isHidden = false
			self.updateBounds()
		}
		func __removeAllAndHideSearchResults()
		{
			self.searchResults = nil
			self.autocompleteResultsView.isHidden = true
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
		{ // This function must also be able to handle being called while a contact is already selected
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
			//
			self.__removeAllAndHideSearchResults()
			self._removeSelectedContactPillView() // but don't do stuff like focusing the input layer
			self.__clearAndHideInputLayer()
			//
			self.selectedContact = contact
			self._display(pickedContact: contact)
			//
			if let fn = self.didPickContact_fn {
				fn(contact, doesNeedToResolve)
			}
			//
			self.set(resolvingIndicatorIsVisible: doesNeedToResolve)
			if doesNeedToResolve {
				let parameters = ContactPickerOpenAliasResolverRequestMaker.Parameters(
					address: contact.address,
					oaResolve__preSuccess_terminal_validationMessage_fn:
					{ [unowned self] (localizedString) in
						self.set(resolvingIndicatorIsVisible: false)
						self.oaResolverRequestMaker = nil // must free, and before call-back
						if let fn = self.oaResolve__preSuccess_terminal_validationMessage_fn {
							fn(localizedString)
						}
					},
					oaResolve__success_fn:
					{ [unowned self] (resolved_xmr_address, payment_id, tx_description) in
						self.set(resolvingIndicatorIsVisible: false)
						self.oaResolverRequestMaker = nil // must free, and before call-back
						if let fn = self.oaResolve__success_fn {
							fn(resolved_xmr_address, payment_id, tx_description)
						}
					}
				)
				let resolver = ContactPickerOpenAliasResolverRequestMaker(parameters: parameters)
				self.oaResolverRequestMaker = resolver
				resolver.resolve()
			}
		}
		func _display(pickedContact: Contact)
		{
			if self.selectedContactPillView == nil {
				let view = SelectedContactPillView()
				view.xButton_tapped_fn =
				{ [unowned self] in
					if self.inputField.isEnabled == false {
						DDLog.Info("UICommonComponents", "💬  Disallowing user unpick of contact while inputLayer is disabled.")
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
		)
		{
			self._removeSelectedContactPillView()
			self.inputField.isHidden = false
			if skipFocusingInputField != true {
				DispatchQueue.main.async
				{ // to decouple redisplay of input layer and un-picking from the display of the unfiltered results triggered by this focus:
					self.inputField.becomeFirstResponder()
				}
			}
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
		// Imperatives - Internal - Layout
		private func updateBounds()
		{
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
			if self.selectedContact == nil {
				self.inputField.frame = CGRect(
					x: 0,
					y: 0,
					width: self.frame.size.width, // size to width
					height: self.inputField.frame.size.height
				)
				if self.autocompleteResultsView.isHidden == false {
					var h: CGFloat
					do {
						let numRows = self.searchResults != nil ? self.searchResults!.count : 0
						if numRows == 0 {
							h = ContactPickerSearchResultsInlinePopoverView.maxHeight
						} else {
							h = ContactPickerSearchResultsInlinePopoverView.height(withNumRows: numRows)
						}
					}
					self.autocompleteResultsView.frame = CGRect(
						x: UICommonComponents.FormInputCells.imagePadding_x,
						y: (self.inputField.frame.origin.y - UICommonComponents.FormInputCells.imagePadding_y) + (self.inputField.frame.size.height - UICommonComponents.FormInputCells.imagePadding_y),
						width: self.frame.size.width - 2*UICommonComponents.FormInputCells.imagePadding_x,
						height: h
					)
				}
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
				if self.resolving_activityIndicator.isHidden == false {
					let size = self.resolving_activityIndicator.new_boundsSize
					self.resolving_activityIndicator.frame = CGRect(
						x: 8,
						y: pillView.frame.origin.y + pillView.frame.size.height + UICommonComponents.GraphicAndLabelActivityIndicatorView.marginAboveActivityIndicatorBelowFormInput,
						width: size.width,
						height: size.height
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
		//
		// Delegation - Text field
		func textFieldDidBeginEditing(_ textField: UITextField)
		{
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
		) -> Bool
		{
			return true
		}
		
		func inputField_editingChanged()
		{
			if self.inputField.isHidden == true || self.inputField.isFirstResponder == false {
				return // in case we're editing .text programmatically
			}
			self._searchForAndDisplaySearchResults() // TODO? wait for sufficient pause in typing
			// TODO: wait for "finished typing"-type pause and call self._didFinishTypingInInput_fn()
			// …… or pass that off to consumer

		}
		//
		// Delegation - Table
		func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
		{
			return self.searchResults != nil ? self.searchResults!.count : 0
		}
		func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
		{
			let contact = self.searchResults![indexPath.row]
			self.pick(contact: contact)
		}
		func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
		{
			return ContactPickerSearchResultsCellView.h
		}
		func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
		{
			var cell = tableView.dequeueReusableCell(withIdentifier: ContactPickerSearchResultsCellView.reuseIdentifier) as? ContactPickerSearchResultsCellView
			if cell == nil {
				cell = ContactPickerSearchResultsCellView()
			}
			let contact = self.searchResults![indexPath.row]
			cell!.configure(withContact: contact)
			//
			return cell!
		}
	}
	//
	class ContactPickerSearchResultsInlinePopoverView: UIView
	{
		//
		// Constants/Static
		static let cornerRadius: CGFloat = 4
		//
		static let maxVisibleRows: CGFloat = 3.5
		static let maxHeight: CGFloat = ContactPickerSearchResultsCellView.h * maxVisibleRows
		static func height(withNumRows numRows: Int) -> CGFloat
		{
			return ContactPickerSearchResultsCellView.h * min(
				CGFloat(numRows),
				maxVisibleRows
			)
		}
		//
		// Properties
		var tableView: UITableView!
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
				let layer = self.layer
				layer.masksToBounds = false
				layer.cornerRadius = ContactPickerSearchResultsInlinePopoverView.cornerRadius
				layer.shadowColor = UIColor(white: 0, alpha: 0.1).cgColor
				layer.shadowOffset = .zero
				layer.shadowOpacity = 0.5
				layer.shadowRadius = 4
			}
			do {
				self.backgroundColor = UIColor(red: 252/255, green: 251/255, blue: 252/255, alpha: 1)
			}
			do {
				let view = UITableView(frame: .zero, style: .plain)
				view.layer.cornerRadius = ContactPickerSearchResultsInlinePopoverView.cornerRadius
				view.layer.masksToBounds = true
				view.backgroundColor = self.backgroundColor
				view.separatorColor = UIColor(rgb: 0xDFDEDF)
				view.separatorInset = UIEdgeInsets(top: 0, left: 49, bottom: 0, right: 0)
				self.tableView = view
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
		// Overrides - Imperatives
		override func layoutSubviews()
		{
			super.layoutSubviews()
			self.tableView.frame = self.bounds
		}
	}
	class ContactPickerSearchResultsCellView: UITableViewCell
	{
		//
		// Constants
		static let reuseIdentifier = "ContactPickerSearchResultsCellView"
		static let h: CGFloat = 32
		//
		// Properties
		var emojiLabel = UILabel()
		var nameLabel = UILabel()
		//
		// Lifecycle - Init
		init()
		{
			super.init(style: .default, reuseIdentifier: ContactPickerSearchResultsCellView.reuseIdentifier)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			do {
				self.isOpaque = true // performance
				self.backgroundColor = UIColor(red: 252/255, green: 251/255, blue: 252/255, alpha: 1)
			}
			do {
				let view = UIView()
				view.backgroundColor = UIColor(red: 223/255, green: 222/255, blue: 223/255, alpha: 1)
				self.selectedBackgroundView = view
			}
			do {
				let view = self.emojiLabel
				view.font = UIFont.systemFont(ofSize: 13)
				view.numberOfLines = 1
				view.textAlignment = .center
				self.addSubview(view)
			}
			do {
				let view = self.nameLabel
				view.font = UIFont.middlingMediumSansSerif
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
				let w: CGFloat = 50
				self.emojiLabel.frame = CGRect(x: 0, y: 0, width: w, height: self.frame.size.height)
			}
			do {
				let x = self.emojiLabel.frame.origin.x + self.emojiLabel.frame.size.width
				self.nameLabel.frame = CGRect(x: x, y: 0, width: self.frame.size.width - x - 8, height: self.frame.size.height)
			}
		}
		//
		// Imperatives - Configuration
		func configure(withContact contact: Contact)
		{
			self.emojiLabel.text = contact.emoji
			self.nameLabel.text = contact.fullname
		}
	}
	//
	class SelectedContactPillView: UIView
	{
		//
		// Constants
		static let visual__h: CGFloat = 31
		static let h = SelectedContactPillView.visual__h + 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
		
		static let emoji_w: CGFloat = 35
		static let xButton_leftMargin: CGFloat = 7
		static let xButton_side = SelectedContactPillView.visual__h
		//
		// Properties
		var contact: Contact?
		var xButton_tapped_fn: ((Void) -> Void)!
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
				self.addSubview(view)
			}
			do {
				let view = self.emojiLabel
				view.font = UIFont.systemFont(ofSize: 13)
				view.numberOfLines = 1
				view.textAlignment = .center
				self.addSubview(view)
			}
			do {
				let view = self.nameLabel
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
			self.stopObserving_contact()
			self.contact = nil
		}
		func stopObserving_contact()
		{
			let contact = self.contact!
			NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: contact)
			NotificationCenter.default.removeObserver(self, name: Contact.NotificationNames.infoUpdated.notificationName, object: contact)
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
			NotificationCenter.default.addObserver(self, selector: #selector(willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: contact)
			NotificationCenter.default.addObserver(self, selector: #selector(infoUpdated), name: Contact.NotificationNames.infoUpdated.notificationName, object: contact)
		}
		//
		// Imperatives - Configuration
		func configureWithContact()
		{
			let contact = self.contact!
			self.nameLabel.text = contact.fullname
			self.emojiLabel.text = contact.emoji
			self.setNeedsLayout()
		}
		//
		// Interface - Layout - Imperatives
		public func layOut(
			withX x: CGFloat,
			y: CGFloat,
			inWidth containerWidth: CGFloat
		)
		{
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
		func xButton_tapped()
		{
			self.xButton_tapped_fn()
		}
		//
		func willBeDeleted()
		{
			self.xButton.sendActions(for: .touchUpInside) // simulate tap to unpick deleted contact - will clear
		}
		func infoUpdated()
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
			self.resolve_requestHandle = OpenAliasResolver.shared.resolveOpenAliasAddress(
				openAliasAddress: self.parameters.address,
				{ [unowned self] (
					err_str: String?,
					addressWhichWasPassedIn: String?,
					response: OpenAliasResolver.OpenAliasResolverResponse?
				) in
					if self.parameters.address != addressWhichWasPassedIn {
						assert(false, "another request's resolution was returned on this form… does that mean it wasn't cancelled from earlier?")
						return
					}
					//
					let handle_wasNil = self.resolve_requestHandle == nil
					self.resolve_requestHandle = nil
					//
					if err_str != nil {
						if let fn = self.parameters.oaResolve__preSuccess_terminal_validationMessage_fn {
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
						if let fn = self.parameters.oaResolve__preSuccess_terminal_validationMessage_fn {
							fn(NSLocalizedString("OpenAlias address no longer lists Monero address", comment: ""))
							return
						}
					}
					let paymentID = response!.returned__payment_id
					let tx_description = response!.tx_description ?? ""
					if let fn = self.parameters.oaResolve__success_fn {
						fn(cached_OAResolved_XMR_address!, paymentID, tx_description)
					}
				}
			)
//			self.requestHandle_for_oaResolution = self.context.openAliasResolver.ResolveOpenAliasAddress(
//				contact.address,
//				function(
//					err,
//					addressWhichWasPassedIn,
//					moneroReady_address,
//					payment_id, // may be undefined
//					tx_description,
//					openAlias_domain,
//					oaRecords_0_name,
//					oaRecords_0_description,
//					dnssec_used_and_secured
//					)
//				{
//					self.resolving_activityIndicatorLayer.style.display = "none"
//					self.enable_submitButton()
//					//
//					if (typeof self.requestHandle_for_oaResolution === 'undefined' || !self.requestHandle_for_oaResolution) {
//						console.warn("⚠️  Called back from ResolveOpenAliasAddress but no longer have a self.requestHandle_for_oaResolution. Canceled by someone else? Bailing after neutralizing UI.")
//						return
//					}
//					self.requestHandle_for_oaResolution = null
//					//
//					if (typeof self.pickedContact === 'undefined' || !self.pickedContact) {
//						console.warn("⚠️  Called back from ResolveOpenAliasAddress but no longer have a self.pickedContact. Bailing")
//						return
//					}
//					if (self.pickedContact.address !== addressWhichWasPassedIn) {
//						console.warn("⚠️  The addressWhichWasPassedIn to the ResolveOpenAliasAddress call of which this is a callback is different than the currently selected self.pickedContact.address. Bailing")
//						return
//					}
//					if (err) {
//						self.validationMessageLayer.SetValidationError(err.toString())
//						return
//					}
//					{ // memo field
//						tx_description = tx_description || "" // to facilitate clearing the memo field
//						self.memoInputLayer.value = tx_description // even if one was already entered; this is tbh an approximation of the behavior we want; ideally we'd try to detect and track whether the user intended to use/type their own custom memo – but that is surprisingly involved to do well enough! at least for now.
//					}
//						{ // there is no need to tell the contact to update its address and payment ID here as it will be observing the emitted event from this very request to .Resolve
//							if (typeof payment_id !== 'undefined' && payment_id) {
//								self.addPaymentIDButtonView.layer.style.display = "none" // hide if showing
//								self.manualPaymentIDInputLayer_containerLayer.style.display = "block" // show if hidden
//								self.manualPaymentIDInputLayer.value = payment_id
//							} else {
//								// we already hid it above… but jic
//								self.addPaymentIDButtonView.layer.style.display = "block" // hide if showing
//								self.manualPaymentIDInputLayer_containerLayer.style.display = "none" // hide if showing
//								self.manualPaymentIDInputLayer.value = ""
//							}
//					}
//				}
//			)
		}
	}
}
