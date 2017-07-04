//
//  ScrollableInfo.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UICommonComponents
{
	class ScrollableValidatingInfoViewController: UIViewController, UIScrollViewDelegate
	{
		//
		// Properties - Cached
		var messageView: UICommonComponents.InlineMessageView?
		//
		// Properties - Derived
		var scrollView: UIScrollView { return self.view as! UIScrollView }
		//
		// Imperatives - Init
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
			self.setup_views() // must be before _navigation b/c that may rely on _views
			self.setup_navigation()
			self.startObserving()
		}
		override func loadView()
		{
			self.view = UIScrollView()
			self.scrollView.delegate = self
		}
		func setup_views()
		{ // override but call on super
			if self.new_wantsInlineMessageViewForValidationMessages() {
				let view = UICommonComponents.InlineMessageView(
					mode: .withCloseButton,
					didHide:
					{ [unowned self] in
						self.view.setNeedsLayout()
					}
				)
				self.messageView = view
				self.view.addSubview(view)
			}
		}
		func setup_navigation()
		{ // override but call on super
			if self.overridable_wantsBackButton {
				self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
					type: .back,
					tapped_fn:
					{ [unowned self] in
						self.navigationController?.popViewController(animated: true)
					}
				)
			}
		}
		func startObserving()
		{ // override, but call on super
		}
		//
		// Lifecycle - Deinit
		deinit
		{
			self.tearDown()
		}
		func tearDown()
		{
			self.stopObserving()
		}
		func stopObserving()
		{
		}
		//
		// Runtime - Accessors - Form components configuration
		func new_wantsInlineMessageViewForValidationMessages() -> Bool
		{ // overridable
			return true
		}
		var overridable_wantsBackButton: Bool { return false }
		//
		// Accessors - Lookups/Derived - Layout metrics
		var inlineMessageValidationView_topMargin: CGFloat
		{
			return 13
		}
		var inlineMessageValidationView_bottomMargin: CGFloat
		{
			return 13
		}
		var yOffsetForViewsBelowValidationMessageView: CGFloat
		{
			assert(self.new_wantsInlineMessageViewForValidationMessages() == true)
			let topMargin = self.inlineMessageValidationView_topMargin
			if self.messageView!.isHidden {
				return topMargin
			}
			let bottomMargin = self.inlineMessageValidationView_bottomMargin
			let y = topMargin + self.messageView!.frame.size.height + bottomMargin
			//
			return ceil(y) // b/c having it be .5 doesn't mix well with consumers' usage of .integral
		}
		//
		// Runtime - Imperatives - Convenience/Overridable - Validation error
		func setValidationMessage(_ message: String)
		{
			if self.new_wantsInlineMessageViewForValidationMessages() == false {
				assert(false, "override \(#function)")
				return
			}
			let view = self.messageView! // this ! is not necessary according to the var's optionality but there seems to be a compiler bug
			view.set(text: message)
			self.layOut_messageView() // this can be slightly redundant, but it is called here so we lay out before showing. maybe rework this so it doesn't require laying out twice and checking visibility. maybe a flag saying "ought to be showing". maybe.
			view.show()
			self.view.setNeedsLayout() // so views (below messageView) get re-laid-out
		}
		func clearValidationMessage()
		{
			if self.new_wantsInlineMessageViewForValidationMessages() == false {
				assert(false, "override \(#function)")
				return
			}
			self.messageView!.clearAndHide() // as you can see, no ! required here. compiler bug?
			// we don't need to call setNeedsLayout() here b/c the messageView callback in self.setup will do so
		}
		//
		// Imperatives - Internal - Layout
		func layOut_messageView()
		{
			assert(self.new_wantsInlineMessageViewForValidationMessages() == true)
			let x = CGFloat.visual__form_input_margin_x // use visual__ instead so we don't get extra img padding
			let w = self.view.frame.size.width - 2 * x
			self.messageView!.layOut(atX: x, y: self.inlineMessageValidationView_topMargin, width: w)
		}
		//
		// Delegation - View
		override func viewDidLayoutSubviews()
		{
			super.viewDidLayoutSubviews()
			if self.new_wantsInlineMessageViewForValidationMessages() {
				if self.messageView!.shouldPerformLayOut { // i.e. is visible
					self.layOut_messageView()
				}
			}
		}
		//
		// Delegation - Internal/Convenience - Scroll view
		func scrollableContentSizeDidChange(withBottomView bottomView: UIView, bottomPadding: CGFloat)
		{
			self.scrollView.contentSize = CGSize(
				width: self.view.frame.size.width,
				height: bottomView.frame.origin.y + bottomView.frame.size.height + bottomPadding
			)
		}		//
		// Delegation - View
		var hasAppearedBefore = false
		override func viewDidAppear(_ animated: Bool)
		{
			super.viewDidAppear(animated)
			if self.hasAppearedBefore == false {
				self.hasAppearedBefore = true
			}
		}
	}
	
}
