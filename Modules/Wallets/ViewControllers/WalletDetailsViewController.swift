//
//  WalletDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/14/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

struct WalletDetails {}
//
class WalletDetailsViewController: UICommonComponents.Details.ViewController, UITableViewDelegate, UITableViewDataSource
{
	//
	// Constants/Types
	static let margin_h: CGFloat = 16
	//
	// Properties
	var wallet: Wallet
	var infoDisclosingCellView: WalletDetails.InfoDisclosing.Cell // manual init - holding a reference to keep state and query for height
	var transactionsSectionHeaderView: WalletDetails.TransactionsSectionHeaderView!
	//
	var tableView: UITableView {
		return self.scrollView as! UITableView
	}
	//
	//
	// Imperatives - Init
	init(wallet: Wallet)
	{
		self.wallet = wallet
		self.infoDisclosingCellView = WalletDetails.InfoDisclosing.Cell(
			wantsMnemonicDisplay: wallet.mnemonicString != nil
		)
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	//
	// Overrides
	override func setup_scrollView()
	{ // NOTE: not going to call on super here b/c UITableView&Delegate conform to UIScrollView, etc…
		let view = UITableView(frame: .zero, style: .grouped)
		do { // need to specify this b/c we're not getting super's config
			view.indicatorStyle = .white
			view.backgroundColor = .contentBackgroundColor
			view.separatorStyle = .none
			view.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude)) // prevent undesired visual top padding
		}
		view.delegate = self
		view.dataSource = self
		self.scrollView = view
		self.view.addSubview(view)
	}
	override func setup_views()
	{
		super.setup_views()
		do {
			self.scrollView.contentInset = UIEdgeInsetsMake(14, 0, 14, 0)
		}
	}
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
		
		// TODO: all observations -> reconfig/reload cells
		
		NotificationCenter.default.addObserver(self, selector: #selector(wasDeleted), name: PersistableObject.NotificationNames.wasDeleted.notificationName, object: self.wallet)
	}
	override func stopObserving()
	{
		super.stopObserving()
		NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.wasDeleted.notificationName, object: self.wallet)
	}
	//
	// Accessors
	// - State
	var shouldShowScanningBlockchainActivityIndicator: Bool {
		return self.wallet.isAccountScannerCatchingUp // TODO: return false if wallet needs to do import
	}
	//
	// - Transforms
	func cellViewType(forCellAtIndexPath indexPath: IndexPath) -> UICommonComponents.Tables.ReusableTableViewCell.Type
	{
		switch indexPath.section {
			case 0:
				return WalletDetails.Balance.Cell.self
			case 1:
				return type(of: self.infoDisclosingCellView) //WalletDetails.InfoDisclosing.Cell.self
			default:
				assert(false)
				return UICommonComponents.Tables.ReusableTableViewCell.self
		}
	}
	//
	// Imperatives - Configuration
	func set_navigationTitle()
	{
		self.navigationItem.title = self.wallet.walletLabel
	}
	//
	// Imperatives - InfoDisclosing
	func toggleInfoDisclosureCell()
	{ // not a huge fan of all this coupling but at least we can put it in a method
		let (contentContainerView_toFrame, isHiding) = self.infoDisclosingCellView.toggleDisclosureAndPrepareToAnimate()
		UIView.animate(
			withDuration: 0.24,
			delay: 0,
			options: [.curveEaseIn],
			animations:
			{
				self.tableView.beginUpdates()
				do { // we must animate the content container height change too
					self.infoDisclosingCellView.contentContainerView.frame = contentContainerView_toFrame // note this will change the value from which the cellHeight itself is derived
				}
				self.tableView.endUpdates()
			},
			completion:
			{ (finished) in
				if finished {
					self.infoDisclosingCellView.hasFinishedCellToggleAnimation(isHiding: isHiding)
				}
			}
		)
		self.infoDisclosingCellView.configureForJustToggledDisclosureState(animated: true, isHiding: isHiding)
	}
	//
	// Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
	}
	//
	// Delegation - Interactions
	func tapped_rightBarButtonItem()
	{
		assert(false, "display wallet edit modal")
	}
	//
	// Delegation - Notifications
	func wasDeleted()
	{
		if self.navigationController!.topViewController! != self {
			assert(false)
			return
		}
		self.navigationController!.popViewController(animated: true)
	}
	//
	// Delegation - Table
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cellType = self.cellViewType(forCellAtIndexPath: indexPath)
		let reuseIdentifier = cellType.reuseIdentifier()
		var lazy_cell: UICommonComponents.Tables.ReusableTableViewCell?
		do {
			if indexPath.section == 1 { // infodisclosing
				lazy_cell = self.infoDisclosingCellView
			} else {
				lazy_cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? UICommonComponents.Tables.ReusableTableViewCell
				if lazy_cell == nil {
					lazy_cell = cellType.init()
				}
			}
		}
		let cell = lazy_cell!
		do {
			let configuration = UICommonComponents.Tables.ReusableTableViewCell.Configuration(
				cellPosition: UICommonComponents.newCellPosition(withCellIndex: 0, cellsCount: 1),
				dataObject: self.wallet
			)
			cell.configure(with: configuration)
		}
		return cell
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		switch section {
			case 0: // balance
				return 1
			case 1: // infodisclosing
				return 1
			case 2: // transactions
				return 0 // TODO
//				return self.wallet.transactions?.count
			default:
				assert(false)
				return 0
		}
	}
	func numberOfSections(in tableView: UITableView) -> Int
	{
		var count = 0
		count += 1 // balance
		count += 1 // infodisclosing
		count += 1 // transactions, 'scanning', 'import', …
		
		return count
	}
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		tableView.deselectRow(at: indexPath, animated: true)
		if indexPath.section == 1 { // infodisclosing
			self.toggleInfoDisclosureCell()
		}
	}
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		if indexPath.section == 1 { // infodisclosing
			return self.infoDisclosingCellView.cellHeight
		}
		return self.cellViewType(forCellAtIndexPath: indexPath).height()
	}
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		let baseSpacing: CGFloat = 16
		if section == 0 {
			return .leastNormalMagnitude // must be this rather than 0
		} else if section == 1 {
			return baseSpacing/* Note: Not sure why the following must be commented out -WalletDetails.Balance.DisplayView.imagePaddingInsets.bottom*/
		} else if section == 2 {
			// remove top shadow height for transactions… but only if not showing resolving indicator
			if self.shouldShowScanningBlockchainActivityIndicator {
				return WalletDetails.TransactionsSectionHeaderView.topPadding() + WalletDetails.TransactionsSectionHeaderView.height(forMode: .scanningIndicator)
			} else {
				let groupedHighlightableCellVariant = UICommonComponents.GroupedHighlightableCells.Variant.new(
					withState: .normal,
					position: .top
				)
				let imagePadding = groupedHighlightableCellVariant.imagePaddingForShadow
				//
				return baseSpacing - imagePadding.top
			}
		}
		assert(false)
		return .leastNormalMagnitude
	}
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
	{
		return .leastNormalMagnitude // must be this rather than 0
	}
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
	{
		if section == 2 { // transactions - so, scanning blockchain header
			if self.shouldShowScanningBlockchainActivityIndicator {
				return WalletDetails.TransactionsSectionHeaderView(mode: .scanningIndicator)
			} else {
			}
		}
		return nil
	}
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
	{
		return nil
	}
}
//
extension WalletDetails
{
	class TransactionsSectionHeaderView: UIView
	{
		enum Mode
		{
			case scanningIndicator
			case importTransactionsButton
		}
		static func topPadding() -> CGFloat
		{
			return 16
		}
		static func height(forMode: Mode) -> CGFloat
		{
			return WalletDetails.TransactionsSectionHeaderView.topPadding() + 16 // TODO: get fixed height instead of '16'
		}
		var mode: Mode
		var contentView: UIView!
		init(mode: Mode)
		{
			self.mode = mode
			super.init(frame: .zero)
			self.setup()
		}		
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			switch mode {
				case .scanningIndicator:
					let view = UICommonComponents.GraphicAndLabelActivityIndicatorView()
					view.set(labelText: NSLocalizedString("SCANNING BLOCKCHAIN…", comment: ""))
					do {
						let size = view.new_boundsSize_withoutVSpacing // cause we manage v spacing here
						view.frame = CGRect( // initial
							x: CGFloat.form_label_margin_x,
							y: type(of: self).topPadding(),
							width: size.width,
							height: size.height
						)
					}
					view.isHidden = true // quirk of activityIndicator API - must start hidden in order to .show(), which triggers startAnimating() - could just reach in and call startAnimating directly, or improve API
					self.contentView = view
					self.addSubview(view)
					DispatchQueue.main.asyncAfter(
						deadline: .now() + 0.05,
						execute:
						{
							view.show() // can show off the bat b/c visibility logic directly controls self lifecycle
						}
					)
					break
				case .importTransactionsButton:
					assert(false, "TODO")
					break
			}
		}
		//
		deinit
		{
		}
		//
		//
		var indicatorView: UICommonComponents.GraphicAndLabelActivityIndicatorView {
			return self.contentView as! UICommonComponents.GraphicAndLabelActivityIndicatorView
		}
	}
}
