//
//  ContactsCellContentView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
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
			view.font = UIFont.systemFont(ofSize: 16)
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
			self._stopObserving_object()
			self.object = nil
		}
	}
	func prepareForReuse()
	{
		self.tearDown_object()
	}
	func _stopObserving_object()
	{
		assert(self.object != nil)
		self.__stopObserving(specificObject: self.object!)
	}
	func _stopObserving(objectBeingDeinitialized object: Contact)
	{
		assert(self.object == nil) // special case - since it's a weak ref I expect self.object to actually be nil
		assert(self.hasStoppedObservingObject_forLastNonNilSetOfObject != true) // initial expectation at least - this might be able to be deleted
		//
		self.__stopObserving(specificObject: object)
	}
	func __stopObserving(specificObject object: Contact)
	{
		if self.hasStoppedObservingObject_forLastNonNilSetOfObject == true {
			// then we've already handled this
			DDLog.Warn("ContactsCellContentView", "Not redundantly calling stopObserving")
			return
		}
		self.hasStoppedObservingObject_forLastNonNilSetOfObject = true // must set to true so we can set back to false when object is set back to non-nil
		//
		NotificationCenter.default.removeObserver(self, name: Contact.NotificationNames.infoUpdated.notificationName, object: object)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: object)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: object)
	}
	//
	// Accessors
	//
	// Imperatives - Configuration
	weak var object: Contact? // prevent self from preventing object from being freed (so we still get .willBeDeinitialized) 
	var hasStoppedObservingObject_forLastNonNilSetOfObject = true // I'm using this addtl state var which is not weak b/c object will be niled purely by virtue of it being freed by strong reference holders (other objects)… and I still need to call stopObserving on that object - while also not doing so redundantly - therefore this variable must be set back to false after self.object is set back to non-nil or possibly more rigorously, in startObserving
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
		if self.object!.didFailToInitialize_flag == true || self.object!.didFailToBoot_flag == true { // unlikely but possible
			self.emojiLabel.text = "❌"
			self.titleLabel.text = NSLocalizedString("Error: Contact Support", comment: "")
			self.subtitleLabel.text = self.object!.didFailToBoot_errStr ?? ""
		} else {
			self.emojiLabel.text = self.object!.emoji
			self.titleLabel.text = self.object!.fullname
			self.subtitleLabel.text = self.object!.address
		}
	}
	//
	func startObserving_object()
	{
		assert(self.object != nil)
		assert(self.hasStoppedObservingObject_forLastNonNilSetOfObject == true) // verify that it was reset back to false
		self.hasStoppedObservingObject_forLastNonNilSetOfObject = false // set to false so we make sure to stopObserving
		NotificationCenter.default.addObserver(self, selector: #selector(_infoUpdated), name: Contact.NotificationNames.infoUpdated.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeinitialized(_:)), name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
	}
	//
	// Imperatives - Overrides
	override func layoutSubviews()
	{
		super.layoutSubviews()
		self.emojiLabel.frame = CGRect(
			x: 17,
			y: 15,
			width: 24,
			height: 25
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
			y: self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 2,
			width: labels_width,
			height: 20 // TODO: size with font for accessibility? NOTE: must support emoji, currently, for locked icon
		).integral
	}
	//
	// Delegation - Notifications
	@objc func _infoUpdated()
	{
		self._configureUI()
	}
	@objc func _willBeDeleted()
	{
		self.tearDown_object() // stop observing, release
	}
	@objc func _willBeDeinitialized(_ note: Notification)
	{ // This obviously doesn't work for calling stopObserving on self.object --- because self.object is nil by the time we get here!!
		let objectBeingDeinitialized = note.userInfo![PersistableObject.NotificationUserInfoKeys.object.key] as! Contact
		self._stopObserving( // stopObserving specific object - self.object will be nil by now - but also call specific method for this as it has addtl check
			objectBeingDeinitialized: objectBeingDeinitialized
		)
	}
}
