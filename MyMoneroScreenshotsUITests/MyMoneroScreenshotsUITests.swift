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
	{ // will assume test_01 did not actually create a wallet
		let app = XCUIApplication()
		do {
			let buttonElement = app.buttons["button.useExistingWallet"]
			buttonElement.tap()
		}
		do {
			let secretMnemonicTextArea = app.scrollViews.otherElements.textViews.containing(.staticText, identifier:"From your existing wallet").element
			secretMnemonicTextArea.tap()
			secretMnemonicTextArea.typeText("foxes selfish humid nexus juvenile dodge pepper ember biscuit elapse jazz vibrate biscuit")
			//
			let forYourReferenceTextField = app.textFields["For your reference"]
			forYourReferenceTextField.tap()
			forYourReferenceTextField.typeText("Spending Cash")
			//
			let purpleColorButton = app.otherElements["walletColorOption.purple"]
			purpleColorButton.tap()
			//
			self.tapNext(inApp: app, atBarTitle: "Log Into Your Wallet")
		}
		do {
			let secureTextField_1 = app.scrollViews.children(matching: .secureTextField).element(boundBy: 0)
			secureTextField_1.tap()
			secureTextField_1.typeText("qweqwe")
			//s
			let secureTextField_2 = app.scrollViews.children(matching: .secureTextField).element(boundBy: 1)
			secureTextField_2.tap()
			secureTextField_2.typeText("qweqwe")
			//
			self.tapNext(inApp: app, atBarTitle: "Create PIN or Password")
		}
		
		//
		// TODO: use expectation to wait for login success & first account info pull rather than the following (naive) sleep - so that failures can be detected w/o manual review of screenshots
		sleep(6) // semi-excessive wait for slow connections
		//
		app.cells.element(boundBy: 0).tap() // tap on wallet list cell
		//
		snapshot("02_Lightweight")
	}
	
	func test_03_contacts()
	{
		//
		// TODO: show contact details having resolved an oa addr, like donate.getmonero.org
		//
		snapshot("03_Contacts")
	}
	
	func test_04_openSource()
	{
		//
		// TODO: show About page? anything better like a feature/use-case?
		//
		
		snapshot("04_OpenSource")
	}
}
