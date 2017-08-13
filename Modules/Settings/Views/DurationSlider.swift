//
//  DurationSlider.swift
//  MyMonero
//
//  Created by John Woods on 07/05/2017.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
// Protocols
protocol DurationSliderDelegate: class
{
    func durationUpdated(_ durationInSeconds:Int)
}
//
// Principal class
class DurationSlider: UISlider
{
	//
	// Types
	typealias SliderSecondsValue = Int
	enum SteppingCategory: SliderSecondsValue
	{
		case subMinute = 5
		case minutes = 60
		//
		var secondsPerStep: SliderSecondsValue {
			return self.rawValue
		}
	}
	//
	// Constants
	static let duration__min: SliderSecondsValue = 5 // I would make the TimeIntervals but they're exclusively treated as whole numbers
	static let duration__max: SliderSecondsValue = 1500 // aka 'Never'
	static let duration__never = DurationSlider.duration__max
	//
	static let minLabelText = String(format: "%ds", DurationSlider.duration__min)
	static let maxLabelText = NSLocalizedString("Never", comment: "")
	//
	// Properties
    let durationLabel = UILabel()
    let minLabel = UILabel()
    let maxLabel = UILabel()
	//
	var steppingCategory: SteppingCategory = .subMinute // initial
	//
    var dateComponents = DateComponents()
    let formatter = DateComponentsFormatter()
    //
    // Properties - Settable by instantiator
    weak var delegate:DurationSliderDelegate?
	//
	// Lifecycle - Init
    init()
	{
        super.init(frame: .zero)
		do {
			let formatter = self.formatter
			formatter.unitsStyle = .abbreviated
			formatter.allowedUnits = [.second, .minute]
		}
		self.setup_views()
    }
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func setup_views()
	{
		do {
			self.minimumValue = 5
			self.maximumValue = 1500
			self.value = 5
			self.tintColor = UIColor.orange
			//
			self.addTarget(self, action: #selector(self.valueChanged), for: .valueChanged)
		}
		do {
			let view = self.durationLabel
			view.frame = CGRect(x: 0, y: -25, width: 0, height: 25) // must set y and h for sizeToFit() and layoutSubviews()
			view.textAlignment = NSTextAlignment.center
			self.addSubview(view)
			self.configureValueLabel(animateTransitions: true)
		}
		do {
            let view = self.minLabel
			view.text = type(of: self).minLabelText
            view.font = UIFont.systemFont(ofSize: 10)
            self.addSubview(view)
		}
		do {
            let view = self.maxLabel
			view.text = type(of: self).maxLabelText
            view.font = UIFont.systemFont(ofSize: 10)
            self.addSubview(view)
		}
	}
	//
	// Accessors - Layout
	var knob_centerX: CGFloat {
		let trackRect = self.trackRect(forBounds: self.bounds)
		let thumbRect = self.thumbRect(forBounds: self.bounds, trackRect: trackRect, value: self.value)
		
		return thumbRect.origin.x + thumbRect.size.width/2
	}
	//
	// Imperatives - Configuration
	fileprivate func configureValueLabel(animateTransitions: Bool)
	{
        if (self.value == 1500) {
            self.durationLabel.text = NSLocalizedString("Never", comment: "")
		} else {
			self.durationLabel.text = self.formatter.string(from: self.dateComponents)
		}
        self.layout_valueLabel()
    }
	//
	// Imperatives - Overrides
    override func layoutSubviews()
	{
		super.layoutSubviews()
		//
		self.layout_valueLabel()
        self.layout_minMaxLabels()
	}
    //
	// Imperatives - Internal - Layout
    fileprivate func layout_minMaxLabels()
	{
        self.minLabel.frame = CGRect(x: -20, y: 0, width: 50, height: self.bounds.height)
        self.maxLabel.frame = CGRect(x: self.bounds.size.width+10, y: 0, width: 50, height: self.bounds.height)
    }
	fileprivate func layout_valueLabel()
	{
		self.durationLabel.sizeToFit() // in order to get w/h
        self.durationLabel.frame = CGRect(
			x: self.knob_centerX - self.durationLabel.frame.width/2,
			y: self.durationLabel.frame.origin.y,
			width: self.durationLabel.frame.size.width,
			height: self.durationLabel.frame.size.height
		).integral
    }
    //
	// Delegation - Interactions
    func valueChanged()
	{
		do { // update local state
			switch (self.value) { // determine stepping category
				case 1..<120:
					self.steppingCategory = .subMinute
				default:
					self.steppingCategory = .minutes
			}
			//
			// round value to step
			self.value = round(self.value / Float(self.steppingCategory.secondsPerStep)) * Float(self.steppingCategory.secondsPerStep)
			//
			// update formatter for UI config
			self.dateComponents.second = Int(self.value)
		}
		do { // update UI given new state
			self.configureValueLabel(
				animateTransitions: true // b/c from user interaction
			)
		}
		do { // emit/yield
			var wholeNumberOfSeconds: Int
			switch self.value {
				case 1500:
					wholeNumberOfSeconds = -1
				default:
					wholeNumberOfSeconds = (Int)(round(self.value / Float(self.steppingCategory.secondsPerStep)) * Float(self.steppingCategory.secondsPerStep))
			}
			self.delegate?.durationUpdated(wholeNumberOfSeconds)
		}
    }
}
