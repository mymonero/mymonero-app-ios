//
//  Details.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit


extension UICommonComponents
{
	class DetailsViewController: ScrollableValidatingInfoViewController
	{
		//
		// Lifecycle - Init
		override func setup_views()
		{
			super.setup_views()
			do {
				self.view.backgroundColor = UIColor.contentBackgroundColor
				self.scrollView.indicatorStyle = .white
			}
		}
	}
}
