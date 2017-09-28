//
//  MyMoneroScreenshotsUITests.swift
//  MyMoneroScreenshotsUITests
//
//  Created by Paul Shapiro on 9/27/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import XCTest

class MyMoneroScreenshotsUITests: XCTestCase
{
    override func setUp()
	{ // This method is called before the invocation of each test method in the class.
        super.setUp()
        //
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
		//
        // UI tests must launch the application that they test.
		let app = XCUIApplication()
		setupSnapshot(app)
		app.launch()
    }
    override func tearDown()
	{ // This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func test_01_onboarding()
	{ // will assume this was a fresh install
		
		let app = XCUIApplication()
		//
		// TODO: assume fresh install, add wallet, set password, wait for dismiss, navigate to wallet, screenshot it
		// …… how to get this w/o doing this long winded process?
		//
		let textField = app.secureTextFields["So we know it's you"]
		textField.tap()
		textField.typeText("qweqwe")
		//
		// TODO: hit 'enter'
		//
		snapshot("01_Onboarding")
	}
	
	func test_02_explore()
	{
		
		snapshot("02_Explore")
	}
}
