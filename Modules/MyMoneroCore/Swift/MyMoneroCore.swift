//
//  MyMoneroCore.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import Foundation
import UIKit // because we use a WKWebView
//
// Principal type
final class MyMoneroCore : MyMoneroCoreJS
{
	// TODO? alternative to subclassing MyMoneroCoreJS would be to hold an instance of it and provide proxy fns as interface.
	//
	// Interface - Singleton
	static let shared = MyMoneroCore()
	//
	// Constants
	static var fixedMixin: Int {
		return 9 // TODO: obtain this via the official core lib… or server?
	}
	//
	// Lifecycle - Init
	private convenience init()
	{
		self.init(window: UIApplication.shared.delegate!.window!!)
	}
	override init(window: UIWindow)
	{
		super.init(window: window)
	}
}
