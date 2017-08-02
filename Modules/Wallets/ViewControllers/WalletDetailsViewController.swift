//
//  WalletDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/14/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
struct WalletDetails {}
//
extension WalletDetails
{
	// Principal class
	class ViewController: UICommonComponents.Details.ViewController, UITableViewDelegate, UITableViewDataSource
	{
		//
		// Constants/Types
		static let margin_h: CGFloat = 16
		//
		// Properties
		var wallet: Wallet
		var infoDisclosingCellView: WalletDetails.InfoDisclosing.Cell // manual init - holding a reference to keep state and query for height
		var transactionsSectionHeaderView: WalletDetails.TransactionsSectionHeaderView?
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
				self.scrollView.contentInset = UIEdgeInsetsMake(14, 0, 0/*14 commented as janky semi-fix to unwanted visual btm padding */, 0)
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
			//
			NotificationCenter.default.addObserver(self, selector: #selector(willBeDeleted), name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.wallet)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(infoUpdated),
				name: Wallet.NotificationNames.balanceChanged.notificationName,
				object: self.wallet
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(infoUpdated),
				name: Wallet.NotificationNames.heightsUpdated.notificationName,
				object: self.wallet
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(infoUpdated),
				name: Wallet.NotificationNames.labelChanged.notificationName, // could go straight to nav bar title changed but preferable to go to a labelChanged instead
				object: self.wallet
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(infoUpdated),
				name: Wallet.NotificationNames.spentOutputsChanged.notificationName,
				object: self.wallet
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(infoUpdated),
				name: Wallet.NotificationNames.swatchColorChanged.notificationName,
				object: self.wallet
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(infoUpdated),
				name: Wallet.NotificationNames.transactionsChanged.notificationName,
				object: self.wallet
			)
		}
		override func stopObserving()
		{
			super.stopObserving()
			NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.balanceChanged.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.heightsUpdated.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.labelChanged.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.spentOutputsChanged.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.swatchColorChanged.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.transactionsChanged.notificationName, object: self.wallet)
		}
		//
		// Accessors
		// - State
		var shouldShowScanningBlockchainActivityIndicator: Bool {
			assert(self.shouldShowImportTransactionsButton == false) // putting this check outside so priority logic is dictated elsewhere (in delegate methods)
			return self.wallet.isAccountScannerCatchingUp
		}
		var shouldShowImportTransactionsButton: Bool {
			if self.wallet.hasEverFetched_transactions != false {
				let transactions = wallet.transactions ?? []
				if transactions.count > 0 {
					return false // if transactions are appearing, we're going to assume we don't need to show the prompt button
				}
			}
			return wallet.shouldDisplayImportAccountOption ?? false // default false on nil
		}
		var hasTransactions: Bool {
			return self.wallet.transactions != nil && self.wallet.transactions!.count > 0
		}
		// - Transforms
		func cellViewType(forCellAtIndexPath indexPath: IndexPath) -> UICommonComponents.Tables.ReusableTableViewCell.Type
		{
			switch indexPath.section {
				case 0:
					return WalletDetails.Balance.Cell.self
				case 1:
					return type(of: self.infoDisclosingCellView) //WalletDetails.InfoDisclosing.Cell.self
				case 2:
					if self.hasTransactions {
						return WalletDetails.Transaction.Cell.self
					} else {
						return WalletDetails.TransactionsEmptyState.Cell.self
					}
				default:
					return UICommonComponents.Tables.ReusableTableViewCell.self
			}
		}
		func cellPosition(forCellAtIndexPath indexPath: IndexPath) -> UICommonComponents.CellPosition
		{
			if indexPath.section == 0 {
				return .standalone
			} else if indexPath.section == 1 { // infodisclosing
				return .standalone // never need this though
			} else if indexPath.section == 2 { // transactions
				if self.hasTransactions {
					let index = indexPath.row
					let cellsCount = self.wallet.transactions!.count
					let cellPosition = UICommonComponents.newCellPosition(
						withCellIndex: index,
						cellsCount: cellsCount
					)
					return cellPosition
				} else {
					return .standalone
				}
			}
			assert(false)
			return .standalone
		}
		// - Factories - Views - Sections - Transactions
		var _new_transactionSectionHeaderView_importTransactionsButton: WalletDetails.TransactionsSectionHeaderView {
			let view = WalletDetails.TransactionsSectionHeaderView(
				mode: .importTransactionsButton,
				wallet: self.wallet
			)
			view.importTransactions_tapped_fn =
			{ [unowned self] in
				self.present_importTransactionsModal()
			}
			return view
		}
		var _new_transactionSectionHeaderView_scanningIndicator: WalletDetails.TransactionsSectionHeaderView {
			let view = WalletDetails.TransactionsSectionHeaderView(
				mode: .scanningIndicator,
				wallet: self.wallet
			)
			return view
		}
		//
		// Imperatives - Configuration
		func set_navigationTitle()
		{
			self.navigationItem.title = self.wallet.walletLabel
		}
		//
		// Imperatives - InfoDisclosing
		var infoDisclosing_contentContainerView_toFrame: CGRect?
		func toggleInfoDisclosureCell()
		{ // not a huge fan of all this coupling but at least we can put it in a method
			let (contentContainerView_toFrame, isHiding) = self.infoDisclosingCellView.toggleDisclosureAndPrepareToAnimate()
			do { // now animate the actual cell height
				self.tableView.beginUpdates() // this opens its own animation context, so it must be outside of the .animate below… but because it must be outside, it seems to mess with the
				do {
					assert(self.infoDisclosing_contentContainerView_toFrame == nil)
					self.infoDisclosing_contentContainerView_toFrame = contentContainerView_toFrame
				}
				self.tableView.endUpdates() // regardless of whether it finished
				do {
					assert(self.infoDisclosing_contentContainerView_toFrame != nil)
					self.infoDisclosing_contentContainerView_toFrame = nil // zero
				}
			}
			self.infoDisclosingCellView.animateToJustToggledDisclosureState(
				animated: true,
				isHiding: isHiding,
				to__contentContainerView_toFrame: contentContainerView_toFrame
			)
		}
		//
		// Imperatives - Import modal
		func present_importTransactionsModal()
		{
			let viewController = ImportTransactionsModal.ViewController(wallet: self.wallet)
			let navigationController = UINavigationController(rootViewController: viewController)
			self.navigationController!.present(navigationController, animated: true, completion: nil)
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
			let viewController = EditWallet.ViewController(wallet: self.wallet)
			let navigationController = UINavigationController(rootViewController: viewController)
			self.navigationController!.present(navigationController, animated: true, completion: nil)
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
				let cellPosition = self.cellPosition(forCellAtIndexPath: indexPath)
				let configuration = UICommonComponents.Tables.ReusableTableViewCell.Configuration(
					cellPosition: cellPosition,
					indexPath: indexPath,
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
					if self.hasTransactions {
						return self.wallet.transactions?.count ?? 0
					} else {
						return 1 // for empty state cell
					}
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
			//
			return count
		}
		func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
		{
			tableView.deselectRow(at: indexPath, animated: true)
			if indexPath.section == 0 { // balance
				return // nothing to do except return early
			} else if indexPath.section == 1 { // infodisclosing
				self.toggleInfoDisclosureCell()
				return
			} else if indexPath.section == 2 { // transactions
				if self.hasTransactions == false {
					return // empty state cell
				}
				let transaction = self.wallet.transactions![indexPath.row]
				let viewController = TransactionDetails.ViewController(transaction: transaction, inWallet: self.wallet)
				self.navigationController!.pushViewController(
					viewController,
					animated: true
				)
				return
			}
			assert(false)
		}
		func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
		{
			let cellPosition = self.cellPosition(forCellAtIndexPath: indexPath)
			if indexPath.section == 0 {
				return self.cellViewType(forCellAtIndexPath: indexPath).cellHeight(withPosition: cellPosition)
			} else if indexPath.section == 1 { // infodisclosing
				if let frame = self.infoDisclosing_contentContainerView_toFrame { // while animating disclosure toggle - done due to how begin and endUpdates works with a custom animation context
					return type(of: self.infoDisclosingCellView).cellHeight(with_contentContainerView_toFrame: frame)
				}
				return self.infoDisclosingCellView.cellHeight
			} else if indexPath.section == 2 { // transactions
				return self.cellViewType(forCellAtIndexPath: indexPath).cellHeight(withPosition: cellPosition)
			}
			assert(false)
			return 0
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
				// here is some header view mode precedence logic
				if self.shouldShowImportTransactionsButton {
					return WalletDetails.TransactionsSectionHeaderView.fullViewHeight(forMode: .scanningIndicator, topPadding: baseSpacing)
				} else if self.shouldShowScanningBlockchainActivityIndicator {
					return WalletDetails.TransactionsSectionHeaderView.fullViewHeight(forMode: .scanningIndicator, topPadding: 10)
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
				// here is some header view mode logic
				// we hang onto self.transactionsSectionHeaderView so that on reloadData etc we can keep showing the same state, e.g. animation step
				if self.shouldShowImportTransactionsButton {
					if self.transactionsSectionHeaderView == nil || self.transactionsSectionHeaderView!.mode != .importTransactionsButton {
						self.transactionsSectionHeaderView = self._new_transactionSectionHeaderView_importTransactionsButton
					}
				} else if self.shouldShowScanningBlockchainActivityIndicator {
					if self.transactionsSectionHeaderView == nil || self.transactionsSectionHeaderView!.mode != .scanningIndicator {
						self.transactionsSectionHeaderView = self._new_transactionSectionHeaderView_scanningIndicator
					}
				} else {
					self.transactionsSectionHeaderView = nil  // free existing
				}
				return self.transactionsSectionHeaderView
			}
			return nil
		}
		func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
		{
			return nil
		}
		//
		// Delegation - Notifications
		func willBeDeleted()
		{
			if self.navigationController!.topViewController! != self {
				assert(false)
				return
			}
			self.navigationController!.popViewController(animated: true)
		}
		func infoUpdated()
		{
			self.set_navigationTitle()
			self.tableView.reloadData()
		}
		//
		// Delegation - View lifecycle
		override func viewDidAppear(_ animated: Bool)
		{
			super.viewDidAppear(animated)
			if let view = self.transactionsSectionHeaderView {
				if view.mode == .scanningIndicator {
					if view.indicatorView.activityIndicator.isAnimating == false {
						if view.superview != nil { // if actually visible
							view.indicatorView.activityIndicator.startAnimating()
						}
					}
				}
			}
		}
		override func viewWillDisappear(_ animated: Bool)
		{
			super.viewWillDisappear(animated)
			if let view = self.transactionsSectionHeaderView {
				if view.mode == .scanningIndicator {
					if view.indicatorView.activityIndicator.isAnimating == true {
						view.indicatorView.activityIndicator.stopAnimating()
					}
				}
			}
		}
		func tableView(_ tableView: UITableView, willDisplayHeaderView headerView: UIView, forSection section: Int)
		{
			if section == 2 { // transactions
				assert(headerView == self.transactionsSectionHeaderView)
				let view = self.transactionsSectionHeaderView!
				if view.mode == .scanningIndicator {
					if view.indicatorView.isHidden { // for very first time
						view.indicatorView.show() // will also start it animating
					} else if view.indicatorView.activityIndicator.isAnimating == false { // already visible but not animating!
						view.indicatorView.activityIndicator.startAnimating()
					}
				}
			}
		}
		func tableView(_ tableView: UITableView, didEndDisplayingHeaderView headerView: UIView, forSection section: Int)
		{
			if section == 2 { // transactions
				assert(headerView == self.transactionsSectionHeaderView)
				let view = self.transactionsSectionHeaderView!
				if view.mode == .scanningIndicator {
					if view.indicatorView.activityIndicator.isAnimating == true {
						view.indicatorView.activityIndicator.stopAnimating()
					}
				}
			}
		}
	}
}
