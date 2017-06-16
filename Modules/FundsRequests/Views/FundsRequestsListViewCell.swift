//
//  FundsRequestsListViewCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class FundsRequestsListViewCell: UITableViewCell
{
	static let reuseIdentifier = "FundsRequestsListViewCell"
	static let cellHeight: CGFloat = 100
	//
	let cellContentView = FundsRequestsCellContentView()
	let accessoryChevronView = UIImageView(image: UIImage(named: "list_rightside_chevron")!)
	//
	// Lifecycle - Init
	init()
	{
		super.init(style: .default, reuseIdentifier: FundsRequestsListViewCell.reuseIdentifier)
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
	}
	//
	// Imperatives - Configuration
	var object: FundsRequest?
	func configure(withObject object: FundsRequest)
	{
		assert(self.object == nil)
		self.object = object
		self.cellContentView.configure(withObject: object)
	}
	//
	// Overrides - Imperatives - Layout
	override func layoutSubviews()
	{
		super.layoutSubviews()
		let frame = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(0, 16, 16, 16))
		self.contentView.frame = frame
//		self.backgroundView!.frame = frame
//		self.selectedBackgroundView!.frame = frame
		self.cellContentView.frame = self.contentView.bounds.insetBy(
			dx: UICommonComponents.HighlightableCells.imagePaddingForShadow_h,
			dy: UICommonComponents.HighlightableCells.imagePaddingForShadow_v
		)
		self.accessoryChevronView.frame = CGRect(
			x: frame.size.width - self.accessoryChevronView.frame.size.width - 16,
			y: frame.origin.y + (frame.size.height - self.accessoryChevronView.frame.size.height)/2,
			width: self.accessoryChevronView.frame.size.width,
			height: self.accessoryChevronView.frame.size.height
		).integral
	}
}
