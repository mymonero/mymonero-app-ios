//
//  ContactsCellContentView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class ContactCellContentView: UIView
{
	var emojiLabel: UILabel!
	var titleLabel: UILabel!
	var subtitleLabel: UILabel!
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
			let view = UILabel()
			view.font = UIFont.systemFont(ofSize: 13)
			view.numberOfLines = 1
			self.addSubview(view)
			self.emojiLabel =  view
		}
		do {
			let view = UILabel()
			view.textColor = UIColor(rgb: 0xFCFBFC)
			view.font = UIFont.middlingSemiboldSansSerif
			view.numberOfLines = 1
			view.lineBreakMode = .byTruncatingTail
			self.addSubview(view)
			self.titleLabel =  view
		}
		do {
			let view = UILabel()
			view.textColor = UIColor(rgb: 0x9E9C9E)
			view.font = UIFont.middlingRegularMonospace
			view.numberOfLines = 1
			view.lineBreakMode = .byTruncatingTail
			self.addSubview(view)
			self.subtitleLabel =  view
		}
	}
	//
	// Lifecycle - Teardown/Reuse
	deinit
	{
		self.tearDown_object()
	}
	func tearDown_object()
	{
		if self.object != nil {
			self.stopObserving_object()
			self.object = nil
		}
	}
	func prepareForReuse()
	{
		self.tearDown_object()
	}
	func stopObserving_object()
	{
		assert(self.object != nil)
		NotificationCenter.default.removeObserver(self, name: Contact.NotificationNames.infoUpdated.notificationName, object: self.object!)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
	}
	//
	// Accessors
	//
	// Imperatives - Configuration
	weak var object: Contact? // prevent self from preventing object from being freed (so we still get .willBeDeinitialized) 
	func configure(withObject object: Contact)
	{
		if self.object != nil {
			self.prepareForReuse() // in case this is not being used in an actual UITableViewCell (which has a prepareForReuse)
		}
		assert(self.object == nil)
		self.object = object
		self._configureUI()
		self.startObserving_object()
	}
	func _configureUI()
	{
		assert(self.object != nil)
		self.emojiLabel.text = self.object!.emoji
		self.titleLabel.text = self.object!.fullname
		self.subtitleLabel.text = self.object!.address
	}
	//
	func startObserving_object()
	{
		assert(self.object != nil)
		NotificationCenter.default.addObserver(self, selector: #selector(_infoUpdated), name: Contact.NotificationNames.infoUpdated.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeinitialized), name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
	}
	//
	// Imperatives - Overrides
	override func layoutSubviews()
	{
		super.layoutSubviews()
		self.emojiLabel.frame = CGRect(
			x: 17,
			y: 17,
			width: 20,
			height: 21
		)
		let labels_x: CGFloat = 50
		let labels_rightMargin: CGFloat = 40
		let labels_width = self.frame.size.width - labels_x - labels_rightMargin
		self.titleLabel.frame = CGRect(
			x: labels_x,
			y: 19,
			width: labels_width,
			height: 16 // TODO: size with font for accessibility?
		).integral
		self.subtitleLabel.frame = CGRect(
			x: labels_x,
			y: self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 1,
			width: labels_width,
			height: 20 // TODO: size with font for accessibility? NOTE: must support emoji, currently, for locked icon
		).integral
	}
	//
	// Delegation - Notifications
	func _infoUpdated()
	{
		self._configureUI()
	}
	func _willBeDeleted()
	{
		self.tearDown_object() // stop observing, release
	}
	func _willBeDeinitialized()
	{
		self.tearDown_object() // stop observing, release
	}
}
