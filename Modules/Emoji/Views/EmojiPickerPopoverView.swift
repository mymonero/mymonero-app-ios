//
//  EmojiPickerPopoverView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/1/17.
//  Copyright (c) 2014-2017, MyMonero.com
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
import Popover

class EmojiPickerPopoverView: Popover
{
	//
	// Properties
	var selectedEmojiCharacter_fn: ((Emoji.EmojiCharacter) -> Void)!
	//
	// Lifecycle - Init
	required override init()
	{
		let options: [PopoverOption] =
		[
			.cornerRadius(5),
			.arrowSize(CGSize(width: 19, height: 17)),
			//
			.animationIn(0.46),
			.animationOut(0.2),
			//
			.showBlackOverlay(true),
			.blackOverlayColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.08)),
			.dismissOnBlackOverlayTap(true)
		]
		super.init(options: options, showHandler: nil, dismissHandler: nil) // set the handlers after init if you want
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
	}
	//
	// Accessors - Factories
	func new_contentView(selecting_emojiCharacter emojiCharacter: Emoji.EmojiCharacter) -> EmojiPickerContentView
	{
		let view = EmojiPickerContentView(selecting_emojiCharacter: emojiCharacter)
		view.selectedEmojiCharacter_fn = self.selectedEmojiCharacter_fn
		//
		return view
	}
	//
	// Imperatives - Convenience
	func show(fromView: UIView, selecting_emojiCharacter emojiCharacter: Emoji.EmojiCharacter)
	{
		let contentView = self.new_contentView(selecting_emojiCharacter: emojiCharacter)
		self.show(contentView, fromView: fromView)
	}
	
}

class EmojiPickerCollectionViewCell: UICollectionViewCell
{
	//
	// Types/Constants
	static let reuseIdentifier = "EmojiPickerCollectionViewCell"
	static let itemSize = CGSize(width: EmojiPickerCollectionViewCell.w, height: EmojiPickerCollectionViewCell.h)
	static let w: CGFloat = 34
	static let h: CGFloat = 30
	static let selected_backgroundImage = UIImage(named: "emojiPickerPopover_cell_selectedBG_stretchable")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
	//
	// Properties
	var label = UILabel()
	//
	var emojiCharacter: Emoji.EmojiCharacter?
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
		self.backgroundColor = .clear // unfortunately. b/c background of collection view is not a solid color
		//
		let view = self.label
		view.font = UIFont.systemFont(ofSize: 15)
		view.textAlignment = .center
		self.addSubview(view)
	}
	//
	// Lifecycle - Deinit/Recycling
	deinit
	{
		self.teardown_emojiCharacter()
	}
	override func prepareForReuse()
	{
		super.prepareForReuse()
		self.teardown_emojiCharacter()
	}
	func teardown_emojiCharacter()
	{
		self.emojiCharacter = nil // just a string so no big deal but useful
	}
	//
	// Runtime - Imperatives
	func configure(withEmoji emojiCharacter: Emoji.EmojiCharacter)
	{
		self.emojiCharacter = emojiCharacter
		self.label.text = emojiCharacter
		self.setNeedsDisplay() // apparently necessary to redraw selection state
	}
	//
	// Overrides - Imperatives
	override func layoutSubviews()
	{
		super.layoutSubviews()
		self.label.frame = self.bounds
	}
	override func draw(_ rect: CGRect)
	{
		if self.isSelected {
			EmojiPickerCollectionViewCell.selected_backgroundImage.draw(in: rect)
		}
		super.draw(rect)
	}
}

class EmojiPickerContentView: UIView, UICollectionViewDelegate, UICollectionViewDataSource
{
	var collectionView: UICollectionView!
	var initial_selected_emojiCharacter: Emoji.EmojiCharacter
	var selectedEmojiCharacter_fn: ((Emoji.EmojiCharacter) -> Void)!
	//
	init(selecting_emojiCharacter emojiCharacter: Emoji.EmojiCharacter)
	{
		let frame = CGRect(x: 0, y: 0, width: 265, height: 174)
		self.initial_selected_emojiCharacter = emojiCharacter
		super.init(frame: frame)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		do {
			let layout = UICollectionViewFlowLayout()
			do {
				layout.itemSize = EmojiPickerCollectionViewCell.itemSize
				layout.minimumInteritemSpacing = 0
				layout.minimumLineSpacing = 0
			}
			let view = UICollectionView(frame: self.bounds.insetBy(dx: 1, dy: 1), collectionViewLayout: layout)
			self.collectionView = view
			do {
				view.contentInset = UIEdgeInsetsMake(8, 8, 8, 8)
				view.delegate = self
				view.dataSource = self
				view.register(
					EmojiPickerCollectionViewCell.self,
					forCellWithReuseIdentifier: EmojiPickerCollectionViewCell.reuseIdentifier
				)
				view.backgroundColor = .clear
				//
				view.allowsSelection = true
				view.allowsMultipleSelection = false
			}
			self.addSubview(view)
		}
		do { // initial selection
			let index = Emoji.allOrdered.index(of: self.initial_selected_emojiCharacter)!
			let indexPath = IndexPath(row: index, section: 0)
			self.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
		}
	}
	//
	// Delegation/Protocols - UICollectionViewDelegate and DataSource
	func collectionView(
		_ collectionView: UICollectionView,
		cellForItemAt indexPath: IndexPath
	) -> UICollectionViewCell
	{
		var optl_cell: EmojiPickerCollectionViewCell? = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiPickerCollectionViewCell.reuseIdentifier, for: indexPath) as? EmojiPickerCollectionViewCell
		if optl_cell == nil {
			optl_cell = EmojiPickerCollectionViewCell()
		}
		let cell = optl_cell!
		let emojiCharacter = Emoji.allOrdered[indexPath.row]
		cell.configure(withEmoji: emojiCharacter)
		//
		return cell
	}
	func collectionView(
		_ collectionView: UICollectionView,
		numberOfItemsInSection section: Int
	) -> Int
	{
		return Emoji.numberOfEmoji
	}
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		if let cell = self.collectionView.cellForItem(at: indexPath) {
			cell.setNeedsDisplay()
		}
		let emojiCharacter = Emoji.allOrdered[indexPath.row]
		self.selectedEmojiCharacter_fn(emojiCharacter)
	}
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
	{
		if let cell = self.collectionView.cellForItem(at: indexPath) {
			cell.setNeedsDisplay()
		}
	}
}
