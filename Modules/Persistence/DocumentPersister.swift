//
//  DocumentPersister.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
// Internal - Singleton - Cache - use DocumentPersister.shared()
var _shared_documentPersister: DocumentPersister?
//
class DocumentPersister
{
	typealias DocumentId = String
	static func new_DocumentId() -> DocumentId { return UUID().uuidString }
	typealias CollectionName = String
	typealias DocumentJSON = [String: Any]
	static let documentFiles_parentDirectory_URL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
	struct DocumentFileDescription
	{
		var inCollectionName: CollectionName
		var documentId: DocumentId
		static let fileKeyComponentDelimiterString = "__" // not -, because those exist in uuids
		var new_fileKey: String
		{
			return "\(self.inCollectionName)\(DocumentFileDescription.fileKeyComponentDelimiterString)\(self.documentId)"
		}
		static let filenameExt = "MMDBDoc.json" // just trying to pick something fairly unique, and short
		var new_filename: String
		{
			return "\(self.new_fileKey).\(DocumentFileDescription.filenameExt)"
		}
		var new_fileURL: URL
		{
			
			let fileURL = DocumentPersister.documentFiles_parentDirectory_URL.appendingPathComponent(self.new_filename)
			
			return fileURL
		}
	}
	//
	//
	// Interface - Static - Instance access
	//
	static func shared() -> DocumentPersister
	{
		if _shared_documentPersister == nil {
			_shared_documentPersister = DocumentPersister()
		}
		return _shared_documentPersister!
	}
	//
	//
	// Lifecycle - Init
	//
	init()
	{
		self.setup()
	}
	func setup()
	{
	}
	//
	//
	// Interface - Runtime - Accessors
	//
	func Documents(
		withIds ids: [DocumentId],
		inCollectionNamed collectionName: CollectionName
	) -> (
		err_str: String?,
		documentJSONs: [DocumentJSON]?
	)
	{
		let fileDescriptions = ids.map{
			DocumentFileDescription(
				inCollectionName: collectionName,
				documentId: $0
			)
		}
		let documentJSONs = self._read_existentDocumentJSONs(
			withDocumentFileDescriptions: fileDescriptions
		)
		return documentJSONs
	}
	func IdsOfAllDocuments(
		inCollectionNamed collectionName: CollectionName
	) -> (
		err_str: String?,
		ids: [DocumentId]?
	)
	{
		let (err_str, fileDescriptions) = self._read_documentFileDescriptions(
			inCollectionNamed: collectionName
		)
		if err_str != nil {
			return (err_str, nil)
		}
		assert(fileDescriptions != nil, "nil fileDescriptions")
		var ids = [DocumentId]()
		for (_, fileDescription) in fileDescriptions!.enumerated() {
			ids.append(fileDescription.documentId)
		}
		//
		return (nil, ids)
	}
	func AllDocuments(
		inCollectionNamed collectionName: CollectionName,
		_ fn: @escaping (
			_ err_str: String,
			_ documents: [DocumentJSON]?
		) -> Void
	) -> Void
	{
	}
	//
	//
	// Interface - Runtime - Imperatives
	//
	func Insert(
		document: DocumentJSON,
		intoCollectionNamed collectionName: CollectionName
	) -> Void
	{
	}
	func UpdateDocument(
		withId id: DocumentId,
		inCollectionNamed collectionName: CollectionName,
		withDocument updatedDocument: DocumentJSON
	) -> Void
	{
	}
	func RemoveDocuments(
		withIds ids: [DocumentId],
		inCollectionNamed collectionName: CollectionName
	) -> Void
	{
	}
	func RemoveAllDocuments(
		inCollectionNamed collectionName: CollectionName
	) -> Void
	{
	}
	//
	//
	// Internal - Accessors - Files
	//
	func _read_existentDocumentJSONs(
		withDocumentFileDescriptions documentFileDescriptions: [DocumentFileDescription]?
	) -> (
		err_str: String?,
		documentJSONs: [DocumentJSON]?
	)
	{
		var documentJSONs = [DocumentJSON]()
		guard let documentFileDescriptions = documentFileDescriptions, documentFileDescriptions.count > 0 else {
			return (nil, documentJSONs)
		}
		for (_, documentFileDescription) in documentFileDescriptions.enumerated() {
			let (err_str, documentJSON) = self.__read_existentDocumentJSON(withDocumentFileDescription: documentFileDescription)
			if err_str != nil {
				return (err_str, nil) // immediately
			}
			assert(documentJSON != nil, "nil documentJSON")
			documentJSONs.append(documentJSON!)
		}
		return (nil, documentJSONs)
	}
	func __read_existentDocumentJSON(
		withDocumentFileDescription documentFileDescription: DocumentFileDescription
	) -> (
		err_str: String?,
		documentJSON: DocumentJSON?
	)
	{
		let expected_fileURL = documentFileDescription.new_fileURL
		var fileData: Data
		do {
			fileData = try Data(contentsOf: expected_fileURL, options: [])
		} catch (let e) {
			return (e.localizedDescription, nil)
		}
		var json: [String: Any]
		do {
			json = try JSONSerialization.jsonObject(with: fileData) as! [String: Any]
		} catch (let e) {
			return (e.localizedDescription, nil)
		}
		return (nil, json)
	}
	func _read_documentFileDescriptions(
		inCollectionNamed collectionName: CollectionName
	) -> (
		err_str: String?,
		fileDescriptions: [DocumentFileDescription]?
	)
	{
		var fileDescriptions = [DocumentFileDescription]()
		let parentDirectory_URL = DocumentPersister.documentFiles_parentDirectory_URL
		do {
			let directoryContents = try FileManager.default.contentsOfDirectory(
				at: parentDirectory_URL,
				includingPropertiesForKeys: nil,
				options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
			)
			// filtering to what should be JSON doc files
			let dbDocumentFileURLs = directoryContents.filter{
				$0.pathExtension == DocumentFileDescription.filenameExt
			}
			// going to assume they're not directories - probably is better way to check or pre-filter
			let dbDocumentFileNames = dbDocumentFileURLs.map{
				$0.deletingPathExtension().lastPathComponent
			}
			for (_, filename_sansExt) in dbDocumentFileNames.enumerated() {
				let fileKey = filename_sansExt // assumption
				let fileKey_components = fileKey.components(separatedBy: DocumentFileDescription.fileKeyComponentDelimiterString)
				if fileKey_components.count != 2 {
					return ("Unrecognized filename format in db data directory.", nil)
				}
				let fileKey_collectionName = fileKey_components[0] as CollectionName
				if fileKey_collectionName != collectionName {
//					console.log("Skipping file named", fileKey, "as it's not in", collectionName)
					continue
				}
				let fileKey_id  = fileKey_components[1] as DocumentId
				let fileDescription = DocumentFileDescription(
					inCollectionName: fileKey_collectionName,
					documentId: fileKey_id
				)
				fileDescriptions.append(fileDescription) // ought to be a JSON doc file
			}
		} catch let error as NSError {
			return (error.localizedDescription, nil)
		}
		return (nil, fileDescriptions)
	}
	//
	//
	// Internal - Imperatives - File writing
	//
	func _write_fileDescriptionDocumentData(
		fileDescription: DocumentFileDescription,
		jsonToWrite: DocumentJSON
	) throws
	{
		let json_Data =  try JSONSerialization.data(
			withJSONObject: jsonToWrite,
			options: []
		)
		let fileURL = fileDescription.new_fileURL
		try json_Data.write(to: fileURL, options: .atomic)
	}
}
