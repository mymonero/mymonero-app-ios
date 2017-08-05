//
//  AboutMyMoneroViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
			view.setTitle(NSLocalizedString("View on Github", comment: ""), for: .normal)
			view.titleLabel!.textAlignment = .center
			view.titleLabel!.font = UIFont.smallRegularSansSerif
			view.setTitleColor(UIColor(rgb: 0x8D8B8D), for: .normal)
			view.setTitleColor(UIColor(rgb: 0xe0e0e0), for: .highlighted)
			view.addTarget(self, action: #selector(viewSourceButton_tapped), for: .touchUpInside)
			self.view.addSubview(view)
		}
		self.setup_navigation()
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
			}
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
	func viewSourceButton_tapped()
	{
		let url = URL(string: HostedSource.sourceRepository_urlString)!
		let options: [String: Any] = [:]
		UIApplication.shared.open(url, options: options, completionHandler: nil)
	}
}
