//
//  SmallUtilityValueButtons.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/26/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
import MobileCoreServices
import PKHUD

extension UICommonComponents
{
	class SmallUtilityValueButton: UIButton
	{
		//
		// Constants - Static/class
		static let usabilityPadding_h: CGFloat = 16
		class func w() -> CGFloat { return self.visual_w() + usabilityPadding_h*2 }
		static let h: CGFloat = 30 // for usability
		class func visual_w() -> CGFloat { return 33 }
		//
		// Properties
		//
		// Lifecycle - Init
		required init()
		{
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.setTitle(NSLocalizedString("COPY", comment: ""), for: .normal)
			self.titleLabel!.font = UIFont.smallBoldSansSerif
			self.setTitleColor(.utilityOrConstructiveLinkColor, for: .normal)
			self.setTitleColor(.disabledAndSemiVisibleLinkColor, for: .disabled)
			self.addTarget(self, action: #selector(did_touchUpInside), for: .touchUpInside)
			//
			let frame = CGRect(x: 0, y: 0, width: type(of: self).w(), height: type(of: self).h)
			self.frame = frame
		}
		//
		// Delegation
		func did_touchUpInside()
		{
		}
	}
	class SmallUtilityCopyValueButton: SmallUtilityValueButton
	{
		//
		// Constants - Overrides
		override class func visual_w() -> CGFloat { return 33 }
		//
		// Properties
		private var pasteboardItem_value_text: String?
		private var pasteboardItem_value_html: String?
		//
		// Lifecycle - Init - Overrides
		override func setup()
		{
			super.setup()
			//
			self.setTitle(NSLocalizedString("COPY", comment: ""), for: .normal)
			self._updateInteractivityByValues() // initial
		}
		//
		// Imperatives
		func set(text: String?)
		{
			self.pasteboardItem_value_text = text
			self._updateInteractivityByValues()
		}
		func set(html: String?)
		{
			self.pasteboardItem_value_html = html
			self._updateInteractivityByValues()
		}
		func _updateInteractivityByValues()
		{
			let aValueExists = (self.pasteboardItem_value_html != nil && self.pasteboardItem_value_html != "") || (self.pasteboardItem_value_text != nil && self.pasteboardItem_value_text != "")
			self.isEnabled = aValueExists
		}
		private func doCopy()
		{
			guard self.pasteboardItem_value_text != nil || self.pasteboardItem_value_text != nil else {
				assert(false)
				return
			}
			var pasteboardItems: [[String: Any]] = []
			if let value = self.pasteboardItem_value_text {
				pasteboardItems.append([ (kUTTypeText as String): value ])
			}
			if let value = self.pasteboardItem_value_html {
				pasteboardItems.append([ (kUTTypeHTML as String): value ])
			}
			assert(pasteboardItems.count != 0) // not that it would be, with the above assert
			UIPasteboard.general.setItems(pasteboardItems, options: [:])
			//
			HUD.flash(.label(NSLocalizedString("Copied", comment: "")), delay: 0.05) // would like to be able to modify fade-out duration of HUD
		}
		//
		// Delegation - Overrides
		override func did_touchUpInside()
		{
			self.doCopy()
		}
	}
	class SmallUtilityShareValueButton: SmallUtilityValueButton
	{
		//
		// Constants - Overrides
		override class func visual_w() -> CGFloat { return 33 }
		//
		// Properties
		private var value_text: String?
		private var value_url: URL?
		private var value_image: UIImage?
		//
		// Lifecycle - Init - Overrides
		override func setup()
		{
			super.setup()
			//
			self.setTitle(NSLocalizedString("SHARE", comment: ""), for: .normal)
			self._updateInteractivityByValues() // initial
		}
		//
		// Imperatives
		func setButtonValue(text: String?)
		{
			self.value_text = text
			self._updateInteractivityByValues()
		}
		func setButtonValue(url: URL?)
		{
			self.value_url = url
			self._updateInteractivityByValues()
		}
		func setButtonValue(image: UIImage?)
		{
			self.value_image = image
			self._updateInteractivityByValues()
		}
		func _updateInteractivityByValues()
		{
			let aValueExists = self.value_url != nil || (self.value_text != nil && self.value_text != "") || self.value_image != nil
			self.isEnabled = aValueExists
		}
		private func openShareActionSheet()
		{
			var items: [Any] = []
			if let value = self.value_text {
				items.append(value)
			}
			if let value = self.value_url {
				items.append(value)
			}
			if let value = self.value_image {
				items.append(value)
			}
			let controller = UIActivityViewController(
				activityItems: items,
				applicationActivities: nil
			)
			controller.modalPresentationStyle = .popover // to prevent iPad crash
			let presentInViewController = UIApplication.shared.delegate!.window!!.rootViewController! // TODO: is this ok? preferable to yield items and controller to present / ask for or be initialized with presentInViewController?
			if let popoverPresentationController = controller.popoverPresentationController { // iPad support
				popoverPresentationController.sourceView = self
				var sourceRect: CGRect = .zero
				sourceRect.origin.y += frame.size.height/2 // vertical middle instead of top edge
				popoverPresentationController.sourceRect = sourceRect
			}
			presentInViewController.present(controller, animated: true, completion: nil)
		}
		//
		// Delegation - Overrides
		override func did_touchUpInside()
		{
			self.openShareActionSheet()
		}
	}
}
