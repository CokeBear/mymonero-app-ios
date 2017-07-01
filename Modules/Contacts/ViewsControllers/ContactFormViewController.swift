//
//  ContactFormViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/29/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
class ContactFormViewController: UICommonComponents.FormViewController
{
	//
	// Properties
	var name_label: UICommonComponents.FormLabel!
	var name_inputView: UICommonComponents.FormInputField!
	//
	var emoji_label: UICommonComponents.FormLabel!
	var emoji_inputView: EmojiUI.EmojiPickerButtonView!
	//
	var address_label: UICommonComponents.FormLabel!
	var address_inputView: UICommonComponents.FormTextViewContainerView!
	//
	var paymentID_label: UICommonComponents.FormLabel?
	var paymentID_inputView: UICommonComponents.FormTextViewContainerView?
	//
	var paymentID_fieldAccessoryMessageLabel: UICommonComponents.FormFieldAccessoryMessageLabel?
	//
	// Lifecycle - Init
	override init()
	{
		super.init()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func setup_views()
	{
		super.setup_views()
		do {
			let view = UICommonComponents.FormLabel(
				title: NSLocalizedString("NAME", comment: ""),
				sizeToFit: true
			)
			self.name_label = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: NSLocalizedString("Enter name", comment: "")
			)
			view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			view.delegate = self
			view.returnKeyType = .next
			self.name_inputView = view
			self.view.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.FormLabel(
				title: NSLocalizedString("EMOJI", comment: ""),
				sizeToFit: true
			)
			self.emoji_label = view
			self.view.addSubview(view)
		}
		do { // TODO: actual emoji field
			let view = EmojiUI.EmojiPickerButtonView()
//			view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
//			view.delegate = self
			self.emoji_inputView = view
			self.view.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.FormLabel(
				title: NSLocalizedString("ADDRESS", comment: ""),
				sizeToFit: true
			)
			self.address_label = view
			self.view.addSubview(view)
		}
		do { // TODO: config as immutable by overridable flag
			let view = UICommonComponents.FormTextViewContainerView(
				placeholder: NSLocalizedString("Enter normal, integrated, or OpenAlias address", comment: "")
			)
			view.textView.autocorrectionType = .no
			view.textView.autocapitalizationType = .none
			view.textView.spellCheckingType = .no
			view.textView.returnKeyType = .next
			view.textView.delegate = self
			self.address_inputView = view
			self.view.addSubview(view)
		}
		// TODO: add 'resolving' act ind here per flag
		
		// TODO: check if paymentID needed by overridable flag
		do {
			let view = UICommonComponents.FormLabel(
				title: NSLocalizedString("PAYMENT ID", comment: ""),
				sizeToFit: true
			)
			self.paymentID_label = view
			self.view.addSubview(view)
		}
		do { // TODO: config as immutable by overridable flag
			let view = UICommonComponents.FormTextViewContainerView(
				placeholder: NSLocalizedString("Optional", comment: "")
			)
			view.textView.autocorrectionType = .no
			view.textView.autocapitalizationType = .none
			view.textView.spellCheckingType = .no
			view.textView.returnKeyType = .go
			view.textView.delegate = self
			self.paymentID_inputView = view
			self.view.addSubview(view)
		}
		// TODO: check if field needs to be displayed:
		do {
			let view = UICommonComponents.FormFieldAccessoryMessageLabel(
				text: NSLocalizedString("Unless you use an OpenAlias or integrated address, if you don't provide a payment ID, one will be generated.", comment: "")
			)
			self.paymentID_fieldAccessoryMessageLabel = view
			self.view.addSubview(view)
		}
		
//		self.view.borderSubviews()
		// TODO: add delete record btn here per overridable flag
	}
	override func setup_navigation()
	{
		super.setup_navigation()
		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .save,
			target: self,
			action: #selector(tapped_rightBarButtonItem),
			title_orNilForDefault: nil
		)
		self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .cancel,
			target: self,
			action: #selector(tapped_barButtonItem_cancel),
			title_orNilForDefault: self._overridable_cancelBarButtonTitle_orNilForDefault()
		)

	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
