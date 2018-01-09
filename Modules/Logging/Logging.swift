//
//  Logging.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/9/17.
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
		case info			= "💬"
		case warn			= "⚠️"
		case error			= "❌"
		case perform		= "🔁" /* `do` is reserved, so calling this perform */
		case done			= "✅"
		case write			= "📝"
		case net			= "📡"
		case tearingDown	= "♻️"
		case todo			= "📌"
		case deleting		= "🗑"
		//
		var logMessagePrefix: String
		{
			return "\t\(self.rawValue)\t"
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
		#if DEBUG
		let final_message = "\(level.logMessagePrefix)\(message)"
		let log = self.log(named: categoryName)
		os_log("%@", log: log, final_message)
		#endif
	}
	//
	// TODO: can these be procedurally generated?
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
