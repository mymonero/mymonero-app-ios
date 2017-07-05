//
//  ContactDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class ContactDetailsViewController: UICommonComponents.DetailsViewController
{
	//
	// Constants/Types
	//
	// Properties
	var contact: Contact
	//
	// Imperatives - Init
	init(contact: Contact)
	{
		self.contact = contact
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	//
	// Overrides
	override func setup_navigation()
	{
		super.setup_navigation()
		self.set_navigationTitle() // also to be called on contact info updated
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .edit,
			target: self,
			action: #selector(tapped_rightBarButtonItem)
		)
	}
	override var overridable_wantsBackButton: Bool {
		return true
	}
	//
	override func startObserving()
	{
		super.startObserving()
		NotificationCenter.default.addObserver(self, selector: #selector(willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.contact)
		NotificationCenter.default.addObserver(self, selector: #selector(infoUpdated), name: Contact.NotificationNames.infoUpdated.notificationName, object: self.contact)
	}
	override func stopObserving()
	{
		super.stopObserving()
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.contact)
		NotificationCenter.default.removeObserver(self, name: Contact.NotificationNames.infoUpdated.notificationName, object: self.contact)
	}
	//
	// Imperatives
	func set_navigationTitle()
	{
		self.navigationItem.title = "\(self.contact.emoji!)   \(self.contact.fullname!)"
	}
	//
	// Delegation
	func tapped_rightBarButtonItem()
	{
		let viewController = EditContactFormViewController(withContact: self.contact)
		let presenting_viewController = UINavigationController(rootViewController: viewController)
		self.navigationController!.present(presenting_viewController, animated: true, completion: nil)
	}
	//
	func willBeDeleted()
	{
		if self.navigationController!.topViewController! != self {
			assert(false)
			return
		}
		self.navigationController!.popViewController(animated: true)
	}
	func infoUpdated()
	{
		self.set_navigationTitle()
		// TODO: also config table/details UI
	}
}
