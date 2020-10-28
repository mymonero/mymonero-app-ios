//
//  ExchangeAmountInput.swift
//  MyMonero
//
//  Created by Karl Buys on 2020/10/27.
//  Copyright © 2020 MyMonero. All rights reserved.
//

import UIKit

protocol MyTextFieldDelegate: AnyObject {
	func textFieldDidDelete()
}

class MyTextField: UITextField {

	weak var myDelegate: MyTextFieldDelegate?
	
}
