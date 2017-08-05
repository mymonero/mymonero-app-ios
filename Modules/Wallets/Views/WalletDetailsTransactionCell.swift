//
//  WalletDetailsTransactionCell.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
import UIKit
//
extension WalletDetails
{
	struct Transaction
	{
		static var _cell_dateFormatter: DateFormatter? = nil
		static func lazy_cell_dateFormatter() -> DateFormatter
		{
			if Transaction._cell_dateFormatter == nil {
				let formatter = DateFormatter() // would be nice
				formatter.dateFormat = "d MMM yyyy"
				Transaction._cell_dateFormatter = formatter
			}
			return Transaction._cell_dateFormatter!
		}
		
		class Cell: UICommonComponents.Tables.ReusableTableViewCell
		{
			//
			// Static - Constants
			static let contentView_margin_h: CGFloat = 16
			//
			// Static - Shared
			static let dateFormatter = DateFormatter()
			//
			// Class - Overrides
			override class func reuseIdentifier() -> String {
				return "WalletDetails.Transaction.Cell"
			}
			override class func cellHeight(withPosition cellPosition: UICommonComponents.CellPosition) -> CGFloat
			{
				let groupedHighlightableCellVariant = UICommonComponents.GroupedHighlightableCells.Variant.new(
					withState: .normal,
					position: cellPosition
				)
				let imagePadding = groupedHighlightableCellVariant.imagePaddingForShadow
				return 70 + imagePadding.top + imagePadding.bottom
			}
			//
			// Properties
			let cellContentView = ContentView()
			let accessoryChevronView = UIImageView(image: UIImage(named: "list_rightside_chevron")!)
			let separatorView = UICommonComponents.Details.FieldSeparatorView(mode: .contiguousCellContainer)
			//
			// Setup
			override func setup()
			{
				super.setup()
				do {
					self.isOpaque = true // performance
					self.backgroundColor = UIColor.contentBackgroundColor
				}
				self.contentView.addSubview(self.cellContentView)
				self.contentView.addSubview(self.accessoryChevronView)
				self.contentView.addSubview(self.separatorView)
			}
			//
			// Imperatives - Configuration
			override func _configureUI()
			{
				let configuration = self.configuration!
				let cellPosition = configuration.cellPosition
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
				do {
					let optl_wallet = configuration.dataObject as? Wallet
					if optl_wallet == nil {
						assert(false)
						return
					}
					let wallet = optl_wallet!
					let transactions = wallet.transactions!
					let transaction = transactions[configuration.indexPath.row]
					self.cellContentView.configure(withObject: transaction)
				}
			}
			//
			// Overrides - Imperatives
			override func layoutSubviews()
			{
				super.layoutSubviews()
				let groupedHighlightableCellVariant = UICommonComponents.GroupedHighlightableCells.Variant.new(
					withState: .normal,
					position: self.configuration!.cellPosition
				)
				let imagePaddingForShadowInsets = groupedHighlightableCellVariant.imagePaddingForShadow
				let frame = UIEdgeInsetsInsetRect(
					self.bounds,
					UIEdgeInsetsMake(
						0,
						WalletDetails.Transaction.Cell.contentView_margin_h - imagePaddingForShadowInsets.left,
						0,
						WalletDetails.Transaction.Cell.contentView_margin_h - imagePaddingForShadowInsets.right
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
						let x = cellContentViewFrame.origin.x + 16
						let h: CGFloat = 1/UIScreen.main.scale
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
		
		class ContentView: UIView
		{
			let amountLabel = UILabel()
			let dateLabel = UILabel()
			let paymentIDLabel = UILabel()
			let statusLabel = UILabel()
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
					let view = self.amountLabel
					// textColor set on configure
					view.font = UIFont.middlingBoldMonospace
					view.numberOfLines = 1
					self.addSubview(view)
				}
				do {
					let view = self.dateLabel
					view.textColor = UIColor(rgb: 0xFCFBFC)
					view.font = UIFont.middlingRegularMonospace
					view.numberOfLines = 1
					view.textAlignment = .right
					self.addSubview(view)
				}
				do {
					let view = self.paymentIDLabel
					view.textColor = UIColor(rgb: 0x9E9C9E)
					view.font = UIFont.middlingRegularMonospace
					view.lineBreakMode = .byTruncatingTail
					view.numberOfLines = 1
					self.addSubview(view)
				}
				do {
					let view = self.statusLabel
					view.textColor = UIColor(rgb: 0x6B696B)
					view.font = UIFont.smallRegularMonospace
					view.numberOfLines = 1
					view.textAlignment = .right
					self.addSubview(view)
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
				NotificationCenter.default.removeObserver(self, name: MoneroHistoricalTransactionRecord.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
			}
			//
			// Accessors
			//
			// Imperatives - Configuration
			weak var object: MoneroHistoricalTransactionRecord? // weak to prevent self from preventing .willBeDeinitialized from being received
			func configure(withObject object: MoneroHistoricalTransactionRecord)
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
				let object = self.object!
				do {
					self.amountLabel.text = "\(object.amount.humanReadableString)"
					if object.approxFloatAmount < 0 {
						self.amountLabel.textColor = UIColor(rgb: 0xF97777)
					} else {
						self.amountLabel.textColor = UIColor(rgb: 0xFCFBFC)
					}
				}
				self.dateLabel.text = Transaction.lazy_cell_dateFormatter().string(from: object.timestamp).uppercased()
				self.paymentIDLabel.text = object.paymentId ?? NSLocalizedString("N/A", comment: "")
				self.statusLabel.text = !object.cached__isConfirmed || !object.cached__isUnlocked ? NSLocalizedString("PENDING", comment: "") : NSLocalizedString("CONFIRMED", comment: "")
			}
			//
			func startObserving_object()
			{
				assert(self.object != nil)
				NotificationCenter.default.addObserver(self, selector: #selector(willBeDeinitialized), name: MoneroHistoricalTransactionRecord.NotificationNames.willBeDeinitialized.notificationName, object: self.object!)
			}
			//
			// Imperatives - Overrides
			override func layoutSubviews()
			{
				super.layoutSubviews()
				//
				let labels_x: CGFloat = 16
				let labels_rightMargin: CGFloat = 40
				let labels_width = self.frame.size.width - labels_x - labels_rightMargin
				self.amountLabel.frame = CGRect(
					x: labels_x,
					y: 19,
					width: labels_width,
					height: 16
				).integral
				self.paymentIDLabel.frame = CGRect(
					x: labels_x,
					y: self.amountLabel.frame.origin.y + self.amountLabel.frame.size.height + 4,
					width: min(189, labels_width * 0.5),
					height: 16
				).integral
				self.dateLabel.frame = CGRect(
					x: labels_x,
					y: self.amountLabel.frame.origin.y,
					width: labels_width,
					height: 17
				).integral
				self.statusLabel.frame = CGRect(
					x: labels_x,
					y: self.amountLabel.frame.origin.y + self.amountLabel.frame.size.height + 4,
					width: labels_width,
					height: 15
				).integral
			}
			//
			// Delegation - Notifications
			func willBeDeinitialized()
			{
				self.tearDown_object() // stop observing/free
			}
		}
	}
}
