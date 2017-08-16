//
//  FundsRequestQRDisplayViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/16/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class FundsRequestQRDisplayViewController: UICommonComponents.ScrollableValidatingInfoViewController
{
	//
	// Constants
	
	//
	// Properties
	var fundsRequest: FundsRequest
	//
	var informationalLabel: UICommonComponents.FormAccessoryMessageLabel!
	var imageView: UIImageView!
	//
	// Lifecycle - Init
	init(fundsRequest: FundsRequest)
	{
		self.fundsRequest = fundsRequest
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func setup()
	{
		super.setup()
		self.view.backgroundColor = .contentBackgroundColor
		do {
			let hasAmount = self.fundsRequest.amount != nil
			let to_address = self.fundsRequest.to_address!
			var text: String
			if hasAmount {
				text = String(
					format: NSLocalizedString("Scan this code to send %@ XMR to %@….", comment: ""),
					self.fundsRequest.amount!,
					to_address
				)
			} else {
				text = String(
					format: NSLocalizedString("Scan this code to send Monero to %@….", comment: ""),
					to_address
				)
			}
			let view = UICommonComponents.FormAccessoryMessageLabel(
				text: text
			)
			view.textAlignment = .justified
			view.numberOfLines = 0
			view.lineBreakMode = .byTruncatingTail
			self.informationalLabel = view
			self.scrollView.addSubview(view)
		}
		do {
			let image = self.fundsRequest.new_qrCodeImage(withQRSize: .large) // generating a new image here - is this performant enough?
			let view = UIImageView(image: image)
			view.image = image
			self.imageView = view
			self.scrollView.addSubview(self.imageView)
		}
		do {
			self.navigationItem.title = NSLocalizedString("Scan Code to Pay", comment: "")
			self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .cancel,
				tapped_fn:
				{ [unowned self] in
					self.navigationController!.dismiss(
						animated: true,
						completion: nil
					)
				},
				title_orNilForDefault: NSLocalizedString("Done", comment: "")
			)
		}
		do {
			let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedDown))
			recognizer.direction = .down
			self.scrollView.addGestureRecognizer(recognizer)
		}
		do {
			let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
			self.scrollView.addGestureRecognizer(recognizer)
		}
	}
	//
	// Lifecycle - Teardown
	
	//
	// Accessors - Overrides
	override func new_wantsInlineMessageViewForValidationMessages() -> Bool
	{
		return false
	}
	//
	// Imperatives - Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		let top_yOffset: CGFloat = 48
		do { // label
			let x: CGFloat = 8
			let w = self.view.frame.size.width - 2*x
			self.informationalLabel.frame = CGRect(
				x: x,
				y: top_yOffset,
				width: w,
				height: 18
			).integral
		}
		self.imageView.frame = CGRect(
			x: (self.view.frame.size.width - FundsRequest.QRSize.large.width)/2,
			y: self.informationalLabel.frame.origin.y + self.informationalLabel.frame.size.height + 32,
			width: FundsRequest.QRSize.large.width,
			height: FundsRequest.QRSize.large.height
		).integral
		//
		self.scrollableContentSizeDidChange(withBottomView: self.imageView, bottomPadding: 24)
	}
	//
	// Delegation - Interactions
	func swipedDown()
	{
		self.navigationController!.dismiss(animated: true, completion: nil)
	}
	func tapped()
	{
		self.navigationController!.dismiss(animated: true, completion: nil)
	}
}
