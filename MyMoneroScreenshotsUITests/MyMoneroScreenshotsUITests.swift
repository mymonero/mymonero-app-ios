//
//  MyMoneroScreenshotsUITests.swift
//  MyMoneroScreenshotsUITests
//
//  Created by Paul Shapiro on 9/27/17.
//  Copyright © 2018 MyMonero. All rights reserved.
//

import XCTest

class MyMoneroScreenshotsUITests: XCTestCase
{
	//
	// Tests - Init
	override func setUp()
	{ // This method is called before the invocation of each test method in the class.
		super.setUp()
		//
		// In UI tests it is usually best to stop immediately when a failure occurs.
		continueAfterFailure = false
		//
		// UI tests must launch the application that they test.
		let app = XCUIApplication()
		app.launchEnvironment =
		[
			AppProcess.EnvironmentKeys.isBeingRunByUIAutomation.key: AppProcess.EnvironmentKeyValues.isBeingRunByUIAutomation_enabled.value // so we can turn off things like autocorrect which mess up our entered values when we do typeText, leading to failed attempt to inject text by way of programmatic copy-paste
		]
		setupSnapshot(app)
		app.launch()
	}
	override func tearDown()
	{ // This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	//
	// Tests - Shared - Imperatives
	func tapNext(inApp app: XCUIApplication, atBarTitle barTitle: String)
	{
		app.navigationBars[barTitle].buttons["Next"].tap()
	}
	//
	// Tests - Cases
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
			buttons.element(boundBy: 3).tap()
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
			let mnemonicString = MyMoneroScreenshots_Constants.addExistingWallet_mnemonicString
			assert(mnemonicString != "")
			secretMnemonicTextArea.tap()
			secretMnemonicTextArea.typeText(mnemonicString)
			//
			let forYourReferenceTextField = app.textFields["For your reference"]
			forYourReferenceTextField.tap()
			forYourReferenceTextField.typeText("Spending Cash")
			//
			let colorButton = app.buttons["walletColorOption.orange"]
			colorButton.tap()
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
			self.tapNext(inApp: app, atBarTitle: "Create PIN/Password")
		}
		app.cells.element(boundBy: 0).tap() // tap on wallet list cell
		sleep(1) // just wait a moment in case acct info hasn't finished loading
		//
		snapshot("02_Lightweight")
	}
	func test_03_contacts()
	{
		let app = XCUIApplication()
		app.secureTextFields["So we know it's you"].typeText("qweqwe")
		app.navigationBars["Enter Password"].buttons["Next"].tap()
		//
		app.tabBars.children(matching: .button).element(boundBy: 3).tap()
		app.navigationBars["Contacts"].buttons["addButtonIcon 10"].tap()
		do {
			let field = app.textFields["Enter name"]
			field.tap()
			field.typeText("The Monero Project")
		}
		do {
			let enterAddressEmailOrDomainTextView = app.scrollViews.otherElements.textViews.containing(.staticText, identifier:"Enter address, email, or domain").element
			enterAddressEmailOrDomainTextView.tap()
			enterAddressEmailOrDomainTextView.tap()
			enterAddressEmailOrDomainTextView.tap()
			app.scrollViews.children(matching: .other).element(boundBy: 0).children(matching: .textView).element.typeText("donate@getmonero.org")
		}
		app.navigationBars["New Contact"].buttons["Save"].tap()
		//
		sleep(2)
		//
		app.cells.element(boundBy: 0).tap() // tap on contacts list cell
		//
		snapshot("03_Contacts")
	}
	
	func test_04_send()
	{
		let app = XCUIApplication()
		app.secureTextFields["So we know it's you"].typeText("qweqwe")
		app.navigationBars["Enter Password"].buttons["Next"].tap()
		//
		app.tabBars.children(matching: .button).element(boundBy: 1).tap() // tap on Send
		do {
			let field = app.scrollViews.otherElements.textFields["00.00"]
			field.tap()
			field.typeText("1")
		}
		let elementsQuery = app.scrollViews.otherElements
		elementsQuery.textFields["Contact name or address/domain"].tap()
		sleep(1) // wait for results / keyboard to show
		app.collectionViews.cells["button.The Monero Project"].tap()
		sleep(3) // wait for possible DNS resolution again
		//
		snapshot("04_Send")
	}
	
	func test_05_openSource()
	{
		let app = XCUIApplication()
		app.secureTextFields["So we know it's you"].typeText("qweqwe")
		app.navigationBars["Enter Password"].buttons["Next"].tap()
		//
		app.tabBars.children(matching: .button).element(boundBy: 4).tap()
		app.navigationBars["Preferences"].buttons["About"].tap()
		//
		snapshot("05_OpenSource")
	}
}
