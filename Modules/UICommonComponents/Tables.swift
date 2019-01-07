//
//  Tables.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/14/17.
//  Copyright (c) 2014-2019, MyMonero.com
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
