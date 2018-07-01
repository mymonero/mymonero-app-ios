//
//  LocalDataMigrations.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/1/18.
//  Copyright © 2018 MyMonero. All rights reserved.
//

import Foundation

class LocalDataMigrations
{
	static let shared = LocalDataMigrations()
	//
	var hasTriedToMigrateAny_v0ToV1 = false
	var didMigrateAny_v0ToV1 = false
	//
	init()
	{
		self.setup()
	}
	func setup()
	{
		//
		// This must either remain synchronous or a synchronization callback should be created and called
		//
		do {
			try self.migrateAny_v0ToV1()
		} catch let e {
			fatalError(e.localizedDescription)
		}
		self.hasTriedToMigrateAny_v0ToV1 = true
	}
	func migrateAny_v0ToV1() throws
	{
		var docsToRemove = [URL]()
		//
		let parentDirectory_URL = DocumentPersister.documentFiles_parentDirectory_URL
		let directoryContents = try FileManager.default.contentsOfDirectory(
			at: parentDirectory_URL,
			includingPropertiesForKeys: nil,
			options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
		)
		// going to assume they're not directories - probably is better way to check or pre-filter
		for (_, fileURL) in directoryContents.enumerated() {
			let filename = fileURL.lastPathComponent
			let preV0_filenameSuffix = "."+DocumentPersister.DocumentFileDescription.preV0_filenameExt
			let preV0_filenameSuffix_length = preV0_filenameSuffix.count
			if filename.hasSuffix(preV0_filenameSuffix) == false {
				DDLog.Info("LocalDataMigrations", "Skipping \(fileURL)")
				continue
			}
			let fileData: Data = try Data(contentsOf: fileURL, options: [])
			//
			// "old" persistable object records:
			var isOldPersistableObjectRecord = false
			var mutable_addSAfterPrefix: String?
			if filename.hasPrefix("Wallet__") {
				isOldPersistableObjectRecord = true
				mutable_addSAfterPrefix = "Wallet"
			} else if filename.hasPrefix("Contact__") {
				isOldPersistableObjectRecord = true
				mutable_addSAfterPrefix = "Contact"
			} else if filename.hasPrefix("FundsRequest__") {
				isOldPersistableObjectRecord = true
				mutable_addSAfterPrefix = "FundsRequest"
			}
			let filename_withExt = fileURL.lastPathComponent
			let endIndex = filename_withExt.index(
				filename_withExt.endIndex,
				offsetBy: -1 * preV0_filenameSuffix_length
			)
			let filename_sansExt = String(filename_withExt[..<endIndex])
			var mutable__to_filenameSansExt = filename_sansExt
			var mutable__to_data = fileData
			if isOldPersistableObjectRecord {
				mutable__to_data = fileData.base64EncodedData() // need to base64 encode it
				//
				let addSAfterPrefix = mutable_addSAfterPrefix!
				mutable__to_filenameSansExt.insert( // pluralize the name of the collection - this naive impl works for the specific inputs above
					"s" as Character,
					at: addSAfterPrefix.index(
						addSAfterPrefix.startIndex,
						offsetBy: addSAfterPrefix.count
					)
				)
			}
			let to_filename = mutable__to_filenameSansExt + "." + DocumentPersister.DocumentFileDescription.v1_filenameExt // new ext
			let to_fileURL = parentDirectory_URL.appendingPathComponent(to_filename)
			//
			// save back with updated (optl updated prefix) and new ext
			DDLog.Info("LocalDataMigrations", "‼️  Moving \(fileURL) to \(to_fileURL)")
			try mutable__to_data.write(to: to_fileURL, options: .atomic)
			//
			// if we haven't exited, we can go ahead and remove the old file
			docsToRemove.append(fileURL)
		}
		try docsToRemove.forEach
		{ (url) in
			try FileManager.default.removeItem(at: url)
		}
	}
}
