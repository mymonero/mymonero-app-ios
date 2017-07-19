//
//  Tables.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/14/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

extension UICommonComponents
{
	//
	enum CellPosition
	{
		case top
		case middle
		case bottom
		case standalone
	}
	static func newCellPosition(withCellIndex cellIndex: Int, cellsCount: Int) -> CellPosition
	{ // would place this as new(::) within CellPosition but there might be a compiler bug; complains about extra arg
		assert(cellsCount > 0)
		if cellsCount == 1  {
			return .standalone
		} else if cellIndex == 0 {
			return .top
		} else if cellIndex == cellsCount - 1 {
			return .bottom
		} else {
			return .middle
		}
	}
	enum CellState
	{
		case normal
		case highlighted
		case disabled
	}
	
	struct Tables
	{
		class ReusableTableViewCell: UITableViewCell
		{
			//
			// Constants
			struct Configuration
			{
				let cellPosition: UICommonComponents.CellPosition
				let indexPath: IndexPath
				let dataObject: Any?
			}
			//
			// Override these:
			class func reuseIdentifier() -> String {
				assert(false, "Override this")
				return "UICommonComponents.Details._override this_"
			}
			class func cellHeight(withPosition cellPosition: UICommonComponents.CellPosition) -> CGFloat {
				assert(false, "Override this")
				return 0
			}
			//
			// Lifecycle - Init
			required init()
			{
				let selfType = type(of: self)
				let reuseIdentifier = selfType.reuseIdentifier()
				super.init(style: .default, reuseIdentifier: reuseIdentifier)
				self.setup()
			}
			required init?(coder aDecoder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			//
			func setup()
			{
				// override and implement - call on super
			}
			//
			// Lifecycle - Teardown
			deinit
			{
				self.teardown()
			}
			func teardown()
			{
				self.teardown_configuration()
			}
			func teardown_configuration()
			{
				self.stopObserving_configurationContents()
				self.configuration = nil
			}
			func stopObserving_configurationContents()
			{
				// override this if you need it but call on super
			}
			//
			override func prepareForReuse()
			{
				super.prepareForReuse()
				self.teardown_configuration()
			}
			//
			// Imperatives - Configuration
			var configuration: Configuration?
			func configure(with configuration: Configuration)
			{
				if self.configuration != nil {
					self.teardown_configuration()
				}
				self.configuration = configuration
				self._configureUI()
			}
			func _configureUI()
			{
				assert(false, "Override and implement")
			}
			func startObserving_configurationContents()
			{
				// override this if you need it but call on super
			}
		}
	}
}
