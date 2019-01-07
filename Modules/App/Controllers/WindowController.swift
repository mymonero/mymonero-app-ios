//
//  WindowController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/5/17.
//  Copyright (c) 2014-2019, MyMonero.com
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

class WindowController
{
	//
	// Static - Convenience
	static var appDelegate: AppDelegate {
		return UIApplication.shared.delegate as! AppDelegate
	}
	static var windowController: WindowController? {
		guard let windowController = appDelegate.windowController else {
			return nil
		}
		return windowController
	}
	static var rootViewController: RootViewController? {
		guard let windowController = WindowController.windowController else {
			return nil
		}
		return windowController.rootViewController
	}
	static var rootTabBarViewController: RootTabBarViewController? {
		guard let rootViewController = WindowController.rootViewController else {
			return nil
		}
		return rootViewController.tabBarViewController
	}
	static var presentModalsInViewController: UIViewController? {
		return WindowController.rootViewController // the tab bar - so the connectivityView is still visibile.
	}
	//
	// Properties
	var window = UIWindow(frame: UIScreen.main.bounds)
	var rootViewController = RootViewController()
	//
	// Lifecycle - Init
	init()
	{
		self.setup()
	}
	func setup()
	{
		let _ = ThemeController.shared // so as to initialize it so it sets up appearance, mode, etc
		self.window.backgroundColor = UIColor.contentBackgroundColor
		//
		window.rootViewController = self.rootViewController
	}
	//
	// Accessors
	var presentModalsInViewController: UIViewController {
		return self.rootViewController.tabBarViewController // rather than the RootViewController, because we need to allow the ConnectivityMessageView embedded in RootViewController to be visible despite e.g. the passwordEntryViewController being presented
	}
	//
	// Imperatives
	func makeKeyAndVisible()
	{
		window.makeKeyAndVisible()
	}
}
