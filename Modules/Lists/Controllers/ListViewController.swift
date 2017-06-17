//
//  ListViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
class ListViewController: UITableViewController
{
	override init(style: UITableViewStyle)
	{
		fatalError("\(#function) has not been implemented")
	}
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
	{
		fatalError("\(#function) has not been implemented")
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("\(#function) has not been implemented")
	}
	var listController: PersistedObjectListController!
	//
	// Lifecycle - Init
	init(withListController listController: PersistedObjectListController)
	{
		super.init(nibName: nil, bundle: nil)
		self.listController = listController
		self.setup()
	}
	func setup()
	{
		self.setup_views()
		do {
			self.configure_navigation_title()
			self.configure_navigation_barButtonItems()
		}
		self.startObserving()
	}
	func setup_views()
	{
		self.setup_tableView()
	}
	func setup_tableView()
	{
		self.tableView.delegate = self
	}
	func startObserving()
	{
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(PersistedObjectListController_Notifications_List_updated),
			name: PersistedObjectListController.Notifications_List.updated.notificationName,
			object: self.listController
		)
	}
	//
	// Lifecycle - Deinit
	deinit
	{
		self.stopObserving()
	}
	func stopObserving()
	{
		NotificationCenter.default.removeObserver(
			self,
			name: PersistedObjectListController.Notifications_List.updated.notificationName,
			object: self.listController
		)
	}
	//
	// Accessors - Required
	func new_navigationTitle() -> String
	{
		assert(false, "required")
	}
	//
	// Imperatives
	func configure_navigation_title()
	{
		self.navigationItem.title = self.new_navigationTitle() // mustn't set self.title or it will also set tabBarItem title
	}
	func configure_navigation_barButtonItems()
	{
		
	}
	//
	// Protocol - Table View - Accessors & Delegation
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		assert(false, "required")
	}
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		assert(false, "required")
	}
	override func numberOfSections(in tableView: UITableView) -> Int
	{
		return 1
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if self.listController.hasBooted != true {
			return 0
		}
		return self.listController.records.count
	}
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		tableView.deselectRow(at: indexPath, animated: true)
	}
	//
	// Delegation - Notifications
	func PersistedObjectListController_Notifications_List_updated()
	{
		self.configure_navigation_title()
		self.configure_navigation_barButtonItems()
		//
		self.tableView.reloadData()
	}
}
