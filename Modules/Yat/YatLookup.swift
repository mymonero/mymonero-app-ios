//
//  YatLookup.swift
//  MyMonero
//
//  Created by Karl Buys on 2021/03/26.
//  Copyright © 2021 MyMonero. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum YatLookupError: Error {
	case addressContainsInvalidEmojis(reason: String)
	case yatNotFound
	case yatLengthInvalid(reason: String)
	case yatTagsNotSet(reason: String)
	case addressContainsNonEmojiCharacters
}

extension UnicodeScalar {
	/// Note: This method is part of Swift 5, so you can omit this.
	/// See: https://developer.apple.com/documentation/swift/unicode/scalar
	var isEmoji: Bool {
		switch value {
		case 0x1F600...0x1F64F, // Emoticons
			 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
			 0x1F680...0x1F6FF, // Transport and Map
			 0x1F1E6...0x1F1FF, // Regional country flags
			 0x2600...0x26FF, // Misc symbols
			 0x2700...0x27BF, // Dingbats
			 0xE0020...0xE007F, // Tags
			 0xFE00...0xFE0F, // Variation Selectors
			 0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
			 0x1F018...0x1F270, // Various asian characters
			 0x238C...0x2454, // Misc items
			 0x20D0...0x20FF: // Combining Diacritical Marks for Symbols
			return true

		default: return false
		}
	}

	var isZeroWidthJoiner: Bool {
		return value == 8205
	}
}

extension String {
	// Not needed anymore in swift 4.2 and later, using `.count` will give you the correct result
//	var glyphCount: Int {
//		let richText = NSAttributedString(string: self)
//		let line = CTLineCreateWithAttributedString(richText)
//		return CTLineGetGlyphCount(line)
//	}

//	var isSingleEmoji: Bool {
//		return { $0.count } == 1 && containsEmoji
//	}

	var containsEmoji: Bool {
		return unicodeScalars.contains { $0.isEmoji }
	}

	var containsOnlyEmoji: Bool {
		return !isEmpty
			&& !unicodeScalars.contains(where: {
				!$0.isEmoji && !$0.isZeroWidthJoiner
			})
	}

	// The next tricks are mostly to demonstrate how tricky it can be to determine emoji's
	// If anyone has suggestions how to improve this, please let me know
	var emojiString: String {
		return emojiScalars.map { String($0) }.reduce("", +)
	}

	var emojis: [String] {
		var scalars: [[UnicodeScalar]] = []
		var currentScalarSet: [UnicodeScalar] = []
		var previousScalar: UnicodeScalar?

		for scalar in emojiScalars {
			if let prev = previousScalar, !prev.isZeroWidthJoiner, !scalar.isZeroWidthJoiner {
				scalars.append(currentScalarSet)
				currentScalarSet = []
			}
			currentScalarSet.append(scalar)

			previousScalar = scalar
		}

		scalars.append(currentScalarSet)

		return scalars.map { $0.map { String($0) }.reduce("", +) }
	}

	fileprivate var emojiScalars: [UnicodeScalar] {
		var chars: [UnicodeScalar] = []
		var previous: UnicodeScalar?
		for cur in unicodeScalars {
			if let previous = previous, previous.isZeroWidthJoiner, cur.isEmoji {
				chars.append(previous)
				chars.append(cur)

			} else if cur.isEmoji {
				chars.append(cur)
			}

			previous = cur
		}

		return chars
	}
}

