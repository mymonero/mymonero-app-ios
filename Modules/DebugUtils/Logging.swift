//
//  Logging.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import os.log
//
struct DDLog
{
	typealias CategoryName = String
	static var logsByCategoryName: [CategoryName: OSLog] = [:]
	//
	enum LogLevel: String
	{
		case info = "💬"
		case warn = "⚠️"
		case error = "❌"
		case perform = "🔁" /* `do` is reserved, so calling this perform */
		case done = "✅"
		case write = "📝"
		case net = "📡"
		case tearingDown = "♻️"
		case todo = "📌"
		case deleting = "🗑"
		//
		var logMessagePrefix: String
		{
			return "\(self.rawValue)  "
		}
	}
	//
	static func log(named categoryName: CategoryName) -> OSLog
	{
		var log = logsByCategoryName[categoryName]
		if log == nil {
			log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: categoryName)
			logsByCategoryName[categoryName] = log
		}
		return log!
	}
	//
	static func addLogEntry(categoryName: CategoryName, level: LogLevel, message: String)
	{
		let final_message = "\(level.logMessagePrefix)\(message)"
		let log = self.log(named: categoryName)
		os_log("%@", log: log, final_message)
	}
	//
	static func Info(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .info, message: message)
	}
	static func Warn(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .warn, message: message)
	}
	static func Error(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .error, message: message)
	}
	static func Do(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .perform, message: message)
	}
	static func Done(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .done, message: message)
	}
	static func Write(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .write, message: message)
	}
	static func Net(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .net, message: message)
	}
	static func TearingDown(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .tearingDown, message: message)
	}
	static func Todo(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .todo, message: message)
	}
	static func Deleting(_ categoryName: CategoryName, _ message: String)
	{
		self.addLogEntry(categoryName: categoryName, level: .deleting, message: message)
	}
}
