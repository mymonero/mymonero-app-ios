//
//  ContactsListViewCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
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

class ContactsListViewCell: UITableViewCell
{
	static let reuseIdentifier = "ContactsListViewCell"
	static let contentViewHeight: CGFloat = 70
	static let contentView_margin_h: CGFloat = 16
	static func cellHeight(withPosition cellPosition: UICommonComponents.CellPosition) -> CGFloat
	{
		let groupedHighlightableCellVariant = UICommonComponents.GroupedHighlightableCells.Variant.new(
			withState: .normal,
			position: cellPosition
		)
		let imagePadding = groupedHighlightableCellVariant.imagePaddingForShadow
		return contentViewHeight + imagePadding.top + imagePadding.bottom
	}
	//
	let cellContentView = ContactCellContentView()
	let accessoryChevronView = UIImageView(image: UIImage(named: "list_rightside_chevron")!)
	let separatorView = UICommonComponents.Details.FieldSeparatorView(mode: .contiguousCellContainer)
	//
	// Lifecycle - Init
	init()
	{
		super.init(style: .default, reuseIdentifier: ContactsListViewCell.reuseIdentifier)
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
		do {
			self.isOpaque = true // performance
			self.backgroundColor = UIColor.contentBackgroundColor
		}
		self.contentView.addSubview(self.cellContentView)
		self.contentView.addSubview(self.accessoryChevronView)
		self.contentView.addSubview(self.separatorView)
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
		self.object = nil
		self.cellPosition = nil
	}
	//
	// Imperatives - Configuration
	weak var object: Contact? // weak to prevent self from preventing .willBeDeinitialized from being received
	var cellPosition: UICommonComponents.CellPosition?
	func configure(withObject object: Contact, cellPosition: UICommonComponents.CellPosition)
	{
		assert(self.object == nil)
		assert(self.cellPosition == nil)
		self.object = object
		self.cellPosition = cellPosition
		do {
			self.backgroundView = UIImageView(
				image: UICommonComponents.GroupedHighlightableCells.Variant.new(
					withState: .normal,
					position: cellPosition
				).stretchableImage
			)
			self.selectedBackgroundView = UIImageView(
				image: UICommonComponents.GroupedHighlightableCells.Variant.new(
					withState: .highlighted,
					position: cellPosition
				).stretchableImage
			)
		}
		self.separatorView.isHidden = cellPosition == .bottom || cellPosition == .standalone
		self.cellContentView.configure(withObject: object)
	}
	//
	// Overrides - Imperatives
	override func layoutSubviews()
	{
		super.layoutSubviews()
		let groupedHighlightableCellVariant = UICommonComponents.GroupedHighlightableCells.Variant.new(
			withState: .normal,
			position: self.cellPosition!
		)
		let imagePaddingForShadowInsets = groupedHighlightableCellVariant.imagePaddingForShadow
		let frame = UIEdgeInsetsInsetRect(
			self.bounds,
			UIEdgeInsetsMake(
				0,
				ContactsListViewCell.contentView_margin_h - imagePaddingForShadowInsets.left,
				0,
				ContactsListViewCell.contentView_margin_h - imagePaddingForShadowInsets.right
			)
		)
		self.contentView.frame = frame
		self.backgroundView!.frame = frame
		self.selectedBackgroundView!.frame = frame
		let cellContentViewFrame = UIEdgeInsetsInsetRect(
			self.contentView.bounds,
			imagePaddingForShadowInsets
		)
		self.cellContentView.frame = cellContentViewFrame
		self.accessoryChevronView.frame = CGRect(
			x: (cellContentViewFrame.origin.x + cellContentViewFrame.size.width) - self.accessoryChevronView.frame.size.width - 16,
			y: cellContentViewFrame.origin.y + (cellContentViewFrame.size.height - self.accessoryChevronView.frame.size.height)/2,
			width: self.accessoryChevronView.frame.size.width,
			height: self.accessoryChevronView.frame.size.height
		).integral
		do {
			if self.separatorView.isHidden == false {
				let x = cellContentViewFrame.origin.x + 50
				let h: CGFloat = UICommonComponents.Details.FieldSeparatorView.h
				self.separatorView.frame = CGRect(
					x: x,
					y: cellContentViewFrame.origin.y + cellContentViewFrame.size.height - h,
					width: cellContentViewFrame.size.width - x + 1, // not sure where the -1 is coming from here - probably some img padding h
					height: h
				)
			}
		}
	}
}
