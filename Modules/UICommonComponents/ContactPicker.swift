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
	class ContactPickerView: UIView
	{
		//
		// Constants
		
		//
		// Properties
		var selectedContact: Contact?
		//
		var inputField = UICommonComponents.FormInputField(
			placeholder: NSLocalizedString("Enter contact name", comment: "")
		)
		var selectedContactPillView: ContactPillView? // TODO
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
			self.startObserving()
		}
		func startObserving()
		{
			
		}
		//
		// Accessors
		var _new_frame: CGRect {
			var h: CGFloat
			if self.selectedContact == nil {
				h = self.inputField.frame.origin.y + self.inputField.frame.size.height
			} else {
				h = 50 // TODO: contact pill itself
			}
			return CGRect(
				x: self.frame.origin.x,
				y: self.frame.origin.y,
				width: self.frame.size.width,
				height: h
			)
		}
		//
		// Imperatives
		func set(selectedContact contact: Contact?)
		{
			if self.selectedContact == contact {
				return
			}
			self.selectedContact = contact
			self._configure()
		}
		func _configure()
		{
			if self.selectedContact == nil {
				self.inputField.isHidden = false
			} else {
				self.inputField.isHidden = true
			}
			self.frame = self._new_frame // resize
		}
		//
		// Imperatives - Overrides
		override func layoutSubviews()
		{
			super.layoutSubviews()
			if self.selectedContact == nil {
				self.inputField.frame = CGRect(
					x: 0,
					y: 0,
					width: self.frame.size.width, // size to width
					height: self.inputField.frame.size.height
				)
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
	}
	//
	class ContactPillView: UIView
	{
		var xButton = UIButton()
		// TODO
		func layOut(
			withX x: CGFloat,
			y: CGFloat,
			inWidth containerWidth: CGFloat
		)
		{
			assert(false, "TODO")
		}
	}
}
