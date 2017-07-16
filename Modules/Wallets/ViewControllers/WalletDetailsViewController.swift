//
//  WalletDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/14/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

struct WalletDetails {}

class WalletDetailsViewController: UICommonComponents.Details.ViewController, UITableViewDelegate, UITableViewDataSource
{
	//
	// Constants/Types
	static let margin_h: CGFloat = 16
	//
	// Properties
	var wallet: Wallet
	var infoDisclosingCellView: WalletDetails.InfoDisclosing.Cell // manual init - holding a reference to keep state and query for height
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
		self.scrollView.contentInset = UIEdgeInsetsMake(14, 0, 14, 0)
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
	// Imperatives
	func set_navigationTitle()
	{
		self.navigationItem.title = self.wallet.walletLabel
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
//		count += 1 // transactions et al
		
		return count
	}
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		tableView.deselectRow(at: indexPath, animated: true)
		if indexPath.section == 1 { // infodisclosing
			let contentContainerView_toFrame = self.infoDisclosingCellView.toggleDisclosureAndPrepareToAnimate_returningContentContainerViewFrame()
			UIView.animate(
				withDuration: 0.34,
				delay: 0,
				options: [.curveEaseInOut],
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
				}
			)
			self.infoDisclosingCellView.configureForJustToggledDisclosureState(animated: true)
		}
	}
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		if indexPath.section == 1 { // infodisclosing
			NSLog("self.infoDisclosingCellView.cellHeight \(self.infoDisclosingCellView.cellHeight)")
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
			// TODO
//			if self.isShowingScanningBlockchainActivityIndicator {
//				return baseSpacing + scanningBlockchainActivityIndicatorTableHeaderView.frame.size.height
//			} else {
				let groupedHighlightableCellVariant = UICommonComponents.GroupedHighlightableCells.Variant.new(
					withState: .normal,
					position: .top
				)
				let imagePadding = groupedHighlightableCellVariant.imagePaddingForShadow
				//
				return baseSpacing - imagePadding.top
//			}
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
		return nil
	}
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
	{
		return nil
	}
}