class YatLookup {
//	struct Parameters {
//		//var address: String
//		var debugMode: Bool
//		var apiUrl: String
//	}
	// 🦈❤️🍒❗😈
	var yatEmojis: Array<String> = ["🐶","🍼","💃","🏦","🔫","📷","🔦","📡","🔔","🍷","💼","🎛️","🤧","✍️","🥒","💥","🤡","💺","🔋","💯","🐬","🕉️","📺","💾","🗽","🍦","🌴","🦂","☦️","🐭","📦","👘","🍈","😍","🎾","🎂","🗿","🍐","👃","♒","📻","☪️","✨","⚾","🥃","🔮","🐽","🌙","😢","🍤","👕","🐯","🍡","🏎️","⛄","🐱","🎐","🗺️","🍪","🤘","⚛️","🏐","🤐","🎹","🗾","🎏","🎨","🤔","😵","👶","🥝","🥗","♉","🏖️","🗞️","🍾","🎃","🆘","🎋","🐙","🎈","💨","🕸️","🚪","☄️","✉️","🐾","🍗","💡","🎤","🍿","♣️","🐛","🛵","🍳","🖨️","🎢","🧀","🏕️","🚦","🌭","🔒","🦍","💍","⚙️","📌","🤝","👽","🆚","🎠","🛍️","🏀","🏏","🐀","🐧","👎","👗","🖖","💩","🗡️","🤖","🐵","🛒","🍭","🔪","📖","🍔","🚚","✡️","🐉","🤠","🏸","❗","😱","🐌","🤑","💪","👏","☀️","🍑","🎀","🆕","😷","🆒","☢️","👻","🦉","⛵","🦀","🎳","📏","🆔","🎸","👣","🍉","✊","🏈","🏹","🦋","☁️","🌈","✂️","🌕","📟","🥛","🏮","🏓","🍽️","💵","🎭","🍱","🕹️","🗄️","🚜","🎻","💊","⌚","🦄","🛋️","🌊","🐊","🥄","🐣","🎰","🚒","👁️","🐮","🕯️","🃏","🐋","🍶","🖍️","🚽","👌","🍇","🎉","😇","🍍","⭐","🙃","🦅","💦","🍕","🏺","🍥","🏆","🚓","📈","💐","🌪️","🍩","🌻","🎥","🀄","🎮","🛢️","👍","🚢","🛡️","🦃","💄","🎷","✏️","🕌","👟","♊","🥁","✌️","⚖️","🗼","❤️","👀","🥞","✈️","🤕","🏁","♟️","🎧","♏","👾","🐗","🎼","🐪","📱","🐜","🐐","🚧","🌮","🐼","🍣","🌯","🦈","🔥","🆓","🐑","🎖️","🥊","⛳","💈","🥙","🤳","🐰","⚜️","🏟️","🎒","🥑","🍺","🎿","🐚","🎎","👛","🚰","💱","🦎","🎁","👒","🎽","👂","🥚","😘","♎","👑","🍀","🍓","🎵","⛪","🏒","😶","🍋","👞","🎣","💅","⚰️","🎩","🍄","🍌","👉","🏰","🍁","❄️","🍬","🚂","🏧","🐨","🚿","🕎","🥜","🔬","🥅","🚭","⚽","💻","🗑️","⏰","♓","😂","🎲","🦁","🤓","♠️","🐝","🥕","🦏","⚠️","💋","🏥","♻️","🛶","👙","😜","🎡","♌","🚠","💰","🐸","🔱","⛰️","📐","🍆","☯️","🚀","🐺","🍜","👠","🎯","🍵","🏯","🦇","🤢","🍊","🌵","💳","🌶️","🍫","✝️","♋","♐","💔","♑","📿","🦆","🥐","🍝","🌰","🍟","🎱","🌽","🏛️","🙏","🍯","🥔","🚫","🖼️","🏭","🍸","🎺","🙌","🔌","⛸️","💣","⚓","☠️","🙈","🐷","☕","☸️","🔑","♈","🍒","🍎","📜","🦊","🚁","🍞","🐃","🎬","⌛","🍘","🐘","🌸","👖","😎","🏠","♍","🕳️","🚗","🍚","💉","🚬","🔧","🌹","🔩","🚑","🥓","⚡","🐞","🎓","📎","🎟️","🐢","📓","🕍","🏍️","👋","🥋","❓","🔭","👢","🕷️","😈","🎪","🚨","🌲","⛓️","🆙","🐍","🚲","🐴","🦌","🐔","💎","➕","🐻","❤"];

	var apiUrl: String
	
