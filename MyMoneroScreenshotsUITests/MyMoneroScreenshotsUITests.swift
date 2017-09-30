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
	func tapNext(inApp app: XCUIApplication, atBarTitle barTitle: String)
	{
		app.navigationBars[barTitle].buttons["Next"].tap()
	}
	func test_01_bank()
	{ // will assume this was a fresh install / clean simulator
		let app = XCUIApplication()
		do {
			let buttonElement = app.buttons["button.createNewWallet"]
			buttonElement.tap()
		}
		do { // details
			let forYourReferenceTextField = app.textFields["For your reference"]
			forYourReferenceTextField.tap() // just in case… but we're expecting to ebcome first responder
			forYourReferenceTextField.typeText("a")
			//
			self.tapNext(inApp: app, atBarTitle: "New Wallet")
		}
		do { // instructions
			app.buttons["GOT IT!"].tap()
			//
			self.tapNext(inApp: app, atBarTitle: "New Wallet")
		}
		do { // inform of mnemonic
			self.tapNext(inApp: app, atBarTitle: "New Wallet")
		}
		do { // now begin to verify mnemonic
			let buttonsContainerQuery = app.scrollViews.otherElements["buttonContainer.confirmMnemonic"]
			let buttons = buttonsContainerQuery.buttons
			buttons.element(boundBy: 1).tap()
			buttons.element(boundBy: 6).tap()
		}
		//
		snapshot("01_Bank")
	}
	
	func test_02_lightweight()
	{
		
		snapshot("02_Lightweight")
	}
	
	func test_03_contact()
	{
		
		snapshot("03_Contacts")
	}
	
	func test_04_openSource()
	{
		
		snapshot("04_OpenSource")
	}
}
