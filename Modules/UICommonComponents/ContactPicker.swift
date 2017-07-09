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
		//
		var textFieldDidBeginEditing_fn: ((_ textField: UITextField) -> Void)?
		var textFieldDidEndEditing_fn: ((_ textField: UITextField) -> Void)?
		var didUpdateHeight_fn: ((Void) -> Void)?
		var didPickContact_fn: ((_ contact: Contact) -> Void)?
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
			self.updateBounds() // initial frame, to get h
			self.startObserving()
		}
		func startObserving()
		{
			// TODO
			// observing contacts list controller for deletions
//			var _contactsListController_EventName_deletedRecordWithId_fn = function(_id)
//			{ // the currently picked contact was deleted, so unpick it
//				if (__pickedContact && __pickedContact._id === _id) {
//					_unpickExistingContact_andRedisplayPickInput(true)
//				}
//			}
//			contactsListController.on(
//				contactsListController.EventName_deletedRecordWithId(),
//				_contactsListController_EventName_deletedRecordWithId_fn
//			)

		}
		//
		// Accessors
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
			self.__removeAllAndHideSearchResults()
			self._removeSelectedContactPillView() // but don't do stuff like focusing the input layer
			self.__clearAndHideInputLayer()
			//
			self.selectedContact = contact
			self._display(pickedContact: contact)
			//
			if let fn = self.didPickContact_fn {
				fn(contact)
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
			// TODO
		}
		//
		// Imperatives - Configuration
		func configure(withContact contact: Contact)
		{
			// TODO
		}
	}
	//
	class SelectedContactPillView: UIView
	{
		//
		// Constants
		//
		// Properties
		var contact: Contact?
		var xButton_tapped_fn: ((Void) -> Void)!
		//
		var xButton = UIButton()
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
			self.contact = nil
			self.stopObserving_contact()
		}
		func stopObserving_contact()
		{
			// TODO: Need/want to observe contact here? Deselect if deleted. Reconfig name/emoji if/when contact info changed
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
			self.configure_views()
			self.startObserving_contact()
		}
		func configure_views()
		{
			// TODO: data vals in label(s)
			self._sizeSelfAndLayOutSubviews()
		}
		func _sizeSelfAndLayOutSubviews()
		{
			
		}
		func startObserving_contact()
		{
			// TODO
		}
		//
		// Interface - Layout - Imperatives
		public func layOut(
			withX x: CGFloat,
			y: CGFloat,
			inWidth containerWidth: CGFloat
		)
		{
			assert(false, "TODO")
		}
	}
}
