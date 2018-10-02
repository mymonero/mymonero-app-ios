//
//  WalletDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/14/17.
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
		enum SectionName: UInt
		{
			case balance		= 0
			case infoDisclosing = 1
			case actionButtons	= 2
			case transactions	= 3
			//
			var indexInTable: Int {
				return Int(self.rawValue)
			}
			static var numberOfSections: UInt {
				var count: UInt = 0
				while let _ = SectionName(rawValue: count) {
					count += 1
				}
				//
				return count
			}
			static func new_SectionName(withSectionIndex sectionIndex: Int) -> SectionName?
			{
				assert(sectionIndex >= 0)
				return SectionName(
					rawValue: UInt(sectionIndex)
				)
			}
		}
		//
		// Properties
		var wallet: Wallet // keeping this strong b/c self will be torn down; similarly, ∴, no need to observe .willBeDeinitialized
		var infoDisclosingCellView: WalletDetails.InfoDisclosing.Cell // manual init - holding a reference to keep state and query for height
		var transactionsSectionHeaderView: WalletDetails.TransactionsSectionHeaderView?
		//
		var tableView: UITableView {
			return self.scrollView as! UITableView
		}
		//
		// State
		var hasEverAutomaticallyDisplayedImportModal: Bool?
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
			let view = UICommonComponents.Details.TableView(frame: .zero, style: .grouped)
			do { // need to specify this b/c we're not getting super's config
				view.indicatorStyle = .white
				view.backgroundColor = .contentBackgroundColor
				view.separatorStyle = .none
				view.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude)) // prevent undesired visual top padding
			}
			do { // to fix apparent visual bug of vertical transit on nav push/pop
				self.automaticallyAdjustsScrollViewInsets = false // NOTE: This is redundant since we inherit from ScrollableInfoVC
				if #available(iOS 11.0, *) {
					view.contentInsetAdjustmentBehavior = .never
				}
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
				self.scrollView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
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
			NotificationCenter.default.addObserver(self, selector: #selector(_wallet_loggedIn), name: PersistableObject.NotificationNames.booted.notificationName, object: self.wallet)
			NotificationCenter.default.addObserver(self, selector: #selector(_wallet_failedToLogIn), name: PersistableObject.NotificationNames.failedToBoot.notificationName, object: self.wallet)
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
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(CcyConversionRates_didUpdateAvailabilityOfRates),
				name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(SettingsController__NotificationNames_Changed__displayCurrencySymbol),
				name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
				object: nil
			)
		}
		override func stopObserving()
		{
			super.stopObserving()
			//
			NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.booted.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.failedToBoot.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: PersistableObject.NotificationNames.willBeDeleted.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.balanceChanged.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.heightsUpdated.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.labelChanged.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.spentOutputsChanged.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.swatchColorChanged.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(self, name: Wallet.NotificationNames.transactionsChanged.notificationName, object: self.wallet)
			NotificationCenter.default.removeObserver(
				self,
				name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
				object: nil
			)
			NotificationCenter.default.removeObserver(
				self,
				name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
				object: nil
			)
		}
		//
		// Accessors
		// - State
		var shouldShowScanningBlockchainActivityIndicator: Bool {
			assert(self.shouldShowImportTransactionsButton == false) // putting this check outside so priority logic is dictated elsewhere (in delegate methods)
			let wallet = self.wallet
			if wallet.isBooted == false/*for now*/ || wallet.hasEverFetched_accountInfo == false/*for now*/
				|| wallet.didFailToInitialize_flag == true || wallet.didFailToBoot_flag == true {
				return false // not yet
			}
			return wallet.isAccountScannerCatchingUp
		}
		var hasWalletBootFailed: Bool {
			let wallet = self.wallet
			//
			return wallet.didFailToInitialize_flag == true || wallet.didFailToBoot_flag == true
		}
		var shouldShowImportTransactionsButton: Bool {
			let wallet = self.wallet
			if wallet.didFailToInitialize_flag == true || wallet.didFailToBoot_flag == true {
				return false // not yet
			}
			if wallet.hasEverFetched_transactions != false {
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
			let sectionName = SectionName.new_SectionName(withSectionIndex: indexPath.section)!
			switch sectionName {
				case .balance:
					return WalletDetails.Balance.Cell.self
				case .infoDisclosing:
					return type(of: self.infoDisclosingCellView) //WalletDetails.InfoDisclosing.Cell.self
				case .actionButtons:
					return WalletDetails.ActionButtons.Cell.self
				case .transactions:
					assert(wallet.didFailToInitialize_flag != true && wallet.didFailToBoot_flag != true)
					if self.hasTransactions {
						return WalletDetails.Transaction.Cell.self
					}
					//
					return WalletDetails.TransactionsEmptyState.Cell.self
			}
		}
		func cellPosition(forCellAtIndexPath indexPath: IndexPath) -> UICommonComponents.CellPosition
		{
			let sectionName = SectionName.new_SectionName(withSectionIndex: indexPath.section)!
			switch sectionName {
				case .balance,
				     .infoDisclosing,
				     .actionButtons:
					return .standalone
				case .transactions:
					assert(wallet.didFailToInitialize_flag != true && wallet.didFailToBoot_flag != true)
					if self.hasTransactions {
						let index = indexPath.row
						let cellsCount = self.wallet.transactions!.count
						let cellPosition = UICommonComponents.newCellPosition(
							withCellIndex: index,
							cellsCount: cellsCount
						)
						return cellPosition
					}
					return .standalone
			}
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
		{
			func __really_proceed()
			{
				// not a huge fan of all this coupling but at least we can put it in a method
				let (contentContainerView_toFrame, isHiding) = self.infoDisclosingCellView.toggleDisclosureAndPrepareToAnimate()
				self.infoDisclosingCellView.isHavingContentContainerFrameManagedExternally = true // prevent its layoutSubviews from racing with what we are doing here, but primarily b/c it will be redundant
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
				self.infoDisclosingCellView.isHavingContentContainerFrameManagedExternally = false
			}
			if SettingsController.shared.authentication__requireToShowWalletSecrets {
				if self.infoDisclosingCellView.isDisclosed == false { // when toggling to 'disclosed'
					PasswordController.shared.initiate_verifyUserAuthenticationForAction(
						customNavigationBarTitle: NSLocalizedString("Authenticate", comment: ""),
						canceled_fn: {},
						entryAttempt_succeeded_fn: {
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute:
							{ // this delay is purely for visual effect, waiting for pw entry to dismiss
								__really_proceed()
							})
						}
					)
					return
				}
			}
			__really_proceed()
		}
		//
		// Imperatives - Import modal
		func present_importTransactionsModal()
		{
			let p_vc: UIViewController? = self.navigationController!.presentingViewController ?? self.navigationController!.presentedViewController ?? nil
			if p_vc != nil {
				if p_vc!.isKind(of: ImportTransactionsModal.ViewController.self) {
					DDLog.Info("Wallets", "Import modal already presented")
					return
				}
			}
			let viewController = ImportTransactionsModal.ViewController(wallet: self.wallet)
			let navigationController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
			navigationController.modalPresentationStyle = .formSheet
			self.navigationController!.present(navigationController, animated: true, completion: nil)
		}
		func _ifNecessary_autoPresent_importTxsModal(afterS: TimeInterval)
		{
			// If this is the first time after logging in that we're displaying the import txs modal,
			// then auto-display it for the user so they don't have to know to click on the button
			if self.hasEverAutomaticallyDisplayedImportModal != true {
				if self.shouldShowImportTransactionsButton {
					self.hasEverAutomaticallyDisplayedImportModal = true // immediately, in case login and viewDidAppear race
					DispatchQueue.main.asyncAfter(
						deadline: .now() + afterS
					) { [weak self] in
						guard let thisSelf = self else {
							return
						}
						thisSelf.present_importTransactionsModal()
					}
				}
			}
		}
		//
		// Overrides - Layout
		override func viewDidLayoutSubviews()
		{
			super.viewDidLayoutSubviews()
		}
		//
		// Delegation - Interactions
		@objc func tapped_rightBarButtonItem()
		{
			let viewController = EditWallet.ViewController(wallet: self.wallet)
			let navigationController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
			navigationController.modalPresentationStyle = .formSheet
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
				switch indexPath.section {
					case SectionName.infoDisclosing.indexInTable:
						lazy_cell = self.infoDisclosingCellView
						break
					default:
						lazy_cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? UICommonComponents.Tables.ReusableTableViewCell
						if lazy_cell == nil {
							lazy_cell = cellType.init()
						}
						break
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
			let sectionName = SectionName.new_SectionName(withSectionIndex: section)!
			switch sectionName {
				case .balance,
					 .infoDisclosing,
					 .actionButtons:
					return 1
				case .transactions:
					if wallet.didFailToInitialize_flag == true || wallet.didFailToBoot_flag == true {
						return 0 // no empty state cell until logged in (cause we don't know)
					}
					if self.hasTransactions {
						return self.wallet.transactions?.count ?? 0
					}
					return 1 // for empty state cell
			}
		}
		func numberOfSections(in tableView: UITableView) -> Int
		{
			return Int(SectionName.numberOfSections) // UInt -> Int
		}
		func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
		{
			tableView.deselectRow(at: indexPath, animated: true)
			let sectionName = SectionName.new_SectionName(withSectionIndex: indexPath.section)!
			switch sectionName {
				case .balance,
				     .actionButtons:
					return // nothing to do except return early
				case .infoDisclosing:
					self.toggleInfoDisclosureCell()
					return
				case .transactions:
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
		}
		func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
		{
			let cellPosition = self.cellPosition(forCellAtIndexPath: indexPath)
			let sectionName = SectionName.new_SectionName(withSectionIndex: indexPath.section)!
			switch sectionName {
				case .balance,
				     .actionButtons:
					return self.cellViewType(forCellAtIndexPath: indexPath).cellHeight(withPosition: cellPosition)
				case .transactions:
					assert(wallet.didFailToInitialize_flag != true && wallet.didFailToBoot_flag != true)
					return self.cellViewType(forCellAtIndexPath: indexPath).cellHeight(withPosition: cellPosition)
				case .infoDisclosing:
					if let frame = self.infoDisclosing_contentContainerView_toFrame { // while animating disclosure toggle - done due to how begin and endUpdates works with a custom animation context
						return type(of: self.infoDisclosingCellView).cellHeight(with_contentContainerView_toFrame: frame)
					}
					return self.infoDisclosingCellView.cellHeight
			}
		}
		func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
		{
			let baseSpacing: CGFloat = 16
			let sectionName = SectionName.new_SectionName(withSectionIndex: section)!
			switch sectionName {
				case .balance:
					return 14 // since we don't supply this as contentInset.top
				case .infoDisclosing:
					return baseSpacing/* Note: Not sure why the following must be commented out -WalletDetails.Balance.DisplayView.imagePaddingInsets.bottom*/
				case .actionButtons:
					return .leastNormalMagnitude // the cell supplies its own; must be this instead of 0
				case .transactions:
					if self.wallet.didFailToInitialize_flag == true || self.wallet.didFailToBoot_flag == true {
						return .leastNormalMagnitude
					}
					// remove top shadow height for transactions… but only if not showing resolving indicator
					// here is some header view mode precedence logic
					if self.shouldShowImportTransactionsButton {
						return WalletDetails.TransactionsSectionHeaderView.fullViewHeight(
							forMode: .scanningIndicator,
							topPadding: baseSpacing
						)
					} else if self.shouldShowScanningBlockchainActivityIndicator {
						return WalletDetails.TransactionsSectionHeaderView.fullViewHeight(
							forMode: .scanningIndicator,
							topPadding: 10
						)
					}
					let groupedHighlightableCellVariant = UICommonComponents.GroupedHighlightableCells.Variant.new(
						withState: .normal,
						position: .top
					)
					let imagePadding = groupedHighlightableCellVariant.imagePaddingForShadow
					//
					return baseSpacing - imagePadding.top
			}
		}
		func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
		{
			return .leastNormalMagnitude // must be this rather than 0
		}
		func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
		{
			if section == SectionName.transactions.indexInTable { // transactions - so, scanning blockchain header, etc
				if self.wallet.didFailToInitialize_flag == true || self.wallet.didFailToBoot_flag == true {
					return nil
				}
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
		func tableView(_ tableView: UITableView, willDisplayHeaderView headerView: UIView, forSection section: Int)
		{
			if section == SectionName.transactions.indexInTable { // transactions
				assert(headerView == self.transactionsSectionHeaderView)
				let view = self.transactionsSectionHeaderView!
				if view.mode == .scanningIndicator {
					assert(view.superview == nil)
					if view.indicatorView.isHidden { // for very first time
						view.indicatorView.show() // will also start it animating
					}
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // fixed delay unfortunately fragile .. any better solution? I don't actually fully get why this is necessary.. lack of superview? then why does .isHidden->.show() case work w/o this call?
						// if still not animating
						if view.indicatorView.activityIndicator.isAnimating == false {
							view.indicatorView.activityIndicator.startAnimating()
						}
					}
				}
			}
		}
		func tableView(_ tableView: UITableView, didEndDisplayingHeaderView headerView: UIView, forSection section: Int)
		{
			if section == SectionName.transactions.indexInTable { // transactions
				assert(headerView == self.transactionsSectionHeaderView)
				let view = self.transactionsSectionHeaderView!
				if view.mode == .scanningIndicator {
					if view.indicatorView.activityIndicator.isAnimating == true {
						view.indicatorView.activityIndicator.stopAnimating() // optimization
					}
				}
			}
		}
		//
		// Delegation - Notifications
		@objc func _wallet_loggedIn()
		{
			self.tableView.reloadData()
			self._ifNecessary_autoPresent_importTxsModal(afterS: 1)
		}
		@objc func _wallet_failedToLogIn()
		{
			self.tableView.reloadData()
		}
		@objc func willBeDeleted()
		{
			if self.navigationController!.topViewController! != self {
				assert(false)
				return
			}
			self.navigationController!.popViewController(animated: true)
		}
		@objc func infoUpdated()
		{
			self.set_navigationTitle()
			self.tableView.reloadData()
		}
		@objc func CcyConversionRates_didUpdateAvailabilityOfRates()
		{
			self.tableView.reloadData() // want balance label update
		}
		@objc func SettingsController__NotificationNames_Changed__displayCurrencySymbol()
		{
			self.tableView.reloadData() // want balance label update
		}
		//
		// Delegation - View lifecycle
		override func viewDidAppear(_ animated: Bool)
		{
			super.viewDidAppear(animated)
			self.wallet.requestManualUserRefresh()
			do { // this may not actually be necessary:
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
			self._ifNecessary_autoPresent_importTxsModal(afterS: 1)
		}
		override func viewWillDisappear(_ animated: Bool)
		{
			super.viewWillDisappear(animated)
			do { // this may not actually be necessary:
				if let view = self.transactionsSectionHeaderView {
					if view.mode == .scanningIndicator {
						if view.indicatorView.activityIndicator.isAnimating == true {
							view.indicatorView.activityIndicator.stopAnimating()
						}
					}
				}
			}
		}
		//
		// Delegation - Device orientation
		override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
		{
			super.viewWillTransition(to: size, with: coordinator)
			do { // so that the table view also updates cell heights … because the info disclosing view will have updated itself if it's currently open (reflowing text)
				
				// Not a huge fan of reaching through infoDisclosingCellView to contentContainerView… maybe rework
				let contentContainerView_toFrame = self.infoDisclosingCellView.contentContainerView.sizeAndLayOutSubviews_returningSelfFrame(
					withContainingWidth: size.width
				)
				self.infoDisclosingCellView.isHavingContentContainerFrameManagedExternally = true // prevent its layoutSubviews from racing with what we are doing here b/c the infoDisclosingCellView.frame.size.width will be different
				do { // now animate the actual cell height
					self.tableView.beginUpdates() // this opens its own animation context, so it must be outside of the .animate below… but because it must be outside, it seems to mess with the
					do {
						assert(self.infoDisclosing_contentContainerView_toFrame == nil)
						self.infoDisclosing_contentContainerView_toFrame = contentContainerView_toFrame // used in heightForRowAt during update!
					}
					self.infoDisclosingCellView.contentContainerView.frame = contentContainerView_toFrame // must set this ourselves
					//
					self.tableView.endUpdates() // regardless of whether it finished
					do {
						assert(self.infoDisclosing_contentContainerView_toFrame != nil)
						self.infoDisclosing_contentContainerView_toFrame = nil // zero
					}
				}
				DispatchQueue.main.asyncAfter(
					deadline: .now() + coordinator.transitionDuration, // hopefully this is not too fragile of a way to do this? we want to prevent infoDisclosingCellView from handling the change in width for this orientation change in its layoutSubviews so we must wait until the transition is over (or rather until after self.infoDisclosingCellView has finished having its frame changed owing to this transition)
					execute:
					{ [weak self] in
						guard let thisSelf = self else {
							return
						}
						thisSelf.infoDisclosingCellView.isHavingContentContainerFrameManagedExternally = false
					}
				)
			}
		}
	}
}
