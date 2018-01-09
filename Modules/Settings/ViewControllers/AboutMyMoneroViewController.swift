//
//  AboutMyMoneroViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/3/17.
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
import UIKit

class AboutMyMoneroViewController: UIViewController
{
	//
	// Properties
	let logo_imageView = UIImageView(image: UIImage(named: "logo_solid_light"))
	let versionLabel = UILabel()
	let viewSourceButton = UIButton()
	//
	// Lifecycle - Init
	init()
	{
		super.init(nibName: nil, bundle: nil)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.view.backgroundColor = .contentBackgroundColor
		self.automaticallyAdjustsScrollViewInsets = false // to fix apparent visual bug of vertical transit on nav push/pop
		//
		self.view.addSubview(self.logo_imageView)
		do {
			let view = self.versionLabel
			view.numberOfLines = 0
			view.textAlignment = .center
			view.font = UIFont.middlingBoldSansSerif
			view.textColor = UIColor(rgb: 0xFCFBFC)
			view.text = String(format:
				NSLocalizedString("Version %@", comment: ""),
				Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
			)
			self.view.addSubview(view)
		}
		do {
			let view = self.viewSourceButton
			view.setTitle(NSLocalizedString("View on GitHub", comment: ""), for: .normal)
			view.titleLabel!.textAlignment = .center
			view.titleLabel!.font = UIFont.smallRegularSansSerif
			view.setTitleColor(UIColor(rgb: 0x8D8B8D), for: .normal)
			view.setTitleColor(UIColor(rgb: 0xe0e0e0), for: .highlighted)
			view.addTarget(self, action: #selector(viewSourceButton_tapped), for: .touchUpInside)
			self.view.addSubview(view)
		}
		self.setup_navigation()
		do {
			let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedDown))
			recognizer.direction = .down
			self.view.addGestureRecognizer(recognizer)
		}
	}
	func setup_navigation()
	{
		self.navigationItem.title = NSLocalizedString("About MyMonero", comment: "")
		self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .cancel,
			tapped_fn:
			{ [unowned self] in
				self.navigationController!.dismiss(
					animated: true,
					completion: nil
				)
			},
			title_orNilForDefault: NSLocalizedString("Close", comment: "")
		)
	}
	//
	// Delegation - Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let image_h = self.logo_imageView.frame.size.height
		let versionLabel_h: CGFloat = 18
		let viewSourceButton_h: CGFloat = 18
		//
		let imageToVersion_h: CGFloat = 13
		let versionToSourceLinkButton_h: CGFloat = 0
		let contentBlock_h =
			image_h + imageToVersion_h
				+ versionLabel_h + versionToSourceLinkButton_h
				+ viewSourceButton_h
		let contentBlock_y = floor(
			(self.view.frame.size.height - contentBlock_h)/2
			- self.view.frame.size.height/7/*for visual effect only*/
		)
		do {
			self.logo_imageView.frame = CGRect(
				x: self.view.frame.size.width/2 - self.logo_imageView.frame.size.width/2,
				y: contentBlock_y,
				width: self.logo_imageView.frame.size.width,
				height: self.logo_imageView.frame.size.height // aka image_h
			).integral
		}
		do {
			self.versionLabel.frame = CGRect(
				x: 0, 
				y: self.logo_imageView.frame.origin.y + self.logo_imageView.frame.size.height + imageToVersion_h,
				width: self.view.frame.size.width,
				height: versionLabel_h
			).integral
		}
		do {
			self.viewSourceButton.frame = CGRect(
				x: 0,
				y: self.versionLabel.frame.origin.y + self.versionLabel.frame.size.height + versionToSourceLinkButton_h,
				width: self.view.frame.size.width,
				height: viewSourceButton_h
			).integral
		}
	}
	//
	// Delegation - Interactions
	@objc func viewSourceButton_tapped()
	{
		let url = URL(string: HostedSource.sourceRepository_urlString)!
		let options: [String: Any] = [:]
		UIApplication.shared.open(url, options: options, completionHandler: nil)
	}
	//
	// Delegation - Interactions
	@objc func swipedDown()
	{
		self.navigationController!.dismiss(animated: true, completion: nil)
	}

}