	init() {
		debugPrint("Initted YatLookup without parameters")
		self.apiUrl = "https://a.y.at"
	}
	
	init(debugMode: Bool) {
		if (debugMode == true) {
			self.apiUrl = "https://api-dev.yat.rocks"
		} else {
			self.apiUrl = "https://a.y.at"
		}
	}
	
	func containsEmojis(possibleAddress: String) -> Bool {
		if possibleAddress.containsEmoji {
			debugPrint("Contains at least one emoji")
			return true
		}
		return false
	}
	
	func containsOnlyEmojis(possibleAddress: String) -> Bool {
		if possibleAddress.containsOnlyEmoji {
			debugPrint("Contains only emojis")
			return true
		}
		debugPrint("Contains non-emojis")
		return false
	}
	
	func getSupportedEmojis() -> Array<String> {
		debugPrint("getSupportedEmojis")
		return self.yatEmojis
	}
	
	// Not necessary to implement this feature -- we're going to assume any emoji to be correct until we have an exhaustive list to check
	func isValidYatCharacter() -> Bool {
		debugPrint("isValidYatCharacter unimplemented at present")
		return false
	}
	
	// TODO: consider removing this stub
	func lookupMoneroAddresses(yatHandle: String) {
		debugPrint("lookupMoneroAddresses")
		debugPrint("Ok, cool, let's look this thing up")
	}
	
	
	func performLookup(yatHandle: String!, completion: @escaping (Result<[String: String]>) -> Void) {
		
		let url: String = self.apiUrl + "/emoji_id/" + yatHandle + "?tags=0x1001,0x1002"
		debugPrint("Let us look up \(yatHandle): url is \(url)")
		let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
		
		Alamofire.request(encodedUrl!, method: .get).responseJSON {
				response in
				// add switch response.result here. Check for cases .success, .failure, default

				switch response.result {
				case .success(let value as [String: Any]):
					// This might return successful in spite of a 404 error -- manually check
					//if (response.result.err)
					let notFound: Int = 404
					if (response.response?.statusCode == 404) {
						completion(.failure(YatLookupError.yatNotFound))
						return
					}
					let json = JSON(response.result.value)
					var returnValueDict: [String: String] = [:]
					for (index,subJson):(String, JSON) in json["result"] {
						returnValueDict[subJson["tag"].stringValue] = subJson["data"].stringValue
					}

					completion(.success(returnValueDict))

				case .failure(let error):
					// Could be user's internet is down, or Yat's servers unreachable
					completion(.failure(error))

				default:
					fatalError("received non-dictionary JSON response")
				}
			}
	}
	
	func testEmojisAgainstUnicodePropertyEscape() {
		debugPrint("testEmojisAgainstUnicodePropertyEscape is a stubbed method -- use it in future for unit tests")
	}
	func isValidYatHandle(possibleAddress: String) throws -> Bool {

		// Check string contains only emojis
		if (possibleAddress.containsOnlyEmoji == false) {
			throw YatLookupError.addressContainsNonEmojiCharacters
		}
		
		// Check that string is between one and five characters
		if (possibleAddress.count > 5) {
			throw YatLookupError.yatLengthInvalid(reason: "A Yat can have a maximum of five characters")
		}
		if (possibleAddress.count < 1) {
			throw YatLookupError.yatLengthInvalid(reason: "A Yat must have a minimum of one character")
		}
		
		
		// TODO: Once we import the proprietary Rust library, we'll be able to exhaustively check emojis against what Yat supports
		// For now, we don't throw an error because the entered emoji may be valid based on Yat's mapping, which could cause valid lookups to fail
		// Uncomment this once we have an exhaustive list
		
//		let emojiArr = possibleAddress.emojis
//		for (index, emoji) in emojiArr.enumerated() {
//			if (self.yatEmojis.contains(emoji) == false) {
//				//throw YatLookupError.addressContainsInvalidEmojis(reason: "\(emoji) is not a valid Yat emoji")
//			}
//		}
		
		return true
	}

}