//		if self.isSubmitting == true {
//			return false
//		}
		// TODO: check things like form fields (based on existence),
		// and whether is resolving…… anything else?
		return true
	}
	//
	// Accessors - Overridable
	func _overridable_cancelBarButtonTitle_orNilForDefault() -> String? { return nil }
	//
	// Runtime - Imperatives - Overrides
	override func disableForm()
	{
		super.disableForm()
		//
		self.scrollView.isScrollEnabled = false
		//
		// TODO
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		// TODO
	}
	override func _tryToSubmitForm()
	{
	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		let textField_w = self.new__textField_w
		let fullWidth_label_w = self.new__fieldLabel_w
		//
		let visual__nameField_marginRight: CGFloat = 24
		let nameField_marginRight = visual__nameField_marginRight - UICommonComponents.FormInputCells.imagePadding_x - UICommonComponents.PushButtonCells.imagePaddingForShadow_h
		//
		do {
			let visual__nameField_w = textField_w - (nameField_marginRight + self.emoji_inputView.frame.size.width)
			self.name_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: top_yOffset,
				width: visual__nameField_w,
				height: self.name_label.frame.size.height
			).integral
			self.name_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.name_label.frame.origin.y + self.name_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
				width: visual__nameField_w,
				height: self.name_inputView.frame.size.height
			).integral
		}
		do {
			let emojiField_x = self.name_inputView.frame.origin.x + self.name_inputView.frame.size.width + nameField_marginRight
			let label_inset: CGFloat = 8
			self.emoji_label.frame = CGRect(
				x: emojiField_x + label_inset,
				y: top_yOffset,
				width: self.emoji_inputView.frame.size.width - label_inset,
				height: self.emoji_label.frame.size.height
			).integral
			self.emoji_inputView.frame = CGRect(
				x: emojiField_x - UICommonComponents.PushButtonCells.imagePaddingForShadow_h,
				y: self.name_label.frame.origin.y + self.name_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAbovePushButton + 1, // +1 to align vertically - should not technically be necessary but there's some height weirdness with the text field
				width: self.emoji_inputView.frame.size.width,
				height: self.emoji_inputView.frame.size.height
			).integral
		}
		do {
			self.address_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: self.name_inputView.frame.origin.y + self.name_inputView.frame.size.height + UICommonComponents.FormLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.address_label.frame.size.height
			).integral
			self.address_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.address_label.frame.origin.y + self.address_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.address_inputView.frame.size.height
			).integral
		}
		//
		// TODO: lay out Resolving field if exists and not hidden
		//
		if self.paymentID_label != nil {
			assert(self.paymentID_inputView != nil)
			self.paymentID_label!.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: self.address_inputView.frame.origin.y + self.address_inputView.frame.size.height + UICommonComponents.FormLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.paymentID_label!.frame.size.height
			).integral
			self.paymentID_inputView!.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.paymentID_label!.frame.origin.y + self.paymentID_label!.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.paymentID_inputView!.frame.size.height
			).integral
			if self.paymentID_fieldAccessoryMessageLabel != nil {
				self.paymentID_fieldAccessoryMessageLabel!.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.paymentID_inputView!.frame.origin.y + self.paymentID_inputView!.frame.size.height + 7,
					width: fullWidth_label_w,
					height: 0
				).integral
				self.paymentID_fieldAccessoryMessageLabel!.sizeToFit()
			}
		} else {
			assert(self.paymentID_inputView == nil)
			assert(self.paymentID_fieldAccessoryMessageLabel == nil)
		}
		// TODO: lay out delete record field if exists
		//
		// TODO: derive bottommost view based on existence
		// … delete record, payment id, address, … and set up way to expand border box to fill view
		// TODO: if applicable set up inset fields for add contact from send funds tab
		
		
		let bottomMostView = self.paymentID_fieldAccessoryMessageLabel /*?? self.deleteRecordButton*/ ?? self.paymentID_inputView ?? self.address_inputView
		let bottomPadding: CGFloat = 18
		self.formContentSizeDidChange(
			withBottomView: bottomMostView!,
			bottomPadding: bottomPadding
		)
	}
	override func viewDidAppear(_ animated: Bool)
	{
		let isFirstAppearance = self.hasAppearedBefore == false
		super.viewDidAppear(animated)
		if isFirstAppearance {
			DispatchQueue.main.async
			{ [unowned self] in
				self.name_inputView.becomeFirstResponder()
			}
		}
	}
	//
	// Delegation - UITextView
	func textView(
		_ textView: UITextView,
		shouldChangeTextIn range: NSRange,
		replacementText text: String
		) -> Bool
	{
		if text == "\n" { // simulate single-line input
			return self.aField_shouldReturn(textView, returnKeyType: textView.returnKeyType)
		}
		return true
	}
	//
	// Delegation - Interactions
	func tapped_rightBarButtonItem()
	{
		self.aFormSubmissionButtonWasPressed()
	}
	func tapped_barButtonItem_cancel()
	{
		assert(self.navigationController!.presentingViewController != nil)
		// we always expect self to be presented modally
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
}
