//
//  WalletsListViewCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/11/17.
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

class WalletsListViewCell: UITableViewCell
{
	static let reuseIdentifier = "WalletsListViewCell"
	static let contentViewHeight: CGFloat = 82
	static let contentView_margin_h: CGFloat = 16
	static let cellSpacing: CGFloat = 12
	static let cellHeight: CGFloat = contentViewHeight + cellSpacing
	//
	let cellContentView = WalletCellContentView(sizeClass: .large48)
	let accessoryChevronView = UIImageView(image: UIImage(named: "list_rightside_chevron")!)
	var activityIndicator = UICommonComponents.GraphicActivityIndicatorView(appearance: .onAccentBackground)
	//
	// Lifecycle - Init
	init()
	{
		super.init(style: .default, reuseIdentifier: WalletsListViewCell.reuseIdentifier)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.setup_views()
	}
	func setup_views()
	{
		self.isOpaque = true // performance
		self.backgroundColor = UIColor.contentBackgroundColor
		//
		self.backgroundView = UIImageView(image: UICommonComponents.HighlightableCells.Variant.normal.stretchableImage)
		self.selectedBackgroundView = UIImageView(image: UICommonComponents.HighlightableCells.Variant.highlighted.stretchableImage)
		//
		self.contentView.addSubview(self.cellContentView)
		//
		self.contentView.addSubview(self.accessoryChevronView)
		do {
			self._hide_activityIndicator()
			self.contentView.addSubview(self.activityIndicator)
		}
	}
	//
	// Lifecycle - Deinit
	deinit
	{
		self.prepareForReuse()
	}
	override func prepareForReuse()
	{
		self.cellContentView.prepareForReuse()
		self.tearDown_object()
	}
	func tearDown_object()
	{
		if self.object != nil { // TODO: there's some kind of bug seen here. self.object is nil when it still needs to have self removed as an observer
			self._stopObserving_object()
			self.object = nil
		}
	}
	func _stopObserving_object()
	{
		assert(self.object != nil)
		self.__stopObserving(specificObject: self.object!)
	}
	func _stopObserving(objectBeingDeinitialized object: Wallet)
	{
		assert(self.object == nil) // special case - since it's a weak ref I expect self.object to actually be nil
		assert(self.hasStoppedObservingObject_forLastNonNilSetOfObject != true) // initial expectation at least - this might be able to be deleted
		//
		self.__stopObserving(specificObject: object)
	}
	func __stopObserving(specificObject object: Wallet)
	{
		if self.hasStoppedObservingObject_forLastNonNilSetOfObject == true {
			// then we've already handled this
			DDLog.Warn("WalletsListViewCell", "Not redundantly calling stopObserving")
			return
		}
		self.hasStoppedObservingObject_forLastNonNilSetOfObject = true // must set to true so we can set back to false when object is set back to non-nil
		//
		NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.didChange_isFetchingAnyUpdates.notificationName, object: object)
		//
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: object)
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: object)
	}
	//
	// Imperatives - Configuration
	weak var object: Wallet? // weak to prevent self from preventing .willBeDeinitialized from being received
	var hasStoppedObservingObject_forLastNonNilSetOfObject = true // I'm using this addtl state var which is not weak b/c object will be niled purely by virtue of it being freed by strong reference holders (other objects)… and I still need to call stopObserving on that object - while also not doing so redundantly - therefore this variable must be set back to false after self.object is set back to non-nil or possibly more rigorously, in startObserving
	func configure(withObject object: Wallet)
	{
		if self.object != nil {
			self.prepareForReuse() // in case this is not being used in an actual UITableViewCell (which has a prepareForReuse)
		}
		assert(self.object == nil)
		self.object = object
		do {
			self.cellContentView.configure(withObject: object)
			self.configureAccessoryViews()
		}
		self.startObserving_object()
	}
	func startObserving_object()
	{
		assert(self.object != nil)
		assert(self.hasStoppedObservingObject_forLastNonNilSetOfObject == true) // verify that it was reset back to false
		self.hasStoppedObservingObject_forLastNonNilSetOfObject = false // set to false so we make sure to stopObserving
		NotificationCenter.default.addObserver(self, selector: #selector(didChange_isFetchingAnyUpdates), name: Wallet.NotificationNames.didChange_isFetchingAnyUpdates.notificationName, object: self.object!)
		//
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.object!)
		NotificationCenter.default.addObserver(self, selector: #selector(_willBeDeinitialized(_:)), name: PersistableObject.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
	}
	//
	// - - Accessory views
	func configureAccessoryViews()
	{
		if self.object != nil && self.object!.isFetchingAnyUpdates {
			self._show_activityIndicator()
			self.accessoryChevronView.isHidden = true
		} else {
			self._hide_activityIndicator()
			self.accessoryChevronView.isHidden = false
		}
		self.setNeedsLayout() // to lay out whichever accessory view is not visible
	}
	// - - - Activity Indicator
	func _show_activityIndicator()
	{
		if self.activityIndicator.isHidden {
			self.activityIndicator.isHidden = false
		}
		if self.activityIndicator.isAnimating == false {
			self.activityIndicator.startAnimating()
		}
	}
	func _hide_activityIndicator()
	{
		if !self.activityIndicator.isHidden {
			self.activityIndicator.isHidden = true
		}
		if self.activityIndicator.isAnimating {
			self.activityIndicator.stopAnimating()
		}
	}
	//
	// Overrides - Imperatives - Layout
	override func layoutSubviews()
	{
		super.layoutSubviews()
		let frame = self.bounds.inset(by: UIEdgeInsets.init(
				top: 0,
				left: WalletsListViewCell.contentView_margin_h - UICommonComponents.HighlightableCells.imagePaddingForShadow_h,
				bottom: WalletsListViewCell.cellSpacing - 2*UICommonComponents.HighlightableCells.imagePaddingForShadow_v,
				right: WalletsListViewCell.contentView_margin_h - UICommonComponents.HighlightableCells.imagePaddingForShadow_h
			)
		)
		self.contentView.frame = frame
		self.backgroundView!.frame = frame
		self.selectedBackgroundView!.frame = frame
		self.cellContentView.frame = self.contentView.bounds.insetBy(
			dx: UICommonComponents.HighlightableCells.imagePaddingForShadow_h,
			dy: UICommonComponents.HighlightableCells.imagePaddingForShadow_v
		)
		if self.accessoryChevronView.isHidden == false {
			self.accessoryChevronView.frame = CGRect(
				x: frame.size.width - self.accessoryChevronView.frame.size.width - 16,
				y: frame.origin.y + (frame.size.height - self.accessoryChevronView.frame.size.height)/2,
				width: self.accessoryChevronView.frame.size.width,
				height: self.accessoryChevronView.frame.size.height
			).integral
		} else {
			assert(self.activityIndicator.isHidden == false)
			let visualAlignment_x: CGFloat = 0
			let visualAlignment_y = abs(UICommonComponents.GraphicActivityIndicatorPartBulbView.y_off - UICommonComponents.GraphicActivityIndicatorPartBulbView.y_on)
			self.activityIndicator.frame = CGRect(
				x: frame.size.width - self.activityIndicator.frame.size.width - 16 + visualAlignment_x,
				y: frame.origin.y + (frame.size.height - self.activityIndicator.frame.size.height)/2 - visualAlignment_y,
				width: self.activityIndicator.frame.size.width,
				height: self.activityIndicator.frame.size.height
			).integral
		}
	}
	//
	// Delegation - Notifications
	@objc func didChange_isFetchingAnyUpdates()
	{
		self.configureAccessoryViews()
	}

	@objc func _willBeDeleted()
	{
		self.tearDown_object() // stopObserving/release
	}
	@objc func _willBeDeinitialized(_ note: Notification)
	{ // This obviously doesn't work for calling stopObserving on self.object --- because self.object is nil by the time we get here!!
		let objectBeingDeinitialized = note.userInfo![PersistableObject.NotificationUserInfoKeys.object.key] as! Wallet
		self._stopObserving( // stopObserving specific object - self.object will be nil by now - but also call specific method for this as it has addtl check
			objectBeingDeinitialized: objectBeingDeinitialized
		)
	}
	//
	// Delegation - Module-private delegation methods
	func _willBecomeVisible()
	{
		self.configureAccessoryViews() // this will handle retriggering animation if necessary
	}
}
