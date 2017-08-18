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
    func durationUpdated(_ durationInSeconds_orNeverValue: TimeInterval)
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
	static let h: CGFloat = 60
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
			let y: CGFloat = 22
			let h = self.bounds.size.height - y
			let frame = CGRect(
				x: x,
				y: y,
				width: rightEdge_x - x,
				height: h
			)
			self.slider.frame = frame
		}
	}
	//
	// Imperatives - Internal - Layout
	fileprivate func layout_minMaxLabels()
	{
		let y: CGFloat = 20 // slightly higher than slider track for visual vertical centering
		let h = self.bounds.height - y
		do {
			let view = self.minLabel!
			let w = view.frame.size.width
			view.frame = CGRect(
				x: 0,
				y: y,
				width: w,
				height: h
			)
		}
		do {
			let view = self.maxLabel!
			let w = view.frame.size.width
			view.frame = CGRect(
				x: self.bounds.size.width - w,
				y: y,
				width: w,
				height: h
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
			//
			let trackImage = UIImage(named: "slider_track")!.stretchableImage(withLeftCapWidth: 1, topCapHeight: 1)
			self.setMaximumTrackImage(trackImage, for: .normal)
			self.setMaximumTrackImage(trackImage, for: .highlighted)
			self.setMinimumTrackImage(trackImage, for: .normal)
			self.setMinimumTrackImage(trackImage, for: .highlighted)
			let knobImage = UIImage(named: "slider_knob")!
			let knobImage_highlighted = UIImage(named: "slider_knob_highlighted")!
			self.setThumbImage(knobImage, for: .normal)
			self.setThumbImage(knobImage_highlighted, for: .highlighted) // TODO
			//
			self.addTarget(self, action: #selector(self.valueChanged), for: .valueChanged)
		}
		do {
			let view = self.durationLabel
			let h = UICommonComponents.Form.FieldLabel.fixedHeight
			view.frame = CGRect(x: 0, y: -8, width: 0, height: h) // must set y and h for sizeToFit() and layoutSubviews()
			view.textAlignment = NSTextAlignment.center
			self.addSubview(view)
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
	var valueAsWholeNumberOfSeconds_orNeverValue: TimeInterval {
		var value: TimeInterval
		switch self.value {
			case Float(SettingsAppTimeoutAfterSecondsSlider.duration__max):
				value = SettingsController.appTimeoutAfterS_neverValue
			default:
				value = round(TimeInterval(self.value) / self.steppingCategory.secondsPerStep) * self.steppingCategory.secondsPerStep
		}
		//
		return value
	}
	//
	// Imperatives - Configuration
	func setValueFromSettings()
	{
		do {
			var useValue: Float
			let settingsController_value = SettingsController.shared.appTimeoutAfterS_nilForDefault_orNeverValue
			if settingsController_value != nil {
				if settingsController_value == SettingsController.appTimeoutAfterS_neverValue {
					useValue = self.maximumValue
				} else {
					useValue = Float(settingsController_value!)
					assert(useValue >= self.minimumValue && useValue < self.maximumValue)
				}
			} else {
				useValue = Float(SettingsController.shared.default_appTimeoutAfterS)
			}
			self.value = Float(useValue)
		}
		self._configureWithUpdatedValue()
	}
	fileprivate func _configureWithUpdatedValue()
	{
		// State
		self.dateComponents.second = Int(self.value) // must update or we will get same value in value label
		// UI
		self.__configureValueLabel()
	}
	fileprivate func __configureValueLabel()
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
				case 1..<240: // is/was 120 in JS app but it's nice to have an area where sliding is more granular
					self.steppingCategory = .subMinute
				default:
					self.steppingCategory = .minutes
			}
			//
			// round value to step
			self.value = round(self.value / Float(self.steppingCategory.secondsPerStep)) * Float(self.steppingCategory.secondsPerStep)
		}
		//
		self._configureWithUpdatedValue()
		//
		// emit/yield
		self.interactionsDelegate?.durationUpdated(self.valueAsWholeNumberOfSeconds_orNeverValue)
    }
}