//
//  FundsRequest.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/15/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import CoreImage
import UIKit

class FundsRequest: PersistableObject
{
	//
	// Types/Constants
	enum NotificationNames: String
	{
		case infoUpdated		= "FundsRequest_NotificationNames_infoUpdated"
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	enum DictKey: String
	{ // (For persistence)
		case from_fullname = "from_fullname"
		case to_walletHexColorString = "to_walletHexColorString"
		case to_address = "to_address"
		case payment_id = "payment_id"
		case amount = "amount"
		case message = "message"
		case description = "description"
	}
	enum QRSize: CGFloat
	{
		case small = 20
		case medium = 96 // 2 * 8
		case large = 272 // 320 - 2*24
		//
		var side: CGFloat {
			return self.rawValue
		}
		var width: CGFloat {
			return self.side
		}
		var height: CGFloat {
			return self.side
		}
	}
	//
	// Properties - Persisted Values
	var from_fullname: String?
	var to_walletSwatchColor: Wallet.SwatchColor!
	var to_address: MoneroAddress!
	var payment_id: MoneroPaymentID?
	var amount: String?
	var message: String?
	var description: String?
	//
	// Properties - Transient
	var qrCode_cgImage: CGImage!
	var cached__qrCode_image_small: UIImage!
	//
	// 'Protocols' - Persistable Object
	override func new_dictRepresentation() -> [String: Any]
	{
		var dict = super.new_dictRepresentation() // since it constructs the base object for us
		do {
			if let value = self.from_fullname {
				dict[DictKey.from_fullname.rawValue] = value
			}
			dict[DictKey.to_walletHexColorString.rawValue] = self.to_walletSwatchColor.jsonRepresentation()
			dict[DictKey.to_address.rawValue] = self.to_address
			if let value = self.payment_id {
				dict[DictKey.payment_id.rawValue] = value
			}
			if let value = self.amount {
				dict[DictKey.amount.rawValue] = value
			}
			if let value = self.message {
				dict[DictKey.message.rawValue] = value
			}
			if let value = self.description {
				dict[DictKey.description.rawValue] = value
			}
		}
		return dict
	}
	//
	// Lifecycle - Init - Reading existing (already saved) wallet
	override func collectionName() -> String
	{
		return "FundsRequest"
	}
	required init?(withPlaintextDictRepresentation dictRepresentation: DocumentPersister.DocumentJSON) throws
	{
		try super.init(withPlaintextDictRepresentation: dictRepresentation) // this will set _id for us
		//
		self.from_fullname = dictRepresentation[DictKey.from_fullname.rawValue] as? String
		self.to_walletSwatchColor = Wallet.SwatchColor.new(from_jsonRepresentation: dictRepresentation[DictKey.to_walletHexColorString.rawValue] as! String)
		self.to_address = dictRepresentation[DictKey.to_address.rawValue] as! String
		self.payment_id = dictRepresentation[DictKey.payment_id.rawValue] as? String
		self.amount = dictRepresentation[DictKey.amount.rawValue] as? String
		self.message = dictRepresentation[DictKey.message.rawValue] as? String
		self.description = dictRepresentation[DictKey.description.rawValue] as? String
		self.setup()
	}
	//
	// Lifecycle - Init - For adding new
	required init()
	{
		super.init()
	}
	convenience init(
		from_fullname: String?,
		to_walletSwatchColor: Wallet.SwatchColor,
		to_address: MoneroAddress,
		payment_id: MoneroPaymentID?,
		amount: String?,
		message: String?,
		description: String?
	)
	{
		self.init()
		self.from_fullname = from_fullname
		self.to_walletSwatchColor = to_walletSwatchColor
		self.to_address = to_address
		self.payment_id = payment_id
		self.amount = amount
		self.message = message
		self.description = description
		self.setup()
	}
	func setup()
	{
		self.setup_qrCode_cgImage()
		self.cached__qrCode_image_small = self.new_qrCodeImage(withQRSize: .small) // cache for table view access
	}
	func setup_qrCode_cgImage()
	{
		let uriStringData = self.new_URI.absoluteString.data(using: .utf8)
		guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
			assert(false)
			return
		}
		filter.setValue(uriStringData, forKey: "inputMessage")
		filter.setValue("Q"/*quartile/25%*/, forKey: "inputCorrectionLevel")
		let outputImage = filter.outputImage!
		let context = CIContext(options: nil)
		self.qrCode_cgImage = context.createCGImage(outputImage, from: outputImage.extent)!
	}
	//
	// Accessors - Factories
	func new_qrCodeImage(withQRSize qrSize: QRSize) -> UIImage
	{
		let targetSize = CGSize(
			width: qrSize.width,
			height: qrSize.height
		)
		UIGraphicsBeginImageContext(
			CGSize(
				width: targetSize.width * UIScreen.main.scale,
				height: targetSize.height * UIScreen.main.scale
			)
		)
		var preScaledImage: UIImage!
		do {
			let graphicsContext = UIGraphicsGetCurrentContext()!
			graphicsContext.interpolationQuality = .none
			let boundingBoxOfClipPath = graphicsContext.boundingBoxOfClipPath
			graphicsContext.draw(
				self.qrCode_cgImage,
				in: CGRect(
					x: 0,
					y: 0,
					width: boundingBoxOfClipPath.width,
					height: boundingBoxOfClipPath.height
				)
			)
			//
			preScaledImage = UIGraphicsGetImageFromCurrentImageContext()!
		}
		UIGraphicsEndImageContext()
		let scaled_qrCodeImage = UIImage(
			cgImage: preScaledImage.cgImage!,
			scale: 1.0/UIScreen.main.scale,
			orientation: .downMirrored
		)
		
		return scaled_qrCodeImage
	}
	//
	// Interface - Runtime - Accessors/Properties
	var new_URI: URL
	{
		return MoneroUtils.RequestURIs.new_URL(
			address: self.to_address,
			amount: self.amount,
			description: self.description,
			paymentId: self.payment_id,
			message: self.message
		)
	}
}
