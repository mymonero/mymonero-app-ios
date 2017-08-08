//
//  CreateWallet_ConfirmMnemonic_ViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/18/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
import PKHUD
//
struct CreateWallet_ConfirmMnemonic {}
//
class CreateWallet_ConfirmMnemonic_ViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Properties
	let headerLabel = UICommonComponents.ReadableInfoHeaderLabel()
	let descriptionLabel = UICommonComponents.ReadableInfoDescriptionLabel()
	var selectedWordsView: CreateWallet_ConfirmMnemonic.SelectedWordsView!
	var selectableWordsView: CreateWallet_ConfirmMnemonic.SelectableWordsView!
	let incorrectMnemonicMessageLabel = UILabel()
	var tryAgain_actionButtonView: UICommonComponents.ActionButton!
	var startOver_actionButtonView: UICommonComponents.ActionButton!
	//
	var hasUserJustSubmittedIncorrectMnemonic = false
	//
	// Lifecycle - Init
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.title = NSLocalizedString("New Wallet", comment: "")
	}
	override var overridable_wantsBackButton: Bool { return true }
	override func setup_views()
	{
		super.setup_views()
		do {
			let view = self.headerLabel
			view.text = NSLocalizedString("Verify your mnemonic", comment: "")
			view.textAlignment = .center
			self.scrollView.addSubview(view)
		}
		do {
			let view = self.descriptionLabel
			view.set(text: NSLocalizedString("Choose each word in the correct order.", comment: ""))
			view.textAlignment = .center
			self.scrollView.addSubview(view)
		}
		let mnemonicWords = self.wizardWalletMnemonicString.components(separatedBy: " ").map(
			{ (word) -> CreateWallet_ConfirmMnemonic.MnemonicWordHandle in
				return CreateWallet_ConfirmMnemonic.MnemonicWordHandle(
					uuid: UUID().uuidString,
					word: word as CreateWallet_ConfirmMnemonic.MnemonicWord
				)
			}
		)
		do {
			let view = CreateWallet_ConfirmMnemonic.SelectedWordsView(
				mnemonicWords: mnemonicWords,
				didSelectWord_fn:
				{ [unowned self] (wordHandle) in
					self.set_isFormSubmittable_needsUpdate()
					self.view.setNeedsLayout() // b/c the selectedWordsView may change its height
				},
				didDeselectWord_fn:
				{ [unowned self] (wordHandle) in
					self.set_isFormSubmittable_needsUpdate()
					self.view.setNeedsLayout() // b/c the selectedWordsView may change its height
				}
			)
			self.selectedWordsView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = CreateWallet_ConfirmMnemonic.SelectableWordsView(
				mnemonicWords: mnemonicWords,
				selectedWordsView: self.selectedWordsView
			)
			self.selectableWordsView = view
			self.scrollView.addSubview(view)
		}
		self.selectedWordsView.postInit_set(selectableWordsView: self.selectableWordsView)
		do {
			let view = self.incorrectMnemonicMessageLabel
			view.isHidden = true
			view.numberOfLines = 0
			view.font = UIFont.smallRegularMonospace
			view.textColor = UIColor(rgb: 0xF97777)
			view.text = NSLocalizedString("That’s not right. You can try again or start over with a new mnemonic.", comment: "")
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: true, iconImage: UIImage(named: "actionButton_iconImage__tryAgain")!)
			view.addTarget(self, action: #selector(tryAgain_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Try again", comment: ""), for: .normal)
			view.isHidden = true
			self.tryAgain_actionButtonView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.ActionButton(pushButtonType: .utility, isLeftOfTwoButtons: false, iconImage: UIImage(named: "actionButton_iconImage__startOver")!)
			view.addTarget(self, action: #selector(startOver_tapped), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Start over", comment: ""), for: .normal)
			view.isHidden = true
			self.startOver_actionButtonView = view
			self.scrollView.addSubview(view)
		}
	}
	//
	// Accessors - Derived
	var margin_h: CGFloat { return 16 }
	var content_x: CGFloat { return self.margin_h }
	var content_w: CGFloat { return (self.scrollView.frame.size.width - 2*content_x) }
	var topPadding: CGFloat { return 36 }
	override var yOffsetForViewsBelowValidationMessageView: CGFloat
	{ // overridden to get topPadding and max() behavior
		if self.messageView!.isHidden {
			return self.topPadding
		}
		return max(
			self.topPadding,
			(self.inlineMessageValidationView_topMargin + self.messageView!.frame.size.height + self.inlineMessageValidationView_bottomMargin)
		)
	}
	//
	var wizardWalletMnemonicString: MoneroSeedAsMnemonic {
		let walletInstance = self.wizardController.walletCreation_walletInstance!
		//
		return walletInstance.generatedOnInit_walletDescription!.mnemonic
	}
	//
	// Accessors - Overrides
	override func new_titleForNavigationBarButtonItem__next() -> String
	{
		return NSLocalizedString("Confirm", comment: "")
	}
	override func new_isFormSubmittable() -> Bool
	{
		if self.hasUserJustSubmittedIncorrectMnemonic {
			return false
		}
		if self.selectedWordsView.hasUserSelectedAllWords == false {
			return false
		}
		return true
	}
	//
	// Imperatives - Overrides - Submission
	override func disableForm()
	{
		super.disableForm()
		//
		self.scrollView.isScrollEnabled = false
		//
		self.selectedWordsView.isEnabled = false
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		self.selectedWordsView.isEnabled = true
	}
	var isSubmitting = false
	override func _tryToSubmitForm()
	{
		if self.isSubmitting == true {
			return
		}
		if self.selectedWordsView.hasUserSelectedTheCorrectMnemonicWordOrdering == false {
			self.set(hasUserJustSubmittedIncorrectMnemonic: true)
			return
		}
		do {
			UserIdle.shared.temporarilyDisable_userIdle()
			ScreenSleep.temporarilyDisable_screenSleep()
			//
			self.set(isFormSubmitting: true) // will update 'Confirm' btn
			self.disableForm()
			self.clearValidationMessage()
			HUD.show(
				.label(
					NSLocalizedString("Loading…", comment: "")
				),
				onView: self.navigationController!.view/*or self.view*/
			)
			self.navigationItem.leftBarButtonItem!.isEnabled = false
		}
		func ____reEnable_userIdleAndScreenSleepFromSubmissionDisable()
		{ // factored because we would like to call this on successful submission too!
			UserIdle.shared.reEnable_userIdle()
			ScreenSleep.reEnable_screenSleep()
		}
		func ___reEnableFormFromSubmissionDisable()
		{
			____reEnable_userIdleAndScreenSleepFromSubmissionDisable()
			//
			self.navigationItem.leftBarButtonItem!.isEnabled = true
			HUD.hide(animated: true)
			self.set(isFormSubmitting: false) // will update 'Next' btn
			self.reEnableForm()
		}
		func __trampolineFor_failedWithErrStr(_ err_str: String)
		{
			self.scrollView.setContentOffset(.zero, animated: true) // because we want to show the validation err msg
			self.setValidationMessage(err_str)
			___reEnableFormFromSubmissionDisable()
		}
		func __trampolineFor_didAddWallet()
		{
			____reEnable_userIdleAndScreenSleepFromSubmissionDisable() // we must call this manually as we are not re-enabling the form (or it will break user idle!!)
			self.wizardController.proceedToNextStep() // will dismiss
		}
		//
		let walletLabel = self.wizardController.walletCreation_metaInfo_walletLabel!
		let color = self.wizardController.walletCreation_metaInfo_color!
		let walletInstance = self.wizardController.walletCreation_walletInstance!
		WalletsListController.shared.OnceBooted_ObtainPW_AddNewlyGeneratedWallet(
			walletInstance: walletInstance,
			walletLabel: walletLabel,
			swatchColor: color,
			{ [unowned self] (err_str, saved_walletInstance) in
				if err_str != nil {
					__trampolineFor_failedWithErrStr(err_str!)
					return
				}
				____reEnable_userIdleAndScreenSleepFromSubmissionDisable() // must call this manually, since we're not re-enabling the form
				self.wizardController.proceedToNextStep() // should lead to dismissal of the wizard
			},
			userCanceledPasswordEntry_fn:
			{
				___reEnableFormFromSubmissionDisable()
			}
		)
	}
	//
	// Imperatives - Form submission states
	func set(hasUserJustSubmittedIncorrectMnemonic: Bool)
	{
		self.hasUserJustSubmittedIncorrectMnemonic = hasUserJustSubmittedIncorrectMnemonic
		self.configureWith_submittedIncorrectMnemonic_state()
		//
		UIView.animate(withDuration: 0.3)
		{ [unowned self] in
			self.scrollView.contentOffset = .zero
		}
	}
	func configureWith_submittedIncorrectMnemonic_state()
	{
		if self.hasUserJustSubmittedIncorrectMnemonic {
			self.clearValidationMessage() // in case it is being displayed
			do {
				self.selectedWordsView.layer.borderColor = UIColor(rgb: 0xF97777).cgColor
				self.selectedWordsView.layer.borderWidth = 1
			}
		} else {
			self.selectedWordsView.layer.borderWidth = 0
		}
		self.incorrectMnemonicMessageLabel.isHidden = self.hasUserJustSubmittedIncorrectMnemonic == false
		self.selectedWordsView.isEnabled = self.hasUserJustSubmittedIncorrectMnemonic == false
		self.selectableWordsView.isHidden = self.hasUserJustSubmittedIncorrectMnemonic == true
		do {
			self.tryAgain_actionButtonView.isHidden = self.hasUserJustSubmittedIncorrectMnemonic == false
			self.startOver_actionButtonView.isHidden = self.hasUserJustSubmittedIncorrectMnemonic == false
		}
		self.set_isFormSubmittable_needsUpdate()
		self.view.setNeedsLayout()
	}
	//
	// Delegation - Overrides - Layout
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let content_x = self.margin_h
		let content_w = self.content_w
		//
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		let headers_x: CGFloat = 4 // would normally use content_x, but that's too large to fit content on small screens
		let headers_w = self.scrollView.frame.size.width - 2*headers_x
		self.headerLabel.frame = CGRect(x: 0, y: 0, width: headers_w, height: 0)
		self.descriptionLabel.frame = CGRect(x: 0, y: 0, width: headers_w, height: 0)
		self.headerLabel.sizeToFit() // to get height
		self.descriptionLabel.sizeToFit() // to get height
		self.headerLabel.frame = CGRect(
			x: headers_x,
			y: top_yOffset,
			width: headers_w,
			height: self.headerLabel.frame.size.height
		).integral
		self.descriptionLabel.frame = CGRect(
			x: headers_x,
			y: self.headerLabel.frame.origin.y + self.headerLabel.frame.size.height + 4,
			width: headers_w,
			height: self.descriptionLabel.frame.size.height
		).integral
		//
		self.selectedWordsView.layOut(
			atX: content_x,
			y: self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 44,
			width: content_w
		)
		if self.selectableWordsView.isHidden == false {
			let special__content_x: CGFloat = 8 // this is instead of 16 and different from the design but it gives more room on small screens
			let special__content_w = self.scrollView.frame.size.width - 2*special__content_x
			let topMargin: CGFloat = 24 // design says 40 but this better accommodates small screens
			self.selectableWordsView.layOut(
				atX: special__content_x,
				y: self.selectedWordsView.frame.origin.y + self.selectedWordsView.frame.size.height + topMargin - UICommonComponents.PushButtonCells.imagePaddingForShadow_v,
				width: special__content_w
			)
		}
		if self.incorrectMnemonicMessageLabel.isHidden == false {
			let w: CGFloat = 250
			let x = self.selectedWordsView.frame.origin.x + (self.selectedWordsView.frame.size.width - w)/2
			let y = self.selectedWordsView.frame.origin.y + self.selectedWordsView.frame.size.height
			let h: CGFloat = 40 // rough estimate (should be ok in this case) which contains extra btm padding
			self.incorrectMnemonicMessageLabel.frame = CGRect(x: x, y: y, width: w, height: h).integral
			//
			assert(self.tryAgain_actionButtonView.isHidden == false)
			assert(self.startOver_actionButtonView.isHidden == false)
			let buttons_y = self.scrollView.bounds.size.height - (UICommonComponents.ActionButton.buttonHeight + UICommonComponents.ActionButton.bottomMargin) // we'll assume the view contents are short enough not to obscure these
			self.tryAgain_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: content_x)
			self.startOver_actionButtonView.givenSuperview_layOut(atY: buttons_y, withMarginH: content_x)
		}
		let bottomMostView = self.selectedWordsView.isHidden == false
			? self.selectableWordsView
			: self.startOver_actionButtonView
		assert(self.selectableWordsView.isHidden != self.startOver_actionButtonView.isHidden) // assert both are not both visible or hidden
		self.scrollableContentSizeDidChange(withBottomView: bottomMostView, bottomPadding: 18)
	}
	//
	// Delegation - Interactions
	func tryAgain_tapped()
	{
		self.set(hasUserJustSubmittedIncorrectMnemonic: false) // reset
		self.selectedWordsView.deselectAllWords()
	}
	func startOver_tapped()
	{
		self.wizardController.regenerateWalletAndPopToInformOfMnemonicScreen()
	}
	//
	// Delegation - Internal - Overrides
	override func _viewControllerIsBeingPoppedFrom()
	{ // must maintain correct state if popped
		self.wizardController.patchToDifferentWizardTaskMode_withoutPushingScreen(
			patchTo_wizardTaskMode: self.wizardController.current_wizardTaskMode,
			atIndex: self.wizardController.current_wizardTaskMode_stepIdx - 1
		)
	}
}
//
extension CreateWallet_ConfirmMnemonic
{
	static let wellImage = UIImage(named: "mnemonicDisplayView_bg_stretchable")!.stretchableImage(
		withLeftCapWidth: 6,
		topCapHeight: 6
	)
	typealias MnemonicWord = String
	struct MnemonicWordHandle: Equatable
	{
		var uuid: String
		var word: MnemonicWord
		static func ==(l: MnemonicWordHandle, r: MnemonicWordHandle) -> Bool
		{
			return l.uuid == r.uuid
		}
	}
	static func layOut(
		wordViews: [WordView],
		atXOffset xOffset: CGFloat,
		yOffset: CGFloat,
		inContainingWidth containingWidth: CGFloat
	)
	{
		var rowIdx = 0
		var columnInRow = 0
		var currentRow_y: CGFloat = 0
		var currentRow_width_soFar: CGFloat = 0
		var viewsInCurrentRow = [WordView]() // tracked so we can shift them all, after obtaining the full width
		func centerWordViewsInRow()
		{
			let centering_xOffset = (containingWidth - currentRow_width_soFar)/2
			for (_, wordView) in viewsInCurrentRow.enumerated() {
				var frame = wordView.frame
				frame.origin.x += centering_xOffset
				wordView.frame = frame
			}
		}
		func advanceToNextRow()
		{
			rowIdx += 1
			columnInRow = 0
			currentRow_y += WordView.h + WordView.interWordView_margin_v
			currentRow_width_soFar = 0
			viewsInCurrentRow = []
		}
		for (_, wordView) in wordViews.enumerated() {
			// we rely here on the wordView having been sized already
			let projectedWidthAfterAddingThisView = currentRow_width_soFar + wordView.frame.size.width + (columnInRow == 0 ? 0 : WordView.interWordView_margin_h)
			if projectedWidthAfterAddingThisView >= containingWidth {
				centerWordViewsInRow() // before resetting values
				advanceToNextRow()
			} else { // staying in the same row
				if columnInRow != 0 { // if not first, add right margin from previous
					currentRow_width_soFar += WordView.interWordView_margin_h
				}
			}
			wordView.frame = CGRect(
				x: xOffset + currentRow_width_soFar,
				y: yOffset + currentRow_y,
				width: wordView.frame.size.width,
				height: wordView.frame.size.height
			)
			currentRow_width_soFar += wordView.frame.size.width
			columnInRow += 1
			viewsInCurrentRow.append(wordView)
		}
		centerWordViewsInRow() // and center last row, as well
	}
	class WordView: UIView
	{
		//
		// Constants/Types
		enum Mode
		{
			case inSelectable_butNotYetSelected
			case inSelectable_butSelected
			//
			case inSelected_butDeselectable
			case inSelected_butNotDeselectable
		}
		static let selectedWord_bgImage = UIImage(named: "mnemonicWordView_selected_bg_stretchable")!.stretchableImage(
			withLeftCapWidth: 4,
			topCapHeight: 4
		)
		static let visual__h: CGFloat = 21
		static let h = visual__h + 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
		static let visual__interWordView_margin_h: CGFloat = 8
		static let interWordView_margin_h = visual__interWordView_margin_h - 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_h
		static let visual__interWordView_margin_v: CGFloat = 8
		static let interWordView_margin_v = visual__interWordView_margin_v - 2*UICommonComponents.PushButtonCells.imagePaddingForShadow_v
		//
		// Properties
		var wordHandle: MnemonicWordHandle!
		var mode: Mode
		var tapped_fn: (WordView) -> Void
		var button: UICommonComponents.PushButton!
		//
		// Lifecycle - Init
		init(wordHandle: MnemonicWordHandle, mode: Mode, tapped_fn: @escaping (WordView) -> Void)
		{
			self.mode = mode
			self.wordHandle = wordHandle
			self.tapped_fn = tapped_fn
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.backgroundColor = .clear
			do {
				let view = UICommonComponents.PushButton(pushButtonType: .utility)
				// and specially, change the font
				view.titleLabel!.font = UIFont.smallRegularMonospace
				view.setTitle(self.wordHandle.word.uppercased(), for: .normal)
				view.addTarget(self, action: #selector(tapped), for: .touchUpInside)
				self.button = view
				self.addSubview(view)
			}
			self.setup_size()
			self.configureWithMode(isFirstTime: true)
		}
		func setup_size()
		{
			self.button.sizeToFit()
			var button_frame = self.button.frame
			do {
				button_frame.size.width += 2*(8+UICommonComponents.PushButtonCells.imagePaddingForShadow_h)
				button_frame.size.height = WordView.h
			}
			self.button.frame = button_frame
			self.frame = CGRect(x: 0, y: 0, width: self.button.frame.size.width, height: self.button.frame.size.height)
		}
		//
		// Imperatives - Configuration
		func setAndConfigure(withMode mode: Mode)
		{
			self.mode = mode
			self.configureWithMode(isFirstTime: false)
		}
		private func configureWithMode(isFirstTime: Bool)
		{
			self.button.isHidden = self.mode == .inSelectable_butSelected
			self.button.isEnabled = self.mode != .inSelected_butNotDeselectable
			if isFirstTime == false {
				self.setNeedsDisplay() // to draw bg if necessary
			}
		}
		//
		// Imperatives - Overrides - Drawing
		override func draw(_ rect: CGRect)
		{
			if self.mode == .inSelectable_butSelected {
				WordView.selectedWord_bgImage.draw(in:
					rect.insetBy( // must inset, b/c we increase the height of self by the same, to account for shadow
						dx: UICommonComponents.PushButtonCells.imagePaddingForShadow_h,
						dy: UICommonComponents.PushButtonCells.imagePaddingForShadow_v
					)
				)
			}
			super.draw(rect)
		}
		//
		// Delegation - Interactions
		func tapped()
		{
			if self.mode == .inSelected_butNotDeselectable {
				DDLog.Warn("WalletWizard", "WordView tapped but not deselectable.")
				return
			}
			if self.mode == .inSelectable_butSelected {
				DDLog.Warn("WalletWizard", "WordView tapped but already selected.")
				return
			}
			self.tapped_fn(self)
		}
	}
	class SelectedWordsView: UIView
	{
		//
		// Properties
		var selectableWordsView: SelectableWordsView!
		var didSelectWord_fn: ((MnemonicWordHandle) -> Void)!
		var didDeselectWord_fn: ((MnemonicWordHandle) -> Void)!
		var isEnabled = true
		//
		var mnemonicWords: [MnemonicWordHandle]
		var ordered_selectedWordViews = [WordView]()
		//
		// Lifecycle - Init
		init(
			mnemonicWords: [MnemonicWordHandle],
			didSelectWord_fn: @escaping ((MnemonicWordHandle) -> Void),
			didDeselectWord_fn: @escaping ((MnemonicWordHandle) -> Void)
		)
		{
			self.mnemonicWords = mnemonicWords
			self.didSelectWord_fn = didSelectWord_fn
			self.didDeselectWord_fn = didDeselectWord_fn
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.backgroundColor = .clear
			self.layer.cornerRadius = 5 // for red border on incorrect mnemonic submission
		}
		func postInit_set(selectableWordsView: SelectableWordsView)
		{
			self.selectableWordsView = selectableWordsView
		}
		//
		// Accessors - Derived
		var selectedWords: [MnemonicWord] {
			let words = self.ordered_selectedWordViews.map(
				{ (wordView) -> MnemonicWord in
					return wordView.wordHandle.word
				}
			)
			return words
		}
		var hasUserSelectedAllWords: Bool {
			return (self.ordered_selectedWordViews.count == self.mnemonicWords.count)
		}
		var hasUserSelectedTheCorrectMnemonicWordOrdering: Bool {
			if self.hasUserSelectedAllWords == false {
				return false
			}
			for (idx, selectedWordView) in self.ordered_selectedWordViews.enumerated() {
				let correctWordHandleForIdx = self.mnemonicWords[idx]
				if correctWordHandleForIdx.word != selectedWordView.wordHandle.word {
					// here, do not compare wordHandles, since that will check UUID equality, which is not what we want, in case user selects the same word in a different order
					return false
				}
			}
			return true
		}
		//
		// Imperatives - Word selection
		func fromSelectableWords_selectWord(withWordHandle wordHandle: MnemonicWordHandle)
		{
			if self.isEnabled == false {
				DDLog.Warn("WalletWizard", "Asked to select word view but isEnabled=false")
				assert(false)
				return
			}
			let wordView = WordView(wordHandle: wordHandle, mode: .inSelected_butDeselectable)
			{ [unowned self] (this_wordView) in
				if self.isEnabled == false {
					DDLog.Warn("WalletWizard", "Asked to deselect word view but isEnabled=false")
					return
				}
				this_wordView.setAndConfigure(withMode: .inSelected_butNotDeselectable) // disable redundant deselection
				self.deselectWord(withWordView: this_wordView)
			}
			self.ordered_selectedWordViews.append(wordView)
			self.addSubview(wordView)
			//
			self.didSelectWord_fn(wordHandle) // will cause self to be laid out
		}
		func deselectWord(withWordView wordView: WordView)
		{
			let wordHandle = wordView.wordHandle! // pretty certain this ! ought not to be necessary - compiler bug?
			//
			wordView.removeFromSuperview()
			self.ordered_selectedWordViews.remove(at: self.ordered_selectedWordViews.index(of: wordView)!)
			//
			self.selectableWordsView.didDeselectWord(withWordHandle: wordHandle)
			self.didDeselectWord_fn(wordHandle) // will cause self to be laid out
		}
		func deselectAllWords()
		{
			for (_, wordView) in self.ordered_selectedWordViews.enumerated() {
				self.deselectWord(withWordView: wordView)
			}
		}
		//
		// Imperatives - Interactivity
		func set(isEnabled: Bool)
		{
			self.isEnabled = isEnabled
			let to_mode: WordView.Mode = isEnabled ? .inSelected_butDeselectable : .inSelected_butNotDeselectable
			for (_, wordView) in self.ordered_selectedWordViews.enumerated() {
				wordView.setAndConfigure(withMode: to_mode)
			}
		}
		//
		// Imperatives - Overrides
		override func draw(_ rect: CGRect)
		{
			CreateWallet_ConfirmMnemonic.wellImage.draw(in: rect)
			super.draw(rect)
		}
		//
		// Imperatives - Layout
		func layOut(atX x: CGFloat, y: CGFloat, width: CGFloat)
		{
			let visual__padding_v: CGFloat = 24
			let padding_v: CGFloat = visual__padding_v - UICommonComponents.PushButtonCells.imagePaddingForShadow_v
			let visual__padding_h: CGFloat = 12 // this is different from the 16 stipulated by design but gives more room on small mobile screens
			let padding_h: CGFloat = visual__padding_h - UICommonComponents.PushButtonCells.imagePaddingForShadow_h
			let min_height: CGFloat = 128
			CreateWallet_ConfirmMnemonic.layOut(
				wordViews: self.ordered_selectedWordViews,
				atXOffset: padding_h,
				yOffset: padding_v,
				inContainingWidth: width - 2*padding_h
			)
			let last_wordView = self.ordered_selectedWordViews.last
			let height = last_wordView != nil ? max(min_height, last_wordView!.frame.origin.y + last_wordView!.frame.size.height + padding_v) : min_height
			self.frame = CGRect(x: x, y: y, width: width, height: height)
		}
		//
		// Imperatives - State
	}
	//
	class SelectableWordsView: UIView
	{
		//
		// Properties
		var mnemonicWords: [MnemonicWordHandle]!
		var shuffled_mnemonicWords: [MnemonicWordHandle]!
		var selectedWordsView: SelectedWordsView!
		var wordViews = [WordView]()
		//
		// Lifecycle - Init
		init(mnemonicWords: [MnemonicWordHandle], selectedWordsView: SelectedWordsView)
		{
			self.mnemonicWords = mnemonicWords
			self.shuffled_mnemonicWords = mnemonicWords.sorted {
				$0.word.localizedCaseInsensitiveCompare($1.word) == ComparisonResult.orderedAscending
			}
			self.selectedWordsView = selectedWordsView
			super.init(frame: .zero)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			do {
				self.backgroundColor = .clear
			}
			for (_, wordHandle) in self.shuffled_mnemonicWords.enumerated() {
				let view = CreateWallet_ConfirmMnemonic.WordView(
					wordHandle: wordHandle,
					mode: .inSelectable_butNotYetSelected,
					tapped_fn:
					{ (wordView) in
						if self.selectedWordsView.isEnabled == false {
							DDLog.Warn("WalletWizard", "Word selected but disabled.")
							return
						}
						let mode = wordView.mode
						if mode != .inSelectable_butNotYetSelected {
							assert(false)
							return
						}
						wordView.setAndConfigure(withMode: .inSelectable_butSelected) // flip from selectable to selected
						let tapped_wordHandle = wordView.wordHandle! // pretty sure the ! ought not to be necessary but there may be a compiler bug
						self.selectedWordsView.fromSelectableWords_selectWord(withWordHandle: tapped_wordHandle)
					}
				)
				self.wordViews.append(view)
				self.addSubview(view)
			}
		}
		//
		// Imperatives - Layout
		func layOut(atX x: CGFloat, y: CGFloat, width: CGFloat)
		{
			CreateWallet_ConfirmMnemonic.layOut(
				wordViews: self.wordViews,
				atXOffset: 0,
				yOffset: 0,
				inContainingWidth: width
			)
			//
			let last_wordView = self.wordViews.last!
			let height = last_wordView.frame.origin.y + last_wordView.frame.size.height
			self.frame = CGRect(x: x, y: y, width: width, height: height)
		}
		//
		// Delegation - From SelectedWordsView
		func didDeselectWord(withWordHandle wordHandle: MnemonicWordHandle)
		{
			var wordView: WordView!
			for (_, this_wordView) in self.wordViews.enumerated() {
				if this_wordView.wordHandle == wordHandle {
					wordView = this_wordView
					break
				}
			}
			assert(wordView != nil)
			wordView.setAndConfigure(withMode: .inSelectable_butNotYetSelected) // flip back to selectable
		}
	}
}
