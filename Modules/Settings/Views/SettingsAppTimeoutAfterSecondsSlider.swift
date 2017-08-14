//
//  SettingsAppTimeoutAfterSecondsSlider.swift
//  MyMonero
//
//  Created by John Woods on 07/05/2017.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
// Protocols
protocol SettingsAppTimeoutAfterSecondsSliderInteractionsDelegate: class
{
    func durationUpdated(_ durationInSeconds: TimeInterval)
}
//
// Views
class SettingsAppTimeoutAfterSecondsSliderInputView: UIView
{
	//
	// Types
	enum MinMaxLabelType
	{
		case min
		case max
	}
	//
	// Constants
	static let h: CGFloat = 100
	//
	static let textForValue__never = NSLocalizedString("Never", comment: "")
	//
	// Properties
	let slider = SettingsAppTimeoutAfterSecondsSlider()
	var minLabel: UILabel!
	var maxLabel: UILabel!
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
		self.addSubview(self.slider)
		do {
			let view = self._new_minMaxLabel(type: .min)
			self.minLabel = view
			self.addSubview(view)
		}
		do {
			let view = self._new_minMaxLabel(type: .max)
			self.maxLabel = view
			self.addSubview(view)
		}
	}
	//
	// Accessors - Factories
	func _new_minMaxLabel(type: MinMaxLabelType) -> UILabel
	{
		let view = UILabel()
		view.font = UIFont.smallRegularMonospace
		view.isUserInteractionEnabled = false // do not intercept touches destined for the form background tap recognizer
		view.textColor = UIColor(rgb: 0x8d8b8d)
		view.numberOfLines = 1
		switch type {
			case .max:
				view.text = SettingsAppTimeoutAfterSecondsSliderInputView.textForValue__never
				break
			case .min:
				view.text = String(format: "%ds", Int(SettingsAppTimeoutAfterSecondsSlider.duration__min))
				break
		}
		view.sizeToFit() // get initial width
		//
		return view
	}
	//
	// Imperatives - Overrides - Layout
	override func layoutSubviews()
	{
		super.layoutSubviews()
		self.layout_minMaxLabels()
		do {
			let sliderTrackSidePadding_x: CGFloat = 6
			let x = self.minLabel.frame.origin.x + self.minLabel.frame.size.width + sliderTrackSidePadding_x
			let rightEdge_x = self.maxLabel.frame.origin.x - sliderTrackSidePadding_x
			let frame = CGRect(
				x: x,
				y: 0,
				width: rightEdge_x - x,
				height: self.bounds.size.height
			)
			self.slider.frame = frame
		}
	}
	//
	// Imperatives - Internal - Layout
	fileprivate func layout_minMaxLabels()
	{
		do {
			let view = self.minLabel!
			let w = view.frame.size.width
			view.frame = CGRect(
				x: 0,
				y: 0,
				width: w,
				height: self.bounds.height
			)
		}
		do {
			let view = self.maxLabel!
			let w = view.frame.size.width
			view.frame = CGRect(
				x: self.bounds.size.width - w,
				y: 0,
				width: w,
				height: self.bounds.height
			)
		}
	}
	//
	// Imperatives - Interface - Interactivity
	func set(isEnabled: Bool)
	{
		self.slider.isEnabled = isEnabled
	}
}
class SettingsAppTimeoutAfterSecondsSlider: UISlider
{
	//
	// Types
	typealias SliderSecondsValue = TimeInterval
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
	static let duration__min: SliderSecondsValue = 5
	static let duration__max: SliderSecondsValue = 1500 // aka 'Never'
	static let duration__never = SettingsAppTimeoutAfterSecondsSlider.duration__max
	//
	// Properties
    let durationLabel = UICommonComponents.Form.FieldLabel(title: "") // for now
	//
	var steppingCategory: SteppingCategory = .subMinute // initial
	//
    var dateComponents = DateComponents()
    let formatter = DateComponentsFormatter()
    //
    // Properties - Settable by instantiator
    weak var interactionsDelegate: SettingsAppTimeoutAfterSecondsSliderInteractionsDelegate?
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
			self.minimumValue = Float(type(of: self).duration__min)
			self.maximumValue = Float(type(of: self).duration__max)
			do {
				let to_value = Float(SettingsController.shared.appTimeoutAfterS_nilForDefault_orNeverValue ?? SettingsController.shared.default_appTimeoutAfterS)
				assert(to_value >= self.minimumValue && to_value < self.maximumValue)
				self.value = to_value
			}
			self.tintColor = UIColor.orange
			//
			self.addTarget(self, action: #selector(self.valueChanged), for: .valueChanged)
		}
		do {
			let view = self.durationLabel
			let h = UICommonComponents.Form.FieldLabel.fixedHeight
			view.frame = CGRect(x: 0, y: 0, width: 0, height: h) // must set y and h for sizeToFit() and layoutSubviews()
			view.textAlignment = NSTextAlignment.center
			self.addSubview(view)
			self.configureValueLabel(animateTransitions: true)
		}
	}
	//
	// Accessors - Layout
	var knob_centerX: CGFloat {
		let trackRect = self.trackRect(forBounds: self.bounds) // is it ok to call this directly? documentation says not to but that may not be applicable to this usage?
		let thumbRect = self.thumbRect(forBounds: self.bounds, trackRect: trackRect, value: self.value)
		
		return thumbRect.origin.x + thumbRect.size.width/2
	}
	//
	// Accessors - Value
	var valueAsWholeNumberOfSeconds: TimeInterval {
		var wholeNumberOfSeconds: TimeInterval
		switch self.value {
		case 1500:
			wholeNumberOfSeconds = SettingsController.appTimeoutAfterS_neverValue
		default:
			wholeNumberOfSeconds = round(TimeInterval(self.value) / self.steppingCategory.secondsPerStep) * self.steppingCategory.secondsPerStep
		}
		//
		return wholeNumberOfSeconds
	}
	//
	// Imperatives - Configuration
	fileprivate func configureValueLabel(animateTransitions: Bool)
	{
        if self.value == Float(type(of: self).duration__max) {
            self.durationLabel.text = SettingsAppTimeoutAfterSecondsSliderInputView.textForValue__never
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
		self.layout_valueLabel()
	}
    //
	// Imperatives - Internal - Layout
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
			self.interactionsDelegate?.durationUpdated(self.valueAsWholeNumberOfSeconds)
		}
    }
}
