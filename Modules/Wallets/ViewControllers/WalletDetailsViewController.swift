//
//  WalletDetailsViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/14/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class WalletDetailsViewController: UICommonComponents.Details.ViewController, UITableViewDelegate, UITableViewDataSource
{
	//
	// Constants/Types
	//
	// Properties
	var wallet: Wallet
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
				return WalletDetailsBalanceViewCell.self
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
			lazy_cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? UICommonComponents.Tables.ReusableTableViewCell
			if lazy_cell == nil {
				lazy_cell = cellType.init()
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
		return 1
	}
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		return self.cellViewType(forCellAtIndexPath: indexPath).height()
	}
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		return 0
	}
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
	{
		return 0
	}
}

class WalletDetailsBalanceViewCell: UICommonComponents.Tables.ReusableTableViewCell
{
	override class func reuseIdentifier() -> String {
		return "UICommonComponents.Details.WalletDetailsBalanceViewCell"
	}
	override class func height() -> CGFloat {
		return WalletBalanceDisplayView.height
	}
	//
	let balanceDisplayView = WalletBalanceDisplayView()
	override func setup()
	{
		super.setup()
		do {
			self.backgroundColor = UIColor.contentBackgroundColor
			self.addSubview(self.balanceDisplayView)
		}
	}
	//
	// Overrides
	override func layoutSubviews()
	{
		super.layoutSubviews()
		self.balanceDisplayView.frame = self.bounds
	}
	override func configure(with configuration: UICommonComponents.Tables.ReusableTableViewCell.Configuration)
	{
		let wallet = configuration.dataObject as? Wallet
		if wallet == nil {
			assert(false)
			return
		}
		if wallet!.didFailToInitialize_flag == true || wallet!.didFailToBoot_flag == true {
			self.balanceDisplayView.label.textColor = .white
			self.balanceDisplayView.label.text = NSLocalizedString("ERROR LOADING", comment: "")
		} else if wallet!.hasEverFetched_accountInfo == false {
			self.balanceDisplayView.set(
				utilityText: NSLocalizedString("LOADING…", comment: ""),
				withWallet: wallet!
			)
		} else {
			self.balanceDisplayView.set(balanceWithWallet: wallet!)
		}
	}
}

class WalletBalanceDisplayView: UIView
{
	//
	// Constants
	static let height: CGFloat = 71
	//
	// Properties
	let label = UILabel()
	//
	// Init
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
		let view = self.label
		view.numberOfLines = 1
		view.lineBreakMode = .byTruncatingTail
		view.font = UIFont(name: UIFont.lightMonospaceFontName, size: 32)
		self.addSubview(view)
	}
	//
	// Overrides
	override func layoutSubviews() {
		super.layoutSubviews()
		self.label.frame = self.bounds.insetBy(dx: 10, dy: 5) // TODO
	}
	//
	// Accessors
	func mainSectionColor(withWallet wallet: Wallet) -> UIColor {
		if wallet.swatchColor.isADarkColor {
			return UIColor(rgb: 0xF8F7F8) // so use light text
		} else {
			return UIColor(rgb: 0x161416) // so use dark text
		}
	}
	func paddingZeroesSectionColor(withWallet wallet: Wallet) -> UIColor {
		
		if wallet.swatchColor.isADarkColor {
			return UIColor(red: 248/255, green: 247/255, blue: 248/255, alpha: 0.2)
		} else {
			return UIColor(red: 29/255, green: 26/255, blue: 29/255, alpha: 0.2)
		}
	}
	//
	// Imperatives
	func set(balanceWithWallet wallet: Wallet)
	{
		var finalized_main_string = ""
		var finalized_paddingZeros_string = ""
		do {
			let raw_balanceString = wallet.balance_formattedString
			let coinUnitPlaces = MoneroConstants.currency_unitPlaces
			let raw_balanceString__components = raw_balanceString.components(separatedBy: ".")
			if raw_balanceString__components.count == 1 {
				let balance_aspect_integer = raw_balanceString__components[0]
				if balance_aspect_integer == "0" {
					finalized_main_string = ""
					finalized_paddingZeros_string = "00." + String(repeating: "0", count: coinUnitPlaces)
				} else {
					finalized_main_string = balance_aspect_integer + "."
					finalized_paddingZeros_string = String(repeating: "0", count: coinUnitPlaces)
				}
			} else if raw_balanceString__components.count == 2 {
				finalized_main_string = raw_balanceString
				let decimalComponent = raw_balanceString__components[1]
				let decimalComponent_length = decimalComponent.characters.count
				if decimalComponent_length < coinUnitPlaces + 2 {
					finalized_paddingZeros_string = String(repeating: "0", count: coinUnitPlaces - decimalComponent_length + 2)
				}
			} else {
				assert(false, "Couldn't parse formatted balance string.")
				finalized_main_string = raw_balanceString
				finalized_paddingZeros_string = ""
			}
		}
		let attributes: [String: Any] = [:]
		let attributedText = NSMutableAttributedString(string: "\(finalized_main_string)\(finalized_paddingZeros_string)", attributes: attributes)
		let mainSectionColor = self.mainSectionColor(withWallet: wallet)
		let paddingZeroesSectionColor = self.paddingZeroesSectionColor(withWallet: wallet)
		do {
			attributedText.addAttributes(
				[
					NSForegroundColorAttributeName: mainSectionColor,
					],
				range: NSMakeRange(0, finalized_main_string.characters.count)
			)
			if finalized_paddingZeros_string.characters.count > 0 {
				attributedText.addAttributes(
					[
						NSForegroundColorAttributeName: paddingZeroesSectionColor,
						],
					range: NSMakeRange(
						finalized_main_string.characters.count,
						attributedText.string.characters.count - finalized_paddingZeros_string.characters.count
					)
				)
			}
		}
		self.label.textColor = paddingZeroesSectionColor // for the '…' during truncation
		self.label.attributedText = attributedText
		self._configureBackgroundColor(withWallet: wallet)
	}
	func set(utilityText text: String, withWallet wallet: Wallet)
	{
		self.label.textColor = self.mainSectionColor(withWallet: wallet)
		self.label.text = text
		self._configureBackgroundColor(withWallet: wallet)
	}
	func _configureBackgroundColor(withWallet wallet: Wallet)
	{
		self.backgroundColor = UIColor(rgb: wallet.swatchColor.rgbIntValue) // TODO: img?
	}
}
