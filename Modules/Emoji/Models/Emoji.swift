//
//  Emoji.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/1/17.
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
import Foundation

struct Emoji
{
	typealias EmojiCharacter = String
	
	static func anEmojiWhichIsNotInUse(amongInUseEmoji inUseEmojiCharacters: [EmojiCharacter]) -> EmojiCharacter
	{
		let allOrdered = Emoji.lazy_allOrdered
		for (_, emojiCharacter) in allOrdered.enumerated() {
			if inUseEmojiCharacters.contains(emojiCharacter) == false { // if not in use
				return emojiCharacter
			}
		}
		DDLog.Warn("Emoji", "Ran out of emojis to select in anEmojiWhichIsNotInUse")
		let randomIdx = Int(arc4random_uniform(UInt32(numberOfEmoji)))
		//
		return allOrdered[randomIdx]
	}
	//
	static let numberOfEmoji = Emoji.lazy_allOrdered.count
	static var _allOrdered: [EmojiCharacter]? = nil
	static var lazy_allOrdered: [EmojiCharacter] {
		if Emoji._allOrdered == nil {
			var mutable_allOrdered: [EmojiCharacter] = []
			do {
				let url = Bundle.main.url(forResource: "emoji-20171214", withExtension: "json")!
				var raw_json: Any?
				do {
					let raw_data = try Data(contentsOf: url)
					do {
						raw_json = try JSONSerialization.jsonObject(with: raw_data)
					} catch let e {
						fatalError("Emoji set resource parse error … \(e)")
					}
				} catch let e {
					fatalError("Emoji set resource read error … \(e)")
				}
				let raw_jsonDict = raw_json as! [String: Any]
				let raw_sets = raw_jsonDict["sets"] as! [[String: Any]]
				for (_, raw_set) in raw_sets.enumerated() {
					let _ = raw_set["t"] as! String
					let raw_emojiList = raw_set["l"] as! [String]
					let emojiList = raw_emojiList as [EmojiCharacter] // TODO/FIXME: will assume for now that they are valid … reasonable to assume control of file contents?
					//
					mutable_allOrdered.append(contentsOf: emojiList)
				}
			}
			Emoji._allOrdered = mutable_allOrdered
		}
		return Emoji._allOrdered!
	}
	
}
