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
	init()
	{
		super.init(nibName: nil, bundle: nil)
		self.setup()
	}
	//
	func setup()
	{
		
	}
	// TODO: observe list controller change
	//
	
//	guard let tableView = self?.tableView else { return }
//	switch changes {
//	case .initial:
//	// Results are now populated and can be accessed without blocking the UI
//	tableView.reloadData()
//	break
//	case .update(_, let deletions, let insertions, let modifications):
//	// Query results have changed, so apply them to the UITableView
//	tableView.beginUpdates()
//	tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
//	with: .automatic)
//	tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
//	with: .automatic)
//	tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
//	with: .automatic)
//	tableView.endUpdates()
//	break
//	case .error(let error):
//	// An error occurred while opening the Realm file on the background worker thread
//	fatalError("\(error)")
//	break
//	}
}
