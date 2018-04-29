//
//  QRCodeImages.swift
//  MyMonero
//
//  Created by Paul Shapiro on 4/29/18.
//  Copyright (c) 2014-2018, MyMonero.com
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
import CoreImage

struct QRCodeImages {}
extension QRCodeImages
{
	enum QRSize: CGFloat
	{
		case small = 20
		case medium = 56
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
	// Accessors - Factories
	static func new_qrCode_cgImage(
		withContentString contentString: String
	) -> CGImage? {
		let qrCode_stringData = contentString.data(
			using: .utf8
		)
		guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
			assert(false)
			return nil
		}
		filter.setValue(qrCode_stringData, forKey: "inputMessage")
		filter.setValue("Q"/*quartile/25%*/, forKey: "inputCorrectionLevel")
		let outputImage = filter.outputImage!
		let context = CIContext(options: nil)
		let cgImage = context.createCGImage(outputImage, from: outputImage.extent)!
		//
		return cgImage
	}
	static func new_qrCode_UIImage(
		fromCGImage qrCode_cgImage: CGImage,
		withQRSize qrSize: QRSize
	) -> UIImage {
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
				qrCode_cgImage,
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
		//
		return scaled_qrCodeImage
	}
}
