//
//  ContactsListViewCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
	var object: Contact?
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
