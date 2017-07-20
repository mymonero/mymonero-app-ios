//
//  CopyButton.swift
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
	class CopyButton: UIButton
	{
		//
		// Constants
		static let usabilityPadding_h: CGFloat = 16
		static let w: CGFloat = visual_w + usabilityPadding_h*2 // this should probably be increased for usability
		static let h: CGFloat = 30 // for usability
		static let visual_w: CGFloat = 33
		//
		// Properties
		private var pasteboardItem_value_text: String?
		private var pasteboardItem_value_html: String?
		//
		// Lifecycle - Init
		init()
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
			let frame = CGRect(x: 0, y: 0, width: CopyButton.w, height: CopyButton.h)
			self.frame = frame
			//
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
			HUD.flash(.label(NSLocalizedString("Copied", comment: "")), delay: 0.3)
			//
			DDLog.Done(
				"UICommonComponents"/*maybe CopyButton instead*/,
				"Copied items to pasteboard: \(pasteboardItems)"
			)
		}
		//
		// Delegation
		func did_touchUpInside()
		{
			self.doCopy()
		}
	}
}
